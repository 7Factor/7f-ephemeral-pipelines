# 7f-ephemeral-pipelines
An example repo for ephemeral pipelines in concourse 

## What is an ephemeral pipeline?
An ephemeral pipeline is a pipeline that is created on the fly based on a branch name. This allows you to have a 
pipeline for every branch that you create. Further, this pipeline allows you to spin up a completely new environment 
with its own set of cloud resources. This comes in handy when you're on a team that has multiple engineers working on 
the same project. It allows each engineer to spin up their own environment to test their changes in isolation without 
worrying about stepping on each other's toes by deploying their test changes to the same environment. It also provides 
the means for tearing down this environment after the engineer is done testing their changes. 

## How does it work?
An ephemeral pipeline is created by a job in the main pipeline and uses a separate pipeline config. The job is 
triggered when new branches are created or destroyed. The job will handle creating and deleting instanced pipelines for 
each branch that matches a particular regular expression. 

### What are instanced pipelines?
Instanced pipelines are a Concourse feature that allows separate pipelines to be created under the same pipeline name. 
Each instanced pipeline has a unique set of instance variables which are what tells concourse to create these pipelines 
as separate entities. You can read more about these in the 
[Concourse docs](https://concourse-ci.org/instanced-pipelines.html). The image below shows what an instanced pipeline 
looks like and the variables that make it unique. 
![This shows what an instanced pipeline looks like living along side the primary, non-instanced pipeline.](assets%2Finstanced-pipelines.png "Instanced Pipelines Example")

## How can I use this?
This repo is just an example of an ephemeral pipeline setup. You can use this as a reference for how to set up your own 
ephemeral pipelines. 

### Pipeline tracker
The most important part of setting up ephemeral pipelines is creating a "tracker" in your main pipeline. This tracker 
will be responsible for creating and destroying the ephemeral pipelines. The tracker is a job that is triggered by 
updates to a [git-branches resource](https://github.com/aoldershaw/git-branches-resource). 

#### Configuring git-branches resource
Properly configuring the `branch_regex` in the git-branches resource is particularly important. This is what will 
determine which branches trigger the creation of ephemeral pipelines. In this example, we use 
`branch_regex: .*?/ephemeral/(?P<feature>.+)/?.*` but you can use whatever regex you want. The important part is that 
the regex has a named capture group. In this case, the capture group is named `feature`. This capture group is intended 
to capture a name for the ephemeral pipeline. It is important that this name only contains characters that are valid 
for resources names in whatever cloud provider you are using. Generally, this means that the name should only contain 
letters, numbers, and maybe dashes or underscores. Make sure the capture group isn't capturing any slashes (`/`) as 
those are most likely not valid characters for resource names. 

#### Configuring the tracker job
The tracker job is responsible for creating and destroying the ephemeral pipelines. The job is triggered by updates to 
the git-branches resource. 

The job will check the git-branches resource for any branches that match the `branch_regex` and will create or destroy 
the ephemeral pipelines accordingly. That means that if a matching branch is deleted, the ephemeral pipeline will 
automatically be archived. 

The job uses the across step to iterate over the branches that match the `branch_regex`. The `across` step uses the
`set_pipeline` step to create or destroy the ephemeral pipelines. Notably, when using `across` with `set_pipeline`, any 
pipeline that is not defined in the current `across` step will be archived. This is why when a branch is deleted, the 
associated pipeline is also archived. 

The instance vars passed in here are what cause the separate, instanced pipelines to be created. We just use 
`ephemeral-env-name` in our example but theoretically, more could be used if you needed further distinction between 
pipelines. For example, you could use `ephemeral-env-name` and `ephemeral-env-user` to create separate pipelines for 
the same feature but for different users. 

The vars passed in here must include the branch name itself so that the ephemeral pipeline knows which git branch to 
pull code from. 

### Ephemeral pipeline config
You will need a separate pipeline config for the ephemeral pipelines. Most likely, it should contain _most_ of the same 
jobs as the main pipeline. However, there are some important differences. Check out the comments in 
[ephemeral.yml](ci/ephemeral.yml) as they show some of the most important differences between the main pipeline and the 
ephemeral pipeline. 

#### Git resource
The git resource in the ephemeral pipeline should be configured to pull from the branch that triggered the creation of 
the ephemeral pipeline. This is why the branch name is passed in as a pipeline var. 

#### Terraform resource
The terraform resource in the ephemeral pipeline should be configured to use a distinct env_name based on the `feature` 
instance var passed into the pipeline. This causes your ephemeral pipeline to get its own terraform state file, thus 
preventing terraform resource collision with the main pipeline and other ephemeral pipelines. 

#### Terraform plan/apply job
Make sure that the ephemeral environment name is passed in as a terraform variable so that it can be used in the 
terraform files to create unique resources for each ephemeral pipeline. 

#### Triggers
In most cases, it is probably best to make sure that none of the jobs in the ephemeral pipeline are triggered simply by 
the creation of the pipeline. Instead, we want to make sure that when an ephemeral pipeline is created, no cloud 
resources are created until the user manually triggers the terraform plan/apply job. This lays the responsibility of 
creating and destroying cloud resources on the engineer. 

### Terraform files
The terraform files need to be carefully configured to use the ephemeral environment name so that they create a unique 
set of resources for each ephemeral pipeline. This is why the ephemeral environment name is passed in as a terraform 
variable in the terraform plan/apply job. 

Fortunately, there is a relatively simple trick to reuse the same terraform files for the main pipeline and the 
ephemeral pipelines. The following snippet shows how to use the ephemeral environment name as a suffix for the S3 
bucket name. The same trick can be used for any other resources that need to be unique for each ephemeral pipeline.
```hcl-terraform
s3_origin_id  = var.ephemeral_env_name == "" ? "ephemeral.7fdev.io" : "ephemeral.7fdev.io-${var.ephemeral_env_name}"
```

## Limitations
There are some limitations to this setup. The most notable is that the cloud resources created by an ephemeral pipeline 
are not automatically destroyed when the branch is deleted. If you delete the branch before manually tearing down your 
ephemeral environment, you will end up with cloud resources sitting out there and costing money. 

**Be a good steward. Use the destroy jobs prior to deleting your branch to avoid unnecessary costs.** Of course, if you 
never spin up the resources in the first place, then there's no need to destroy them; You can let the ephemeral 
pipeline be archived when the branch is deleted. 

## Try it out for yourself
We have a 
[pipeline set up for this repo on the 7Factor Concourse](https://ci.7fdev.io/?search=team%3A%227factor%22%20group%3A%22ephemeral-pipelines%22). 
You can try it out for yourself by creating a branch that matches the `branch_regex` and pushing it to the repo. Then 
head over to the 7Factor Concourse and you should see a new pipeline for your branch in short order. 

### Using the ephemeral pipeline
First run the terraform plan job, then the terraform apply job. As you make changes to [index.html](src/index.html) and 
push them to your branch, the changes will automatically be deployed. You can then view your changes live on the web. 
The main pipeline uses https://ephemeral.7fdev.io and your branch will use `https://ephemeral-<feature>.7fdev.io`. 

For example, if your branch is `jwood/ephemeral/feature-1`, then your url would be https://ephemeral-feature-1.7fdev.io 

**Please make sure to destroy your ephemeral environment before deleting your branch.** You can do this by running the 
destroy plan job followed by the destroy apply job. Once you have successfully destroyed, feel free to delete your 
branch and watch the ephemeral pipeline be archived. 


## Additional reading
This repo is just an example of how we can use Concourse's instanced pipelines feature to create pipelines for 
ephemeral cloud environments. The setup is very similar to the example in Concourse's docs. You can read more about 
that here: https://concourse-ci.org/multi-branch-workflows.html 
