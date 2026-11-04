{
  services.flatpak.packages = [
    {
      appId = "org.vinegarhq.Sober";

      # to update:
      # flatpak remote-info flathub org.vinegarhq.Sober | awk -F': *' '/Version:/ {version=$2} /Commit:/ {commit=$2} END {printf "commit = \"%s\"; # %s\n", commit, version}'
      commit = "2dc01ea5b3a80dedebc0b06d7e674b15d8ee3f01fe35115d78d38afd34882327"; # 1.7.0
    }
  ];
}
