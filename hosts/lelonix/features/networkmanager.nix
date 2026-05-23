{
  imports = [
    # keep-sorted start
    ../../common/features/networkmanager.nix
    # keep-sorted end
  ];

  networking.networkmanager.ensureProfiles.profiles = {
    # keep-sorted start block=yes newline_separated=yes
    "Redmi_2.4GHz" = {
      connection = {
        id = "Redmi_2.4GHz";
        type = "wifi";
        autoconnect = false;
      };
      wifi.ssid = "Redmi_2.4GHz";
    };

    Redmi = {
      connection = {
        id = "Redmi";
        type = "wifi";
      };
      wifi.ssid = "Redmi";
    };

    philone = {
      connection = {
        id = "philone";
        type = "wifi";
      };
      wifi.ssid = "philone";
    };
    # keep-sorted end
  };
}
