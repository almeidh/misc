#!/bin/bash

set -e

MFA_ARN='arn:aws:iam::<aws-acc>:mfa/<aws-username>'

if [ $# -ne 1 ]; then
  echo "Usage: $0  <MFA_TOKEN_CODE>"
  echo "Where:"
  echo "   <MFA_TOKEN_CODE> = Code from virtual MFA device"
  exit 2
fi

OUTPUT=`aws --profile default sts get-session-token --serial-number $MFA_ARN --token-code $1`

aws_access_key_id=`echo $OUTPUT | jq -r '.Credentials.AccessKeyId'`
aws_secret_access_key=`echo $OUTPUT | jq -r '.Credentials.SecretAccessKey'`
aws_session_token=`echo $OUTPUT | jq -r '.Credentials.SessionToken'`

aws --profile sts configure set aws_access_key_id "$aws_access_key_id"
aws --profile sts configure set aws_secret_access_key "$aws_secret_access_key"
aws --profile sts configure set aws_session_token "$aws_session_token"

echo "Credentials configured"
