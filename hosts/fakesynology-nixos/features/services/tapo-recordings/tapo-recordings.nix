{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: let
  surveillanceStationAddress = "192.168.1.10";

  # `surveillance-import.sh` moves the recordings from here into surveillance station
  importPath = "/mnt/surveillance-import";
in {
  sops.secrets = let
    tapoRecordingsSecret = {restartUnits = ["tapo-recordings.service"];};
  in {
    "credentials/tapo/terminal-uuid" = tapoRecordingsSecret;
    "credentials/tapo/token" = tapoRecordingsSecret;

    "credentials/tapo/push/android-id" = tapoRecordingsSecret;
    "credentials/tapo/push/security-token" = tapoRecordingsSecret;
    "credentials/tapo/push/registration-token" = tapoRecordingsSecret;

    "credentials/tapo/cloud-password".restartUnits = [
      # keep-sorted start
      "go2rtc.service"
      "tapo-recordings.service"
      # keep-sorted end
    ];
  };

  # go2rtc serves the cameras without a login; open its rtsp to surveillance station only
  networking.firewall.extraInputRules = "ip saddr ${surveillanceStationAddress} tcp dport ${lib.removePrefix ":" config.services.go2rtc.settings.rtsp.listen} accept";

  services = {
    prometheus.exporters.node.extraFlags = ["--collector.textfile.directory=/run/${config.systemd.services.tapo-recordings.serviceConfig.RuntimeDirectory}"];

    go2rtc = {
      enable = true;

      settings = {
        api.listen = "127.0.0.1:1984"; # keep the web ui with its live views off the network
        rtsp.listen = ":8554";
      };
    };
  };

  fileSystems.${importPath} = {
    device = "${surveillanceStationAddress}:/volume1/surveillance-import";

    fsType = "nfs";

    options = [
      # keep-sorted start
      "actimeo=1" # notice the live view markers within a second
      "noauto"
      "x-systemd.automount"
      # keep-sorted end
    ];
  };

  systemd = {
    tmpfiles.rules = ["e /var/lib/private/tapo-recordings/saved/* - - - 3d"]; # the script looks only at yesterday's and today's recordings

    paths.go2rtc-streams = {
      wantedBy = ["multi-user.target"];

      pathConfig.PathChanged = "/var/lib/private/${config.systemd.services.tapo-recordings.serviceConfig.StateDirectory}/cameras.json";
    };

    services = {
      # save camera recordings on their detections from the tapo pushes and the cloud history
      tapo-recordings = {
        wantedBy = ["multi-user.target"];

        after = ["network-online.target"];
        wants = ["network-online.target"];

        unitConfig.RequiresMountsFor = importPath;

        serviceConfig = {
          DynamicUser = true;
          ReadWritePaths = importPath; # `DynamicUser` mounts the rest of the system read-only

          StateDirectory = "tapo-recordings";
          RuntimeDirectory = "tapo-recordings";

          LoadCredential = [
            "terminal-uuid:${config.sops.secrets."credentials/tapo/terminal-uuid".path}"
            "token:${config.sops.secrets."credentials/tapo/token".path}"

            "android-id:${config.sops.secrets."credentials/tapo/push/android-id".path}"
            "security-token:${config.sops.secrets."credentials/tapo/push/security-token".path}"
            "registration-token:${config.sops.secrets."credentials/tapo/push/registration-token".path}"

            "cloud-password:${config.sops.secrets."credentials/tapo/cloud-password".path}"
          ];

          ExecStart = "${lib.getExe pkgs.tapo-recordings} ${importPath}";

          Restart = "on-failure"; # a failed cloud request ends the process
          RestartSec = 60;
        };
      };

      # a live view stream for surveillance station per camera tapo-recordings knows, named by its mac address
      go2rtc-streams = {
        before = ["go2rtc.service"];

        serviceConfig = {
          Type = "oneshot";

          RuntimeDirectory = "go2rtc-streams";
          RuntimeDirectoryPreserve = true; # go2rtc reads the streams after the oneshot exits

          ExecStart = let
            # print the camera's tapo url, with the cloud account's password its local admin takes
            cameraUrl = pkgs.writeShellApplication {
              name = "tapo-camera-url";

              runtimeInputs = with pkgs; [
                # keep-sorted start
                curl
                iproute2
                jq
                # keep-sorted end
              ];

              excludeShellChecks = (import ../../../../../shared.nix).ignoredShellcheckRules;

              # the router serves a self-signed certificate
              text = ''
                address=$(curl --silent --show-error --fail --insecure https://$(ip --json route show default | jq --raw-output .[0].gateway)/api/v1/hosts | jq --raw-output --arg mac $1 '.[0].hosts.list[] | select(.macaddress | gsub(":"; "") | ascii_upcase == $mac) | .ipaddress')

                echo tapo://$(jq --raw-input --raw-output @uri <$CREDENTIALS_DIRECTORY/cloud-password)@$address
              '';
            };

            # stream the camera while surveillance station shows its live view, and its last frame otherwise, so that a battery camera sleeps
            liveView = pkgs.writeShellApplication {
              name = "tapo-live-view";

              runtimeInputs = with pkgs; [
                # keep-sorted start
                coreutils
                ffmpeg-headless
                # keep-sorted end
              ];

              excludeShellChecks = (import ../../../../../shared.nix).ignoredShellcheckRules;

              text = ''
                mac=$1
                output=$2

                marker=${importPath}/.live/$mac
                frame=$STATE_DIRECTORY/$mac.jpg
                placeholder=$STATE_DIRECTORY/$mac.mkv

                # surveillance station renews the marker every 30s while it shows the live view and drops the live stream after 60s without a renewal
                watched() {
                  # stream a camera until it has a frame for the placeholder
                  if [[ ! -e $frame ]]; then
                    return 0
                  fi

                  [[ -e $marker ]] && (($(date +%s) - $(stat --format=%Y $marker) < 60))
                }

                # go2rtc stops the script with `killsignal`; take ffmpeg along
                trap 'kill $!; exit' TERM

                # go2rtc starts the script again once it exits, and keeps surveillance station's connection meanwhile
                if watched; then
                  # decode only the keyframes, for the placeholder
                  ffmpeg -loglevel error -skip_frame nokey -rtsp_transport tcp -i rtsp://127.0.0.1${config.services.go2rtc.settings.rtsp.listen}/$mac-camera -map 0 -codec copy -f rtsp $output -map 0:v -fps_mode passthrough -update 1 -atomic_writing 1 -y $frame &

                  while watched; do
                    sleep 1
                  done
                else
                  # encode the placeholder once per frame; the camera's resolution and silent audio in its codec keep surveillance station's decoders across the switch
                  if [[ $frame -nt $placeholder ]]; then
                    ffmpeg -loglevel error -loop 1 -framerate 5 -i $frame -f lavfi -i anullsrc=sample_rate=8000:channel_layout=mono -t 10 -codec:v libx264 -profile:v high -tune stillimage -pix_fmt yuv420p -g 5 -codec:a pcm_alaw -y $placeholder.tmp.mkv

                    mv $placeholder.tmp.mkv $placeholder
                  fi

                  ffmpeg -loglevel error -re -stream_loop -1 -i $placeholder -codec copy -f rtsp $output &

                  until watched; do
                    sleep 1
                  done
                fi

                kill $!
              '';
            };
          in
            lib.getExe (pkgs.writeShellApplication {
              name = "go2rtc-streams";

              runtimeInputs = with pkgs; [
                # keep-sorted start
                diffutils
                jq
                systemd
                # keep-sorted end
              ];

              excludeShellChecks = (import ../../../../../shared.nix).ignoredShellcheckRules;

              text = ''
                cameras=/var/lib/private/${config.systemd.services.tapo-recordings.serviceConfig.StateDirectory}/cameras.json

                # tapo-recordings adds a camera on its first detection
                if [[ ! -e $cameras ]]; then
                  exit
                fi

                # surveillance station takes the live view stream; `<mac>-camera` connects to the camera while the live view streams it
                jq --arg live ${lib.getExe liveView} --arg url ${lib.getExe cameraUrl} '{streams: (keys | map({(.): "exec:\($live) \(.) {output}#killsignal=15", "\(.)-camera": "echo:\($url) \(.)"}) | add)}' $cameras >$RUNTIME_DIRECTORY/streams.yaml.new

                # restart go2rtc only for a new camera: `cameras.json` changes on every detection, and a restart cuts off the live views
                if ! cmp --silent $RUNTIME_DIRECTORY/streams.yaml.new $RUNTIME_DIRECTORY/streams.yaml; then
                  mv $RUNTIME_DIRECTORY/streams.yaml.new $RUNTIME_DIRECTORY/streams.yaml

                  # go2rtc waits for this oneshot to start
                  systemctl try-restart --no-block go2rtc.service
                fi
              '';
            });
        };
      };

      go2rtc = {
        wants = ["go2rtc-streams.service"];

        unitConfig.RequiresMountsFor = importPath;

        serviceConfig = {
          LoadCredential = ["cloud-password:${config.sops.secrets."credentials/tapo/cloud-password".path}"];

          # add the camera streams to the module's config
          ExecStart = lib.mkForce "${lib.getExe config.services.go2rtc.package} -config ${(pkgs.formats.yaml {}).generate "go2rtc.yaml" config.services.go2rtc.settings} -config /run/${config.systemd.services.go2rtc-streams.serviceConfig.RuntimeDirectory}/streams.yaml";
        };
      };
    };
  };
}
