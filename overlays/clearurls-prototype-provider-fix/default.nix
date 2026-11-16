final: prev: {
  firefox-addons =
    prev.firefox-addons
    // {
      # the enumerable `Object.prototype.getOrDefault` turns into a match-all provider without exceptions, which moves the query of a url ending in `#` into the fragment and breaks google sign-in
      clearurls = prev.firefox-addons.clearurls.overrideAttrs (oldAttrs: {
        src =
          final.runCommand oldAttrs.src.name {
            inherit (oldAttrs) src;

            nativeBuildInputs = with final; [
              # keep-sorted start
              unzip
              zip
              # keep-sorted end
            ];
          } ''
            unzip $src core_js/tools.js
            patch --strip=1 <${./prototype-provider-fix.patch}

            cp $src $out
            chmod u+w $out

            zip $out core_js/tools.js
            # the changed script no longer matches the amo signature
            zip --delete $out 'META-INF/*'
          '';
      });
    };
}
