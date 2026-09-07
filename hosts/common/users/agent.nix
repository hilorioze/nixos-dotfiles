{
  users.users.agent = {
    isNormalUser = true;

    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBoZ1gmNz36Q9r6L6kYlBeW20C/3RlFECa6zZv7bORr/"];
  };

  security.sudo.extraRules = [
    {
      users = ["agent"];

      commands = [
        {
          command = "ALL";

          options = ["NOPASSWD"];
        }
      ];
    }
  ];
}
