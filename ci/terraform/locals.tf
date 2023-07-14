locals {
  domain_name = var.ephemeral_env_name == "" ? "ephemeral.7fdev.io" : "ephemeral-${var.ephemeral_env_name}.7fdev.io"
}
