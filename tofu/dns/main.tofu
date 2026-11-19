terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

# reads `CLOUDFLARE_API_TOKEN`
provider "cloudflare" {}

locals {
  # hilorioze.com; not a `cloudflare_zone`; avoid account data leakage
  zone_id = "d3064ca9a1ac89d3edf1e2a9faa887d4"

  automatic_ttl = 1
}
