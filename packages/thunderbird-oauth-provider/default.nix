{
  # keep-sorted start
  oauthProvider,
  writeTextFile,
  # keep-sorted end
}: let
  extensionID = "oauth-provider@hilorioze.com";
  version = "1.0.0";
in
  writeTextFile {
    name = "thunderbird-oauth-provider-${version}";

    destination = "/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/${extensionID}/manifest.json";

    text = builtins.toJSON {
      manifest_version = 2;

      applications.gecko.id = extensionID;
      name = "OAuth provider";
      inherit version;

      oauth_provider = oauthProvider;
    };
  }
