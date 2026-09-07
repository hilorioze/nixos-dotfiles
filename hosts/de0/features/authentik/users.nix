{
  # keep-sorted start
  domain,
  lib,
  mkInitialPasswordCredential,
  users,
  # keep-sorted end
}: let
  renderInitialUser = username:
    lib.concatStringsSep "\n" [
      "    - model: authentik_core.user"
      "      state: created"
      "      identifiers:"
      "        username: ${username}"
      "      attrs:"
      "        name: ${username}"
      ""
      "        password: !File /run/credentials/authentik-worker.service/${mkInitialPasswordCredential username}"
    ];

  renderUser = username: {groups}: let
    groupReferences =
      map (
        group:
          if group == "mail-users"
          then "!KeyOf mail-users"
          else "!Find [authentik_core.group, [name, ${group}]]"
      )
      groups;
  in
    lib.concatStringsSep "\n" [
      "    - model: authentik_core.user"
      "      identifiers:"
      "        username: ${username}"
      "      attrs:"
      "        name: ${username}"
      "        email: ${username}@${domain}"
      ""
      (
        if groupReferences == []
        then "        groups: []"
        else
          lib.concatStringsSep "\n" [
            "        groups:"
            (lib.concatMapStringsSep "\n" (group: "          - ${group}") groupReferences)
          ]
      )
    ];

  reconciledUsers = lib.concatStringsSep "\n\n" (lib.mapAttrsToList renderUser users);
in
  ''
    version: 1

    entries:
      dependencies:
        - model: authentik_blueprints.metaapplyblueprint
          attrs:
            identifiers:
              path: system/bootstrap.yaml

      users:
        - model: authentik_core.user
          identifiers:
            username: akadmin
          attrs:
            is_active: false

            groups: []

        - model: authentik_core.group
          id: mail-users
          identifiers:
            name: mail-users

  ''
  + lib.concatStringsSep "\n\n" (lib.mapAttrsToList (username: _: renderInitialUser username) users)
  + "\n\n"
  + reconciledUsers
  + "\n"
