{
  services.prometheus.exporters.node = {
    enable = true;

    # needed by the "Node Exporter Full" dashboard
    enabledCollectors = [
      # keep-sorted start
      "processes"
      "systemd"
      # keep-sorted end
    ];
  };
}
