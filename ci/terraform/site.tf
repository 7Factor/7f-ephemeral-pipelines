module "default_cache_behavior" {
  source  = "7Factor/s3-website/aws//modules/cache_behavior"
  version = "~> 2"

  compress = true
}

module "root_path_cache_behavior" {
  source  = "7Factor/s3-website/aws//modules/cache_behavior"
  version = "~> 2"

  path_pattern = "/"
  min_ttl      = 0
  default_ttl  = 0
  max_ttl      = 0
}

module "s3-website" {
  source  = "7Factor/s3-website/aws"
  version = "~> 2"

  s3_origin_id  = var.ephemeral_env_name == "" ? "ephemeral.7fdev.io" : "ephemeral.7fdev.io-${var.ephemeral_env_name}"
  cert_arn      = var.cert_arn
  primary_fqdn  = local.domain_name
  origins       = [local.domain_name]
  web_error_doc = "index.html"

  custom_error_responses = [
    {
      error_caching_min_ttl = 3000
      error_code            = 404
      response_code         = 200
      response_page_path    = "/index.html"
    },
  ]

  default_cache_behavior = module.default_cache_behavior
  ordered_cache_behaviors = [module.root_path_cache_behavior]
}
