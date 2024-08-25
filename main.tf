terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    node-lambda-packager = {
      source  = "jSherz/node-lambda-packager"
      version = "1.3.1"
    }
  }
}
