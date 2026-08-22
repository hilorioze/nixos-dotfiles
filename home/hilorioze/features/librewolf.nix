{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: let
  librewolfProfileDir = "${config.home.homeDirectory}/${config.programs.librewolf.configPath}/${config.programs.librewolf.profiles.default.path}";
in {
  sops = {
    secrets."apps/dearrow/license-key" = {};

    templates."apps/keepassxc/storage.js" = {
      content = builtins.toJSON (lib.recursiveUpdate (builtins.fromJSON config.sops.templates."apps/keepassxc/storage-keyring.json".content) {
        settings = {
          autoFillAndSend = true;

          downloadFaviconAfterSave = true;

          passkeys = true;
        };
      });

      path = "${librewolfProfileDir}/browser-extension-data/keepassxc-browser@keepassxc.org/storage.js";
    };
  };

  stylix.targets.librewolf = {
    colorTheme.enable = true;

    profileNames = ["default"];
  };

  programs.librewolf = {
    enable = true;

    nativeMessagingHosts = with pkgs; [
      # keep-sorted start
      kdePackages.plasma-browser-integration
      keepassxc
      # keep-sorted end
    ];

    languagePacks = ["en-GB"];

    profiles.default = {
      search = let
        defaultEngine = "ddg";
      in {
        default = defaultEngine;
        privateDefault = defaultEngine;

        order = [
          defaultEngine

          "google"
        ];

        force = true;
      };

      extensions = {
        force = true; # required when using `settings`

        packages = with pkgs.firefox-addons; [
          # keep-sorted start
          clearurls
          cookie-quick-manager
          darkreader
          dearrow
          keepa
          keepassxc-browser
          plasma-integration
          re-enable-right-click
          return-youtube-dislikes
          ruffle_rs
          search-by-image # search_by_image
          sponsorblock
          steam-database
          translate-web-pages # traduzir-paginas-web
          ublock-origin
          user-agent-string-switcher
          video-downloadhelper
          violentmonkey
          web-archives # view-page-archive
          # keep-sorted end
        ];

        settings = {
          # keep-sorted start block=yes newline_separated=yes
          "amptra@keepa.com".settings.install = true;

          "uBlock0@raymondhill.net".settings = {
            # https://github.com/gorhill/uBlock/blob/d2c3d9a33edaa5897b5c4bce79c2d156e8459872/assets/assets.json
            selectedFilterLists = [
              # keep-sorted start
              "adguard-spyware-url"
              "easylist"
              "easyprivacy"
              "fanboy-cookiemonster"
              "ublock-badware"
              "ublock-cookies-easylist"
              "ublock-filters"
              "ublock-privacy"
              "ublock-quick-fixes"
              "ublock-unbreak"
              # keep-sorted end
            ];

            netWhitelist = ["duckduckgo.com"];
          };
          # keep-sorted end
        };
      };

      userChrome = ''
        /* hide all tabs button */
        #alltabs-button {
          display: none !important;
        }

        /* hide firefox view button */
        #firefox-view-button {
          display: none !important;
        }
      '';

      settings = {
        # nix manages extension versions
        "extensions.update.enabled" = false;
        "extensions.update.autoUpdateDefault" = false;

        # fixes extensions being disabled right after a fresh install
        "extensions.autoDisableScopes" = 0;

        # use native file picker instead of GTK file picker
        "widget.use-xdg-desktop-portal.file-picker" = 1;

        "toolkit.legacyUserProfileCustomizations.stylesheets" = true; # enable `userChrome.css`

        "middlemouse.paste" = false;

        "general.autoScroll" = true; # enable middle-click autoscroll

        "layout.css.always_underline_links" = true;

        # enable search suggestions
        "browser.search.suggest.enabled" = true;
        "browser.urlbar.suggest.searches" = true;

        # enable search and form history (disabled by `librewolf` by default)
        "browser.formfill.enable" = true;

        # disable fingerprinting resistance so websites can follow the system theme (enabled by default in `librewolf`)
        "privacy.resistFingerprinting" = false;

        # keep browsing data between sessions (`librewolf` clears it on shutdown by default)
        "privacy.sanitize.sanitizeOnShutdown" = false;

        "widget.gtk.overlay-scrollbars.enabled" = false; # always show scrollbars

        "browser.urlbar.suggest.quickactions" = false; # disable quick action entries shown in the urlbar suggestion dropdown

        # hide urlbar search tips by marking them as already shown
        "browser.urlbar.tipShownCount.searchTip_onboard" = 4;
        "browser.urlbar.tipShownCount.searchTip_redirect" = 4;

        "browser.download.useDownloadDir" = false; # always ask where to save files

        "browser.startup.page" = 3; # restore previous session

        "browser.sessionstore.resume_from_crash" = false;

        "browser.tabs.inTitlebar" = 0; # disable tabs in titlebar

        "browser.urlbar.trimURLs" = false;

        "browser.tabs.closeWindowWithLastTab" = false;

        "browser.newtabpage.activity-stream.feeds.topsites" = false; # hide new tab shortcuts row
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false; # hide new tab recommended stories block

        "browser.toolbars.bookmarks.visibility" = "never";

        "media.videocontrols.picture-in-picture.video-toggle.has-used" = true; # mark PiP intro popup as already shown

        "intl.locale.requested" = "en-GB"; # UI locale
        "intl.regional_prefs.use_os_locales" = true; # use OS regional formatting

        "intl.accept_languages" = "en-IE,en-GB,en-US,en,uk"; # preferred content languages/`Accept-Language`

        "findbar.highlightAll" = true;

        "permissions.default.persistent-storage" = 2; # deny persistent storage prompts

        "signon.rememberSignons" = false; # disable built-in password save prompts; use keepassxc

        "extensions.formautofill.creditCards.enabled" = false; # disable payment info save/autofill

        "privacy.globalprivacycontrol.enabled" = true;

        "network.trr.mode" = 5; # disable DoH

        # enable firefox sync (`librewolf` disables it by default)
        "identity.fxaccounts.enabled" = true;

        # disable unwanted sync categories
        "services.sync.engine.addons" = false;
        "services.sync.engine.passwords" = false;
        "services.sync.engine.prefs" = false;
        "services.sync.engine.bookmarks" = false;
      };
    };

    policies.ExtensionSettings = {
      # keep-sorted start
      "keepassxc-browser@keepassxc.org".private_browsing = true;
      "uBlock0@raymondhill.net".private_browsing = true;
      # keep-sorted end
    };
  };

  home.activation.setDeArrowLicense = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [[ -f ${librewolfProfileDir}/storage-sync-v2.sqlite ]]; then
      ${lib.getExe pkgs.sqlite} ${librewolfProfileDir}/storage-sync-v2.sqlite \
        "INSERT OR IGNORE INTO storage_sync_data (ext_id, data) VALUES ('deArrow@ajay.app', '{}');" \
        "UPDATE storage_sync_data SET data = json_set(data, '$.licenseKey', '$(<${config.sops.secrets."apps/dearrow/license-key".path})', '$.activated', json('true'), '$.alreadyActivated', json('true')) WHERE ext_id = 'deArrow@ajay.app';"
    fi
  '';

  xdg.mimeApps.defaultApplications = {
    # keep-sorted start
    "application/x-extension-htm" = "librewolf.desktop";
    "application/x-extension-html" = "librewolf.desktop";
    "application/x-extension-shtml" = "librewolf.desktop";
    "application/x-extension-xht" = "librewolf.desktop";
    "application/x-extension-xhtml" = "librewolf.desktop";
    "application/xhtml+xml" = "librewolf.desktop";
    "text/html" = "librewolf.desktop";
    "text/xml" = "librewolf.desktop";
    "x-scheme-handler/about" = "librewolf.desktop";
    "x-scheme-handler/chrome" = "librewolf.desktop";
    "x-scheme-handler/ftp" = "librewolf.desktop";
    "x-scheme-handler/http" = "librewolf.desktop";
    "x-scheme-handler/https" = "librewolf.desktop";
    "x-scheme-handler/unknown" = "librewolf.desktop";
    # keep-sorted end
  };
}
