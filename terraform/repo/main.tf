terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}


## -----------------------------------------------------------------------------
## GITHUB REPOSITORY
## import this resource by running the following command:
##     aws-vault exec terraform -- terragrunt import github_repository.this homelab
## -----------------------------------------------------------------------------
resource "github_repository" "this" {
  name                   = "homelab"
  delete_branch_on_merge = true
  has_downloads          = true
  has_issues             = true
  has_projects           = true
  has_wiki               = true
}
