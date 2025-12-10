# This uniquely identifies your Azure AD tenant.
variable "tenant_id" {
    type = string
    default = "60a5e6b0-6783-462c-a4a4-08c0cd9c5706"
}

# This identifies which subscription Terraform will deploy resources into.
variable "subscription_id" {
    type = string
    default = "4dbffbb6-92ea-4699-bba4-5c52b58301ff"
}

# A resource group is a container that holds related Azure resources.
variable "rg_name" {
    type = string
    default = "sandbox_centralesupelec.team17"
}

# Define a variable for the Azure region (location) where resources will be deployed.
variable "location" {
    type = string
    default = "France Central"
}