packer {
  required_plugins {
    hyperv = {
      source  = "github.com/hashicorp/hyperv"
      version = "~> 1"
    }
  }
}

locals {
  vm_name      = "ubuntu-22.04-minimal"
  iso_url      = "https://releases.ubuntu.com/jammy/ubuntu-22.04.5-live-server-amd64.iso"
  iso_checksum = "sha256:9bc6028870aef3f74f4e16b900008179e78b130e6b0b9a140635434a46aa98b0"

  username = "ubuntu"
  password = "ubuntu"
}

source "hyperv-iso" "ubuntu" {
  # ISO configuration
  iso_url      = local.iso_url
  iso_checksum = local.iso_checksum

  # VM hardware settings
  cpus       = 2
  memory     = 4096
  disk_size  = 40960
  generation = 2

  # Network configuration
  switch_name = "Default Switch"

  # SSH configuration
  ssh_username            = local.username
  ssh_password            = local.password
  ssh_timeout             = "60m"
  ssh_handshake_attempts  = 100
  ssh_wait_timeout        = "60m"

  # Output configuration
  output_directory = "./output-ubuntu-minimal"
  vm_name          = local.vm_name
  skip_export      = false

  # Cloud-init configuration
  cd_content = {
    "meta-data" = ""
    "user-data" = <<-EOF
      #cloud-config
      autoinstall:
        version: 1
        early-commands:
          - sudo systemctl stop ssh
        apt:
          geoip: true
          preserve_sources_list: false
          primary:
            - arches: [amd64, i386]
              uri: http://archive.ubuntu.com/ubuntu
            - arches: [default]
              uri: http://ports.ubuntu.com/ubuntu-ports
        locale: en_US
        keyboard:
          layout: us
        storage:
          layout:
            name: direct
        identity:
          hostname: ${local.vm_name}
          username: ${local.username}
          password: "$6$2XYHnHc/feuG/kIv$x9vQHRuNcX3QRDyEjNn6H6qyPaAHn9hJxaUvgTTPcdBxq1QpPw7Kf7YsFBIyANKrZjS7cGgVCYx2DhJgIXTAM1"
        ssh:
          install-server: true
          allow-pw: true
        packages:
          - openssh-server
          - cloud-init
          - linux-virtual
          - linux-cloud-tools-virtual
          - linux-tools-virtual
        user-data:
          disable_root: false
          timezone: UTC
        late-commands:
          - sed -i -e 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /target/etc/ssh/sshd_config
          - echo '${local.username} ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/${local.username}
          - curtin in-target --target=/target -- chmod 440 /etc/sudoers.d/${local.username}
      EOF
  }
  cd_label = "cidata"

  # Boot configuration
  boot_command = [
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall ds=\"nocloud\"",
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot",
    "<enter>"
  ]
  boot_wait          = "5s"
  first_boot_device  = "DVD"
  enable_secure_boot = false

  # Shutdown configuration
  shutdown_command = "echo '${local.password}' | sudo -S shutdown -P now"
}

build {
  sources = ["source.hyperv-iso.ubuntu"]

  # Optional: Add basic provisioning
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get clean"
    ]
  }

  provisioner "shell" {
    inline = [
      "curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sudo sh -s -- -b /usr/local/bin",                        # syft
      "curl -sSfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin v0.68.2", # trivy
      "sudo syft / -o cyclonedx-json > /tmp/syft-sbom.cdx.json",
      "sudo trivy fs / --format cyclonedx --output /tmp/trivy-sbom.cdx.json",
      "sudo chmod 644 /tmp/syft-sbom.cdx.json /tmp/trivy-sbom.cdx.json"
    ]
  }

  provisioner "file" {
    direction   = "download"
    source      = "/tmp/syft-sbom.cdx.json"
    destination = "./artifacts/sbom-syft.json"
  }

  provisioner "file" {
    direction   = "download"
    source      = "/tmp/trivy-sbom.cdx.json"
    destination = "./artifacts/sbom-trivy.json"
  }
}
