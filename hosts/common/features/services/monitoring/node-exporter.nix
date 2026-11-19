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

    extraFlags = ["--collector.systemd.enable-restarts-metrics"]; # a crash loop under `Restart=` never leaves the unit failed
  };
}
