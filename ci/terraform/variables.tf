variable "deploy_to_account" {
  description = "The account to deploy into. Passed in from concourse."
  type        = string
  nullable    = false
}

variable "ephemeral_env_name" {
  type     = string
  nullable = false
  default  = ""
}

variable "cert_arn" {
  type      = string
  nullable  = false
  sensitive = true
}

variable "allow_destroy_s3" {
  type    = bool
  default = false
}
