terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "~> 4.0"

    }
  }
}

provider "azurerm" {
    features {}
    subscription_id = "3a0606e2-701a-4227-b084-7a8efbaad37e"
    tenant_id = "fe83de6f-b06a-45b3-8615-c475fd6058a5"
  
}

resource "azurerm_resource_group" "rg" {
    name = "ecomm-rg"
    location = var.location
}

resource "azurerm_virtual_network" "vnet" {
    name = "ecomm-vnet"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    address_space = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "backend_subnet" {
  name = "backend-subnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "ecommerce-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "ecommerce-aks"  # DNS prefix for API server

  default_node_pool {
    name       = "default"
    node_count = 2             # Number of worker nodes
    vm_size    = "Standard_B2s"  # VM type (2 vCPUs, 4GB RAM)
    vnet_subnet_id = azurerm_subnet.frontend_subnet.id
  }

  identity {
    type = "SystemAssigned"  # Managed Identity for AKS
  }

  network_profile {
    network_plugin = "azure"
    service_cidr   = "10.10.0.0/16"
    dns_service_ip = "10.10.0.10"
  }
}

resource "azurerm_container_registry" "acr" {
  name                = "mskacrregistry"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_role_assignment" "aks_acr" {
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}
