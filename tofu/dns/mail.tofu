# the mailserver on hel0
resource "cloudflare_dns_record" "mail_service" {
  for_each = toset([
    # keep-sorted start
    "imap",
    "mail",
    "smtp",
    # keep-sorted end
  ])

  zone_id = local.zone_id

  name = "${each.key}.hilorioze.com"
  type = "CNAME"

  content = "hel0.hilorioze.com"

  ttl = local.automatic_ttl
}

resource "cloudflare_dns_record" "mx" {
  zone_id = local.zone_id

  name = "hilorioze.com"
  type = "MX"

  content  = "mail.hilorioze.com"
  priority = 10

  ttl = local.automatic_ttl
}

resource "cloudflare_dns_record" "imaps" {
  zone_id = local.zone_id

  name = "_imaps._tcp.hilorioze.com"
  type = "SRV"

  data = {
    priority = 0
    weight   = 0

    port   = 993
    target = "imap.hilorioze.com"
  }

  priority = 0 # mirror of `data.priority`; plans a change without it

  ttl = local.automatic_ttl
}

resource "cloudflare_dns_record" "submission" {
  zone_id = local.zone_id

  name = "_submission._tcp.hilorioze.com"
  type = "SRV"

  data = {
    priority = 0
    weight   = 0

    port   = 587
    target = "smtp.hilorioze.com"
  }

  priority = 0 # mirror of `data.priority`; plans a change without it

  ttl = local.automatic_ttl
}

resource "cloudflare_dns_record" "spf" {
  zone_id = local.zone_id

  name = "hilorioze.com"
  type = "TXT"

  content = "\"v=spf1 a:hel0.hilorioze.com -all\""

  ttl = local.automatic_ttl
}

# public key of `services/rspamd/dkim/hilorioze.com/private-key` on hel0
resource "cloudflare_dns_record" "dkim" {
  zone_id = local.zone_id

  name = "mail._domainkey.hilorioze.com"
  type = "TXT"

  content = "\"v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAv81sE+H5ngWfSSIxKh4l+Eief/BjPdo60WZNc8bk8RrC+Uja/jiqmThKQgV9hsD1yMBHCkxEPsx6hmwcNfCsLwvSyMzFWlbWpc0Tvmz1Eo1ipe1ur53nYsA+yjNS9/e9EDLdtxlJidR6V4JfhYH35PU1nAY7D1D5K6vadAjlN4OGWgZxep5LIY1OlZPt1qcwo\" \"yWDqR3RZg6QXr1ar8yezA8YRsLM8Ex2rDR08Fk9RFi0hhv3c+gg284XEgJ06HV2lni209/jLC2G9nnKaG1t5PZbDRD770FdJZnTKzokAqgOAMTOreF4Nnue+n0t5hJGiEtDgGsNgYUdws7hsO0q3wIDAQAB\""

  ttl = local.automatic_ttl
}

resource "cloudflare_dns_record" "dmarc" {
  zone_id = local.zone_id

  name = "_dmarc.hilorioze.com"
  type = "TXT"

  content = "\"v=DMARC1; p=reject; sp=reject; fo=1; adkim=s; aspf=s; pct=100; rf=afrf; ri=86400; rua=mailto:c2637dafdeed46dcaedb955c274e4cc4@dmarc-reports.cloudflare.net\""

  ttl = local.automatic_ttl
}
