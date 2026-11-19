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
    carcass   = { host = "de0" }
    dashboard = { host = "de0", proxied = true }
    grafana   = { host = "de0" }
    hs        = { host = "hel0" }
    idm       = { host = "de0" }
    mud       = { host = "de0" }
    niks3     = { host = "de0" }
    status    = { host = "de0", proxied = true }
    # keep-sorted end
  }

  zone_id = local.zone_id

  name = "${each.key}.hilorioze.com"
  type = "CNAME"

  content = "${each.value.host}.hilorioze.com"

  ttl     = local.automatic_ttl
  proxied = lookup(each.value, "proxied", false)
}
