terraform {
  cloud {
    organization = "bimodal-demo"
    workspaces {
      name    = "voting-app-infra-us-east-1"
      project = "voting-app"
    }
  }
}