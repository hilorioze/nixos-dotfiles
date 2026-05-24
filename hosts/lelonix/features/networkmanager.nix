{
  imports = [../../common/features/networkmanager.nix];

  networking.networkmanager.ensureProfiles.profiles = {
    # keep-sorted start block=yes newline_separated=yes
    "Redmi_2.4GHz" = {
      connection = {
        type = "wifi";

        id = "Redmi_2.4GHz";

        autoconnect = false;
      };

      wifi.ssid = "Redmi_2.4GHz";
    };

    Redmi = {
      connection = {
        type = "wifi";

        id = "Redmi";
      };

      wifi.ssid = "Redmi";
    };

    philone = {
      connection = {
        type = "wifi";

        id = "philone";
      };

      wifi.ssid = "philone";
    };
    # keep-sorted end
  };
}
