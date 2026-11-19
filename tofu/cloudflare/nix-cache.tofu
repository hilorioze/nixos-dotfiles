# serves the private niks3 bucket on b2 through cloudflare; b2 doesn't bill egress to cloudflare
resource "cloudflare_workers_script" "nix_cache" {
  account_id = local.account_id

  script_name = "nix-cache-b2-proxy"

  content_file   = "${path.module}/nix-cache.js"
  content_sha256 = filesha256("${path.module}/nix-cache.js")
  main_module    = "nix-cache.js"

  compatibility_date = "2026-06-24"

  bindings = [
    {
      name = "B2_BUCKET"
      type = "plain_text"

      text = "nix-cache-hilorioze"
    },
    {
      name = "B2_ENDPOINT"
      type = "plain_text"

      text = "s3.us-east-005.backblazeb2.com"
    },
    {
      name = "B2_REGION"
      type = "plain_text"

      text = "us-east-005"
    },
  ]
  keep_bindings = ["secret_text"] # the b2 application key is set in the dashboard; keep it out of the public state
}

resource "cloudflare_workers_custom_domain" "nix_cache" {
  account_id = local.account_id
  zone_id    = local.zone_id

  hostname = "nix-cache.hilorioze.com"

  service = cloudflare_workers_script.nix_cache.script_name
}
