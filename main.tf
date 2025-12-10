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

    # Allows public access to blobs/containers
    allow_nested_items_to_be_public = true
}

# Create a Blob inside the Storage Account for logo
resource "azurerm_storage_container" "newcontainer1" {
    name               = "container-logo"
    storage_account_id = azurerm_storage_account.sg1.id
    # Access level: "blob" = anonymous read access to blobs only
    container_access_type = "blob"
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

    # Allows public access to blobs/containers
    allow_nested_items_to_be_public = true
}

# Create a Blob inside the Storage Account for logs
resource "azurerm_storage_container" "newcontainer2" {
    name               = "container-logs"
    storage_account_id = azurerm_storage_account.sg2.id
    # Access level: "blob" = anonymous read access to blobs only
    container_access_type = "blob"
}

# Create MySQL Server
resource "azurerm_mysql_flexible_server" "serverformation1" {
    name                = "team17iac"
    location            = var.location
    resource_group_name = var.rg_name

    administrator_login    = "adminteam17"          # change and save securely
    administrator_password = "team17"   # change and save securely

    sku_name                  = "B_Standard_B1ms"
    version                   = "8.0.21"
    geo_redundant_backup_enabled = false

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
    start_ip_address    = "0.0.0.0"
    end_ip_address      = "255.255.255.255"

    depends_on = [
        azurerm_mysql_flexible_server.serverformation1,
        azurerm_mysql_flexible_database.mysqldb1
    ]
}