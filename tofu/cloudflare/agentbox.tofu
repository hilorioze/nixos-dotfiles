# agentboxes' zones, served by knot on de0 (`hosts/de0/features/services/knot.nix`)
resource "cloudflare_dns_record" "agentbox_ns" {
  zone_id = local.zone_id

  name = "agentbox.hilorioze.com"
  type = "NS"

  content = "de0.hilorioze.com"

  ttl = local.automatic_ttl
}

# the zone's signing key never rolls; this is `keymgr agentbox.hilorioze.com. ds` of the key in de0's `services/agentbox/knot/signing-key`
resource "cloudflare_dns_record" "agentbox_ds" {
  zone_id = local.zone_id

  name = "agentbox.hilorioze.com"
  type = "DS"

  data = {
    key_tag   = 48665
    algorithm = 13 # ecdsap256sha256

    digest_type = 2 # sha-256
    digest      = "89386d03b994bdbe7243c78427636af56ea35037d8e99e32a86fdda2327d64ea"
  }

  ttl = local.automatic_ttl

  depends_on = [cloudflare_dns_record.agentbox_ns] # cloudflare refuses a DS without the delegation
}
