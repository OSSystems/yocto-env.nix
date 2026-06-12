{ flake, ... }:

{
  mkYoctoEnv =
    pkgs:

    let
      inherit (pkgs) lib;

      # Extra tools layered on top of the base host toolchain.
      extraTools = [
        flake.packages.${pkgs.stdenv.hostPlatform.system}.bitbake-setup
        pkgs.google-cloud-sdk
        pkgs.kas
        pkgs.oelint-adv
      ];

      # python3 plus the modules the Yocto build host requires
      # (system-requirements.html: python3-{git,jinja2,pexpect,pip,subunit,websockets}).
      pythonEnv = pkgs.python3.withPackages (
        ps: with ps; [
          gitpython
          jinja2
          pexpect
          pip
          subunit
          websockets

          # BitBake's `gs://` GCP fetcher (bb/fetch2/gcp.py) imports
          # `google.cloud.storage` and `google.api_core.exceptions`; the
          # google-cloud-sdk in extraTools provides gsutil/gcloud for the
          # application-default credentials it authenticates with.
          google-cloud-storage
        ]
      );

      histFile = "~/.history-yocto-env";

      ccSalt = pkgs.stdenv.cc.suffixSalt;

      # The FHS-generated `/etc/profile` sets
      # `LOCALE_ARCHIVE=/usr/lib/locale/locale-archive`; we symlink that
      # path to a full glibcLocales archive compatible with the FHS's
      # glibc. Consumers must also whitelist `LOCALE_ARCHIVE` for
      # bitbake (e.g. via `BB_ENV_PASSTHROUGH_ADDITIONS` or the BSP's
      # variable whitelist) or bitbake will strip it from `os.environ`
      # before forking subprocesses.
      localeArchive = "${pkgs.glibcLocales}/lib/locale/locale-archive";

      # OE-core's base-passwd ships these standard accounts/groups. On NixOS,
      # the FHS bubblewrap exposes host `/etc/{passwd,group,shadow}` as
      # symlinks into `/.host-etc`, so shadow's `open(O_RDWR|O_NOFOLLOW)`
      # inside `groupadd --root <sysroot>` (postinst-base-passwd, during
      # do_prepare_recipe_sysroot) fails with ELOOP. Seed a writable copy
      # with the expected accounts so groupadd succeeds and later
      # getpwnam/getgrnam lookups inside the bubblewrap resolve names like
      # `mail` or `audio` that recipes rely on.
      basePasswd = pkgs.writeText "yocto-env-passwd" ''
        root:x:0:0:root:/root:/bin/sh
        daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
        bin:x:2:2:bin:/bin:/usr/sbin/nologin
        sys:x:3:3:sys:/dev:/usr/sbin/nologin
        sync:x:4:65534:sync:/bin:/bin/sync
        games:x:5:60:games:/usr/games:/usr/sbin/nologin
        man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
        lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
        mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
        news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
        uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
        proxy:x:13:13:proxy:/bin:/usr/sbin/nologin
        www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
        backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
        list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
        irc:x:39:39:ircd:/run/ircd:/usr/sbin/nologin
        gnats:x:41:41:Gnats:/var/lib/gnats:/usr/sbin/nologin
        nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
      '';
      baseGroup = pkgs.writeText "yocto-env-group" ''
        root:x:0:
        daemon:x:1:
        bin:x:2:
        sys:x:3:
        adm:x:4:
        tty:x:5:
        disk:x:6:
        lp:x:7:
        mail:x:8:
        news:x:9:
        uucp:x:10:
        man:x:12:
        proxy:x:13:
        kmem:x:15:
        dialout:x:20:
        fax:x:21:
        voice:x:22:
        cdrom:x:24:
        floppy:x:25:
        tape:x:26:
        sudo:x:27:
        audio:x:29:
        dip:x:30:
        www-data:x:33:
        backup:x:34:
        operator:x:37:
        list:x:38:
        irc:x:39:
        src:x:40:
        gnats:x:41:
        shadow:x:42:
        utmp:x:43:
        video:x:44:
        sasl:x:45:
        plugdev:x:46:
        staff:x:50:
        games:x:60:
        users:x:100:
        nogroup:x:65534:
      '';

      etcRwFiles = {
        passwd = basePasswd;
        group = baseGroup;
        shadow = pkgs.writeText "yocto-env-shadow" "";
      };
      etcRwNames = builtins.attrNames etcRwFiles;

      zshConfig = pkgs.writeTextFile {
        name = "zshrc";
        text = ''
          export HISTFILE="$(realpath ${histFile})"
          export GRML_COMP_CACHING="0"

          # grml's chpwd hook writes the directory stack to
          # $DIRSTACKFILE, which defaults to $ZDOTDIR/.zdirs. Our ZDOTDIR
          # lives in the read-only nix store, so the default would error
          # on every `cd`. Redirect it to $HOME.
          export DIRSTACKFILE="$HOME/.yocto-env-zdirs"

          source ${pkgs.grml-zsh-config}/etc/zsh/zshrc

          # Current grml zshrc ignores `$PROMPT` assignments — use zstyle:
          # https://unix.stackexchange.com/questions/656152/why-does-setting-prompt-have-no-effect-in-grmls-zshrc

          # Disable the right-side sad-smiley for non-zero exit codes —
          # it makes copy-pasting terminal output painful.
          # https://bts.grml.org/grml/issue2267
          zstyle ':prompt:grml:right:setup' items

          # http://bewatermyfriend.org/p/2013/003/
          nix_shell_prompt() {
              REPLY=''${IN_NIX_SHELL+"(yocto-env) "}
          }
          grml_theme_add_token nix-shell-indicator -f nix_shell_prompt '%F{magenta}' '%f'

          zstyle ':prompt:grml:left:setup' items rc change-root user at host path vcs \
                                           nix-shell-indicator percent



          alias l='${pkgs.eza}/bin/eza -l'
          alias ls='${pkgs.eza}/bin/eza'

          export LESSOPEN="|${pkgs.lesspipe}/bin/lesspipe.sh %s"
          source ${pkgs.fzf}/share/fzf/completion.zsh
          source ${pkgs.fzf}/share/fzf/key-bindings.zsh
        '';
        destination = "/.zshrc";
      };

      zshBin = pkgs.writeShellApplication {
        name = "zsh";
        runtimeInputs = [ pkgs.zsh ];
        text = ''
          export SHELL_SESSIONS_DISABLE=1
          ZDOTDIR=${zshConfig} ${pkgs.zsh}/bin/zsh -o NO_GLOBAL_RCS
        '';
      };

      fhs = pkgs.buildFHSEnvBubblewrap {
        name = "yocto-env";
        targetPkgs =
          _:
          extraTools
          ++ (with pkgs; [
            acl
            attr
            bc
            binutils
            chrpath
            cpio
            diffstat
            expect
            file
            gcc
            gdb
            git
            git-lfs
            gnumake
            gnupg
            hostname
            iputils
            kconfig-frontends
            libxcrypt
            lz4
            ncurses
            netcat-gnu
            openssh
            patch
            perl
            pigz
            pythonEnv
            rpcsvc-proto
            socat
            texinfo
            unzip
            util-linux
            wget
            which
            zlib
            zstd
          ]);
        multiPkgs = null;
        extraOutputsToInstall = [ "dev" ];

        # Overlay writable copies (see `basePasswd`), then expose the host's
        # msmtp config. `git send-email` with no `sendemail.smtp*` config
        # defaults to the first `sendmail` on PATH; on NixOS that is a msmtp
        # wrapper (`/run/wrappers/bin/sendmail`), which reads `/etc/msmtprc`.
        # The FHS `/etc` shadows the host's, so without this msmtp fails with
        # "no configuration file available". `/.host-etc` is the host `/etc`
        # the FHS bubblewrap binds in; a dangling link (host without msmtp) is
        # harmless — msmtp just falls back to its other config locations.
        extraBwrapArgs =
          (lib.concatMap (name: [
            "--bind"
            "\${YOCTO_ENV_ETC_RW}/${name}"
            "/etc/${name}"
          ]) etcRwNames)
          ++ [
            "--symlink"
            "/.host-etc/msmtprc"
            "/etc/msmtprc"
          ];

        # `extraInstallCommands` only mutates the bwrap wrapper's $out,
        # which is *not* bound onto /usr inside the bubblewrap (nixpkgs'
        # bubblewrap default.nix removes the attr before calling
        # buildFHSEnv). To land files in the rootfs that actually maps
        # to /usr/* under bwrap, use `extraBuildCommands`.
        #
        # The FHS rootfs ships `/usr/lib -> /usr/lib64` as a symlink
        # (usr-merge), so `mkdir -p $out/usr/lib/locale` would try to
        # resolve through that absolute symlink and fail inside the
        # builder; write to `usr/lib64` directly instead.
        extraBuildCommands = ''
          mkdir -p $out/usr/lib64/locale
          ln -sf ${localeArchive} $out/usr/lib64/locale/locale-archive

          # Pre-kirkstone-and-friends BSP layers (meta-freescale, older
          # OE-core sanity checks) list `lz4c` in HOSTTOOLS. Debian/Ubuntu
          # ship it as a symlink to `lz4`; nixpkgs doesn't, so bitbake
          # fails its host-tool sanity check. Provide the same symlink.
          ln -s lz4 $out/usr/bin/lz4c

          # nixpkgs' gcc wrapper omits the LTO shims (gcc-ar/gcc-nm/gcc-ranlib)
          # that LTO-enabled recipes need; take them from the unwrapped gcc.
          for t in gcc-ar gcc-nm gcc-ranlib; do
            ln -s ${pkgs.stdenv.cc.cc}/bin/$t $out/usr/bin/$t
          done

          # Suppress the FHS env's `/etc/X -> /.host-etc/X` symlinks by
          # giving its rootfs an entry at /etc/X — its etc-walk then
          # --ro-binds these placeholders and skips the symlink branch.
          mkdir -p $out/etc
          ${lib.concatMapStringsSep "\n" (name: ": > $out/etc/${name}") etcRwNames}
        '';
        profile =
          let
            setVars = {
              # Suppress nixpkgs gcc-wrapper's auto-injected `-rpath
              # <nix-store glibc>`. With it, binaries that recipes link
              # against uninative's `ld-linux-x86-64.so.2` would load
              # libc from the gcc-wrapper's pinned glibc instead — ABI
              # mismatch, SIGSEGV at first jump. The wrapper's opt-out is
              # salt-suffixed; the unsalted `NIX_DONT_SET_RPATH` is
              # silently ignored.
              "NIX_DONT_SET_RPATH_${ccSalt}" = "1";
            };

            exportVars = [
              "NIX_CC_WRAPPER_TARGET_HOST_${ccSalt}"
              "NIX_CFLAGS_COMPILE"
              "NIX_CFLAGS_LINK"
              "NIX_LDFLAGS"
              "NIX_DYNAMIC_LINKER_${ccSalt}"
            ];

            # BitBake's conf parser wants whitespace on both sides of `=`,
            # otherwise it warns: "lack of whitespace around the assignment".
            exports =
              (lib.mapAttrsToList (n: v: ''export ${n} = "${v}"'') setVars)
              ++ (map (v: "export ${v}") exportVars);

            passthroughVars = (builtins.attrNames setVars) ++ exportVars;
            passthroughList = lib.concatStringsSep " " passthroughVars;

            nixconf = pkgs.writeText "nixvars.conf" ''
              ${lib.concatStringsSep "\n" exports}

              BB_BASEHASH_IGNORE_VARS += "${passthroughList}"
            '';
          in
          ''
            # Clear any inherited LD_LIBRARY_PATH so it doesn't override
            # the RPATHs of yocto-built binaries and pull in host libs at
            # runtime. The FHS bubblewrap configures ld.so.conf already.
            unset LD_LIBRARY_PATH

            # gcc-wrapper bakes its own dynamic-loader path into produced
            # binaries, bypassing the FHS ld.so.conf. Point it at the FHS
            # loader so executables built inside the shell load
            # `/lib/ld-linux-x86-64.so.2`.
            export NIX_DYNAMIC_LINKER_${ccSalt}="/lib/ld-linux-x86-64.so.2"

            export BB_ENV_PASSTHROUGH_ADDITIONS="${passthroughList}"

            # `--postread` equivalent for bitbake.
            export BBPOSTCONF="${nixconf}"
          '';
        runScript = ''
          ${zshBin}/bin/zsh
        '';
      };
    in
    fhs.env.overrideAttrs (old: {
      shellHook = ''
        YOCTO_ENV_ETC_RW="''${XDG_RUNTIME_DIR:-/tmp}/yocto-env-etc.$UID"
        install -d -m 700 "$YOCTO_ENV_ETC_RW"
        ${lib.concatMapStringsSep "\n" (
          name: ''install -m 644 ${etcRwFiles.${name}} "$YOCTO_ENV_ETC_RW/${name}"''
        ) etcRwNames}
      ''
      + old.shellHook;
    });
}
