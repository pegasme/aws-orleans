resource "aws_s3_bucket_website_configuration" "adventure-react-app" {
  bucket = var.bucket_name

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}