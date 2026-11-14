{
  # replay starts at login, before the cursor settles, so the default `focused_monitor` sometimes picks a side monitor; DP-6 is the AOC in the middle
  xdg.configFile."gpu-screen-recorder/config_ui".text = ''
    replay.record_options.record_area_option DP-6
  '';
}
