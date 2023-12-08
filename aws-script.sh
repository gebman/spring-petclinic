#!/bin/bash
user="mlabecki" #change this

function destroy_resources {
    trap - EXIT
    trap - ERR
    echo "Destroying resources..."
    aws ec2 terminate-instances --instance-ids $instance_id  > /dev/null 
    if [ ! -z ${instance_id+x} ]; then
        echo "Waiting for the EC2 instance to terminate... (this might take 1-3 minutes)"
        while [ "$ec2_status" != "terminated" ]; do
            ec2_status=`aws ec2 describe-instance-status --instance-id $instance_id --include-all-instances \
            --query 'InstanceStatuses[0].InstanceState.Name' --output text` 
        done
        echo "EC2 instance terminated, destroying rest of the resources"
    fi
    aws ecr delete-repository --repository-name "${user}/spring-petclinic" --force > /dev/null
    aws iam remove-role-from-instance-profile --instance-profile-name allow_ec2_ecr_profile --role-name "allow_ec2_ecr_${user}" 
    aws iam delete-instance-profile --instance-profile-name allow_ec2_ecr_profile 
    aws iam detach-role-policy --role-name "allow_ec2_ecr_${user}" --policy-arn arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess 
    aws iam delete-role --role-name "allow_ec2_ecr_${user}" 
    aws ec2 detach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id 
    aws ec2 delete-internet-gateway --internet-gateway-id $igw_id 
    aws ec2 disassociate-route-table --association-id $rt_assoc_id 
    aws ec2 delete-route-table --route-table-id $rt_id 
    aws ec2 delete-subnet --subnet-id $subnet_id 
    aws ec2 delete-security-group --group-id $sg_id 
    aws ec2 delete-vpc --vpc-id $vpc_id 
    echo "Destroyed all resources"
    exit
}

trap destroy_resources EXIT
trap destroy_resources ERR

common_tags="{Key=Project,Value=2023_intership_warsaw_mlabecki},{Key=Owner,Value=${user}}"

# check aws login-status

aws_info=`aws sts get-caller-identity --output text`

echo "Current AWS account info:" $aws_info
# create vpc

vpc_id=`aws ec2 create-vpc \
    --cidr-block 172.16.0.0/16 \
    --tag-specification \
    ResourceType=vpc,Tags="[$common_tags,{Key=Name,Value=module_task_${user}VPC}]" \
    --output text \
    --query 'Vpc.VpcId'`
echo "Sucessfully created a VPC, vpc-id:" $vpc_id

# create security group

sg_id=`aws ec2 create-security-group \
    --vpc-id $vpc_id \
    --group-name 'module task SG' \
    --description 'this security group allows ssh and http from the internet, created automatically by a bash script' \
    --tag-specification \
    ResourceType=security-group,Tags="[$common_tags,{Key=Name,Value=module_task_${user}SG}]" \
    --output text \
    --query 'GroupId'`
aws ec2 authorize-security-group-ingress \
    --group-id $sg_id \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 > /dev/null
aws ec2 authorize-security-group-ingress \
    --group-id $sg_id \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 > /dev/null
echo "Sucessfully created a security group, sg-id:" $sg_id

# create subnet

subnet_id=`aws ec2 create-subnet \
    --vpc-id $vpc_id \
    --cidr-block 172.16.0.0/24 \
    --tag-specification \
    ResourceType=subnet,Tags="[$common_tags,{Key=Name,Value=module_task_${user}SUBNET}]" \
    --output text \
    --query 'Subnet.SubnetId'`
aws ec2 modify-subnet-attribute --subnet-id $subnet_id --map-public-ip-on-launch
echo "Sucessfully created a subnet, subnet-id:" $subnet_id

# create internet gateway 

igw_id=`aws ec2 create-internet-gateway \
    --tag-specification \
    ResourceType=internet-gateway,Tags="[$common_tags,{Key=Name,Value=module_task_${user}IGW}]" \
    --output text \
    --query 'InternetGateway.InternetGatewayId'`
aws ec2 attach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id > /dev/null
echo "Sucessfully created an internet gateway, igw-id:" $igw_id

#create a route table

rt_id=`aws ec2 create-route-table \
    --vpc-id $vpc_id \
    --tag-specification \
    ResourceType=route-table,Tags="[$common_tags,{Key=Name,Value=module_task_${user}RT}]" \
    --output text \
    --query 'RouteTable.RouteTableId'`
aws ec2 create-route --route-table-id $rt_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id > /dev/null
rt_assoc_id=`aws ec2 associate-route-table --route-table-id $rt_id --subnet-id $subnet_id --output text --query 'AssociationId'`
echo "Sucessfully created a route table, rt-id:" $rt_id

# create an IAM role with ecr permissions

aws iam create-role --role-name "allow_ec2_ecr_${user}" --assume-role-policy-document file://./allow_ec2_to_ecr.json > /dev/null
aws iam attach-role-policy --role-name "allow_ec2_ecr_${user}" --policy-arn arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess > /dev/null
aws iam create-instance-profile --instance-profile-name allow_ec2_ecr_profile > /dev/null
aws iam add-role-to-instance-profile --instance-profile-name allow_ec2_ecr_profile --role-name "allow_ec2_ecr_${user}" > /dev/null
echo "Sucessfully created an IAM role"

# create the ecr repository

aws ecr create-repository --repository-name "${user}/spring-petclinic" > /dev/null
echo "Sucessfully created the ECR repository"

# authenticate and push the image

region=`aws configure get region`
account_id=`aws sts get-caller-identity --query "Account" --output text`

aws ecr get-login-password --region $region | docker login --username AWS --password-stdin "${account_id}.dkr.ecr.${region}.amazonaws.com/${user}/spring-petclinic"
docker build . -t "${account_id}.dkr.ecr.${region}.amazonaws.com/${user}/spring-petclinic"
docker push "${account_id}.dkr.ecr.${region}.amazonaws.com/${user}/spring-petclinic"

# create an ec2 instance

instance_id=`aws ec2 run-instances \
    --iam-instance-profile Name=allow_ec2_ecr_profile \
    --subnet-id $subnet_id \
    --security-group-ids $sg_id \
    --instance-type t2.small \
    --image-id ami-0230bd60aa48260c6 \
    --tag-specification \
    ResourceType=instance,Tags="[$common_tags,{Key=Name,Value=module_task_${user}INSTANCE}]" \
    --metadata-options "InstanceMetadataTags=enabled" \
    --output text \
    --query 'Instances[0].InstanceId' \
    --user-data file://./ec2-user-data.txt`

echo "Sucesfully created an ec2 instance, instance-id:" $instance_id

instance_ip=`aws ec2 describe-instances --instance-ids $instance_id --query 'Reservations[0].Instances[0].PublicIpAddress' --output text`
echo $instance_ip

echo 'Destroy the entire stack?(y/n)?'
read answer

if [ "$answer" != "${answer#[Yy]}" ] ;then 
    destroy_resources
fi