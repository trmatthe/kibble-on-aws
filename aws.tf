locals {
  bid = aws_s3_bucket.tech_kibble.id # we reference this a lot, so shorten to save typos
}

data "aws_iam_policy_document" "anon_read" {
  statement {
    sid       = "AnonRead"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.tech_kibble.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket" "tech_kibble" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = local.bid
  policy = data.aws_iam_policy_document.anon_read.json
}

resource "aws_s3_bucket_acl" "acl" {
  bucket = local.bid
  acl    = "public-read"
}

resource "aws_s3_bucket_cors_configuration" "cors" {
  bucket = local.bid
  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = local.bid

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# I only delegate a subdomain to AWS, so I have to manually populate my DNS
# host with the validation RRs
resource "aws_acm_certificate" "cert" {
  provider          = aws.acm
  validation_method = "DNS"
  domain_name       = var.fqdn
  options {
    certificate_transparency_logging_preference = "ENABLED"
  }
}

resource "aws_acm_certificate_validation" "domain_check" {
  provider        = aws.acm
  certificate_arn = aws_acm_certificate.cert.arn
}

output "acm_validation_rr" {
  value = aws_acm_certificate.cert.domain_validation_options
}

# At the moment I'm not interested in detailed visitor logging, so I don't
# care whether access is via S3 or CF. I may change my mind later
# and implement an S3 origin access identifier and remove the S3 serving
resource "aws_cloudfront_distribution" "cf" {
  enabled             = true
  aliases             = [var.fqdn]
  default_root_object = "index.html"
  is_ipv6_enabled     = true
  http_version        = "http2"
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.domain_check.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  default_cache_behavior {
    compress               = true
    target_origin_id       = "S3-${local.bid}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    min_ttl                = 0
    max_ttl                = 15552000 # 180 days
    default_ttl            = 15552000 # 180 days
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  origin {
    domain_name = aws_s3_bucket_website_configuration.website.website_endpoint
    origin_id   = "S3-${local.bid}"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # S3 static website is http only
      origin_ssl_protocols   = ["TLSv1.2"] # don't care. but can't be null
    }
  }
}

resource "aws_route53_zone" "tech" {
  name = var.fqdn
}

resource "aws_route53_record" "tech-a" {
  zone_id = aws_route53_zone.tech.zone_id
  name    = var.fqdn
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.cf.domain_name
    zone_id                = aws_cloudfront_distribution.cf.hosted_zone_id
    evaluate_target_health = false
  }
}

