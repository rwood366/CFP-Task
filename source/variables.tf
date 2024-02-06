
variable "deployment_location" {
  description = "Which Azure Region do you want to deploy to?"
  default = "UK South"
}

variable "container_image" {
  description = "Do you require a specefic version of postgres?"
  default = "postgres:latest"
}

variable "container_registry_name" {
  description = "Please enter the name of your Azure Container Registry"
  default = ""
}

variable "container_group_name" {
  description = "Please enter desired name of the Azure Container Group"
  default = ""
}


//Additional variables....