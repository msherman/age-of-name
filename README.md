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
        1. Pipeline Notifications
    1. AWS CodeBuild
        1. Terraform code
        1. Buildspec.yml
    1. AWS SNS
    1. AWS Budgets
    1. Thought exercise

## Overview
### Assumptions
The below are assumptions that are made prior to beginning.
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

This guide is an opportunity to get your feet wet and have a working pipeline within AWS.

### TL;DR - Is there a boot script so I don't need to read below?
Absolutely. There is a bootstrap.sh script located in [config/bootstrap](config/bootstrap). Running the script will ask
for seven pieces of information. Let's cover quickly to get started. All the buckets below should **not**
be created already.
- infra bucket = a bucket name that will be created in S3 to store the terraform state files for creating the pipeline.
- pipeline artifacts bucket = A bucket where the pipeline will store its artifacts during the process
- Github repo name = if you forked this repo the value for this is `age-of-name` otherwise it's the name of your repo
- Github repo owner = this is your github username
- Github repo branch = the name of the branch to build from this guide works from `master`
- Github personal access token = AWS needs access to Github. Follow these steps to generate a token: [docs](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token)
  - When creating the token make sure `repo` and `admin:repo_hook` are checked at the parent level
- Website hosting bucket = a bucket to host your website. Example `your-initials-age-of-name.com`

Once you have all of this information, navigate to `config/bootstrap` and run `./bootstrap.sh`

This will provision everything you need to see the pipeline, and the terraform output is the s3 url to the website.

**Happy coding!**

## Required information & Manual execution.
### The repo
To get started with this guide the first step that should be done is to fork this repository in to your own personal
github account. This is needed as AWS will need to have an access token to be able to connect to the repository to source
the necessary artifacts. 

There are three key pieces of information that is needed and should be noted down. Two come from the URL for your repository
the last one is up to the reader.
* Github owner
* Github repo name
* Github repo branch  

Example of finding the owner and repo name. Using this current repos URL: https://github.com/msherman/age-of-name 
* The owner is: `msherman`
* the repo name is: `age-of-name`
* the branch I would default to: `master`

This repository holds all the necessary artifacts to build the React application and create the infrastructure via
Terraform. If you want to see what the end application will look like prior to deploying, navigate to the root of the
project and execute `npm install && npm run dev`. This will spin up a local version of the application for you to see the
final state which is a simple React app that makes one async call to get the age of a name.
### Github personal access token
As mentioned in the previous section AWS CodePipeline will need an access token to be able to access the repository and
source the necessary artifacts to use inside the CodePipeline phases. To generate a code Github has some great [documentation](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token).  

With the generated token there are two main areas that AWS needs access to be able to source the artifacts. First it
will need access to the whole `repo` block which includes the following:
* repo
  * repo:status
  * repo_deployment
  * public_repo
  * repo:invite
  * security_events

The other section it needs access to is `admin:repo_hook` which will give it access to monitor the code base. This includes the following:
* admin:repo_hook
  * write:repo_hook
  * read:repo_hook

After clicking `Generate Token` copy the token somewhere locally.

**DO NOT COMMIT THIS PERSONAL ACCESS TOKEN IN TO YOUR CODE BASE**

### Planning the buckets
Now the github details are out of the way and noted down we need to start thinking about and planning our buckets
that will be utilized in AWS S3. If you attempt to utilize the bucket names in the examples it will most likely fail as
that bucket is already in use. S3 buckets are global to _all_ of S3.

In total, we will need three buckets.
* The infrastructure bucket  

This bucket is responsible for housing all the terraform state that will be generated as part of the main pipeline.
We are going to utilize the terraform file in the [config/bootstrap](config/bootstrap) directory to generate this bucket.
My recommendation is something along the lines of `initials-random 3 numbers-age-of-name-infra` ie. if your initials were ms
`ms-247-age-of-name-infra`.

* The pipeline bucket

This bucket is responsible for housing all the artifacts created as part of the AWs CodePipeline process. We won't 
necessarily be interacting with this bucket, but the process needs it. My recommendation is something along the lines of
`initials-same 3 numbers as above-age-of-name-pipeline` ie. if your initials were `ms` and the previous number you chose was 
`247` then `ms-247-age-of-name-pipeline`.

* The website hosting bucket

S3 has the awesome ability of being able to host static web files. We will leverage this as part of process and serve
the files from an S3 bucket. In the end the output from the terraform commands will provide the URL to where
the hosted application, but we need to tell it the bucket to put it in. My recommendation is to follow the same pattern
as above `intiais-same 3 numbers as above-age-of-name.com` ie if your initials were `ms` and the previous number you chose was
`247` then `ms-247-age-of-name.com`.

Great! We now have all the necessary pieces to move on and create the infrastructure and application!

### Creating the infrastructure bucket
To create the infrastructure bucket open a terminal and navigate to [config/bootstrap](config/bootstrap). Keep in mind we are *NOT*
running the `bootstrap.sh` file we just need access to the terraform files to create the infrastructure bucket.

Now let's initialize terraform with a `terraform init`. After terraform is initialized we need to get
our bucket created. If you look at the `main.tf` file you'll notice that it is creating an S3 bucket by using a variable
`infra-bucket-name`. We will pass this variable in when we execute terraform.

In the terminal execute `terraform plan -var="infra_bucket_name=your_infrastructure_bucket_name_here"`

ie. `terraform plan -var="infra_bucket_name=ms-247-age-of-nameinfra`.

This will provide the output of the plan for the infrastructure it will create. 

Run `terraform apply -var="infra_bucket_name=your_infrastructure_bucket_nameh_here"` and after
reviewing type `yes`. At this point wait for the bucket to be created.

While it creates it is worth noting, this process is going to store local terraform state to your computer ideally this would
be in the cloud, but it's a catch 22 as you need a bucket to store the state in, but don't have a bucket yet so a bucket needs
to be created. It could be manually created, and the above could be skipped.

Let's move on to creating the AWS CodePipeline and deploying our application to an S3 bucket.
### Creating the pipeline
Now we have an infrastructure bucket created we can start the process for creating the pipeline and deploying the
React artifacts to S3. There are a few approaches that can be taken to running the terraform code. I will outline two of
them.

**First option:**  
1. In your terminal navigate to the [config/](config) directory
1. Initialize terraform with a `terraform init`
1. Execute a `terraform plan -out=plan` which will generate a terraform plan to be passed to the `apply` phase
1. The planning process will ask for six inputs (alphabetical order)
    1. pipeline_bucket_name = the pipeline bucket we planned for above
    1. repo_branch = the branch to build the code from
    1. repo_name = the repo where your code is stored
    1. repo_owner = your username in github
    1. repo_token = the personal access token created previously
    1. website_bucket_name = the bucket that will serve as your website.  
1. Execute `terraform apply "plan"` to provision the infrastructure.

**Second option (preferred):**  
I am the kind of person who doesn't want to type the variables in again and again. Let's set up a file to store variables.
1. In your terminal navigate to the [config/](config) directory
1. create a copy of the `template.tfvars` file to have the magic naming picked up by terraform by running
`cp template.tfvars terraform.tfvars` 
1. Update the appropriate variables in the `terraform.tfvars` file
    1. pipeline_bucket_name = the pipeline bucket we planned for above
    1. repo_branch = the branch to build the code from
    1. repo_name = the repo where your code is stored
    1. repo_owner = your username in github
    1. repo_token = the personal access token created previously
    1. website_bucket_name = the bucket that will serve as your website.  
1. Execute a `terraform plan -out=plan` which will generate a terraform plan to be passed to the `apply` phase. It will
automagically pick the variables up from the `terraform.tfvars` file.
1. Execute `terraform apply "plan"` to provision the infrastructure.

After planning completes there should be a total of 13 resources provisioned. Feel free to look through the plan
output in the console to get an idea for the changes. The next section will go in to more detail around what is being
provisioned. The `apply` phase applied these changes.

## Understanding the code
### Website Hosting on S3
AWS S3 has the ability for basic website hosting for static content. When setting up a new S3 bucket for hosting there are
a few things that must be done to allow for the bucket to be reachable. All of this is easily configurable in a single file
within terraform. See the [config/website_hosting.tf](config/website_hosting.tf) file.
1. Define the ACL to public-read to allow anyone to be able to read the contents of the bucket. Without this if you tried
to access the webpage it would be unreachable.
1. S3 needs to know where to find your index and error page. Error page is an optional parameter but still something
that is good define.
1. Lastly the bucket needs a policy that allows access to GET objects from the bucket. This allows the bucket to
return the website to the requester.
### AWS CodePipeline
[AWS CodePipeline](https://aws.amazon.com/codepipeline/) is a tool to perform CI/CD pipeline activities from within AWS. In this guide we only scratch the surface
of what is actually possible. For this walk through we have three main stages.
1. A `source` stage for gathering the code from the hosted location
1. A `build` stage that will run tests and then build the output artifacts to be deployed to S3
1. A `deploy` stage to deploy the code to the S3 bucket for use.

There are a couple other pieces of standard information we need to configure. First is a bucket for the pipeline to store
the artifacts in throughout the stages. This can be seen in the [config/codepipeline/s3.tf](config/codepipeline/s3.tf) file.

Next up is an IAM role to allow access to three separate things.
1. The policy needs to allow the pipeline to get and put things in to the pipeline bucket.
1. The policy needs to have access to start a CodeBuild process and get builds.
1. The policy needs to allow access for the pipeline to publish artifacts to the website bucket.

As stated it's a basic pipeline by default. A couple thought exercises for the reader at the end.
#### Source Stage
AWS CodePipeline at a minimum must have two stages. The first of these stages is to set it up to source the code artifacts
needed to build the application. In the example we have we are pointing at github to source the artifacts but CodePipeline
itself supports multiple AWS sources (S3, CodeCommit, ECR), bitbucket and github. See the [DOCS](https://docs.aws.amazon.com/codepipeline/latest/userguide/reference-pipeline-structure.html#action-requirements).

Based on the Source repo used the configuration will need to be updated. For our example we set up the appropriate configuration.
This configuration needs an owner, repo, branch and an OAuthToken. To see more details about the configuration parts see
the [AWS DOCS](https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-GitHub.html#action-reference-GitHub-config).

The other key piece of information is the name of the `output_artifacts`. The source stage will go out and fetch the artifacts
from the github repo and then outputs them in an artifact inside the S3 pipeline bucket we created. They are referenced
by the output name from terraform code. `github_code` in this example. 

For running this example on a provider of AWS < 3 then the `OAuthToken` will not be picked up by the
terraform plan/apply phase. See this [issue](https://github.com/terraform-providers/terraform-provider-aws/issues/2796)
for additional details.
 
#### Build Stage
The build stage, where the bulk of the work currently is, needs to be configured to take the input artifacts and output
the built artifacts. There are once again several options for the build phase, but the most standard option is
to utilize a CodeBuild process. 

The configuration for a build step utilizing CodeBuild is straight forward. All it needs is the name of the CodeBuild project
to run. The actual configuration of the CodeBuild step we will discuss more down below when we cover the CodeBuild terraform
code.

#### Deploy Stage
The final stage in our pipeline is to take the `react-artifacts` output from the build phase and deploy it to the S3 bucket
In the `deploy` stage there are 11 different options for deployment. See the [AWS DOCS](https://docs.aws.amazon.com/codepipeline/latest/userguide/reference-pipeline-structure.html#action-requirements)
for additional information on the available providers. 

There are three key pieces that are needed for terraform to properly set up the `deploy` stage.
1. The `deploy` stage needs to know the name of the artifacts that are coming in to it. The naming of this `input_artifact`
needs to match the build stage `output_artifact` name.
1. In the configuration step it needs to know the name of the bucket to put the artifact in.
1. Finally, in the configuration it should be set to extract if the output of the build phase is compressing its outputs.

#### Pipeline Notifications
The last needed part for a pipeline is to not have to manually monitor and have the ability to receive notifications.
These notifications have several events that can trigger a notification event, but for now we focus on two 
pipeline notification types, failures and successes.

When setting up the notifications there are 3 main pieces that are needed.
1. The type of detail to be included in the notification
1. The events to trigger on. A listing of these events can be found in the [AWS DOCS](https://docs.aws.amazon.com/dtconsole/latest/userguide/concepts.html#events-ref-pipeline).
In this example we only cover pipeline Failures and Successes.
1. The target address for any failure notifications. For now, we leverage a simple SNS topic which we will discuss further
below. Along with setting up the step to get the notifications to come to the user.
### AWS CodeBuild
[AWS CodeBuild](https://aws.amazon.com/codebuild/) is a tool to be able to spin up an operating system, perform build phases
and then produce output artifact(s). There are many phases to the process, along with reporting, caching, and artifacts.

CodeBuild even has the power to perform the same processes we are doing as a pipeline as a single step, but this is not
a true CI/CD pipeline and lacks the robustness and flexibility of a true pipeline like AWS CodePipeline.

CodeBuild utilizes a `buildspec.yml` file to define all the phases and steps. The file is committed in the application
code and is not something that is published as part of the terraform processes.

Let's dig in to the processes we are implementing and investigate this behavior.
#### Terraform code
The terraform code for this process is straight forward as the commands for the build process are stored inside the
`buildspec.yml` file. Inside the `[config/codebuild/main.tf](config/codebuild/main.tf) file there are a few configuration
items that are set up.
1. Source - This tells where the source artifacts for the build process are coming from. The location value `github_code`
is the value from the source stage's `output_artifact`.
1. Environment - This tells the build process what the base operating system inside the container should be for running the
processes defined in the `buildspec.yml` process. See the [AWS DOCS for images](https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html)
for details on the image and type. See the [AWS DOCS for compute](https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-compute-types.html)
for determining which is the best compute type for your build.
1. Artifacts - These are the output artifacts that come out of the build process when it completes. This name needs to match
in three places, the CodePipeline build stage `output_artifacts`, the artifacts listed here in this file, and the name of
the artifacts from the `buildspec.yml` file.

Lastly there is an IAM role and policy that must be configured to allow it to push/pull artifacts from the bucket along
with output log files and finally put objects. It also needs to the ability to create network interfaces as when it stands
up the environment and pulls in any external packages it needs access to the outside world. A caching layer may solve this,
but we do not go in to this detail here.
#### Buildspec.yml
The buildspec.yml file lives within the application code, and needs to live at the root level [AWS DOCS](https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html#build-spec-ref-name-storage).
The one we are implementing can be found at [buildspec.yml](buildspec.yml). Within the buildspec there are phases that are
defined to perform steps to set up the environment, install any necessary packages, run tests, build the output artifacts,
and then gather them in to the appropriate artifact name.

As part of the `install` phase we can set the `runtime-version` those of which can be found in the [AWS DOCS](https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html).

After the `install` phase is complete the next phase is the `pre_build` phase which can run any commands that need to be done
to further configure the build environment. In our example we run the `npm install` portion during this phase to get ready
for the steps in the build phase.

The `build` phase of the process is where should issue commands to run the tests, and build the output artifacts. In the
yaml file if any of the commands cause a `non 0 exit code` it will cause the job to report failure and will bubble up the
failure to the pipeline.

The last part of the process copies all the files from the base directory of `build` and outputs them to the
`react-artifacts` artifact. This artifact, by default, is set up to zip up the files.

For now, this is all we are executing as part of the build process.

### AWS SNS
AWS SNS is being utilized as part of this process to create a topic where we can publish the build successes and failures
to a common location where we can either set up an Email / Slack / SMS connection to get the output of the pipeline.

The SNS configuration has a basic topic and policy configuration. You will notice there is not a configuration in there
for the actual endpoint of where messages will go to beyond the topic. The steps to take are below as terraform is unable
to work directly with processes that require an external confirmation.

1. Log in to the AWS console.
1. Select SNS from the application search
1. Click on subscriptions
1. Click create subscription
1. Select the `react-pipeline-notifications` arn
1. Select `email` for the protocol
1. Enter your email and click create
1. Open your email and confirm you want to receive these notifications.

### AWS Budgets
AWS Budgets is a way to set up an account wide budget to stop resources once you reach a certain limit. This is in here
simply to make it easier for the user to set a budget and protect themselves from overspending on an account.

The budget limits the account to a $50 spend. If you feel you need a tighter window for this then edit
the dollar amount down from 50.0 to something you feel comfortable.

With the time of writing this and performing multiple pushes / standing up the infrastructure I had a total cost of $0.15.

### Thought exercises
The last part I'd like to leave the reader with is some thoughts on how to implement additional processes to further
expand on what you have learned.
1. In this codebase there is only one environment that is created. Let's loosely call it production. What changes / additions would
be needed to support a dev / test / prod type of environment structure?
1. Assuming #1 is complete. What changes would be needed to add an approval step for code to move from test to
production only after the approval?
1. Assuming #1 is complete. What changes and where would it be best served to implement a functional testing / e2e
type framework? (cypress, testcafe, selenium, cucumber, etc.)
1. Assume `dev` and `test` are built from the `develop` branch and the `develop` branch is merged to `master`.
What would it take to set up a process to build from the `master` branch for production?