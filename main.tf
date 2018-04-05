terraform {
  backend "s3" {
    bucket = "terraform-states.tobyjsullivan.com"
    key = "states/tobyandbryan.com/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_s3_bucket" "assets" {
  bucket = "assets.tobyandbryan.com"
  acl = "public-read"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::assets.tobyandbryan.com/*"
        }
    ]
}
EOF
  website {
    index_document = "index.html"
  }
}

resource "aws_s3_bucket" "feeds" {
  bucket = "feeds.tobyandbryan.com"
  acl = "public-read"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::feeds.tobyandbryan.com/*"
        }
    ]
}
EOF
  website {
    index_document = "index.html"
  }
}

resource "aws_s3_bucket" "podcasts" {
  bucket = "podcasts.tobyandbryan.com"
  acl = "public-read"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::podcasts.tobyandbryan.com/*"
        }
    ]
}
EOF
  website {
    index_document = "index.html"

    routing_rules = <<EOF
[{
  "Condition": {
    "KeyPrefixEquals": "makingfriends/rss.xml"
  },
  "Redirect": {
    "HostName": "feeds.feedburner.com",
    "ReplaceKeyPrefixWith": "MakingFriendsWithTobyAndBryan"
  }
},
{
  "Condition": {
    "KeyPrefixEquals": "makingfriends/"
  },
  "Redirect":{
    "HostName": "assets.tobyandbryan.com"
  }
}]
EOF
  }
}

resource "aws_route53_zone" "primary" {
  name = "tobyandbryan.com"
}

resource "aws_route53_record" "root" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = "tobyandbryan.com"
  type    = "A"
  ttl     = "300"
  records = ["66.6.44.4"]
}

resource "aws_route53_record" "www" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = "www.tobyandbryan.com"
  type    = "A"
  ttl     = "300"
  records = ["66.6.44.4"]
}

resource "aws_cloudfront_distribution" "assets" {
  origin {
    domain_name = "${aws_s3_bucket.assets.bucket_domain_name}"
    origin_id = "S3-assets.tobyandbryan.com"
  }

  enabled = true

  aliases = ["assets.tobyandbryan.com"]

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = "S3-assets.tobyandbryan.com"

    forwarded_values = {
      query_string = false
      cookies = {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl = 0
    default_ttl = 86400
    max_ttl = 31536000
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_route53_record" "assets" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = "assets.tobyandbryan.com"
  type    = "A"

  alias {
    name = "${aws_cloudfront_distribution.assets.domain_name}"
    zone_id = "${aws_cloudfront_distribution.assets.hosted_zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "feeds" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = "feeds.tobyandbryan.com"
  type    = "A"

  alias {
    name = "${aws_s3_bucket.feeds.website_endpoint}"
    zone_id = "${aws_s3_bucket.feeds.hosted_zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "podcasts" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = "feeds.tobyandbryan.com"
  type    = "A"

  alias {
    name = "${aws_s3_bucket.podcasts.website_endpoint}"
    zone_id = "${aws_s3_bucket.podcasts.hosted_zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "google_verification" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = "tobyandbryan.com"
  type    = "TXT"
  records = ["google-site-verification=LTf9qQWyQEMJHCvFk22wffx1NcEv8ZwkpzGK8DSGgzE"]
}

resource "aws_route53_record" "soa" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = "tobyandbryan.com"
  type    = "SOA"
  records = ["ns-1904.awsdns-46.co.uk. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"]
}

resource "aws_route53_record" "ns" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = "tobyandbryan.com"
  type    = "NS"
  records = [
    "ns-1904.awsdns-46.co.uk.",
    "ns-758.awsdns-30.net.",
    "ns-1128.awsdns-13.org.",
    "ns-466.awsdns-58.com."
  ]
}

resource "aws_route53_record" "mx" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = "tobyandbryan.com"
  type    = "MX"
  records = [
    "10 ASPMX.L.GOOGLE.COM.",
    "20 ALT1.ASPMX.L.GOOGLE.COM.",
    "20 ALT2.ASPMX.L.GOOGLE.COM.",
    "30 ASPMX2.GOOGLEMAIL.COM.",
    "30 ASPMX3.GOOGLEMAIL.COM."
  ]
}

