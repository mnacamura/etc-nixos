# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

{
  imports = [
    ../users/mnacamura.nix
    ../modules/alacritty.nix
    ../modules/colors
    ../modules/conky.nix
    ../modules/feh.nix
    ../modules/dunst.nix
    ../modules/hidpi.nix
    ../modules/light-locker.nix
    ../modules/polybar.nix
    ../modules/rofi.nix
  ];

  boot = {
    extraModprobeConfig = ''
      # https://github.com/NixOS/nixpkgs/issues/57053
      options cfg80211 ieee80211_regdom="JP"
    '';

    loader.systemd-boot = {
      enable = true;
      consoleMode = "auto";
    };
    loader.efi.canTouchEfiVariables = true;

    kernelPackages = pkgs.linuxPackages_latest;

    kernelParams = [
      "nmi_watchdog=0"
    ];

    swraid.enable = false;

    tmp.useTmpfs = true;
  };

  hardware = {
    # platform regulatory.0: Direct firmware load for regulatory.db failed with error -2
    firmware = with pkgs; [ wireless-regdb ];

    bluetooth.enable = true;
    bluetooth.disabledPlugins = [ "sap" ];

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

  i18n.defaultLocale = "ja_JP.UTF-8";

  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
    ];
  };

  fonts = {
    packages = with pkgs; [
      newsreader
      shippori
      raleway
      mplus-outline-fonts.githubRelease
      (nerdfonts.override { fonts = [ "Mononoki" ]; })

      # Complements missing characters such as zenkaku ＡＢＣ.
      source-han-sans-japanese
      source-han-serif-japanese
      source-han-code-jp

      noto-fonts-emoji
    ];

    fontconfig.defaultFonts = {
      serif = [
        "Newsreader"
        "Shippori Mincho"
        "Source Han Serif"
      ];
      sansSerif = [
        "Raleway"
        "M PLUS 2"
        "Source Han Sans"
      ];
      monospace = [
        "Mononoki Nerd Font"
        # NOTE: Combining Mononoki with Japanese monospace fonts, unfortunately, breaks consistent
        # horizontal width alignment between Latin and Japanese characters in such as electron-based
        # applications. This is because Mononoki has width wider than 50%, while Japanese fonts has
        # 100% width. Regardless of that, I'd employ composition of Mononoki and Japanese fonts as
        # Alacritty enforces 50% width to Mononoki so that no problem, and I realy favor Mononoki.
        "M PLUS 2"
        "Source Han Code JP"
      ];
      emoji = [
        "Noto Color Emoji"
      ];
    };
  };

  nix = {
    settings.trusted-users = [ "@wheel" ];

    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/etc/nixos/hosts/${config.networking.hostName}/default.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];

    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      pulseaudio = true;
    };
  };

  environment = {
    colors.palette = config.environment.colors.palettes.srcery;

    systemPackages = with pkgs; [
      configFiles.fish
      fishPlugins.pure
      firefox-bin
      libnotify
      maim
      pavucontrol
      terminalEnv
      zathura
    ] ++ [
      gtk3 # Required to use Emacs key bindings in GTK apps
      configFiles.gtk3
      oomox-default-theme
      oomox-default-icons
      simp1e-cursors
    ];

    pathsToLink = [
      "/etc/fish/conf.d"
      "/etc/fish/functions"
    ];

    profileRelativeEnvVars = {
      MANPATH = [ "/man" "/share/man" ];
    };

    variables = {
      # TODO: Create Srcery-flavoured mouse cursor theme by using
      # [Sim1le's cursor generator](https://gitlab.com/cursors/cursor-generator)
      XCURSOR_THEME = "Simp1e-Gruvbox-Light";
      # Apps launched in ~/.xprofile need it if they use SVG icons.
      GDK_PIXBUF_MODULE_FILE = "${pkgs.librsvg.out}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache";
      PAGER = "less";
      LESS = "-R -ig -j.5";
      LESSCHARSET = "utf-8";
    };

    shellAliases = {
      ls = null;
      l = "ls";
      la = "ls -a";
      ll = "ls -l";
      lla = "ls -la";
      cp = "cp -i";
      mv = "mv -i";
      diff = "diff --color";
    };
  };

  programs = {
    alacritty.enable = true;
    alacritty.configFile = pkgs.configFiles.alacritty;

    bash.loginShellInit = ''
      if [ "$(id -u)" -ge 1000 ]; then  # normal user
          [ "$(id -un)" = "$(id -gn)" ] \
          && umask 007 \
          || umask 077
      else
          umask 022
      fi
    '';
    bash.interactiveShellInit = ''
      ls() {
          type -f lsd >/dev/null 2>&1 \
          && command lsd --date '+%Y-%m-%d %H:%M' "$@" \
          || command ls -Fh --color --time-style=long-iso "$@"
      }
      cat() {
          type -f bat >/dev/null 2>&1 \
          && command bat "$@" \
          || command cat "$@"
      }
    '';

    direnv.enable = true;
    direnv.nix-direnv.enable = true;

    feh.enable = true;

    fish.enable = true;
    fish.loginShellInit = ''
      if [ (id -u) -ge 1000 ]  # normal user
          [ (id -un) = (id -gn) ]
          and umask 007
          or  umask 077
      else
          umask 022
      end
    '';
    fish.interactiveShellInit = ''
      function ls
          type -fq lsd
          and command lsd --date '+%Y-%m-%d %H:%M' $argv
          or  command ls -Fh --color --time-style=long-iso $argv
      end
      function cat
          type -fq bat
          and command bat $argv
          or  command cat $argv
      end
      function tree
          type -fq lsd
          and command lsd --tree $argv
          or  command tree $argv
      end
    '';
    fish.shellAliases = {
      l = null;
      la = null;
      ll = null;
      lla = null;
    };
    fish.shellAbbrs = {
      l = "ls";
      la = "ls -a";
      ll = "ls -l";
      lla = "ls -la";
      h = "history";
      d = "dirh";
      nd = "nextd";
      pd = "prevd";
      t = "tree";
    };

    git.enable = true;
    git.package = pkgs.gitFull;
    git.config = {
      init.defaultBranch = "main";
      push.default = "current";
      status.short = true;
      user.useConfigOnly = true;
    };

    dconf.enable = true;

    light-locker.enable = true;
    light-locker.lockAfterScreensaver = 10;

    ssh.startAgent = true;

    rofi.enable = true;
    rofi.configFile = pkgs.configFiles.rofi;

    vim.defaultEditor = true;
  };

  services = {
    chrony.enable = true;

    dunst.enable = true;
    dunst.configFile = pkgs.configFiles.dunst;

    polybar.enable = true;
    polybar.configFile = pkgs.configFiles.polybar;

    fstrim.enable = true;

    devmon.enable = true;

    printing.enable = true;
    printing.drivers = [ pkgs.gutenprint ];
    colord.enable = true;  # required by CUPS
  };

  services.xserver = {
    enable = true;

    libinput.enable = true;
    libinput.touchpad = {
      accelSpeed = "0.69";
      disableWhileTyping = true;
      naturalScrolling = true;
      sendEventsMode = "disabled-on-external-mouse";
    };
    libinput.mouse = {
      accelProfile = "flat";
      # 4k display, scale 1.36 => cursor moving from left to right: ~3inch
      accelSpeed = "0.69";
    };

    inputClassSections = [
      ''
        Identifier       "HHKB Professional"
        MatchIsKeyboard  "on"
        MatchProduct     "Topre Corporation HHKB Professional"

        Option "XkbModel"    "hhk"
        Option "XkbLayout"   "us"
        Option "XkbVariant"  ""
        Option "XkbOptions"  "terminate:ctrl_alt_bksp"
      ''
      ''
        Identifier       "HHKB Professional BT"
        MatchIsKeyboard  "on"
        MatchProduct     "HHKB-BT"

        Option "XkbModel"    "hhk"
        Option "XkbLayout"   "us"
        Option "XkbVariant"  ""
        Option "XkbOptions"  "terminate:ctrl_alt_bksp"
      ''
    ];

    displayManager.sessionCommands = ''
      ${pkgs.xorg.xsetroot}/bin/xsetroot -cursor_name left_ptr
      ${pkgs.feh}/bin/feh --no-fehbg --bg-scale ${pkgs.desktop-background}
    '';

    displayManager.lightdm = {
      enable = true;

      # TODO: Here background is not scaled while session background above is scaled.
      background = pkgs.desktop-background;

      greeters.mini = {
        enable = true;
        user = config.users.users.mnacamura.name;
        extraConfig = let
          inherit (config.hardware.video.legacy) hidpi;
          colors = config.environment.colors.hex;
        in with colors; ''
          [greeter]
          show-password-label = true
          password-label-text = 󰣐 
          invalid-password-text = Invalid password!
          password-alignment = center
          show-sys-info = false

          [greeter-theme]
          background-image-size = cover
          font = monospace
          font-size = 13pt
          text-color = "${brred}"
          error-color = "${red}"
          window-color = "${term_bg}"
          border-width = ${toString (2 * hidpi.scale)}
          border-color = "${wm_border_unfocus}"
          layout-space = ${toString (19 * hidpi.scale)}
          password-color = "${term_fg}"
          password-background-color = "${term_bg}"
          password-border-color = "${wm_border_focus}"
          password-border-radius = 0
          password-border-width = ${toString (2 * hidpi.scale)}
        '';
      };
    };

    # Enable bspwm environment.
    displayManager.defaultSession = "none+bspwm";
    windowManager.bspwm = {
      enable = true;
      configFile = pkgs.configFiles.bspwm;
      sxhkd.configFile = pkgs.configFiles.sxhkd;
    };

    # Enable XDG autostart, especially for fcitx5.
    # See https://nixos.org/manual/nixos/unstable/release-notes#sec-release-22.05-notable-changes.
    desktopManager.runXdgAutostartIfNone = true;
  };

  services.picom = let
    inherit (config.hardware.video.legacy) hidpi;
    hasAmdgpu = lib.any (d: d == "amdgpu") config.services.xserver.videoDrivers;
  in {
    enable = true;

    fade = true;
    fadeDelta = 8;
    fadeSteps = [ 0.056 0.06 ];

    # glx with amdgpu does not work for now.
    # https://github.com/chjj/compton/issues/477
    backend = if hasAmdgpu then "xrender" else "glx";
    vSync = true;

    settings = {
      frame-opacity = "0.0";
      inactive-opacity-override = false;

      detect-client-leader = true;
      detect-transient = true;
      unredir-if-possible = true;
      use-ewmh-active-win = true;

      glx-copy-from-front = false;
      glx-no-rebind-pixmap = true;
      glx-no-stencil = true;
    };
  };

  virtualisation = {
    docker.storageDriver = "btrfs";
    docker.rootless.enable = true;
    docker.rootless.setSocketVariable = true;
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.09"; # Did you read the comment?
}
