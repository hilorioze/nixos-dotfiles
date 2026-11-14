final: prev: {
  firefox-addons =
    prev.firefox-addons
    // {
      # librewolf has no policy for optional data collection and asks for consent on youtube; declare what voting needs as required, which librewolf grants from the manifest
      return-youtube-dislikes = prev.firefox-addons.return-youtube-dislikes.overrideAttrs (oldAttrs: {
        src =
          final.runCommand oldAttrs.src.name {
            inherit (oldAttrs) src;

            nativeBuildInputs = with final; [
              # keep-sorted start
              jq
              unzip
              zip
              # keep-sorted end
            ];
          } ''
            unzip $src manifest.json

            jq '.browser_specific_settings.gecko.data_collection_permissions |= . + {required: $voting, optional: (.optional - $voting)}' \
              --argjson voting '["browsingActivity", "websiteActivity", "websiteContent"]' \
              manifest.json >manifest.patched.json
            mv manifest.patched.json manifest.json

            cp $src $out
            chmod u+w $out

            zip $out manifest.json
            # the changed manifest no longer matches the amo signature
            zip --delete $out 'META-INF/*'
          '';
      });
    };
}
