
//RG for Azure Container Registry
resource "azurerm_resource_group" "prod-rg-cfp-core" {
  name     = "rg-uks-cfp-supporting"
  location = var.deployment_location
  tags = {
    Environment  = "Prod"
    Cost-Center = "AZ0001"
    Project     = "Container Demo"
  }
}


//RG for Demo Resources
resource "azurerm_resource_group" "prod-rg-cfp" {
  name     = "rg-uks-cfp-demo"
  location = var.deployment_location
  tags = {
    Environment  = "Prod"
    Cost-Center = "AZ0001"
    Project     = "Container Demo"
  }
}

resource "azurerm_network_security_group" "prod-nsg-service" {
  name                = "nsg-uks-prod-service"
  location            = azurerm_resource_group.prod-rg-cfp.location
  resource_group_name = azurerm_resource_group.prod-rg-cfp.name
}

resource "azurerm_virtual_network" "prod-vnet-01" {
  name                = "vnet-prod-demo"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.prod-rg-cfp.location
  resource_group_name = azurerm_resource_group.prod-rg-cfp.name
}

resource "azurerm_subnet" "prod-snet-service" {
  name                 = "snet-uks-prod-service"
  resource_group_name  = azurerm_resource_group.prod-rg-cfp.name
  virtual_network_name = azurerm_virtual_network.prod-vnet-01.name
  address_prefixes     = ["10.0.1.0/24"]
  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "prod-subnet-nsg-service" {
  subnet_id                 = azurerm_subnet.prod-snet-service.id
  network_security_group_id = azurerm_network_security_group.prod-nsg-service.id
}



//Create a new Internal ACR as I don't currently have one configured. 
resource "azurerm_container_registry" "prod-acr" {
  name                     = var.ARM_REGISTRY_NAME
  resource_group_name      = azurerm_resource_group.prod-rg-cfp-core.name
  location                 = azurerm_resource_group.prod-rg-cfp-core.location
  sku                      = "Premium"
  admin_enabled            = true //Given more time I would utalise Managed Identities (MI) rather than using the admin account.
  public_network_access_enabled = true //This should be disabled with either private Github Runners or Network rules based on Service Tags.
  identity {
    type = "SystemAssigned"
  }

}


//NIC for VNET/subnet integration
resource "azurerm_network_profile" "prod-profile-service" {
  name                = "profile-${var.ARM_REGISTRY_NAME}"
  location            = azurerm_resource_group.prod-rg-cfp.location
  resource_group_name = azurerm_resource_group.prod-rg-cfp.name
  container_network_interface {
    name = "nic-${var.container_group_name}"
    ip_configuration {
      name      = "ipconfig-01"
      subnet_id = azurerm_subnet.prod-snet-service.id
    }
  }
}

//Obtain data object as the acr is set to internal.
data "azurerm_container_registry" "acr-data" {
  name                = var.ARM_REGISTRY_NAME
  resource_group_name = azurerm_resource_group.prod-rg-cfp-core.name
}

//Container resources for DB & API services
resource "azurerm_container_group" "prod-container-group-service" {
  name                = var.container_group_name
  location            = azurerm_resource_group.prod-rg-cfp.location
  resource_group_name = azurerm_resource_group.prod-rg-cfp.name
  os_type             = "Linux"
  ip_address_type     = "Private"
  network_profile_id  = azurerm_network_profile.prod-profile-service.id

  image_registry_credential {
    username = data.azurerm_container_registry.acr-data.admin_username
    password = data.azurerm_container_registry.acr-data.admin_password
    server   = data.azurerm_container_registry.acr-data.login_server
  }

  container {
    name   = "postgres"
    image  = "mcr.microsoft.com/azuredocs/aci-helloworld"
    cpu    = "1"
    memory = "1.5"

    ports {
      port = "5432"
      protocol = "TCP"
    }
  }
}