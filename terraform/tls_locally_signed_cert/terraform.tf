terraform {
  required_providers {
    # tls                        = "= 3.1" # Works
    # BUG: https://github.com/hashicorp/terraform-provider-tls/issues/217
    #      error creating certificate: x509: provided PrivateKey doesn't match parent's PublicKey
    tls                        = "= 3.4" # Does not work
  }
  required_version             = "~> 1.0"
}