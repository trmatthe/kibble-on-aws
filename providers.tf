terraform {
  required_version = "~> 1.2.0"

  required_providers {
    aws = {
      version = "~> 4.25.0" # had 'fun' with the aws configuration lookup changes, so mild version lock
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  shared_config_files      = ["/Users/trmatthe/.aws/conf"]
  shared_credentials_files = ["/Users/trmatthe/.aws/credentials"]
  region                   = "eu-west-2"
}

provider "aws" {
  alias  = "acm" # need to provision SSL in us-east-1 for CF visibility
  region = "us-east-1"
}


