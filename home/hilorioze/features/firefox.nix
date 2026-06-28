{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: let
  firefoxProfileDir = "${config.home.homeDirectory}/${config.programs.firefox.configPath}/${config.programs.firefox.profiles.default.path}";
in {
  imports = [../../common/features/firefox.nix];

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

      path = "${firefoxProfileDir}/browser-extension-data/keepassxc-browser@keepassxc.org/storage.js";
    };
  };

  stylix.targets.firefox = {
    colorTheme.enable = true;

    profileNames = ["default"];
  };

  programs.firefox = {
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
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true; # enable `userChrome.css`

        "middlemouse.paste" = false;

        "general.autoScroll" = true; # enable middle-click autoscroll

        "layout.css.always_underline_links" = true;

        "widget.gtk.overlay-scrollbars.enabled" = false; # always show scrollbars

        "browser.urlbar.suggest.quickactions" = false; # disable quick action entries shown in the urlbar suggestion dropdown

        # hide urlbar search tips by marking them as already shown
        "browser.urlbar.tipShownCount.searchTip_onboard" = 4;
        "browser.urlbar.tipShownCount.searchTip_redirect" = 4;

        "browser.download.useDownloadDir" = false; # always ask where to save files

        "browser.startup.page" = 3; # restore previous session

        "browser.tabs.inTitlebar" = 0; # disable tabs in titlebar

        "browser.urlbar.trimURLs" = false;

        "browser.tabs.closeWindowWithLastTab" = false;

        "browser.newtabpage.activity-stream.feeds.topsites" = false; # hide new tab shortcuts row
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false; # hide new tab recommended stories block

        "browser.newtabpage.activity-stream.widgets.weather.enabled" = false;

        "browser.toolbars.bookmarks.visibility" = "never";

        # disable AI chatbot
        "browser.ml.chat.enabled" = false;
        "browser.ml.chat.menu" = false;

        "browser.aboutConfig.showWarning" = false;

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

        # disable syncing unwanted firefox sync categories
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
    if [[ -f "${firefoxProfileDir}/storage-sync-v2.sqlite" ]]; then
      ${lib.getExe pkgs.sqlite} "${firefoxProfileDir}/storage-sync-v2.sqlite" \
        "INSERT OR IGNORE INTO storage_sync_data (ext_id, data) VALUES ('deArrow@ajay.app', '{}');" \
        "UPDATE storage_sync_data SET data = json_set(data, '$.licenseKey', '$(${lib.getExe' pkgs.coreutils "cat"} ${config.sops.secrets."apps/dearrow/license-key".path})', '$.activated', json('true'), '$.alreadyActivated', json('true')) WHERE ext_id = 'deArrow@ajay.app';"
    fi
  '';

  xdg.mimeApps.defaultApplications = {
    # keep-sorted start
    "application/x-extension-htm" = "firefox.desktop";
    "application/x-extension-html" = "firefox.desktop";
    "application/x-extension-shtml" = "firefox.desktop";
    "application/x-extension-xht" = "firefox.desktop";
    "application/x-extension-xhtml" = "firefox.desktop";
    "application/xhtml+xml" = "firefox.desktop";
    "text/html" = "firefox.desktop";
    "text/xml" = "firefox.desktop";
    "x-scheme-handler/about" = "firefox.desktop";
    "x-scheme-handler/chrome" = "firefox.desktop";
    "x-scheme-handler/ftp" = "firefox.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
    "x-scheme-handler/unknown" = "firefox.desktop";
    # keep-sorted end
  };
}
