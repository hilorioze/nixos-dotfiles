{
  # keep-sorted start
  config,
  pkgs,
  # keep-sorted end
  ...
}: let
  logDirectory = "/var/lib/opencanary";

  certificateName = "185.68.185.206";

  skin = "nasLogin"; # the default `basicLogin` lacks the `redirect.html` its `/` redirect renders
in {
  security.acme.certs.${certificateName} = {
    profile = "shortlived"; # let's encrypt issues ip certificates only under it

    extraLegoFlags = ["--disable-cn"]; # let's encrypt rejects a csr with an ip in its common name

    # the http honeypot serves the challenges from its static directory
    webroot = "/var/lib/acme/acme-challenge";

    reloadServices = ["podman-opencanary.service"]; # opencanary reads the certificate only at start
  };

  virtualisation.oci-containers.containers.opencanary = {
    image = "docker.io/thinkst/opencanary:0.9.10@sha256:4e51338e3b6e349652b0604be656d9b8fc1cde2cd40409b2e956f1da3eb673a1";

    # twisted's context factory loads only the leaf, so https would serve no intermediate; the rest is the image's own command
    entrypoint = "sh";
    cmd = [
      "-c"
      "sed --in-place s/use_certificate_file/use_certificate_chain_file/ /opencanary/.venv/lib/python3.10/site-packages/twisted/internet/ssl.py && exec opencanaryd --dev --uid=nobody --gid=nogroup"
    ];

    # ssh and telnet are left to cowrie; smb needs a samba, and portscan reads iptables logs from `kern.log`
    ports = [
      # keep-sorted start numeric=yes
      "21:21/tcp"
      "69:69/udp"
      "80:80/tcp"
      "123:123/udp"
      "161:161/udp"
      "443:443/tcp"
      "1433:1433/tcp"
      "3306:3306/tcp"
      "3389:3389/tcp"
      "5060:5060/udp"
      "5900:5900/tcp"
      "6379:6379/tcp"
      "8080:8080/tcp"
      "9418:9418/tcp"
      "27017:27017/tcp"
      # keep-sorted end
    ];

    volumes = [
      "${pkgs.writeText "opencanary.conf" (builtins.toJSON {
        "device.node_id" = config.networking.hostName;

        # keep-sorted start
        "ftp.enabled" = true;
        "git.enabled" = true;
        "http.enabled" = true;
        "httpproxy.enabled" = true;
        "https.enabled" = true;
        "mongodb.enabled" = true;
        "mssql.enabled" = true;
        "mysql.enabled" = true;
        "ntp.enabled" = true;
        "rdp.enabled" = true;
        "redis.enabled" = true;
        "sip.enabled" = true;
        "snmp.enabled" = true;
        "tftp.enabled" = true;
        "vnc.enabled" = true;
        # keep-sorted end

        "https.certificate" = "/etc/ssl/opencanary/fullchain.pem";
        "https.key" = "/etc/ssl/opencanary/key.pem";

        "http.skin" = skin;
        "https.skin" = skin;

        "httpproxy.port" = 8080; # the default 8443 is rarely probed for proxies

        logger = {
          class = "PyLogger";

          kwargs.handlers = {
            console = {
              class = "logging.StreamHandler";

              stream = "ext://sys.stdout";
            };

            file = {
              class = "logging.FileHandler";

              filename = "/var/log/opencanary/opencanary.log";
            };
          };
        };
      })}:/etc/opencanaryd/opencanary.conf:ro"

      "${config.security.acme.certs.${certificateName}.directory}:/etc/ssl/opencanary:ro"
      "${config.security.acme.certs.${certificateName}.webroot}/.well-known:/opencanary/opencanary/modules/data/http/skin/${skin}/static/.well-known:ro"

      "${logDirectory}:/var/log/opencanary"
    ];
  };

  systemd = {
    tmpfiles.rules = ["d ${logDirectory} 0755 root root -"];

    services = {
      podman-opencanary.after = ["acme-${certificateName}.service"]; # the unit puts a self-signed certificate in place before the first order

      "acme-order-renew-${certificateName}".after = ["podman-opencanary.service"]; # let's encrypt fetches the challenge through opencanary

      honeypot-reporter.environment.OPENCANARY_LOG = "${logDirectory}/opencanary.log";
    };
  };
}
