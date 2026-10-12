{lib, ...}: {
  xdg.configFile."gpu-screen-recorder/config_ui".text = let
    audioTracks = [
      "false [add_audio_track]" # system and microphone
      "false device:default_output"
      "false device:default_input"

      "false [add_audio_track]" # system only
      "false device:default_output"

      "false [add_audio_track]" # microphone only
      "false device:default_input"
    ];
  in
    lib.generators.toKeyValue {
      mkKeyValue = lib.generators.mkKeyValueDefault {} " ";

      listsAsDuplicateKeys = true;
    } {
      "main.wayland_warning_shown" = true; # shut up about x11

      "record.container" = "mkv";

      "record.record_options.codec" = "hevc";
      "record.record_options.video_quality" = "high";

      "record.record_options.audio_track_item" = audioTracks;

      "replay.record_options.codec" = "hevc";
      "replay.record_options.video_bitrate" = 12000;

      "replay.record_options.audio_track_item" = audioTracks;

      "replay.time" = 20 * 60; # 20m in seconds

      "replay.turn_on_replay_automatically_mode" = "turn_on_at_system_startup";

      # everything except the show/hide hotkey is unbound
      "record.start_stop_hotkey" = "0 0";
      "record.start_stop_region_hotkey" = "0 0";
      "record.start_stop_window_hotkey" = "0 0";
      "record.pause_unpause_hotkey" = "0 0";

      "replay.start_stop_hotkey" = "0 0";
      "replay.save_hotkey" = "0 0";
      "replay.save_1_min_hotkey" = "0 0";
      "replay.save_10_min_hotkey" = "0 0";

      "streaming.start_stop_hotkey" = "0 0";

      "screenshot.take_screenshot_hotkey" = "0 0";
      "screenshot.take_screenshot_region_hotkey" = "0 0";
      "screenshot.take_screenshot_window_hotkey" = "0 0";
    };
}
