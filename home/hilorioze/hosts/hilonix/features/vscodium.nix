{
  home.file.".vscode-oss/argv.json".text = builtins.toJSON {
    enable-crash-reporter = false; # keep explicit because 'vscodium' otherwise tries to modify this read-only file managed by 'home-manager' and complains that `argv.json` contains errors

    disable-hardware-acceleration = true; # https://github.com/microsoft/vscode/issues/238088
  };
}
