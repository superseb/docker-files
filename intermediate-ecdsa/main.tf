// Inspired by https://gist.github.com/mauilion/23691ebd727324d8bdbd012771097f13, thanks!
provider "tls" {
}

variable "dns_names" {
  type    = list(string)
  default = []
}

variable "ip_addresses" {
  type    = list(string)
  default = ["127.0.0.1"]
}

locals {
  client_cert  = 1
  organization = "dummy-ca"
  algorithm    = "ECDSA"
  ecdsa_curve  = "P384"
}

resource "tls_private_key" "root_ca" {
  algorithm   = local.algorithm
  ecdsa_curve = local.ecdsa_curve
}

resource "local_file" "root_ca_key" {
  content  = tls_private_key.root_ca.private_key_pem
  filename = "./files/root_ca.key"
}


resource "tls_self_signed_cert" "root_ca" {
  key_algorithm   = tls_private_key.root_ca.algorithm
  private_key_pem = tls_private_key.root_ca.private_key_pem

  subject {
    common_name  = "root-ca"
    organization = local.organization
  }

  is_ca_certificate     = true
  validity_period_hours = 99999

  allowed_uses = [
    "non_repudiation",
    "digital_signature",
    "key_encipherment",
    "cert_signing",
  ]
}

resource "local_file" "root_ca_cert" {
  content  = tls_self_signed_cert.root_ca.cert_pem
  filename = "./files/root_ca.crt"
}

resource "tls_private_key" "intermediate_ca" {
  algorithm   = local.algorithm
  ecdsa_curve = local.ecdsa_curve
}

resource "local_file" "intermediate_ca_key" {
  content  = tls_private_key.intermediate_ca.private_key_pem
  filename = "./files/intermediate_ca.key"
}

resource "tls_cert_request" "intermediate_ca" {
  key_algorithm   = tls_private_key.intermediate_ca.algorithm
  private_key_pem = tls_private_key.intermediate_ca.private_key_pem

  subject {
    common_name  = "intermediate-ca"
    organization = local.organization
  }
}

resource "tls_locally_signed_cert" "intermediate_ca" {
  cert_request_pem = tls_cert_request.intermediate_ca.cert_request_pem

  ca_key_algorithm   = tls_private_key.root_ca.algorithm
  ca_private_key_pem = tls_private_key.root_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root_ca.cert_pem

  is_ca_certificate     = true
  validity_period_hours = 99999

  allowed_uses = [
    "non_repudiation",
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]
}

resource "local_file" "intermediate_ca_cert" {
  content  = tls_locally_signed_cert.intermediate_ca.cert_pem
  filename = "./files/intermediate_ca.crt"
}

resource "tls_private_key" "server" {
  algorithm   = local.algorithm
  ecdsa_curve = local.ecdsa_curve
}

resource "local_file" "server_key" {
  content  = tls_private_key.server.private_key_pem
  filename = "./files/server.key"
}

resource "random_id" "server" {
  keepers = {
    name = local.organization
  }
  byte_length = 8
}


resource "tls_cert_request" "server" {
  key_algorithm   = tls_private_key.server.algorithm
  private_key_pem = tls_private_key.server.private_key_pem

  subject {
    common_name   = "yolo"
    organization  = local.organization
    serial_number = random_id.server.hex
  }

  dns_names    = var.dns_names
  ip_addresses = var.ip_addresses
}


resource "tls_locally_signed_cert" "server" {
  cert_request_pem = tls_cert_request.server.cert_request_pem

  ca_key_algorithm   = tls_private_key.intermediate_ca.algorithm
  ca_private_key_pem = tls_private_key.intermediate_ca.private_key_pem
  ca_cert_pem        = tls_locally_signed_cert.intermediate_ca.cert_pem

  validity_period_hours = 26280

  allowed_uses = [
    "non_repudiation",
    "digital_signature",
    "key_encipherment",
  ]
}

resource "local_file" "server_cert" {
  content  = tls_locally_signed_cert.server.cert_pem
  filename = "./files/server.crt"
}

resource "local_file" "server_full_chain" {
  content  = "${tls_locally_signed_cert.server.cert_pem}${tls_locally_signed_cert.intermediate_ca.cert_pem}"
  filename = "./files/server.fullchain.crt"
}
