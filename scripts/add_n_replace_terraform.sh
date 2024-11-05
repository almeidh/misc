#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <platform> <version>"
    exit 1
fi

# Assigning the input arguments to variables
TERRAFORM_PLATFORM=$1
TERRAFORM_VERSION=$2

# Define the URL for the Terraform zip file
TERRAFORM_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TERRAFORM_PLATFORM}.zip"

# Download the zip file
echo "Downloading Terraform version ${TERRAFORM_VERSION} for platform ${TERRAFORM_PLATFORM}..."
wget ${TERRAFORM_URL} -O terraform_${TERRAFORM_VERSION}.zip

# Check if download was successful
if [ $? -ne 0 ]; then
    echo "Failed to download Terraform. Please check the version and platform."
    exit 1
fi

# Unzip the downloaded file
echo "Unzipping Terraform..."
unzip terraform_${TERRAFORM_VERSION}.zip

# Move the terraform binary to /usr/bin
echo "Moving Terraform binary to /usr/bin..."
mv terraform /usr/bin 

# Clean up the zip file
rm terraform_${TERRAFORM_VERSION}.zip

# Verify the installation
echo "Verifying Terraform installation..."
terraform --version
