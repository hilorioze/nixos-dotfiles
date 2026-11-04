{
  services.pipewire.wireplumber.extraConfig."51-ignore-nvidia-hda"."monitor.alsa.rules" = [
    {
      matches = [
        {
          "device.bus-path" = "pci-0000:01:00.1";
        }
      ];

      actions.update-props."device.disabled" = true;
    }
  ];
}
