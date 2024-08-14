# Create namespaces using an array of strings
resource "kubernetes_namespace" "namespace" {
  for_each = toset(var.namespaces)

  metadata {
    name = each.value
  }
}

# Create Ingress for each namespace
resource "kubernetes_ingress_v1" "namespace_ingress" {
  for_each = kubernetes_namespace.namespace

  metadata {
    name      = "${each.key}-ingress"
    namespace = each.key
  }

  spec {
    default_backend {
      service {
        name = var.ingress_service_name
        port {
          number = var.ingress_service_port
        }
      }
    }

    rule {
      http {
        path {
          backend {
            service {
              name = var.ingress_service_name
              port {
                number = var.ingress_service_port
              }
            }
          }
          path = "/*"
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.namespace]
}

# Create a Network Policy to deny all ingress traffic by default
resource "kubernetes_network_policy" "deny_all" {
  for_each = kubernetes_namespace.namespace

  metadata {
    name      = "${each.key}-deny-all"
    namespace = each.key
  }

  spec {
    pod_selector {}

    ingress {
      from {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }
    }

    policy_types = ["Ingress"]
  }

  depends_on = [kubernetes_namespace.namespace]
}

# Create a Network Policy to allow traffic from selected CIDRs
resource "kubernetes_network_policy" "allow_selected_cidrs" {
  for_each = kubernetes_namespace.namespace

  metadata {
    name      = "${each.key}-allow-selected-cidrs"
    namespace = each.key
  }

  spec {
    pod_selector {}

    ingress {
      dynamic "from" {
        for_each = var.allowed_cidrs
        content {
          ip_block {
            cidr = from.value
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }

  depends_on = [kubernetes_namespace.namespace]
}

# Create a Service Account for each namespace
resource "kubernetes_service_account" "namespace_service_account" {
  for_each = kubernetes_namespace.namespace

  metadata {
    name      = "${each.key}-sa"
    namespace = each.key
  }

  depends_on = [kubernetes_namespace.namespace]
}