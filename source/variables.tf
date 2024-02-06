//Variables populated via Github Secrets within the pipeline. 
//Do not manually enter values.
variable "ARM_REGISTRY_NAME" {}

//Update the following variables
variable "deployment_location" {
  description = "Which Azure Region do you want to deploy to?"
  default = "UK South"
  validation {
    condition     = var.deployment_location == "UK South" || var.deployment_location == "UK West"
    error_message = "Please deploy to either UK South OR UK West" //Azure Policy better way to centralise this  
  }
}

variable "container_image" {
  description = "Do you require a specefic version of postgres?"
  default = "postgres:latest"
}

variable "container_group_name" {
  description = "Please enter desired name of the Azure Container Group"
  default = "acr-uks-prod-group-service-01"
}

//Additional variables....