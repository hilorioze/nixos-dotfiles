{
  programs.looking-glass-client = {
    enable = true;

    settings = {
      win = {
        size = "2560x1440";

        dontUpscale = true;
      };

      spice = {
        clipboard = false; # LGMP clipboard only; no SPICE fallback

        input = false; # LGMP input only; no SPICE fallback
      };

      audio.micDefault = "deny"; # deny mic access by default; toggle explicitly via ScrLk+E
    };
  };
}
