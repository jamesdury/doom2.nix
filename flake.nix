{
  description = "gzdoom 4.11.3";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import <nixpkgs> {};
        
        wrapperScript = pkgs.writeScriptBin "gzdoom-wrapper" ''
          #!${pkgs.bash}/bin/bash
          
          export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [
            pkgs.alsa-lib
            pkgs.libpulseaudio
            pkgs.pipewire
            pkgs.wireplumber
            pkgs.SDL2
            pkgs.fluidsynth
            pkgs.openal
          ]}:$LD_LIBRARY_PATH
          
          export XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
          export PIPEWIRE_RUNTIME_DIR=''${XDG_RUNTIME_DIR}/pipewire
          
          if [ -S "$XDG_RUNTIME_DIR/pipewire-0" ]; then
            export PIPEWIRE_REMOTE=pipewire-0
          fi
          
          export OPENAL_DRIVER=pipewire
          
          echo "Using PipeWire at: $PIPEWIRE_RUNTIME_DIR"
          ls -la $XDG_RUNTIME_DIR/pipewire* 2>/dev/null || echo "No PipeWire sockets found"
          
          exec ${gzdoom-4-11-3}/bin/gzdoom -file ./brutal-doom.zip ./project-brutality.zip -iwad ./doom2.wad -snd_midiprecache -snd_driver openal "$@"
        '';
        
        gzdoom-4-11-3 = pkgs.gzdoom.overrideAttrs (oldAttrs: {
          version = "4.11.3";
          src = pkgs.fetchFromGitHub {
            owner = "coelckers";
            repo = "gzdoom";
            rev = "g4.11.3";
            sha256 = "sha256-pY+5R3W/9pJGiBoDFkxxpuP0I2ZLb+Q/s5UYU20G748=";
          };
          patches = builtins.filter 
            (patch: !(pkgs.lib.hasSuffix "string_format.patch" (toString patch))) 
            oldAttrs.patches;
        });
        
        customGzdoom = pkgs.symlinkJoin {
          name = "gzdoom-custom";
          paths = [ 
            gzdoom-4-11-3 
            wrapperScript 
            pkgs.alsa-lib 
            pkgs.libpulseaudio 
            pkgs.pipewire
            pkgs.wireplumber
            pkgs.SDL2 
            pkgs.fluidsynth
            pkgs.openal
            pkgs.alsa-plugins
          ];
        };
      in
      {
        packages = {
          gzdoom-4-11-3 = gzdoom-4-11-3;
          customGzdoom = customGzdoom;
          default = customGzdoom;
        };
        apps = {
          gzdoom = {
            type = "app";
            program = "${wrapperScript}/bin/gzdoom-wrapper";
          };
          default = self.apps.${system}.gzdoom;
        };
      }
    );
}
