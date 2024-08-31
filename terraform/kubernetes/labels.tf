resource "kubernetes_labels" "hgh0" {
  api_version = "v1"
  kind        = "Node"
  metadata {
    name = "hgh0"
  }
  labels = {
    "svccontroller.k3s.cattle.io/enablelb" : "true"
    "svccontroller.k3s.cattle.io/lbpool" : "public"
  }
}

resource "kubernetes_labels" "hgh1" {
  api_version = "v1"
  kind        = "Node"
  metadata {
    name = "hgh1"
  }
  labels = {
    "svccontroller.k3s.cattle.io/enablelb" : "true"
    "svccontroller.k3s.cattle.io/lbpool" : "public"
  }
}


resource "kubernetes_labels" "hgh2" {
  api_version = "v1"
  kind        = "Node"
  metadata {
    name = "hgh2"
  }
  labels = {
    "svccontroller.k3s.cattle.io/enablelb" : "true"
    "svccontroller.k3s.cattle.io/lbpool" : "private"
  }
}
