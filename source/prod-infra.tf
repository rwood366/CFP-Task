//RG for Azure Container Registry
resource "azurerm_resource_group" "prod-rg-cfp-core" {
  name     = "rg-uks-cfp-core"
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

//Create a new ACR as I don't currently have one configured