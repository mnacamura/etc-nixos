{ pkgs, ... }:

{
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
    tmpOnTmpfs = true;
  };

  hardware = {
    # cpu.intel.updateMicrocode = true;
    bluetooth.enable = true;
    pulseaudio.enable = true;
  };

  networking = {
    networkmanager.enable = true;
  };

  time.timeZone = "Asia/Tokyo";

  i18n = {
    # TODO: consoleColors = [ ... ];
    # consoleKeyMap = "us";  # conflicts with consoleUseXkbConfig
    consoleUseXkbConfig = true;
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
    # useSandbox = true;
    nixPath = [
      "$HOME/.nix-defexpr/channels"
      "nixpkgs=/var/repos/nixpkgs"
      # "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/etc/nixos/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      pulseaudio = true;
    };
  };

  environment = {
    systemPackages = with pkgs; [
      btops
      dunst
      feh
      scrot
      lightlocker
      rofi
      termite
      yabar-unstable
      pavucontrol
    ] ++ [
      gtk3  # Required to use Emacs key bindings in GTK apps
      arc-theme
      papirus-icon-theme
      numix-cursor-theme
    ];
    variables = {
      # Apps launched in ~/.xprofile need it if they use SVG icons.
      GDK_PIXBUF_MODULE_FILE = "${pkgs.librsvg.out}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache";
    };
  };

  programs = {
    fish.enable = true;
    fish.shellInit = ''
      umask 077
    '';
    # Don't override aliases after loading snippets in ~/.config/fish.
    fish.shellAliases = {};
    vim.defaultEditor = true;
    bash.enableCompletion = true;
  };

  services = {
    chrony.enable = true;
    fstrim.enable = true;
    autofs.enable = true;
    autofs.autoMaster = let
      mapConf = pkgs.writeText "auto" ''
          usbdisk  -fstype=noauto,async,group,gid=100,fmask=117,dmask=007  :/dev/sda1
      '';
    in ''
        /media  file:${mapConf}  --timeout=10
    '';
    printing.enable = true;
    printing.drivers = [ pkgs.gutenprint ];
    xserver.enable = true;
    compton.enable = true;
  };

  services.xserver = {
    # exportConfiguration = true;
    layout = "us";
    # Enable LightDM and bspwm environment.
    displayManager.lightdm.enable = true;
    windowManager.bspwm.enable = true;
    desktopManager.default = "none";
    windowManager.default = "bspwm";
  };

  services.compton = {
    fade = true;
    fadeDelta = 5;
    fadeSteps = [ "0.03" "0.03" ];
    shadow = true;
    shadowOpacity = "0.46";
  };

  services.xserver.displayManager.lightdm = {
    background = "/etc/nixos/data/pixmaps/login_background.jpg";
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

  users.users.mnacamura = {
    isNormalUser = true;
    uid = 1000;
    description = "Mitsuhiro Nakamura";
    extraGroups = [ "users" "wheel" "networkmanager" ];
    createHome = true;
    shell = "/run/current-system/sw/bin/fish";
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.03"; # Did you read the comment?
}
