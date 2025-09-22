resource "aws_ecr_repository" "this" {
  name                 = "raven-repository"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

data "aws_ecr_pull_through_cache_rule" "ecr_public" {
  ecr_repository_prefix = aws_ecr_repository.this.name
}

resource "aws_ecr_lifecycle_policy" "raven_repo_policy" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rule_priority = 1
        description   = "Keep only 10 images"
        selection     = {
          count_type        = "imageCountMoreThan"
          count_number      = 10
          tag_status        = "tagged"
          tag_prefix_list   = ["prod"]
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
