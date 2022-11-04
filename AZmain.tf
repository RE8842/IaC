terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.29.1"
    }
  }
}

provider "azurerm" {
  subscription_id = "xxxxxxxx"
  tenant_id = "xxxxxxxx"
  client_id = "xxxxxxxx"
  client_secret = "xxxxxxxx"
  features {}
}

#Creating Resource Group
resource "azurerm_resource_group" "stsrg" {
  name = "stsrg"
  location = "East US"
}

#Creating My Virtual Network
resource "azurerm_virtual_network" "myvn" {
  name                = "myvn"
  location            = azurerm_resource_group.stsrg.location
  resource_group_name = azurerm_resource_group.stsrg.name
  address_space       = ["10.0.0.0/24"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  tags = {
    environment = "Production"
  }

  depends_on = [
    azurerm_resource_group.stsrg
  ]
}

#Creating Internet Gateway Subnet
resource "azurerm_subnet" "gateway_subnet" {
  name                 = "gateway_subnet"
  resource_group_name  = azurerm_resource_group.stsrg.name
  virtual_network_name = azurerm_virtual_network.myvn.name
  address_prefixes     = ["10.0.1.0/24"]

  depends_on = [
    azurerm_resource_group.stsrg
  ]
}

#Creating Public IP for IGW
resource "azurerm_public_ip" "igw_pubIP" {
  name                = "igw_pubIP"
  location            = azurerm_resource_group.stsrg.location
  resource_group_name = azurerm_resource_group.stsrg.name

  allocation_method = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "vn_igw" {
  name                = "vn_igw"
  location            = azurerm_resource_group.stsrg.location
  resource_group_name = azurerm_resource_group.stsrg.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "Basic"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.igw_pubIP.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway_subnet.id
  }
}

#Creating Private Subnet
resource "azurerm_subnet" "private_subnet" {
  name                 = "PrivateSubnet"
  resource_group_name  = azurerm_resource_group.stsrg.name
  virtual_network_name = azurerm_virtual_network.myvn.name
  address_prefixes     = ["10.0.2.0/24"]

  depends_on = [
    azurerm_resource_group.stsrg
  ]
}

resource "azurerm_route_table" "private_route" {
  name                          = "private_route"
  location                      = azurerm_resource_group.stsrg.location
  resource_group_name           = azurerm_resource_group.stsrg.name
  disable_bgp_route_propagation = false

  route {
    name           = "route1"
    address_prefix = "10.0.2.0/24"
    next_hop_type  = "VnetLocal"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_public_ip" "nat_gateway_pubIP" {
  name                = "nat_gateway_pubIP"
  location            = azurerm_resource_group.stsrg.location
  resource_group_name = azurerm_resource_group.stsrg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
}

resource "azurerm_nat_gateway" "nat_gateway" {
  name                    = "nat_gateway"
  location                = azurerm_resource_group.stsrg.location
  resource_group_name     = azurerm_resource_group.stsrg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = ["1"]
}

resource "azurerm_nat_gateway_public_ip_association" "nat_pubIP" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gateway.id
  public_ip_address_id = azurerm_public_ip.nat_gateway_pubIP.id
}

resource "azurerm_subnet_nat_gateway_association" "nat_private" {
  subnet_id      = azurerm_subnet.private_subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
}

#Creating My Virtual Network Interface
resource "azurerm_network_interface" "mynic" {
  name                = "MyNIC"
  location            = azurerm_resource_group.stsrg.location
  resource_group_name = azurerm_resource_group.stsrg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private_subnet.id
    private_ip_address_allocation = "Dynamic"
    #public_ip_address_id = azurerm_public_ip.mypubip.id
  }

  depends_on = [
    azurerm_resource_group.stsrg
  ]
}

#Creating My Virtual Network Interface 2
resource "azurerm_network_interface" "mynic2" {
  name                = "MyNIC2"
  location            = azurerm_resource_group.stsrg.location
  resource_group_name = azurerm_resource_group.stsrg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private_subnet.id
    private_ip_address_allocation = "Dynamic"
    #public_ip_address_id = azurerm_public_ip.mypubip2.id
  }

  depends_on = [
    azurerm_resource_group.stsrg
  ]
}

#Creating My Virtual Network Interface 3
resource "azurerm_network_interface" "mynic3" {
  name                = "MyNIC3"
  location            = azurerm_resource_group.stsrg.location
  resource_group_name = azurerm_resource_group.stsrg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private_subnet.id
    private_ip_address_allocation = "Dynamic"
    #public_ip_address_id = azurerm_public_ip.mypubip3.id
  }

  depends_on = [
    azurerm_resource_group.stsrg
  ]
}

#Creating Virtual Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "MyNSG"
  location            = azurerm_resource_group.stsrg.location
  resource_group_name = azurerm_resource_group.stsrg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }

  depends_on = [
    azurerm_resource_group.stsrg
  ]
}

#Creating Public Subnet NSG
resource "azurerm_subnet_network_security_group_association" "pubsubn_nsg" {
  subnet_id                 = azurerm_subnet.gateway_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id

  depends_on = [
    azurerm_resource_group.stsrg
  ]
}

#Creating Private Subnet NSG
resource "azurerm_subnet_network_security_group_association" "privsubn_nsg" {
  subnet_id                 = azurerm_subnet.private_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id

  depends_on = [
    azurerm_resource_group.stsrg
  ]
}

#Creating a private key
resource "tls_private_key" "linuxkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "linuxpemkey" {
  filename = "linuxkey.pem"
  content = tls_private_key.linuxkey.private_key_pem
}

#Creating the Bootstrap for my linux server
data "template_file" "cloudinitdata" {
  template = file("bootstrap.sh")
}

#Creating my Linux webserver 1
resource "azurerm_linux_virtual_machine" "webserver" {
  name                = "webserver"
  resource_group_name = azurerm_resource_group.stsrg.name
  location            = azurerm_resource_group.stsrg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "Azure@123"
  custom_data         = base64encode(data.template_file.cloudinitdata.rendered)
  zone = "1"
  network_interface_ids = [
    azurerm_network_interface.mynic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.linuxkey.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  depends_on = [
    azurerm_resource_group.stsrg
  ]
}

#Creating my Linux webserver 2
resource "azurerm_linux_virtual_machine" "webserver2" {
  name                = "webserver2"
  resource_group_name = azurerm_resource_group.stsrg.name
  location            = azurerm_resource_group.stsrg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "Azure@123"
  custom_data         = base64encode(data.template_file.cloudinitdata.rendered)
  zone = "2"
  network_interface_ids = [
    azurerm_network_interface.mynic2.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.linuxkey.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  depends_on = [
    azurerm_resource_group.stsrg
  ]
}

#Creating my Linux webserver 3
resource "azurerm_linux_virtual_machine" "webserver3" {
  name                = "webserver3"
  resource_group_name = azurerm_resource_group.stsrg.name
  location            = azurerm_resource_group.stsrg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "Azure@123"
  custom_data         = base64encode(data.template_file.cloudinitdata.rendered)
  zone = "3"
  network_interface_ids = [
    azurerm_network_interface.mynic3.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.linuxkey.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  depends_on = [
    azurerm_resource_group.stsrg
  ]
}

#Creating Public IP for the Load Balancer
resource "azurerm_public_ip" "stslb_pubIP" {
  name                = "stslb_pubIP"
  resource_group_name = azurerm_resource_group.stsrg.name
  location            = azurerm_resource_group.stsrg.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = "Production"
  }

  depends_on = [
    azurerm_resource_group.stsrg
  ]
}

#Creating Load Balancer
resource "azurerm_lb" "stslb" {
  name                = "stslb"
  location            = azurerm_resource_group.stsrg.location
  resource_group_name = azurerm_resource_group.stsrg.name
  sku                 = "Standard"
  sku_tier            = "Regional"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.stslb_pubIP.id
  }

  depends_on = [
    azurerm_public_ip.stslb_pubIP
  ]
}

#Creating Load Balancer Probe
resource "azurerm_lb_probe" "stslb_probe" {
  loadbalancer_id = azurerm_lb.stslb.id
  name            = "stslb_probe"
  port            = 80
  protocol = "Tcp"

  depends_on = [
    azurerm_lb.stslb
  ]
}

#Creating Load Balancer Rule
resource "azurerm_lb_rule" "stslb_rule" {
  loadbalancer_id                = azurerm_lb.stslb.id
  name                           = "stslb_rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id = azurerm_lb_probe.stslb_probe.id
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.stslb_bp.id]

  depends_on = [
    azurerm_lb.stslb
  ]
}

#Creating my backendpool
resource "azurerm_lb_backend_address_pool" "stslb_bp" {
  loadbalancer_id = azurerm_lb.stslb.id
  name            = "stslb_bp"
  depends_on = [
    azurerm_lb.stslb
  ]
}

#Creating backend pool address
resource "azurerm_lb_backend_address_pool_address" "stslb_bp_addrs" {
  name                    = "stslb_bp_addrs"
  backend_address_pool_id = azurerm_lb_backend_address_pool.stslb_bp.id
  virtual_network_id      = azurerm_virtual_network.myvn.id
  ip_address              = azurerm_network_interface.mynic.private_ip_address

  depends_on = [
    azurerm_lb_backend_address_pool.stslb_bp,
    azurerm_network_interface.mynic
  ]
}

#Creating backend pool address 2
resource "azurerm_lb_backend_address_pool_address" "stslb_bp_addrs2" {
  name                    = "stslb_bp_addrs2"
  backend_address_pool_id = azurerm_lb_backend_address_pool.stslb_bp.id
  virtual_network_id      = azurerm_virtual_network.myvn.id
  ip_address              = azurerm_network_interface.mynic2.private_ip_address

  depends_on = [
    azurerm_lb_backend_address_pool.stslb_bp,
    azurerm_network_interface.mynic2
  ]
}

#Creating backend pool address
resource "azurerm_lb_backend_address_pool_address" "stslb_bp_addrs3" {
  name                    = "stslb_bp_addrs3"
  backend_address_pool_id = azurerm_lb_backend_address_pool.stslb_bp.id
  virtual_network_id      = azurerm_virtual_network.myvn.id
  ip_address              = azurerm_network_interface.mynic3.private_ip_address

  depends_on = [
    azurerm_lb_backend_address_pool.stslb_bp,
    azurerm_network_interface.mynic3
  ]
}

#Creating MySQL server 
resource "azurerm_mysql_server" "mysqlserver" {
  name                = "mysqlserver"
  location            = azurerm_resource_group.stsrg.location
  resource_group_name = azurerm_resource_group.stsrg.name

  administrator_login          = "admin"
  administrator_login_password = "Azure@123"

  sku_name   = "GP_Gen5_2"
  storage_mb = 5120
  version    = "5.7"

  auto_grow_enabled                 = true
  backup_retention_days             = 7
  geo_redundant_backup_enabled      = true
  infrastructure_encryption_enabled = true
  public_network_access_enabled     = false
  ssl_enforcement_enabled           = true
  ssl_minimal_tls_version_enforced  = "TLS1_2"

  depends_on = [
    azurerm_resource_group.stsrg
  ]
}

#Creating MySQL DB
resource "azurerm_mysql_database" "mysqldb" {
  name                = "mysqldb"
  resource_group_name = azurerm_resource_group.stsrg.name
  server_name         = azurerm_mysql_server.mysqlserver.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"

  depends_on = [
    azurerm_resource_group.stsrg
  ]
}

resource "azurerm_mysql_firewall_rule" "fw_private_rule" {
  name                = "fw_private_rule"
  resource_group_name = azurerm_resource_group.stsrg.name
  server_name         = azurerm_mysql_server.mysqlserver.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}
