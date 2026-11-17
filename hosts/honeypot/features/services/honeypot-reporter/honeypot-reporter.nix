{
  # keep-sorted start
  config,
  pkgs,
  # keep-sorted end
  ...
}: let
  honeypotReporter = pkgs.writers.writePython3 "honeypot-reporter" {
    doCheck = false; # treefmt lints the script with ruff
  } (builtins.readFile ./honeypot-reporter.py);
in {
  sops.secrets."services/honeypot-reporter/telegram-bot-token".restartUnits = ["honeypot-reporter.service"];

  systemd.services.honeypot-reporter = {
    description = "Honeypot Telegram reporter";

    wantedBy = ["multi-user.target"];

    environment.TELEGRAM_CHAT_ID = "-1004433146141";

    serviceConfig = {
      ExecStart = honeypotReporter;

      Restart = "on-failure"; # a failed telegram request ends the reporter
      RestartSec = 30;

      DynamicUser = true;

      LoadCredential = ["telegram-bot-token:${config.sops.secrets."services/honeypot-reporter/telegram-bot-token".path}"];
    };
  };
}
