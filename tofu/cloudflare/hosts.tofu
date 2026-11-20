locals {
  # lan hosts' A records are handled by `services.cloudflare-ddns`
  servers = jsondecode(file("${path.module}/../../hosts/servers.json")) # the hosts' own configurations read the addresses too
}

resource "cloudflare_dns_record" "server_ipv4" {
  for_each = local.servers

  zone_id = local.zone_id

  name = "${each.key}.hilorioze.com"
  type = "A"

  content = each.value.ipv4

  ttl = local.automatic_ttl
}

resource "cloudflare_dns_record" "server_ipv6" {
  for_each = local.servers

  zone_id = local.zone_id

  name = "${each.key}.hilorioze.com"
  type = "AAAA"

  content = each.value.ipv6

  ttl = local.automatic_ttl
}

# wildcard for `<service>.${config.networking.fqdn}`
resource "cloudflare_dns_record" "host_services" {
  for_each = toset([
    # keep-sorted start
    "de0",
    "fakesynology-nixos",
    "hel0",
    # keep-sorted end
  ])

  zone_id = local.zone_id

  name = "*.${each.key}.hilorioze.com"
  type = "CNAME"

  content = "${each.key}.hilorioze.com"

  ttl = local.automatic_ttl
}
