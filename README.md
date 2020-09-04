# Utilizing terraform, AWS CodePipeline, and S3 to host a REACT.js application

## Outline
1. Overview
    1. Assumptions
    1. What are we building?
    1. TL;DR - Is there a boot script so I don't need to read below?
1. Required information & Manual execution.
    1. The repo
    1. Github personal access token
    1. Planning the buckets
    1. Creating the infrastructure bucket
    1. Creating the pipeline
1. Understanding the code
    1. Website Hosting on S3
    1. AWS CodePipeline
        1. Source Stage
        1. Build Stage
        1. Deploy Stage
    1. AWS CodeBuild
        1. Terraform code
        1. Buildspec.yml
    1. AWS SNS
    1. AWS Budgets

## Overview
### Assumptions
These are assumptions being made prior to beginning.
1. You have some familiarity with Terraform and AWS
1. You have Terraform version >=0.13.0 installed
    1. If you don't, I highly recommend installing [tfswitch](https://tfswitch.warrensbox.com/)
        1. Then just navigate to the `config` directory and run `tfswitch`
1. You have the aws cli installed and have run aws configure to set your aws configuration
    1. Terraform sources your AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_CODE from this location. [See here for more details](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication)

### What are we building?
This repo takes the idea of using Terraform with the AWS provider to utilize an AWS CodePipeline to automatically source,
test, build, and deploy a React.js application from github. It will continually monitor for new updates to the specific
branch and rerun the pipeline on 
each subsequent run.  

This guide is meant to be just an opportunity to get your feet wet and have a working pipeline within AWS.

### TL;DR - Is there a boot script so I don't need to read below?
Absolutely. There is a bootstrap.sh script located in [config/bootstrap](config/bootstrap). Running the script will ask
for seven pieces of information. Let's cover those quickly so you can get started. All the buckets below should **not**
be created already
- infra bucket = a bucket name that will be created in S3 to store the main state files in
- pipeline artifacts bucket = A bucket where the pipeline will store its artifacts during the process
- Github repo name = if you forked this repo the value for this is `age-of-name` otherwise it's the name of your repo
- Github repo owner = this is your github username
- Github repo branch = the name of the branch to build from this guide works from `master`
- Github personal access token = AWS needs access to Github. Follow these steps to generate a token: [docs](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token)
  - When creating the token make sure `repo` and `admin:repo_hook` are checked at the parent level
- Website hosting bucket = a bucket to host your website. Example `your-initials-age-of-name.com`

Once you have all of this information, navigate to `config/bootstrap` and run `./bootstrap.sh`

This will provision everything you need to see your pipeline and the last output you see is where your website is being
hosted.

**Happy coding!**

## Required information & Manual execution.
### The repo
To get started with this guide the first step that should be done is to fork this repository in to your own personal
github account. This is needed as AWS will need to have an access token to be able to connect to the repository to source
the necessary artifacts. 

There are three key pieces of information that is needed that you should note down. Two come from the URL for your repository
the last one is left up to the reader but I have a recommendation
* Github owner
* Github repo name
* Github repo branch  

Example of finding the owner and repo name. Using this current repos URL: https://github.com/msherman/age-of-name 
* The owner is: `msherman`
* the repo name is: `age-of-name`
* the branch I would default to: `master`

This repository holds all of the necessary artifacts to build the React application and create the infrastructure via
Terraform. If you want to see what the end application will look like prior to deploying, navigate to the root of the
project and execute `npm install && npm run dev`. This will spin up a local version of the application for you to see the
final state which is a simple react app that makes one async call to get the age of a name.
### Github personal access token
As mentioned in the previous section AWS CodePipeline will need an access token to be able to access the repository and
source the necessary artifacts to use inside the CodePipeline phases. To generate a code Github has some great [documentation](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token)  

When the token is generated there are two main areas that AWS needs access to be able to source the artifacts. First it
will need access to the whole `repo` block which includes the following:
* repo
  * repo:status
  * repo_deployment
  * public_repo
  * repo:invite
  * security_events

The other section it needs access to is `admin:repo_hook` which will give it access to monitor the code base. This includes
* admin:repo_hook
  * write:repo_hook
  * read:repo_hook

After clicking Generate Token copy the token somewhere locally.

**DO NOT COMMIT THIS CODE IN TO YOUR CODE BASE**

### Planning the buckets
Now that the github details are out of the way and noted down we need to start thinking about and planning our buckets
that will be utilized in AWS S3. 

In total we will need three buckets.
* The infrastructure bucket  

This bucket is responsible for housing all of the terraform state that will be generated as part of the main pipeline.
We are going to utilize the terraform file in the [config/bootstrap](config/bootstrap) directory to generate this bucket.
My recommendation is something along the lines of `initials-random 3 numbers-age-of-name-infra` ie. if your initials were ms
`ms-247-age-of-name-infra`

* The pipeline bucket

This bucket is responsible for housing all of the artifacts created as part of the AWs CodePipeline process. We won't 
necessarily be interacting with this bucket but the process needs it. My recommendation is something along the lines of
`initials-same 3 numbers as above-age-of-name-pipeline` ie. if your initials were `ms` and the previous number you chose was 
`247` then `ms-247-age-of-name-pipeline`

* The website hosting bucket

S3 has the awesome ability of being able to host static web files. We will leverage this as part of process and serve
the files from an S3 bucket. In the end the output from the terraform commands will provide us with the URL to where
the application is hosted, but we need to tell it the bucket to put it in. My recommendation is to follow the same pattern
as above `intiais-same 3 numbers as above-age-of-name.com` ie if your intials were `ms` and the previous number you chose was
`247` then `ms-247-age-of-name.com`

Great! We now have all the necessary pieces to move on and create the infrastructure and application!

### Creating the infrastructure bucket
To create the infrastructure bucket open a terminal and navigate to [config/bootstrap](config/bootstrap). Keep in mind we are *NOT*
running the `bootstrap.sh` file we just need access to the terraform files to create the infrastructure bucket.

Now that we are here lets initialize terraform with a `terraform init`. After terraform is initailized we need to get
our bucket created. If you look at the `main.tf` file you'll notice that it is creating an S3 bucket by using a variable
`infra-bucket-name`. We will pass this variable in when we execute terraform.

In the terminal execute `terraform plan -var="infra_bucket_name=your_infrastructure_bucket_name_here"`

ie. `terraform plan -var="infra_bucket_name=ms-247-age-of-nameinfra`.

This will provide the output of the plan for the infrastructure it will create. 

Run `terraform apply -var="infra_bucket_name=your_infrastructure_bucket_nameh_here"` and after
reviewing type in yes. At this point wait for the bucket to be created.

While it creates it is worth noting, this process is going to store local terraform state to your computer ideally this would
be in the cloud but its a catch 22 as you need a bucket to store the state in, but don't have a bucket yet so a bucket needs
to be created. It could be manually created and the above could be skipped.

Let's move on to creating the AWS CodePipeline and deploying our application to an S3 bucket.
### Creating the pipeline
## Understanding the code
### Website Hosting on S3
### AWS CodePipeline
#### Source Stage
#### Build Stage
#### Deploy Stage
### AWS CodeBuild
#### Terraform code
#### Buildspec.yml
### AWS SNS
### AWS Budgets