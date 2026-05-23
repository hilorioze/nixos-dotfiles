{
  # keep-sorted start
  pkgs,
  # keep-sorted end
  ...
}: {
  environment = {
    systemPackages = with pkgs.gst_all_1; [
      # keep-sorted start
      gst-libav
      gst-plugins-bad
      gst-plugins-base
      gst-plugins-good
      gst-plugins-ugly
      gst-vaapi
      gstreamer
      # keep-sorted end
    ];

    variables.GST_PLUGIN_PATH = "/run/current-system/sw/lib/gstreamer-1.0/";
  };
}
