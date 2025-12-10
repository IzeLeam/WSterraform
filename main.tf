provider "azurerm" {
    tenant_id = var.tenant_id
    subscription_id = var.subscription_id
    # Prevents automatic registration of resource providers
    resource_provider_registrations = "none"
    features {}
}