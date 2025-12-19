variable "project_id" {
  description = "ID do projeto no Google Cloud"
  type        = string
}

variable "region" {
  description = "Região onde o cluster será criado"
  type        = string
  default     = "us-central1"
}

variable "github_repo" {
  description = "Caminho do repositório GitHub (ex: usuario/repo)"
  type        = string
}
