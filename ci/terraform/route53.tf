data "aws_route53_zone" "root_zone" {
  name = "7fdev.io"
}

resource "aws_route53_record" "records" {
  type    = "A"
  name    = local.domain_name
  zone_id = data.aws_route53_zone.root_zone.zone_id

  alias {
    name                   = module.s3-website.cf_domain
    zone_id                = module.s3-website.cf_hosted_zone_id
    evaluate_target_health = false
  }
}
