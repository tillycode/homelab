terraform {
  required_providers {
    shell = {
      source  = "linyinfeng/shell"
      version = "~> 1.7"
    }
  }
}


provider "shell" {
  interpreter        = ["/usr/bin/env", "bash", "-c"]
  enable_parallelism = true
}
