
#!/bin/bash

set -Eeuo pipefail

# ==========================================================
# Production Linux Server Automation
# Script: create-ec2.sh
# ==========================================================

# -----------------------------
# Usage validation
# -----------------------------

if [[ $# -ne 4 ]]; then
    echo "Usage:"
    echo "./scripts/create-ec2.sh <region> <key-name> <subnet-id> <security-group-id>"
    echo ""
    echo "Example:"
    echo "./scripts/create-ec2.sh ap-south-1 production-server-key subnet-xxxx sg-xxxx"
    exit 1
fi

# -----------------------------
# Input variables
# -----------------------------

REGION="$1"
KEY_NAME="$2"
SUBNET_ID="$3"
SECURITY_GROUP_ID="$4"

# -----------------------------
# Project directory
# -----------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

KEY_FILE="$PROJECT_ROOT/${KEY_NAME}.pem"

# -----------------------------
# EC2 configuration
# -----------------------------

INSTANCE_TYPE="t3.micro"
UBUNTU_VERSION="24.04"

AMI_PARAMETER="/aws/service/canonical/ubuntu/server/${UBUNTU_VERSION}/stable/current/amd64/hvm-ssd-gp3/ami-id"

# -----------------------------
# Error handling
# -----------------------------

trap 'echo "ERROR: Script failed at line $LINENO."' ERR

# -----------------------------
# Validate AWS CLI
# -----------------------------

if ! command -v aws >/dev/null 2>&1; then
    echo "ERROR: AWS CLI is not installed."
    exit 1
fi

# -----------------------------
# Validate region
# -----------------------------

if [[ ! "$REGION" =~ ^[a-z]{2}-[a-z]+-[0-9]+$ ]]; then
    echo "ERROR: Invalid AWS region: $REGION"
    exit 1
fi

# -----------------------------
# Validate subnet ID
# -----------------------------

if [[ ! "$SUBNET_ID" =~ ^subnet-[a-zA-Z0-9]+$ ]]; then
    echo "ERROR: Invalid subnet ID: $SUBNET_ID"
    exit 1
fi

# -----------------------------
# Validate security group ID
# -----------------------------

if [[ ! "$SECURITY_GROUP_ID" =~ ^sg-[a-zA-Z0-9]+$ ]]; then
    echo "ERROR: Invalid security group ID: $SECURITY_GROUP_ID"
    exit 1
fi

# -----------------------------
# Validate AWS authentication
# -----------------------------

echo "Checking AWS authentication..."

aws sts get-caller-identity \
    --region "$REGION" \
    >/dev/null

echo "AWS authentication successful."

# -----------------------------
# Validate subnet
# -----------------------------

echo "Checking subnet..."

SUBNET_INFO=$(aws ec2 describe-subnets \
    --region "$REGION" \
    --subnet-ids "$SUBNET_ID" \
    --query "Subnets[0].[State,VpcId]" \
    --output text)

if [[ -z "$SUBNET_INFO" || "$SUBNET_INFO" == "None" ]]; then
    echo "ERROR: Subnet not found: $SUBNET_ID"
    exit 1
fi

SUBNET_STATE=$(echo "$SUBNET_INFO" | awk '{print $1}')
SUBNET_VPC_ID=$(echo "$SUBNET_INFO" | awk '{print $2}')

if [[ "$SUBNET_STATE" != "available" ]]; then
    echo "ERROR: Subnet is not available."
    echo "Current state: $SUBNET_STATE"
    exit 1
fi

echo "Subnet is available."
echo "Subnet VPC: $SUBNET_VPC_ID"

# -----------------------------
# Validate security group
# -----------------------------

echo "Checking security group..."

SG_INFO=$(aws ec2 describe-security-groups \
    --region "$REGION" \
    --group-ids "$SECURITY_GROUP_ID" \
    --query "SecurityGroups[0].[GroupId,VpcId]" \
    --output text)

if [[ -z "$SG_INFO" || "$SG_INFO" == "None" ]]; then
    echo "ERROR: Security group not found: $SECURITY_GROUP_ID"
    exit 1
fi

SG_VPC_ID=$(echo "$SG_INFO" | awk '{print $2}')

if [[ "$SUBNET_VPC_ID" != "$SG_VPC_ID" ]]; then
    echo "ERROR: Subnet and security group belong to different VPCs."
    echo "Subnet VPC: $SUBNET_VPC_ID"
    echo "Security Group VPC: $SG_VPC_ID"
    exit 1
fi

echo "Security group belongs to the same VPC."

# -----------------------------
# Manage key pair
# -----------------------------

echo ""
echo "Checking key pair: $KEY_NAME"

KEY_EXISTS=$(aws ec2 describe-key-pairs \
    --region "$REGION" \
    --key-names "$KEY_NAME" \
    --query "KeyPairs[0].KeyName" \
    --output text 2>/dev/null || true)

if [[ "$KEY_EXISTS" == "$KEY_NAME" ]]; then

    echo "Key pair already exists in AWS."

    if [[ ! -f "$KEY_FILE" ]]; then
        echo ""
        echo "ERROR: Private key file does not exist:"
        echo "$KEY_FILE"
        echo ""
        echo "AWS cannot download the private key again."
        echo "Use an existing .pem file or create a new key pair."
        exit 1
    fi

    echo "Private key found:"
    echo "$KEY_FILE"

else

    if [[ -f "$KEY_FILE" ]]; then
        echo "ERROR: Local key file already exists, but AWS key pair does not."
        echo "File: $KEY_FILE"
        echo ""
        echo "Choose a different key name or remove the unused file."
        exit 1
    fi

    echo "Key pair does not exist in AWS."
    echo "Creating key pair: $KEY_NAME"

    umask 077

    aws ec2 create-key-pair \
        --region "$REGION" \
        --key-name "$KEY_NAME" \
        --query "KeyMaterial" \
        --output text > "$KEY_FILE"

    chmod 400 "$KEY_FILE"

    echo "Key pair created successfully."
    echo "Private key saved at:"
    echo "$KEY_FILE"

fi

# -----------------------------
# Find Ubuntu AMI
# -----------------------------

echo ""
echo "Finding Ubuntu ${UBUNTU_VERSION} AMI..."

AMI_ID=$(aws ssm get-parameter \
    --region "$REGION" \
    --name "$AMI_PARAMETER" \
    --query "Parameter.Value" \
    --output text)

if [[ -z "$AMI_ID" || "$AMI_ID" == "None" ]]; then
    echo "ERROR: Ubuntu AMI was not found."
    exit 1
fi

echo "Ubuntu AMI: $AMI_ID"

# -----------------------------
# Display configuration
# -----------------------------

echo ""
echo "=========================================="
echo "EC2 INSTANCE CONFIGURATION"
echo "=========================================="
echo "Region:           $REGION"
echo "AMI ID:           $AMI_ID"
echo "Instance Type:    $INSTANCE_TYPE"
echo "Key Name:         $KEY_NAME"
echo "Private Key:      $KEY_FILE"
echo "Subnet ID:        $SUBNET_ID"
echo "Security Group:   $SECURITY_GROUP_ID"
echo "=========================================="

# -----------------------------
# Confirmation
# -----------------------------

echo ""
read -r -p "Type 'yes' to launch the EC2 instance: " CONFIRMATION

if [[ "$CONFIRMATION" != "yes" ]]; then
    echo "Operation cancelled."
    exit 0
fi

# -----------------------------
# Launch EC2 instance
# -----------------------------

echo ""
echo "Launching EC2 instance..."

INSTANCE_ID=$(aws ec2 run-instances \
    --region "$REGION" \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --subnet-id "$SUBNET_ID" \
    --security-group-ids "$SECURITY_GROUP_ID" \
    --associate-public-ip-address \
    --tag-specifications \
        'ResourceType=instance,Tags=[{Key=Name,Value=production-server}]' \
    --query "Instances[0].InstanceId" \
    --output text)

if [[ -z "$INSTANCE_ID" || "$INSTANCE_ID" == "None" ]]; then
    echo "ERROR: EC2 instance was not created."
    exit 1
fi

echo "EC2 instance created."
echo "Instance ID: $INSTANCE_ID"

# -----------------------------
# Wait for instance to run
# -----------------------------

echo ""
echo "Waiting for EC2 instance to reach running state..."

aws ec2 wait instance-running \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID"

echo "EC2 instance is running."

# -----------------------------
# Retrieve instance information
# -----------------------------

INSTANCE_INFO=$(aws ec2 describe-instances \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].[InstanceId,State.Name,PrivateIpAddress,PublicIpAddress]" \
    --output text)

INSTANCE_STATE=$(echo "$INSTANCE_INFO" | awk '{print $2}')
PRIVATE_IP=$(echo "$INSTANCE_INFO" | awk '{print $3}')
PUBLIC_IP=$(echo "$INSTANCE_INFO" | awk '{print $4}')

# -----------------------------
# Display result
# -----------------------------

echo ""
echo "=========================================="
echo "EC2 INSTANCE CREATED SUCCESSFULLY"
echo "=========================================="
echo "Instance ID:     $INSTANCE_ID"
echo "State:           $INSTANCE_STATE"
echo "Private IP:      $PRIVATE_IP"
echo "Public IP:       $PUBLIC_IP"
echo "Private Key:     $KEY_FILE"
echo "=========================================="

if [[ -n "$PUBLIC_IP" && "$PUBLIC_IP" != "None" ]]; then
    echo ""
    echo "SSH command:"
    echo "ssh -i \"$KEY_FILE\" ubuntu@$PUBLIC_IP"
else
    echo ""
    echo "WARNING: No public IP address was assigned."
    echo "Check your subnet and networking configuration."
fi