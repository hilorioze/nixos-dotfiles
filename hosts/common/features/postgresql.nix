{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: {
  sops.secrets."services/postgresql/users/hilorioze/hashed-password".owner = config.systemd.services.postgresql-setup.serviceConfig.User;

  services.postgresql = {
    enable = true;

    enableTCPIP = true;

    authentication = lib.mkForce ''
      local all postgres peer map=postgres

      ${lib.concatStringsSep "\n" config.services.postgresql.authRules}

      # podman0 bridge subnet for local containers
      host all all 10.88.0.0/16 scram-sha-256
    '';

    ensureUsers = [
      {
        name = "hilorioze";
      }
    ];
  };

  systemd.services.postgresql-setup.script = lib.mkAfter ''
    psql -X -v ON_ERROR_STOP=1 -tA <<< ${lib.escapeShellArg ''
      SELECT format('ALTER ROLE %I WITH PASSWORD %L', 'hilorioze', pg_read_file('${config.sops.secrets."services/postgresql/users/hilorioze/hashed-password".path}'))
      \gexec
    ''}
  '';
}
