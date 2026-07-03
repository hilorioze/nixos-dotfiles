let
  mediaGroup = "media";
in {
  users.groups.${mediaGroup} = {};

  systemd.tmpfiles.settings.mediaStorage = let
    mediaRoot = "/srv/media";

    mediaDirConfig = {
      mode = "2775";

      user = "root";
      group = mediaGroup;
    };
  in {
    ${mediaRoot}.d = mediaDirConfig;

    # keep-sorted start
    "${mediaRoot}/downloads".d = mediaDirConfig;
    "${mediaRoot}/downloads/incomplete".d = mediaDirConfig;
    "${mediaRoot}/downloads/manual".d = mediaDirConfig;
    "${mediaRoot}/downloads/radarr".d = mediaDirConfig;
    "${mediaRoot}/downloads/sonarr".d = mediaDirConfig;
    # keep-sorted end

    # keep-sorted start
    "${mediaRoot}/library".d = mediaDirConfig;
    "${mediaRoot}/library/movies".d = mediaDirConfig;
    "${mediaRoot}/library/tv".d = mediaDirConfig;
    "${mediaRoot}/library/youtube".d = mediaDirConfig;
    # keep-sorted end
  };
}
