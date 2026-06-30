{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  imports = [../../common/features/plasma.nix];

  programs.plasma = {
    input = {
      keyboard = {
        layouts = [
          {layout = "us";}
          {layout = "ua";}
        ];

        repeatDelay = 200;
        repeatRate = 50.0;

        options = [
          # keep-sorted start
          "caps:none"
          "grp:caps_toggle"
          "grp:shift_caps_toggle"
          # keep-sorted end
        ];
      };

      mice = [
        {
          enable = true;

          name = "Wings Tech Xtrfy M4";

          vendorId = "2ea8";
          productId = "2203";

          accelerationProfile = "none";
        }
        {
          enable = true;

          name = "Xtrfy Xtrfy Wireless Mouse";

          vendorId = "25a7";
          productId = "fa92";

          accelerationProfile = "none";
        }
        {
          enable = true;

          name = "Xtrfy Xtrfy Wireless Receiver";

          vendorId = "25a7";
          productId = "fa99";

          accelerationProfile = "none";
        }
      ];
    };

    kwin = {
      nightLight = {
        enable = true;

        mode = "location";

        location = {
          latitude = "53.35";
          longitude = "-6.26";
        };
      };

      effects.wobblyWindows.enable = true;
    };

    kscreenlocker.appearance.showMediaControls = false;

    session.sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";

    panels = [
      {
        screen = 0;

        height = 40;
        floating = true;

        widgets = [
          # Thermal Monitor
          {
            name = "org.kde.olib.thermalmonitor";

            config = config.programs.thermalmonitor.settings;
          }

          # Margins Separator
          "org.kde.plasma.marginsseparator"

          # Flexible spacer
          "org.kde.plasma.panelspacer"

          # Application Menu
          {
            kicker = {
              behavior.showIconsOnRootLevel = true;

              categories.show = {
                recentApplications = false;
                recentFiles = false;
              };

              settings.General = {
                favoriteApps = []; # effective for fresh profiles only; existing profiles are managed by `startup.startupScript.clear_kicker_app_favorites`

                favoriteSystemActions = "";

                highlightNewlyInstalledApps = false;
              };
            };
          }

          # Virtual Desktop Pager
          "org.kde.plasma.pager"

          # Icons-Only Task Manager
          {
            iconTasks = {
              settings.General.interactiveMute = false;

              launchers = [
                "preferred://filemanager"
                "preferred://browser"
                "applications:com.ayugram.desktop.desktop"
                "applications:org.kde.konsole.desktop" # use an explicit launcher: plasma's `preferred://terminal` maps to `konsole`, but only `org.kde.konsole.desktop` resolves here
                "applications:codium.desktop" # use an explicit launcher: plasma rejects `preferred://text/plain` as malformed
                "preferred://mailer"
              ];

              behavior = {
                middleClickAction = "none";

                grouping.method = "none";
              };
            };
          }

          # Flexible spacer
          "org.kde.plasma.panelspacer"

          # Margins Separator
          "org.kde.plasma.marginsseparator"

          # System Tray
          "org.kde.plasma.systemtray"

          # Digital Clock
          {
            digitalClock = {
              time.showSeconds = "always";

              timeZone = {
                alwaysShow = true;

                selected = [
                  # keep-sorted start
                  "America/Vancouver"
                  "Etc/UTC"
                  "Europe/Kyiv"
                  "Europe/Rome"
                  "Local" # host's timezone; keep for compact panel clock's `lastSelectedTimezone` fallback
                  # keep-sorted end
                ];
              };
            };
          }

          # Show Desktop
          "org.kde.plasma.showdesktop"
        ];
      }
    ];

    # fresh profiles get empty kicker favorites from config; existing profiles need a one-time KAStats purge because app favorites are stored in KAStats; `kactivitymanagerd-statsrc` only stores ordering
    startup.startupScript.clear_kicker_app_favorites = {
      text = ''
        resources_dir=${config.xdg.dataHome}/kactivitymanagerd/resources
        [[ -d $resources_dir ]] || exit 0

        favorite_agent=org.kde.plasma.favorites.applications

        ${lib.getExe pkgs.sqlite} $resources_dir/database \
          "PRAGMA busy_timeout = 5000;" \
          "DELETE FROM ResourceLink WHERE initiatingAgent = '$favorite_agent';" \
          "DELETE FROM ResourceScoreCache WHERE initiatingAgent = '$favorite_agent';" 2>/dev/null
      '';

      restartServices = ["plasma-plasmashell"];
    };

    configFile = {
      plasmaparc.General = {
        VolumeStep = 2;

        RaiseMaximumVolume = true;
      };

      plasmanotifyrc.Notifications.PopupPosition = "TopCenter";

      kwinrc.Windows = {
        FocusPolicy = 1; # FocusFollowsMouse
        NextFocusPrefersMouse = true; # Mouse precedence

        CommandAll1 = "Activate, raise and move"; # KWin left-click action for titlebar/frame clicks: activates the window, raises it, and starts dragging it.
      };

      klipperrc.General.MaxClipItems = 1024;
    };
  };

  home.file.".local/share/user-places.xbel" = {
    force = true;
    text = ''
      <?xml version="1.0" encoding="UTF-8"?>

      <!DOCTYPE xbel>

      <xbel version="1.0" xmlns:bookmark="http://www.freedesktop.org/standards/desktop-bookmarks">
        <info>
          <metadata owner="http://www.kde.org">
            <kde_places_version>4</kde_places_version>

            <GroupState-RecentlySaved-IsHidden>true</GroupState-RecentlySaved-IsHidden>

            <!-- Prevents KDE from auto-adding recentlyused:/ bookmarks by pretending they already exist -->
            <withRecentlyUsed>true</withRecentlyUsed>
          </metadata>
        </info>

        <bookmark href="file://${config.home.homeDirectory}">
          <title>Home</title>

          <info>
            <metadata owner="http://freedesktop.org">
              <bookmark:icon name="user-home"/>
            </metadata>

            <metadata owner="http://www.kde.org">
              <isSystemItem>true</isSystemItem>
            </metadata>
          </info>
        </bookmark>

        <bookmark href="file://${config.xdg.userDirs.desktop}">
          <title>Desktop</title>

          <info>
            <metadata owner="http://freedesktop.org">
              <bookmark:icon name="user-desktop"/>
            </metadata>

            <metadata owner="http://www.kde.org">
              <isSystemItem>true</isSystemItem>
            </metadata>
          </info>
        </bookmark>

        <bookmark href="file://${config.xdg.userDirs.documents}">
          <title>Documents</title>

          <info>
            <metadata owner="http://freedesktop.org">
              <bookmark:icon name="folder-documents"/>
            </metadata>

            <metadata owner="http://www.kde.org">
              <isSystemItem>true</isSystemItem>
            </metadata>
          </info>
        </bookmark>

        <bookmark href="file://${config.xdg.userDirs.download}">
          <title>Downloads</title>

          <info>
            <metadata owner="http://freedesktop.org">
              <bookmark:icon name="folder-downloads"/>
            </metadata>

            <metadata owner="http://www.kde.org">
              <isSystemItem>true</isSystemItem>
            </metadata>
          </info>
        </bookmark>

        <bookmark href="file://${config.xdg.userDirs.music}">
          <title>Music</title>

          <info>
            <metadata owner="http://freedesktop.org">
              <bookmark:icon name="folder-music"/>
            </metadata>

            <metadata owner="http://www.kde.org">
              <isSystemItem>true</isSystemItem>
            </metadata>
          </info>
        </bookmark>

        <bookmark href="file://${config.xdg.userDirs.pictures}">
          <title>Pictures</title>

          <info>
            <metadata owner="http://freedesktop.org">
              <bookmark:icon name="folder-pictures"/>
            </metadata>

            <metadata owner="http://www.kde.org">
              <isSystemItem>true</isSystemItem>
            </metadata>
          </info>
        </bookmark>

        <bookmark href="file://${config.xdg.userDirs.videos}">
          <title>Videos</title>

          <info>
            <metadata owner="http://freedesktop.org">
              <bookmark:icon name="folder-videos"/>
            </metadata>

            <metadata owner="http://www.kde.org">
              <isSystemItem>true</isSystemItem>
            </metadata>
          </info>
        </bookmark>

        <bookmark href="trash:/">
          <title>Trash</title>

          <info>
            <metadata owner="http://freedesktop.org">
              <bookmark:icon name="user-trash"/>
            </metadata>

            <metadata owner="http://www.kde.org">
              <isSystemItem>true</isSystemItem>
            </metadata>
          </info>
        </bookmark>

        <bookmark href="file://${config.home.homeDirectory}/projects">
          <title>projects</title>

          <info>
            <metadata owner="http://freedesktop.org">
              <bookmark:icon name="folder"/>
            </metadata>
          </info>
        </bookmark>

        <bookmark href="file://${config.home.homeDirectory}/projects/k8s">
          <title>k8s</title>

          <info>
            <metadata owner="http://freedesktop.org">
              <bookmark:icon name="folder"/>
            </metadata>
          </info>
        </bookmark>

        <bookmark href="file://${config.home.homeDirectory}/projects/nixos-dotfiles">
          <title>nixos-dotfiles</title>

          <info>
            <metadata owner="http://freedesktop.org">
              <bookmark:icon name="folder"/>
            </metadata>
          </info>
        </bookmark>

        <bookmark href="file://${config.home.homeDirectory}/projects/hilorioze.github.io">
          <title>hilorioze.github.io</title>

          <info>
            <metadata owner="http://freedesktop.org">
              <bookmark:icon name="folder"/>
            </metadata>
          </info>
        </bookmark>

        <bookmark href="file://${config.home.homeDirectory}/projects/rayttage-infra">
          <title>rayttage-infra</title>

          <info>
            <metadata owner="http://freedesktop.org">
              <bookmark:icon name="folder"/>
            </metadata>
          </info>
        </bookmark>

        <bookmark href="remote:/">
          <title>Network</title>

          <info>
            <metadata owner="http://freedesktop.org">
              <bookmark:icon name="folder-network"/>
            </metadata>

            <metadata owner="http://www.kde.org">
              <isSystemItem>true</isSystemItem>
            </metadata>
          </info>
        </bookmark>
      </xbel>
    '';
  };
}
