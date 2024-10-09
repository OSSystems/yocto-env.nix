{ pkgsForInteractiveShell
, pkgsForYocto
, withPython2
, usesInclusiveLanguage
}:

let
  inherit (pkgsForInteractiveShell) lib;

  histFile = "~/.history-yocto-env";

  zshConfig = pkgsForInteractiveShell.writeTextFile {
    name = "zshrc";
    text = ''
      export HISTFILE="$(realpath ${histFile})"
      export GRML_COMP_CACHING="0"

      source ${pkgsForInteractiveShell.grml-zsh-config}/etc/zsh/zshrc

      # Prompt modifications.
      #
      # In current grml zshrc, changing `$PROMPT` no longer works,
      # and `zstyle` is used instead, see:
      # https://unix.stackexchange.com/questions/656152/why-does-setting-prompt-have-no-effect-in-grmls-zshrc

      # Disable the grml `sad-smiley` on the right for exit codes != 0;
      # it makes copy-pasting out terminal output difficult.
      # Done by setting the `items` of the right-side setup to the empty list
      # (as of writing, the default is `items sad-smiley`).
      # See: https://bts.grml.org/grml/issue2267
      zstyle ':prompt:grml:right:setup' items

      # Add nix-shell indicator that makes clear when we're in nix-shell.
      # Described in: http://bewatermyfriend.org/p/2013/003/
      nix_shell_prompt() {
          REPLY=''${IN_NIX_SHELL+"(yocto-env) "}
      }
      grml_theme_add_token nix-shell-indicator -f nix_shell_prompt '%F{magenta}' '%f'

      zstyle ':prompt:grml:left:setup' items rc change-root user at host path vcs \
                                       nix-shell-indicator percent



      alias l='${pkgsForInteractiveShell.eza}/bin/eza -l'
      alias ls='${pkgsForInteractiveShell.eza}/bin/eza'

      export LESSOPEN="|${pkgsForInteractiveShell.lesspipe}/bin/lesspipe.sh %s"
      source ${pkgsForInteractiveShell.fzf}/share/fzf/completion.zsh
      source ${pkgsForInteractiveShell.fzf}/share/fzf/key-bindings.zsh
    '';
    destination = "/.zshrc";
  };

  zshBin = pkgsForInteractiveShell.writeShellApplication {
    name = "zsh";
    runtimeInputs = [ pkgsForInteractiveShell.zsh ];
    text = ''
      export SHELL_SESSIONS_DISABLE=1
      ZDOTDIR=${zshConfig} ${pkgsForInteractiveShell.zsh}/bin/zsh -o NO_GLOBAL_RCS
    '';
  };

  fhs = pkgsForInteractiveShell.buildFHSUserEnvBubblewrap {
    name = "yocto-env";
    targetPkgs = pkgs: (with pkgsForYocto; let
      libxcrypt = pkgsForYocto.libxcrypt or null; # Nixpkgs 20.03
      rpcsvc-proto = pkgsForYocto.rpcsvc-proto or null; # Nixpkgs 20.03
      util-linux = pkgsForYocto.util-linux or pkgsForYocto.utillinux; # Nixpkgs 20.09
    in
    [
      attr
      bc
      binutils
      bzip2
      chrpath
      cpio
      diffstat
      expect
      file
      gcc
      gdb
      git
      gnumake
      hostname
      kconfig-frontends
      libxcrypt
      lz4
      ncurses
      patch
      perl
      python3
      rpcsvc-proto
      unzip
      util-linux
      wget
      which
      xz
      zlib
      zstd
    ] ++ lib.lists.optionals withPython2 [ python2 ]);
    multiPkgs = null;
    extraOutputsToInstall = [ "dev" ];
    profile =
      let
        setVars = {
          "NIX_DONT_SET_RPATH" = "1";
        };

        exportVars = [
          "LOCALE_ARCHIVE"
          "NIX_CC_WRAPPER_TARGET_HOST_${pkgsForInteractiveShell.stdenv.cc.suffixSalt}"
          "NIX_CFLAGS_COMPILE"
          "NIX_CFLAGS_LINK"
          "NIX_LDFLAGS"
          "NIX_DYNAMIC_LINKER_${pkgsForInteractiveShell.stdenv.cc.suffixSalt}"
        ];

        exports =
          (builtins.attrValues (builtins.mapAttrs (n: v: "export ${n}= \"${v}\"") setVars)) ++
          (builtins.map (v: "export ${v}") exportVars);

        passthroughVars = (builtins.attrNames setVars) ++ exportVars;

        # TODO limit export to native pkgs?
        nixconf = pkgsForInteractiveShell.writeText "nixvars.conf" ''
          # This exports the variables to actual build environments
          # From BB_ENV_PASSTHROUGH_ADDITIONS
          ${lib.strings.concatStringsSep "\n" exports}

          # Exclude these when hashing
          # the packages in yocto
          BB_BASEHASH_IGNORE_VARS += "${lib.strings.concatStringsSep " " passthroughVars}"
        '';
      in
      ''
        # buildFHSUserEnvBubblewrap configures ld.so.conf while buildFHSUserEnv additionally sets the LD_LIBRARY_PATH.
        # This is redundant, and incorrectly overrides the RPATH of yocto-built binaries causing the dynamic loader
        # to load libraries from the host system that they were not built against, instead of those from yocto.
        unset LD_LIBRARY_PATH

        # By default gcc-wrapper will compile executables that specify a dynamic loader that will ignore the FHS
        # ld-config causing unexpected libraries to be loaded when when the executable is run.
        export NIX_DYNAMIC_LINKER_${pkgsForInteractiveShell.stdenv.cc.suffixSalt}="/lib/ld-linux-x86-64.so.2"

        # These are set by buildFHSUserEnvBubblewrap
        export BB_ENV_PASSTHROUGH_ADDITIONS="${lib.strings.concatStringsSep " " passthroughVars}"

        # source the config for bibake equal to --postread
        export BBPOSTCONF="${nixconf}"
      '' + lib.strings.optionalString (! usesInclusiveLanguage) ''
        # keep compatibility with version earlier to kirkstone
        export BB_ENV_EXTRAWHITE="$BB_ENV_PASSTHROUGH_ADDITIONS"
      '';
    runScript = ''
      ${zshBin}/bin/zsh
    '';
  };
in
fhs.env
