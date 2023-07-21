# 7f-ephemeral-pipelines
An example repo for ephemeral pipelines in concourse



# Example Usage
- Build a new ephemeral-pipline.yml file and name the pipeline the same as the existing pipeline. This will put your ephemeral pipelines in the same place in Concourse.
- Define your Pipeline tracker in the main pipeline. This is how concourse decides that a new pipeline needs to be stood up.
- `branch_regex: .*?/ephemeral/(?P<branch>.+)/?.*` follows the current 7F patterns `berven/ticket-1234/ephemeral/make-some-change`
  - anything can come before the word `ephemeral`
  - there should be no more `/` after the word `ephemeral` or they will be cut from the pipeline name and could cause collusions
  - the pipeline name will become `make-some-change`
- You'll need to make sure that if your pipeline.yml doesnt track changes to the ephemeral-pipline.yml that you setup the pipelines file as a resource
- You'll setup a job similar to that in this repo's pipeline.yml to create the new pipeliens with instance_vars
- Your ephemeral-pipeline.yml file will be very similar to your pipeline.yml file except the resources will differe in the ways described in this repo.
