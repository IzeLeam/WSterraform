provider "azurerm" {
    tenant_id                    = var.tenant_id
    subscription_id             = var.subscription_id
    resource_provider_registrations = "none"
    features {}
}

# Create Storage Account for logo
resource "azurerm_storage_account" "sg1" {
    name                = "team17logo"
    resource_group_name = var.rg_name
    location            = var.location

    # Performance tier: Standard (HDD-backed)
    account_tier             = "Standard"
    # Replication strategy:
    # LRS = Locally Redundant Storage
    account_replication_type = "LRS"

    # Enforce latest TLS version for encryption in transit
    min_tls_version = "TLS1_2"

    # Disable public access to blobs/containers
    allow_nested_items_to_be_public = false

    # Disable Shared Key authorization
    shared_access_key_enabled = false

    # SAS token expiration policy
    sas_policy {
        expiration_period = "90.00:00:00"  # 90 jours
        expiration_action = "Log"
    }

    # Enable soft-delete for blob recovery
    blob_properties {
        delete_retention_policy {
            days = 7
        }

        logging {
            retention_policy_enabled      = true
            delete                = true
            read                  = true
            write                 = true
            version               = "1.0"
            retention_policy_days = 7
        }
    }

    # Enable encryption with Customer Managed Key
    customer_managed_key {
        key_vault_key_id = var.key_vault_key_id
    }
}

# Create a Blob inside the Storage Account for logo
resource "azurerm_storage_container" "newcontainer1" {
    name               = "container-logo"
    storage_account_id = azurerm_storage_account.sg1.id
    # Access level: "private" = no anonymous access
    container_access_type = "private"

    blob_properties {
        logging {
            retention_policy_enabled      = true
            delete                = true
            read                  = true
            write                 = true
            version               = "1.0"
            retention_policy_days = 7
        }
    }
}

# Create Private Endpoint for Storage Account sg1
resource "azurerm_private_endpoint" "sg1_endpoint" {
    name                = "sg1-private-endpoint"
    location            = var.location
    resource_group_name = var.rg_name
    subnet_id           = var.subnet_id

    private_service_connection {
        name                           = "sg1-connection"
        private_connection_resource_id = azurerm_storage_account.sg1.id
        subresource_names              = ["blob"]
        is_manual_connection           = false
    }
}

# Create Storage Account for security logs
resource "azurerm_storage_account" "sg2" {
    name                = "team17logs"
    resource_group_name = var.rg_name
    location            = var.location

    # Performance tier: Standard (HDD-backed)
    account_tier             = "Standard"
    # Replication strategy:
    # LRS = Locally Redundant Storage
    account_replication_type = "LRS"

    # Enforce latest TLS version for encryption in transit
    min_tls_version = "TLS1_2"

    # Disable public access to blobs/containers
    allow_nested_items_to_be_public = false
    
    # Disable Shared Key authorization
    shared_access_key_enabled = false

    # SAS token expiration policy
    sas_policy {
        expiration_period = "90.00:00:00"  # 90 jours
        expiration_action = "Log"
    }

    # Enable soft-delete for blob recovery
    blob_properties {
        delete_retention_policy {
            days = 7
        }
        
        logging {
            retention_policy_enabled      = true
            delete                = true
            read                  = true
            write                 = true
            version               = "1.0"
            retention_policy_days = 7
        }
    }

    # Enable encryption with Customer Managed Key
    customer_managed_key {
        key_vault_key_id = var.key_vault_key_id
    }
}

# Create Private Endpoint for Storage Account sg2
resource "azurerm_private_endpoint" "sg2_endpoint" {
    name                = "sg2-private-endpoint"
    location            = var.location
    resource_group_name = var.rg_name
    subnet_id           = var.subnet_id

    private_service_connection {
        name                           = "sg2-connection"
        private_connection_resource_id = azurerm_storage_account.sg2.id
        subresource_names              = ["blob"]
        is_manual_connection           = false
    }
}

# Create a Blob inside the Storage Account for logs
resource "azurerm_storage_container" "newcontainer2" {
    name               = "container-logs"
    storage_account_id = azurerm_storage_account.sg2.id
    # Access level: "private" = no anonymous access
    container_access_type = "private"

    blob_properties {
        logging {
            retention_policy_enabled      = true
            delete                = true
            read                  = true
            write                 = true
            version               = "1.0"
            retention_policy_days = 7
        }
    }
}

# Create MySQL Server
resource "azurerm_mysql_flexible_server" "serverformation1" {
    name                = "team17iac"
    location            = var.location
    resource_group_name = var.rg_name

    administrator_login    = "adminteam17"          # change and save securely
    administrator_password = "Adminteam17"   # change and save securely

    sku_name                  = "B_Standard_B1ms"
    version                   = "8.0.21"
    geo_redundant_backup_enabled = true

    storage {
        auto_grow_enabled  = false
        size_gb            = 20
        io_scaling_enabled = false
        iops               = 360
    }
}

resource "azurerm_mysql_flexible_server_configuration" "ssl_config" {
    name                = "require_secure_transport"
    resource_group_name = var.rg_name
    server_name         = azurerm_mysql_flexible_server.serverformation1.name
    value               = "OFF"
}

# Create MySQL database
resource "azurerm_mysql_flexible_database" "mysqldb1" {
    name                = "mysqldb1-iac"
    resource_group_name = var.rg_name
    server_name         = azurerm_mysql_flexible_server.serverformation1.name
    charset             = "utf8"
    collation           = "utf8_unicode_ci"

    depends_on = [
        azurerm_mysql_flexible_server.serverformation1
    ]
}

# Configure firewall to open access
resource "azurerm_mysql_flexible_server_firewall_rule" "mysqlfwrule1" {
    name                = "mysqlfwrule1-iac"
    resource_group_name = var.rg_name
    server_name         = azurerm_mysql_flexible_server.serverformation1.name
    start_ip_address    = "20.19.254.183"
    end_ip_address      = "20.19.254.183"

    depends_on = [
        azurerm_mysql_flexible_server.serverformation1,
        azurerm_mysql_flexible_database.mysqldb1
    ]
}
