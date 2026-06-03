{
  # keep-sorted start
  config,
  inputs,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: let
  display = ":99";

  screen = {
    width = 1920;
    height = 1080;
  };
in {
  imports = [inputs.hermes-agent.nixosModules.default];

  sops = {
    secrets = {
      # keep-sorted start
      "services/hermes-agent/api-server/auth-key" = {};
      "services/hermes-agent/instances/alex/messaging/telegram/allowed-users" = {};
      "services/hermes-agent/instances/alex/messaging/telegram/bot-token" = {};
      "services/hermes-agent/instances/hilorioze/messaging/telegram/bot-token" = {};
      "services/hermes-agent/instances/shared/messaging/telegram/bot-token" = {};
      "services/hermes-agent/providers/firecrawl/api-key" = {};
      "services/hermes-agent/providers/groq/api-key" = {};
      "services/hermes-agent/providers/kilocode/api-key" = {};
      "services/hermes-agent/providers/openrouter/api-key" = {};
      # keep-sorted end
    };

    templates = {
      # keep-sorted start block=yes newline_separated=yes
      "config/hermes-agent/instances/alex.env" = {
        content = ''
          TELEGRAM_BOT_TOKEN=${config.sops.placeholder."services/hermes-agent/instances/alex/messaging/telegram/bot-token"}
          TELEGRAM_HOME_CHANNEL=${config.sops.placeholder."services/hermes-agent/instances/alex/messaging/telegram/allowed-users"}
          TELEGRAM_ALLOWED_USERS=${config.sops.placeholder."services/hermes-agent/instances/alex/messaging/telegram/allowed-users"}

          # keep-sorted start
          FIRECRAWL_API_KEY=${config.sops.placeholder."services/hermes-agent/providers/firecrawl/api-key"}
          GROQ_API_KEY=${config.sops.placeholder."services/hermes-agent/providers/groq/api-key"}
          KILOCODE_API_KEY=${config.sops.placeholder."services/hermes-agent/providers/kilocode/api-key"}
          OPENAI_API_KEY=${config.sops.placeholder."services/hermes-agent/providers/groq/api-key"} # for Groq's OpenAI-compatible vision endpoint
          # keep-sorted end

          STT_GROQ_MODEL=whisper-large-v3 # groq STT uses this env var; `stt.model` is legacy and only the CLI voice path still reads it

          API_SERVER_KEY=${config.sops.placeholder."services/hermes-agent/api-server/auth-key"} # required to enable the `api_server` platform
        '';

        # activation script already sets ownership when passed to `environmentFiles`
      };

      "config/hermes-agent/instances/hilorioze.env" = {
        content = let
          homeChatId = -1003877047703;
        in ''
          TELEGRAM_BOT_TOKEN=${config.sops.placeholder."services/hermes-agent/instances/hilorioze/messaging/telegram/bot-token"}
          TELEGRAM_HOME_CHANNEL=${toString homeChatId}
          TELEGRAM_GROUP_ALLOWED_CHATS=${toString homeChatId}

          # keep-sorted start
          FIRECRAWL_API_KEY=${config.sops.placeholder."services/hermes-agent/providers/firecrawl/api-key"}
          GROQ_API_KEY=${config.sops.placeholder."services/hermes-agent/providers/groq/api-key"}
          KILOCODE_API_KEY=${config.sops.placeholder."services/hermes-agent/providers/kilocode/api-key"}
          OPENAI_API_KEY=${config.sops.placeholder."services/hermes-agent/providers/groq/api-key"} # for Groq's OpenAI-compatible vision endpoint
          # keep-sorted end

          STT_GROQ_MODEL=whisper-large-v3 # groq STT uses this env var; `stt.model` is legacy and only the CLI voice path still reads it

          API_SERVER_KEY=${config.sops.placeholder."services/hermes-agent/api-server/auth-key"} # required to enable the `api_server` platform
        '';

        # activation script already sets ownership when passed to `environmentFiles`
      };

      "config/hermes-agent/instances/shared.env" = {
        content = let
          homeChatId = -1003983310201;
        in ''
          TELEGRAM_BOT_TOKEN=${config.sops.placeholder."services/hermes-agent/instances/shared/messaging/telegram/bot-token"}
          TELEGRAM_HOME_CHANNEL=${toString homeChatId}
          TELEGRAM_GROUP_ALLOWED_CHATS=${toString homeChatId}

          # keep-sorted start
          FIRECRAWL_API_KEY=${config.sops.placeholder."services/hermes-agent/providers/firecrawl/api-key"}
          GROQ_API_KEY=${config.sops.placeholder."services/hermes-agent/providers/groq/api-key"}
          OPENAI_API_KEY=${config.sops.placeholder."services/hermes-agent/providers/groq/api-key"} # for Groq's OpenAI-compatible vision endpoint
          OPENROUTER_API_KEY=${config.sops.placeholder."services/hermes-agent/providers/openrouter/api-key"}
          # keep-sorted end

          STT_GROQ_MODEL=whisper-large-v3 # groq STT uses this env var; `stt.model` is legacy and only the CLI voice path still reads it

          API_SERVER_KEY=${config.sops.placeholder."services/hermes-agent/api-server/auth-key"} # required to enable the `api_server` platform
        '';

        # activation script already sets ownership when passed to `environmentFiles`
      };
      # keep-sorted end
    };
  };

  services.hermes-agent = {
    addToSystemPackages = true;

    instances = {
      # keep-sorted start block=yes newline_separated=yes
      alex = {
        environmentFiles = [config.sops.templates."config/hermes-agent/instances/alex.env".path];

        settings = {
          auxiliary.vision = {
            provider = "custom";
            base_url = "https://api.groq.com/openai/v1";

            model = "meta-llama/llama-4-scout-17b-16e-instruct";
          };

          model = {
            provider = "kilocode";

            default = "poolside/laguna-m.1:free";
          };

          stt.provider = "groq";

          tts.edge.voice = "en-US-AndrewMultilingualNeural";

          streaming.enabled = true; # stream responses

          # won't start without `API_SERVER_KEY` in the environment file
          platforms.api_server.extra = {
            host = "0.0.0.0";
            port = 8643;
          };
        };
      };

      hilorioze = {
        environmentFiles = [config.sops.templates."config/hermes-agent/instances/hilorioze.env".path];

        extraPackages = with pkgs; [
          yt-dlp # required by `yt-dlp-mcp`; doesn't support anything like `YT_DLP_PATH`, it just hardcodes `yt-dlp` binary name instead, so we have to ensure it's in PATH; might be useful for direct usage by the agent
          gallery-dl # to download image posts which `yt-dlp` doesn't support
        ];

        mcpServers = let
          # keep-sorted start block=yes newline_separated=yes
          ffmpegMcpPyproject = lib.importTOML "${inputs.ffmpeg-mcp-lite}/pyproject.toml";

          ytDlpMcpPackageJson = builtins.fromJSON (
            builtins.readFile "${inputs.yt-dlp-mcp}/package.json"
          );
          # keep-sorted end
        in {
          # `newline_separated` would move the blank line inside `playwright` to its closing brace
          # keep-sorted start block=yes
          yt-dlp = {
            command = lib.getExe' pkgs.nodejs "npx";
            args = [
              "-y"
              "${ytDlpMcpPackageJson.name}@${ytDlpMcpPackageJson.version}"
            ];

            env = {
              YTDLP_DOWNLOADS_DIR = "/tmp"; # ~/Downloads dir does not exist by default, use /tmp instead

              YTDLP_COOKIES_FROM_BROWSER = "chromium:${config.services.hermes-agent.instances.hilorioze.mcpServers.playwright.env.PLAYWRIGHT_MCP_USER_DATA_DIR}";
            };
          };

          playwright = {
            command = lib.getExe pkgs.playwright-mcp;

            env = {
              DISPLAY = display;
              PLAYWRIGHT_MCP_HEADLESS = "false"; # force headed mode to render on Xvfb; `DISPLAY` auto-detection doesn't work in MCP subprocess

              PLAYWRIGHT_MCP_VIEWPORT_SIZE = "${toString screen.width}x${toString screen.height}"; # fill Xvfb display

              # keep playwright's browser profile in a writable state dir to avoid the nix store mkdir failure since https://github.com/NixOS/nixpkgs/commit/7cc8a6b08a51d3fd23b9c4fd2493e7e888e88507#diff-cbef874c9961078638cf55b7fca92790722964580fec608f68ebb93f7c458c7dL32; also persists state across sessions
              PLAYWRIGHT_MCP_USER_DATA_DIR = "${config.services.hermes-agent.instances.hilorioze.stateDir}/playwright";
            };
          };

          ffmpeg = {
            command = lib.getExe' pkgs.uv "uvx";
            args = ["ffmpeg-mcp-lite==${ffmpegMcpPyproject.project.version}"];

            env = {
              FFMPEG_PATH = lib.getExe' pkgs.ffmpeg "ffmpeg";
              FFPROBE_PATH = lib.getExe' pkgs.ffmpeg "ffprobe";
            };
          };

          nixos.command = lib.getExe pkgs.mcp-nixos;
          # keep-sorted end
        };

        settings = {
          auxiliary.vision = {
            provider = "custom";
            base_url = "https://api.groq.com/openai/v1";

            model = "meta-llama/llama-4-scout-17b-16e-instruct";
          };

          model = {
            provider = "kilocode";

            default = "poolside/laguna-m.1:free";
          };

          stt.provider = "groq";

          tts.edge.voice = "en-US-AndrewMultilingualNeural";

          display.show_reasoning = true;

          group_sessions_per_user = false; # all users in a group chat share one session

          # won't start without `API_SERVER_KEY` in the environment file
          platforms.api_server.extra = {
            host = "0.0.0.0";
            port = 8642;
          };
        };
      };

      shared = {
        environmentFiles = [config.sops.templates."config/hermes-agent/instances/shared.env".path];

        settings = {
          auxiliary.vision = {
            provider = "custom";
            base_url = "https://api.groq.com/openai/v1";

            model = "meta-llama/llama-4-scout-17b-16e-instruct";
          };

          model.default = "arcee-ai/trinity-large-thinking:free";

          stt.provider = "groq";

          tts.edge.voice = "en-US-AndrewMultilingualNeural";

          approvals.mode = "off";

          group_sessions_per_user = false; # all users in a group chat share one session

          # won't start without `API_SERVER_KEY` in the environment file
          platforms.api_server.extra = {
            host = "0.0.0.0";
            port = 8644;
          };
        };
      };
      # keep-sorted end
    };
  };

  systemd.services.xvfb = {
    wantedBy = ["multi-user.target"];
    before = ["hermes-agent-hilorioze.service"];

    serviceConfig = {
      ExecStart = "${lib.getExe' pkgs.xvfb "Xvfb"} ${display} -screen 0 ${toString screen.width}x${toString screen.height}x24";

      Restart = "on-failure";
    };
  };
}
