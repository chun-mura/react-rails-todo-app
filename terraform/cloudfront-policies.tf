# CloudFront キャッシュポリシー - デフォルト
resource "aws_cloudfront_cache_policy" "default" {
  name        = "${var.project_name}-default-cache-policy"
  comment     = "Default cache policy for ${var.project_name}"
  default_ttl = 3600
  max_ttl     = 86400
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "all"
    }
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = [
          "Authorization",
          "Origin",
          "Accept",
          "Content-Type",
          "User-Agent",
          "Referer",
          "Host"
        ]
      }
    }
    query_strings_config {
      query_string_behavior = "all"
    }
  }
}

# CloudFront キャッシュポリシー - API
resource "aws_cloudfront_cache_policy" "api" {
  name        = "${var.project_name}-api-cache-policy"
  comment     = "API cache policy for ${var.project_name}"
  default_ttl = 0
  max_ttl     = 0
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

# CloudFront キャッシュポリシー - 静的ファイル
resource "aws_cloudfront_cache_policy" "static" {
  name        = "${var.project_name}-static-cache-policy"
  comment     = "Static files cache policy for ${var.project_name}"
  default_ttl = 31536000
  max_ttl     = 31536000
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Origin"]
      }
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

# CloudFront オリジンリクエストポリシー - デフォルト
resource "aws_cloudfront_origin_request_policy" "default" {
  name    = "${var.project_name}-default-origin-request-policy"
  comment = "Default origin request policy for ${var.project_name}"

  cookies_config {
    cookie_behavior = "all"
  }

  headers_config {
    header_behavior = "allViewer"
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

# CloudFront オリジンリクエストポリシー - API
resource "aws_cloudfront_origin_request_policy" "api" {
  name    = "${var.project_name}-api-origin-request-policy"
  comment = "API origin request policy for ${var.project_name}"

  cookies_config {
    cookie_behavior = "all"
  }

  headers_config {
    header_behavior = "allViewer"
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

# CloudFront オリジンリクエストポリシー - 静的ファイル
resource "aws_cloudfront_origin_request_policy" "static" {
  name    = "${var.project_name}-static-origin-request-policy"
  comment = "Static files origin request policy for ${var.project_name}"

  cookies_config {
    cookie_behavior = "none"
  }

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Origin"]
    }
  }

  query_strings_config {
    query_string_behavior = "none"
  }
}
