# github pages; cloudflare flattens the cname on the apex
resource "cloudflare_dns_record" "website" {
  zone_id = local.zone_id

  name = "hilorioze.com"
  type = "CNAME"

  content = "hilorioze.github.io"

  ttl = local.automatic_ttl
}

resource "cloudflare_dns_record" "website_www" {
  zone_id = local.zone_id

  name = "www.hilorioze.com"
  type = "CNAME"

  content = "hilorioze.com"

  ttl = local.automatic_ttl
}

resource "cloudflare_dns_record" "service" {
  for_each = {
    # keep-sorted start
    attic     = { host = "de0" }
    carcass   = { host = "de0" }
    dashboard = { host = "de0", proxied = true }
    grafana   = { host = "de0" }
    hs        = { host = "hel0" }
    idm       = { host = "de0" }
    ldap      = { host = "hel0" }
    mud       = { host = "de0" }
    niks3     = { host = "de0" }
    s3        = { host = "de0" }
    status    = { host = "de0", proxied = true }
    wg        = { host = "de0" }
    # keep-sorted end
  }

  zone_id = local.zone_id

  name = "${each.key}.hilorioze.com"
  type = "CNAME"

  content = "${each.value.host}.hilorioze.com"

  ttl     = local.automatic_ttl
  proxied = lookup(each.value, "proxied", false)
}

resource "cloudflare_dns_record" "ldaps" {
  zone_id = local.zone_id

  name = "_ldaps._tcp.hilorioze.com"
  type = "SRV"

  data = {
    priority = 0
    weight   = 0

    port   = 636
    target = "ldap.hilorioze.com"
  }

  priority = 0 # mirror of `data.priority`; plans a change without it

  ttl = local.automatic_ttl
}
