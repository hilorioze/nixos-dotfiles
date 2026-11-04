{
  programs.looking-glass-client = {
    enable = true;

    settings = {
      win = {
        size = "2560x1440";

        dontUpscale = true;
        setGuestRes = false; # don't match guest resolution to client window size
      };

      spice = {
        clipboard = false; # lgmp clipboard only; no spice fallback

        input = false; # lgmp input only; no spice fallback
      };

      audio.micDefault = "deny"; # deny mic access by default; toggle explicitly via `ScrLk+E`
    };
  };
}
