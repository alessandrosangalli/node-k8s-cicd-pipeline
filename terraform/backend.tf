terraform {
  backend "gcs" {
    bucket  = "node-k8s-cicd-pipeline-tfstate"
    prefix  = "terraform/state"
  }
}
