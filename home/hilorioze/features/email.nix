{
  accounts.email.accounts = {
    "hilorioze@hilorioze.com" = rec {
      primary = true;

      address = "hilorioze@hilorioze.com"; # email address used in `From:` header (`mail.identity.id_*.useremail`)
      realName = "hilorioze"; # display name shown alongside `address` in `From:` header

      imap = {
        host = "imap.hilorioze.com";
        port = 993; # `imaps`; required: `home-manager` default is `143` (`imap`)

        authentication = "xoauth2";
      };

      smtp = {
        host = "smtp.hilorioze.com";
        port = 465; # `smtps`; required: `home-manager` default is `587` (`smtp`)

        authentication = "xoauth2";
      };

      gpg = {
        key = "96715EFAA4FB67F96D3B335258DA93FDD2D02B8D";

        signByDefault = true;
      };

      userName = address; # login credential passed to `imap`/`smtp` servers (`mail.server.server_*.userName`); distinct from `address`
      # `passwordCommand` is useless here because `thunderbird` uses its own internal password store

      thunderbird.enable = true;
    };

    "hilorioze@gmail.com" = {
      address = "hilorioze@gmail.com"; # email address used in `From:` header (`mail.identity.id_*.useremail`)
      realName = "hilorioze"; # display name shown alongside `address` in `From:` header

      flavor = "gmail.com";

      thunderbird.enable = true;
    };
  };
}
