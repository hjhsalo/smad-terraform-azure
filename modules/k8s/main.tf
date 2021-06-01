terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.45.1"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "k8s_rg" {
  name     = "${lower(var.project_name)}-${var.k8s_resource_group_name_suffix}"
  location = var.location
}

resource "random_id" "log_analytics_workspace_name_suffix" {
  byte_length = 8
}

resource "azurerm_log_analytics_workspace" "log_analytics_ws" {
  # The WorkSpace name has to be unique across the whole of azure, not just the current subscription/tenant.
  name                = "${lower(var.project_name)}-log-analytics-ws-${random_id.log_analytics_workspace_name_suffix.dec}"
  location            = var.log_analytics_workspace_location
  resource_group_name = azurerm_resource_group.k8s_rg.name
  sku                 = var.log_analytics_workspace_sku
}

resource "azurerm_log_analytics_solution" "log_analytics_deployment" {
  solution_name         = "ContainerInsights"
  location              = azurerm_log_analytics_workspace.log_analytics_ws.location
  resource_group_name   = azurerm_resource_group.k8s_rg.name
  workspace_resource_id = azurerm_log_analytics_workspace.log_analytics_ws.id
  workspace_name        = azurerm_log_analytics_workspace.log_analytics_ws.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

resource "azurerm_kubernetes_cluster" "k8s_cluster" {
  name                = "${lower(var.project_name)}-${var.k8s_cluster_name_suffix}"
  location            = azurerm_resource_group.k8s_rg.location
  resource_group_name = azurerm_resource_group.k8s_rg.name
  dns_prefix          = var.k8s_dns_prefix 

  # Use Managed Identity for K8S cluster identity
  # https://www.chriswoolum.dev/aks-with-managed-identity-and-terraform
  identity {
    type = "SystemAssigned"
  }

  # Use Service Principal for K8S cluster identity
  # service_principal {
  #     client_id     = var.client_id
  #     client_secret = var.client_secret
  # }

  # linux_profile {
  #     admin_username = "ubuntu"

  #     ssh_key {
  #         key_data = file(var.k8s_ssh_public_key)
  #     }
  # }

  default_node_pool {
    name       = "agentpool"
    node_count = var.k8s_agent_count
    vm_size    = "Standard_D2_v2"
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_ws.id
    }
    kube_dashboard {
      enabled = false
    }
  }

  network_profile {
    load_balancer_sku = "Standard"
    network_plugin    = "kubenet"
  }

  tags = {
    environment = var.environment
  }
}

resource "azurerm_public_ip" "ambassador-ingress" {
  name                = "ambassador-ingress-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.k8s_rg.name
  
  ## or allocation_method = "Dynamic" is sku is "Basic":
  ## https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip#sku
  sku                 = "Standard"
  allocation_method   = "Static" 
  
  domain_name_label   = var.k8s_dns_prefix ##PREFIX WITH TF WORKSPACE NAME
}

resource "azurerm_role_assignment" "publicip" {
  scope              = azurerm_resource_group.k8s_rg.id
  role_definition_name = "Network Contributor"
  principal_id       = azurerm_kubernetes_cluster.k8s_cluster.identity[0].principal_id
}

resource "kubernetes_storage_class" "azure-disk-retain" {
  metadata {
    name = "azure-disk-retain"
  }
  storage_provisioner = "kubernetes.io/azure-disk"
  reclaim_policy      = "Retain"
  volume_binding_mode = "Immediate"
  parameters = {
    kind          = "managed"
    cachingMode   = "ReadOnly"
    resourceGroup = var.use_separate_storage_rg ? "storage-resource-group" : null
  } # implicitly create storage class in the same RG as K8S cluster if false ^^^
}

resource "kubernetes_persistent_volume_claim" "example" {
  metadata {
    name = "mongodb-data"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "8Gi"
      }
    }
    storage_class_name = "azure-disk-retain"
  }
}

# resource "kubernetes_namespace" "hono" {
#  metadata {
#    name = "hono"
#  }
#}

resource "kubernetes_persistent_volume_claim" "influxdb" {
  metadata {
    name = "influx-pvc"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "8Gi"
      }
    }
    storage_class_name = "azure-disk-retain"
  }
}

