{config, ...}: {
  sops = {
    secrets."apps/keepassxc/key" = {};

    templates."apps/keepassxc/storage-keyring.json".content = let
      databaseHash = "fb9a50b4543f9ff95e065ab937916c5e73980e49282a82fab075608bfb382e89";
    in
      builtins.toJSON {
        keyRing."${databaseHash}" = {
          id = "librewolf-lelonix";

          hash = databaseHash;

          key = config.sops.placeholder."apps/keepassxc/key";
        };
      };
  };
}
