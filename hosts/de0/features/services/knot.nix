{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  sops = {
    secrets =
      {
        # keep-sorted start
        "services/agentbox/knot/ds-push-tsig-secret" = {};
        "services/agentbox/knot/signing-key".owner = config.users.users.knot.name;
        # keep-sorted end
      }
      // lib.mapAttrs' (name: _machine: lib.nameValuePair "services/agentbox/machines/${name}/tsig-secret" {}) config.virtualisation.agentbox.machines;

    templates."services/knot/keys.conf" = {
      content = let
        key = id: secret:
          lib.concatMapStrings (line: "  ${line}\n") [
            "- id: ${id}"
            "  algorithm: hmac-sha256"
            "  secret: ${secret}"
          ];
      in
        "key:\n"
        + key "ds-push" config.sops.placeholder."services/agentbox/knot/ds-push-tsig-secret"
        + lib.concatStrings (lib.mapAttrsToList (name: _machine: key name config.sops.placeholder."services/agentbox/machines/${name}/tsig-secret") config.virtualisation.agentbox.machines);

      owner = config.users.users.knot.name;

      restartUnits = ["knot.service"];
    };
  };

  networking.firewall = {
    allowedTCPPorts = [53];
    allowedUDPPorts = [53];
  };

  services.knot = {
    enable = true;

    keyFiles = [config.sops.templates."services/knot/keys.conf".path];

    settings = let
      # what an agentbox may change in its zone; the rest (apex, delegation, dnssec) stays the server's
      updateTypes = [
        # keep-sorted start
        "A"
        "AAAA"
        "CAA"
        "CNAME"
        "DNAME"
        "HTTPS"
        "LOC"
        "MX"
        "NAPTR"
        "OPENPGPKEY"
        "SMIMEA"
        "SRV"
        "SSHFP"
        "SVCB"
        "TLSA"
        "TXT"
        "URI"
        # keep-sorted end
      ];
    in {
      # not the wildcard, which podman's aardvark-dns on its bridge would collide with
      server.listen = [
        "10.0.0.229@53" # oci translates the public ipv4 to this private one
        "${(lib.importJSON ../../../servers.json).${config.networking.hostName}.ipv6}@53"

        "${config.virtualisation.agentbox.bridge.address}@53" # agentboxes update their zones here

        "127.0.0.1@53" # agentbox zones push their DS records to the parent here
      ];

      # the time limit also covers the handshakes of authorized updates, which come only from the host and agentboxes
      mod-rrl = [
        {
          id = "default";

          whitelist = [
            "127.0.0.1"
            "${config.virtualisation.agentbox.bridge.address}/${toString config.virtualisation.agentbox.bridge.prefixLength}"
          ];
        }
      ];

      # knot is also the parent's server, so agentbox zones push their DS records and check them on itself
      remote = [
        {
          id = "self";

          address = "127.0.0.1@53";

          key = "ds-push";
        }
      ];

      submission = [
        {
          id = "self";

          parent = "self";
        }
      ];

      acl =
        [
          {
            id = "ds-push";

            address = "127.0.0.1";

            key = "ds-push";

            action = "update";

            update-type = "DS";

            update-owner = "zone";
            update-owner-match = "sub";
          }
        ]
        ++ lib.mapAttrsToList (name: machine: {
          id = name;

          inherit (machine) address;

          key = name;

          action = "update";

          update-type = updateTypes;

          update-owner = "zone";
          update-owner-match = "sub";
        })
        config.virtualisation.agentbox.machines;

      policy = [
        # one key signs everything and never rolls: its DS is pinned in hilorioze.com through tofu, and sops keeps the key across a lost state directory
        {
          id = "agentbox";

          manual = true;
        }

        {
          id = "machine";

          algorithm = "ecdsap256sha256";

          ksk-lifetime = "365d";

          ksk-submission = "self";
          ds-push = "self";
        }
      ];

      # the zone files are input only; dynamic records live in the journal, and `zonefile-skip` keeps the two from overwriting each other
      template = [
        {
          id = "default";

          global-module = "mod-rrl/default";

          zonefile-sync = -1;
          zonefile-load = "difference-no-serial";
          journal-content = "all";

          dnssec-signing = true;
        }
      ];

      zone = let
        # the only nameserver; agentbox zones go down with de0 anyway
        nameserver = "${config.networking.fqdn}.";

        zoneFile = name: records:
          pkgs.writeText "${name}.zone" ''
            $ORIGIN ${name}.
            $TTL 3600

            @ SOA ${nameserver} hostmaster.${config.networking.domain}. 1 3600 900 1209600 300
            @ NS ${nameserver}

            ${records}
          '';
      in
        [
          {
            inherit (config.virtualisation.agentbox) domain;

            file = zoneFile config.virtualisation.agentbox.domain (lib.concatMapStringsSep "\n" (name: "${name} NS ${nameserver}") (lib.attrNames config.virtualisation.agentbox.machines));
            zonefile-skip = "DS";

            dnssec-policy = "agentbox";

            acl = "ds-push";
          }
        ]
        ++ lib.mapAttrsToList (name: _machine: {
          domain = "${name}.${config.virtualisation.agentbox.domain}";

          file = zoneFile "${name}.${config.virtualisation.agentbox.domain}" "";
          zonefile-skip = updateTypes;

          zone-max-size = "1M";

          dnssec-policy = "machine";

          acl = name;
        })
        config.virtualisation.agentbox.machines;
    };
  };

  # the pinned key enters the kasp database once; knot can't sign the zone without it
  systemd.services.knot.preStart = ''
    if [[ -z $(${lib.getExe' config.services.knot.package "keymgr"} --config /etc/knot/knot.conf ${config.virtualisation.agentbox.domain}. list) ]]; then
      ${lib.getExe' config.services.knot.package "keymgr"} --config /etc/knot/knot.conf ${config.virtualisation.agentbox.domain}. import-pem ${config.sops.secrets."services/agentbox/knot/signing-key".path} algorithm=ecdsap256sha256 ksk=yes zsk=yes
    fi
  '';
}
