# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

{
  imports = [
    ../modules/btops.nix
    ../modules/hidpi.nix
    ../modules/lightlocker.nix
  ];

  fileSystems = let
    # Mount options for Btrfs on SSD
    commonMountOptions = [
      "commit=60"
      "compress=lzo"
      "defaults"
      "noatime"
    ];
  in {
    "/".options = commonMountOptions;
    "/nix".options = commonMountOptions;
    "/var".options = commonMountOptions;
    "/home".options = commonMountOptions;
  };

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    kernelPackages = pkgs.linuxPackages_latest;

    kernelParams = [
      "nmi_watchdog=0"
    ];

    tmpOnTmpfs = true;
  };

  hardware = {
    # cpu.intel.updateMicrocode = true;

    bluetooth.enable = true;

    pulseaudio.enable = true;
    pulseaudio.package = pkgs.pulseaudioFull;
  };

  sound = {
    # ALSA problem: Failed to find module 'snd_pcm_oss'
    enableOSSEmulation = false;
  };

  networking = {
    networkmanager.enable = true;
  };

  time.timeZone = "Asia/Tokyo";

  i18n = {
    # consoleColors = [
    #   # Srcery: https://github.com/srcery-colors/srcery-vim
    #   "1C1B19" "EF2F27" "519F50" "FBB829" "2C78BF" "E02C6D" "0AAEB3" "918175"
    #   "2D2C29" "F75341" "98BC37" "FED06E" "68A8E4" "FF5C8F" "53FDE9" "FCE8C3"
    # ];

    consoleKeyMap = "us";  # conflicts with consoleUseXkbConfig
    # consoleUseXkbConfig = true;

    defaultLocale = "ja_JP.UTF-8";

    inputMethod = {
      enabled = "fcitx";
      fcitx.engines = with pkgs.fcitx-engines; [ mozc ];
    };
  };

  fonts = {
    fonts = with pkgs; [
      source-serif-pro
      source-sans-pro
      source-code-pro
      source-han-serif-japanese
      source-han-sans-japanese
      noto-fonts-emoji
      font-awesome-ttf
      fira-code
    ];

    fontconfig.defaultFonts = {
      serif = [
        "Source Serif Pro"
        "Source Han Serif JP"
      ];
      sansSerif = [
        "Source Sans Pro"
        "Source Han Sans JP"
      ];
      monospace = [
        "Source Code Pro"
      ];
    };
  };

  nix = {
    trustedUsers = [ "@wheel" ];

    nixPath = [
      "nixpkgs=/var/repos/nixpkgs"
      "nixos-config=/etc/nixos/${config.networking.hostName}.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      pulseaudio = true;
    };

    overlays = [ (self: super: {
      fehWrapper = with super; buildEnv {
        name = "${feh.name}-wrapper";
        paths = [ feh.man ];
        buildInputs = [ makeWrapper ];
        postBuild = ''
          mkdir $out/bin
          makeWrapper ${feh.out}/bin/feh $out/bin/feh \
            --add-flags "-B \"#1c1b19\""  # Srcery black
        '';
      };

      rofiWrapper = with super; let
        cfg = config.environment.hidpi;
        configFile = substituteAll {
          src = ../data/config/rofi.conf;
          dpi = toString (96 * (if cfg.enable then cfg.scale else 1));
        };
      in buildEnv {
        name = "${rofi.name}-wrapper";
        paths = [ rofi ];
        pathsToLink = [ "/share" ];
        buildInputs = [ makeWrapper ];
        postBuild = ''
          mkdir $out/bin
          makeWrapper ${rofi}/bin/rofi $out/bin/rofi \
            --add-flags "-config ${configFile}"
          for path in ${rofi}/bin/*; do
            name="$(basename "$path")"
            [ "$name" != rofi ] && ln -s "$path" "$out/bin/$name"
          done
        '';
      };

      zathuraWrapper = with super; let
        cfg = config.environment.hidpi;
        configFile = substituteAll {
          src = ../data/config/zathurarc;
          page_padding = toString (if cfg.enable then cfg.scale else 1);
        };
        configDir = runCommand "zathura-config-dir" {} ''
          install -D -m 444 "${configFile}" "$out/zathurarc"
        '';
      in buildEnv {
        name = "${zathura.name}-wrapper";
        paths = [ zathura ];
        pathsToLink = [ "/share" ];
        buildInputs = [ makeWrapper ];
        postBuild = ''
          mkdir $out/bin
          makeWrapper ${zathura}/bin/zathura $out/bin/zathura \
            --add-flags "--config-dir ${configDir}"
        '';
      };

    gtk3Config = with super; let
      cfg = config.environment.hidpi;
      scale = if cfg.enable then cfg.scale else 1;
      gtkCss = writeText "gtk.css" ''
        VteTerminal, vte-terminal {
            padding-left: ${toString (2 * scale)}px;
        }
      '';
      settingsIni = writeText "settings.ini" ''
        [Settings]
        gtk-font-name = Source Han Sans JP 11
        gtk-theme-name = Arc
        gtk-icon-theme-name = Papirus
        gtk-key-theme-name = Emacs
      '';
    in runCommand "gtk-3.0" {} ''
      confd="$out/etc/xdg/gtk-3.0"
      install -D -m 444 "${gtkCss}" "$confd/gtk.css"
      install -D -m 444 "${settingsIni}" "$confd/settings.ini"
    '';
  }) ];
  };

  environment = {
    systemPackages = with pkgs; let
      desktopPkgs = [
        dunst
        fehWrapper
        rofiWrapper
        termite
        yabar-unstable
        pavucontrol
        zathuraWrapper
      ] ++ gtkPkgs;
      gtkPkgs = [
        gtk3 # Required to use Emacs key bindings in GTK apps
        arc-theme
        papirus-icon-theme
        numix-cursor-theme
        gtk3Config
      ];
      miscPkgs = [
        scrot
      ];
    in desktopPkgs ++ miscPkgs;

    profileRelativeEnvVars = {
      MANPATH = [ "/man" "/share/man" ];
    };

    variables = {
      # Apps launched in ~/.xprofile need it if they use SVG icons.
      GDK_PIXBUF_MODULE_FILE = "${pkgs.librsvg.out}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache";
    };

    shellAliases = {
      ls = "ls -Fh --color --time-style=long-iso";
      cp = "cp -i";
      mv = "mv -i";
      diff = "diff --color";
    };
  };

  programs = { # Shells
    bash.shellAliases = {
      la = "ls -a";
      ll = "ls -l";
      lla = "ls -la";
    };

    fish.enable = true;
    fish.shellInit = ''
      umask 077
    '';
    fish.interactiveShellInit = ''
      abbr --add la 'ls -a'
      abbr --add ll 'ls -l'
      abbr --add lla 'ls -la'
      abbr --add h history
      abbr --add d  dirh
      abbr --add nd nextd
      abbr --add pd prevd
    '';
  } // { # Others
    lightlocker.enable = true;
    lightlocker.lockAfterScreensaver = 10;

    vim.defaultEditor = true;
  };

  services = {
    chrony.enable = true;

    fstrim.enable = true;

    autofs.enable = true;
    autofs.autoMaster = let
      mapConf = pkgs.writeText "auto" ''
        usbdisk -fstype=noauto,async,group,gid=100,fmask=117,dmask=007 :/dev/sda1
      '';
    in ''
      /media file:${mapConf} --timeout=10
    '';

    printing.enable = true;
    printing.drivers = [ pkgs.gutenprint ];
    colord.enable = true;  # required by CUPS
  };

  services.xserver = {
    enable = true;

    layout = "us";

    # Enable bspwm environment.
    desktopManager.default = "none";
    windowManager.default = "bspwm";
    windowManager.bspwm.enable = true;
    windowManager.bspwm.configFile = let
      cfg = config.environment.hidpi;
      scale = if cfg.enable then cfg.scale else 1;
    in pkgs.substituteAll {
      src = ../data/config/bspwmrc;
      postInstall = "chmod +x $out";
      window_gap = toString (60 * scale);
    };
    windowManager.bspwm.sxhkd.configFile = pkgs.runCommand "sxhkdrc" {} ''
      cp ${../data/config/sxhkdrc} $out
    '';
    windowManager.bspwm.btops.enable = true;
    windowManager.bspwm.btops.configFile = pkgs.writeText "config.toml" ''
      watch-config = false
      min = 4
    '';
  };

  services.xserver.displayManager.lightdm = {
    enable = true;

    background = let
      backgroundImage = pkgs.runCommand "login-background" {} ''
        cp ${../data/pixmaps/login_background.jpg} $out
      '';
    in "${backgroundImage}";

    greeters.mini.enable = true;
    greeters.mini.user = "mnacamura";
    greeters.mini.extraConfig = ''
      [greeter-theme]
      font = Source Code Pro Medium
      font-size = 13pt
      text-color = "#fce8c3"
      error-color = "#f75341"
      window-color = "#d75f00"
      border-width = 0
      layout-space = 40
      password-color = "#fce8c3"
      password-background-color = "#1c1b19"
    '';
  };

  services.xserver.displayManager.sessionCommands = let
    xresources = pkgs.writeText "Xresources" ''
        Xcursor.theme: Numix
    '';
    backgroundImage = pkgs.runCommand "desktop-background" {} ''
      cp ${../data/pixmaps/desktop_background.jpg} $out
    '';
  in ''
    ${pkgs.xorg.xrdb}/bin/xrdb -merge ${xresources}
    # xsetroot has to be after setting icon theme
    ${pkgs.xorg.xsetroot}/bin/xsetroot -cursor_name left_ptr
    ${pkgs.feh}/bin/feh --no-fehbg --bg-scale ${backgroundImage}
  '';

  services.compton = let
    cfg = config.environment.hidpi;
    scale = if cfg.enable then cfg.scale else 1;
    hasAmdgpu = lib.any (d: d == "amdgpu") config.services.xserver.videoDrivers;
  in {
    enable = true;

    fade = true;
    fadeDelta = 5;
    fadeSteps = [ "0.03" "0.03" ];

    shadow = true;
    shadowOpacity = "0.46";
    shadowOffsets = [ (-12 * scale) (-15 * scale) ];

    # glx with amdgpu does not work for now
    # https://github.com/chjj/compton/issues/477
    backend = if hasAmdgpu then "xrender" else "glx";
    vSync = if hasAmdgpu then "none" else "opengl-swc";

    extraOptions = ''
      mark-wmwin-focused = true;
      mark-ovredir-focused = true;
      paint-on-overlay = true;
      use-ewmh-active-win = true;
      sw-opti = true;
      unredir-if-possible = true;
      detect-transient = true;
      detect-client-leader = true;
      blur-kern = "3x3gaussian";
      glx-no-stencil = true;
      glx-copy-from-front = false;
      glx-use-copysubbuffermesa = true;
      glx-no-rebind-pixmap = true;
      glx-swap-method = "buffer-age";
      shadow-radius = ${toString (22 * scale)};
      shadow-ignore-shaped = false;
      no-dnd-shadow = true;
      no-dock-shadow = true;
      clear-shadow = true;
    '';
  };

  users.users.mnacamura = {
    description = "Mitsuhiro Nakamura";
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = "/run/current-system/sw/bin/fish";
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.03"; # Did you read the comment?
}