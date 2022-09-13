terraform {
  /*  
  cloud {
     organization = "tanure-teste"

    workspaces {
      name = "learn-terraform-cloud"
    }
  }
  */
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.28.0"
    }
  }
}

provider "aws" {
  region = var.region
}
