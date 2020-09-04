#!/bin/bash

# This script is designed to generate a bucket that will store the overall state
# from the main execution and limit the only local state to be the creation of one bucket
set -e

echo "The following script is here to bootstrap the infrastructure bucket
and then perform the necessary commands to create the entire environment.

This script is intended for those that just want to stand up the infrastructure.

I highly recommend following the readme instead of utilizing this bootstrap
script.

Enter Y or y to continue. All other inputs will exit."
read continue
if [ "$continue" == "Y" ] || [ "$continue" == "y" ]; then
  echo
  echo "---------------------------------------"
  echo "Continuing. Gathering necessary inputs."
  echo "---------------------------------------"
  echo
else
  echo
  echo "--------------------------"
  echo "Exiting. Enjoy the README!"
  echo "--------------------------"
  exit 0
fi

#get the inputs
echo Enter the name of the infra bucket to create:
read infra_bucket_name

echo
echo Enter the bucket name to store the pipeline artifacts:
read pipeline_bucket_name

echo
echo Enter the name of the github repo to source the code from:
read repo_name

echo
echo Enter the name of the github repo owner:
read repo_owner

echo
echo Enter the name of the branch to build from:
read repo_branch

echo
echo Enter the name of your github personal access token:
read repo_token

echo
echo Enter the name of the bucket that will serve your website:
read website_bucket_name

#create the infra bucket
echo
echo "---------------------------------------"
echo "Creating the infrastructure bucket in s3"
echo "---------------------------------------"
terraform init
terraform apply -auto-approve -var="infra_bucket_name=$infra_bucket_name"

#update the main.tf with bucket
echo
echo "-----------------------------------"
echo "Adding infra bucket name to main.tf"
echo "-----------------------------------"
cd ..
sed -i'.bak' "s/your_infra_bucket_here/$infra_bucket_name/" main.tf
rm main.tf.bak

echo
echo "------------------------------"
echo "Creating terraform.tfvars file"
echo "------------------------------"
cp template.tfvars terraform.tfvars
sed -i'.bak' "s/your_pipeline_bucket_name/$pipeline_bucket_name/" terraform.tfvars
sed -i'.bak' "s/your_repo_branch/$repo_branch/" terraform.tfvars
sed -i'.bak' "s/your_repo_name/$repo_name/" terraform.tfvars
sed -i'.bak' "s/your_repo_owner/$repo_owner/" terraform.tfvars
sed -i'.bak' "s/your_website_bucket_name/$website_bucket_name/" terraform.tfvars
sed -i'.bak' "s/your_repo_token/$repo_token/" terraform.tfvars
#osx annoyingly needs to create a backup file. removing it.
rm terraform.tfvars.bak

#run main terraform code
echo
echo "-----------------------"
echo "Creating code pipeline!"
echo "-----------------------"
terraform init
terraform apply -auto-approve