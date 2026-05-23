{
  services.syncthing = {
    enable = true;

    settings.options = {
      urAccepted = -1; # disable usage reporting

      crashReportingEnabled = false;
    };
  };
}
