{
  # keep-sorted start
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  programs.git = {
    signing = {
      key = "D33614F74E83A1439102200AFE60FCD157B4195B!";

      signByDefault = true;
    };

    # local commits may stay unsigned until they are ready, but github's vigilant mode marks pushed unsigned ones as unverified, whatever tool pushes them
    settings.hook.require-signed-commits = {
      event = "pre-push";

      command = lib.getExe (pkgs.writeShellApplication {
        name = "require-signed-commits";

        text = ''
          remote=$1
          email=$(git config user.email)

          unsigned=$(
            while read -r _ local_sha _ remote_sha; do
              [[ $local_sha =~ ^0+$ ]] && continue # a deleted ref pushes no commits

              known=(--remotes="$remote")
              git cat-file -e "$remote_sha^{commit}" 2>/dev/null && known+=("$remote_sha") # also covers pushes to a url without remote-tracking refs

              git log --author="$email" --fixed-strings --format='%G?%h %s' "$local_sha" --not "''${known[@]}" | sed --quiet 's/^N//p'
            done
          )
          [[ -z $unsigned ]] && exit 0

          printf 'unsigned commits by %s:\n%s\n\nsign them and push again, e.g. after: git rebase --gpg-sign --no-ff @{upstream}\n' "$email" "$unsigned" >&2
          exit 1
        '';
      });
    };
  };
}
