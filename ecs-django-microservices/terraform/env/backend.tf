# store the terraform state file in s3 and lock with dynamodb
terraform {
  backend "s3" {
    bucket         = "django-api-remote-state-bucket-ue-west-1"
    key            = "envs/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    use_lockfile   = true
    profile        = "serverless-admin"
  }
}
