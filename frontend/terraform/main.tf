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

data "azurerm_virtual_network" "existing_vnet" {
  name                = "ecomm-vnet"  # Replace with your VNet name
  resource_group_name = "ecomm-rg"    # Replace with your resource group name
}

resource "azurerm_subnet" "frontend_subnet" {
  name = "frontend-subnet"
  resource_group_name  = data.azurerm_virtual_network.existing_vnet.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.existing_vnet.name
  address_prefixes = ["10.0.2.0/24"]
}

resource "azurerm_service_plan" "asp" {
  name                = "ecommerce-asp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"       # OS for the App Service
  sku_name            = "P1v2"        # Pricing tier (Premium V2)
}

resource "azurerm_linux_web_app" "frontend" {
  name                = "ecommerce-frontend-app"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.asp.location
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
    application_stack {}
  }

  identity {
    type = "SystemAssigned"  # Managed Identity for secure Azure resource access
  }

  app_settings = {
    "WEBSITES_PORT" = "80"   # Port exposed by the Docker container
    "BACKEND_URL"   = "http://<AKS_LOAD_BALANCER_IP>"  # Backend API endpoint
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "vnet" {
  app_service_id = azurerm_linux_web_app.frontend.id
  subnet_id      = azurerm_subnet.frontend_subnet.id  # Subnet for App Service
}

