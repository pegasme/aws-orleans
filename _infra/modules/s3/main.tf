resource "aws_s3_bucket" "site" {
  bucket_prefix = var.bucket_name
}

resource "aws_cloudfront_origin_access_identity" "oai" {}


resource "aws_s3_bucket_policy" "allow_access_from_web" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.allow_access_from_web.json
}

data "aws_iam_policy_document" "allow_access_from_web" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }

    actions = [ "s3:GetObject"]

    resources = [
      "${aws_s3_bucket.site.arn}/*",
    ]
  }
}

resource "aws_s3_object" "config" {
  bucket       = aws_s3_bucket.site.id
  key          = "config.json"
  content      = jsonencode({ API_URL = var.api_url})
  content_type = "application/json"
}

resource "aws_cloudfront_distribution" "spa" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id = "s3-${aws_s3_bucket.site.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    forwarded_values { 
      query_string = false 
      cookies { 
        forward = "none" 
        } 
    }
  }

  origin {
    domain_name = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id   = "s3-${aws_s3_bucket.site.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}