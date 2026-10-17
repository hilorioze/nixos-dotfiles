{config, ...}: {
  sops.secrets."apps/adb/private-key".path = "${config.home.homeDirectory}/.android/adbkey";
}
