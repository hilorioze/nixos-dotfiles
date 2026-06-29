{pkgs, ...}: {
  services.factorio = {
    enable = true;

    package = let
      version = "2.0.73";
    in
      pkgs.factorio-headless.overrideAttrs {
        inherit version;

        src = pkgs.fetchurl {
          url = "https://factorio.com/get-download/${version}/headless/linux64";
          name = "factorio_headless_x64-${version}.tar.xz";

          hash = "sha256-dSAl+BtewSKZGe3IafnIdz20u1SKkNNw+Fk4I2yFfZo=";
        };
      };

    openFirewall = true;

    loadLatestSave = true;

    requireUserVerification = false;

    admins = [
      # keep-sorted start
      "Danil"
      "hilorioze"
      # keep-sorted end
    ];

    mods = let
      mkMod = {
        # keep-sorted start
        deps ? [],
        hash,
        pname,
        version,
        # keep-sorted end
      }:
        pkgs.factorio-utils.modDrv {
          allOptionalMods = false;
          allRecommendedMods = false;
        } {
          name = pname;

          src = pkgs.fetchurl {
            url = "https://mods-storage.re146.dev/${pname}/${version}.zip";
            name = "${pname}_${version}.zip";

            inherit hash;
          };

          inherit deps;
        };

      flib = mkMod {
        pname = "flib";
        version = "0.16.5";

        hash = "sha256-j8UHPTdKFJYgMzd32VnSwgSrCvDFlmm+lMXKt96Xhic=";
      };
    in [
      # keep-sorted start block=yes newline_separated=yes
      (mkMod {
        pname = "AutoDeconstruct";
        version = "1.0.12";

        hash = "sha256-QLIOqes24CP3WSVYqPYsbNAn0B2o1zVqkQCw6Tf5Fow=";
      })

      (mkMod {
        pname = "BottleneckLite";
        version = "1.3.4";

        hash = "sha256-I3ha5WyCDhdGQd3BvDgxjCQThB5KTRd51cPWGZvmN0s=";

        deps = [flib];
      })

      (mkMod {
        pname = "DiscoScience";
        version = "2.0.1";

        hash = "sha256-hiPU+340XnpVMP9PxR2hREG/ZUKHXAODGP0mJYKKAZc=";
      })

      (mkMod {
        pname = "Milestones";
        version = "1.4.7";

        hash = "sha256-gRbu1XsMmLEvSwRrmQbHEiEPodj+2YCKuh+BnlEmImE=";

        deps = [flib];
      })

      (mkMod {
        pname = "ModuleInserterEx";
        version = "7.4.1";

        hash = "sha256-HqQogBLtuZW7CQXBUehsjA1pD4GZMc3ObWjnbJ8TfmA=";

        deps = [flib];
      })

      (mkMod {
        pname = "OilOutpostPlanner";
        version = "1.6.7";

        hash = "sha256-4TSAiElHgqRTWUcgZsmqrykB9/Mbfq0sZJ/QemPEfJI=";
      })

      (mkMod {
        pname = "RateCalculator";
        version = "3.3.8";

        hash = "sha256-/md22AnnDxttl50et+R7EcrOCuvBW7ZiVjE2bN2FdjU=";

        deps = [flib];
      })

      (mkMod {
        pname = "belt-visualizer";
        version = "2.0.2";

        hash = "sha256-ljd/puNB4MlTSXTNba+wtq+6ALAVso5ctYZ/1d44n3Q=";
      })

      (mkMod {
        pname = "blueprint-sandboxes";
        version = "3.2.2";

        hash = "sha256-c74FMACWCZxS3PQvJQnBvxpv8SQDOpGVa+bHIqWYY60=";
      })

      (mkMod {
        pname = "bullet-trails";
        version = "0.7.1";

        hash = "sha256-ikd2JCLdLG6xg9ZaI7yC5Py4WuPKba52IR9Qlg9eLAI=";
      })

      (mkMod {
        pname = "even-distribution";
        version = "2.0.2";

        hash = "sha256-Q0OgHb7Mr7H4echmWRil3iRVPk904TNxrhfhmTDFBks=";
      })

      (mkMod {
        pname = "helmod";
        version = "2.2.12";

        hash = "sha256-oCLLYlSsF4Gfgae9BZw59ns1I2F7JM2BEFNLRJYpx1Y=";
      })

      (mkMod {
        pname = "lightorio";
        version = "2.0.1";

        hash = "sha256-kw5DatNf7Tz6XCmfJHNwY0Tw8PXEBcOlHRp0Bvu9b3U=";
      })

      (mkMod {
        pname = "mining-patch-planner";
        version = "1.7.16";

        hash = "sha256-OyPljEy2QDhpCv1cwuj3/k3eQK6QLoSyTlF0HEavhjo=";
      })

      (mkMod {
        pname = "squeak-through-2";
        version = "0.1.4";

        hash = "sha256-E6Q7Lsgg7BEOzx7rAvqPYTAGQm+g+nGFrrtvLzGOlZs=";
      })

      (mkMod {
        pname = "tile-upgrade-planner";
        version = "20.0.1";

        hash = "sha256-H5aRu+6IP0Qvtl1I4Jl3rNui27tCyRDnoBO0tlrIHGo=";
      })
      # keep-sorted end
    ];
  };
}
