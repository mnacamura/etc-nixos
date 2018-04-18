# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  # Mount options for Btrfs on SSD
  commonMountOptions = [ "defaults" "noatime" "compress=lzo" "commit=60" ];

in

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  fileSystems."/".options = commonMountOptions;
  fileSystems."/nix".options = commonMountOptions;
  fileSystems."/var".options = commonMountOptions;
  fileSystems."/home".options = commonMountOptions;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use the latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.blacklistedKernelModules = [
    # sp5100_tco: I/O address 0x0cd6 already in use
    # See http://tsueyasu.blogspot.jp/2012/03/amdwatchdog.html
    "sp5100_tco"
  ];

  boot.extraModprobeConfig = ''
    Set the sound card driver.
    options snd_hda_intel model=generic
  '';

  networking.hostName = "sagnier"; # Define your hostname.
  networking.networkmanager.enable = true;

  # Select internationalisation properties.
  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "us";
    defaultLocale = "ja_JP.UTF-8";
    inputMethod = {
      enabled = "fcitx";
      fcitx.engines = with pkgs.fcitx-engines; [ mozc ];
    };
  };

  # Fonts
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

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";

  # Nix options
  nix.trustedUsers = [ "@wheel" ];
  # nix.useSandbox = true;
  nix.buildCores = 8;

  # Nixpkgs options
  nixpkgs.config = {
    allowUnfree = true;
    pulseaudio = true;
  };

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    dunst
    feh
    scrot
    lightlocker
    rofi
    termite
    yabar-unstable
    pavucontrol
  ] ++ [
    adapta-gtk-theme
    papirus-icon-theme
    numix-cursor-theme
  ];
  programs.fish.enable = true;
  programs.vim.defaultEditor = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.bash.enableCompletion = true;
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # List services that you want to enable:

  # Services for hardware optimizations.
  services.fstrim.enable = true;
  # services.thermald.enable = true;  # It does not work correctly.

  # Enable the chrony deamon.
  # KDE runs nptdate at the start time so no need to do it.
  # services.chrony.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 17886 ];  # for Jupyter
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.gutenprint ];

  # Enable bluetooth.
  hardware.bluetooth.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enjoy Steam.
  hardware.pulseaudio.support32Bit = true;
  hardware.opengl.driSupport32Bit = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  # services.xserver.exportConfiguration = true;
  services.xserver.layout = "us";
  services.xserver.xkbOptions = "terminate:ctrl_alt_bksp";

  # Set the video card driver.
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Extra monitor settings.
  services.xserver.xrandrHeads = [
    { output = "DisplayPort-1"; primary = true; }
  ];

  # Enable LightDM and bspwm environment.
  services.xserver.displayManager.lightdm = {
    enable = true;
    background = "/var/pixmaps/default.jpg";
  };
  services.xserver.displayManager.lightdm.greeter.package =
  let
    theme = pkgs.symlinkJoin {
      name = "lightdm-gtk-greeter-custom-theme";
      paths = with config.services.xserver.displayManager.lightdm.greeters; [
        gtk.theme.package
        gtk.iconTheme.package
        pkgs.numix-cursor-theme
      ];
    };
  in
  pkgs.runCommand "lightdm-gtk-greeter" { buildInputs = [ pkgs.makeWrapper ]; } ''
      # This wrapper ensures that we actually get themes
      # Enable to use SVG icons. See https://github.com/NixOS/nixpkgs/issues/13537#issuecomment-332327760
      makeWrapper ${pkgs.lightdm_gtk_greeter}/sbin/lightdm-gtk-greeter \
        $out/greeter \
        --prefix PATH : "${pkgs.glibc.bin}/bin" \
        --set GDK_PIXBUF_MODULE_FILE "$(echo ${pkgs.librsvg.out}/lib/gdk-pixbuf-2.0/*/loaders.cache)" \
        --set GTK_PATH "${theme}:${pkgs.gtk3.out}" \
        --set GTK_EXE_PREFIX "${theme}" \
        --set GTK_DATA_PREFIX "${theme}" \
        --set XDG_DATA_DIRS "${theme}/share" \
        --set XDG_CONFIG_HOME "${theme}/share" \
        --set XCURSOR_PATH "${theme}/share/icons"

      cat - > $out/lightdm-gtk-greeter.desktop << EOF
      [Desktop Entry]
      Name=LightDM Greeter
      Comment=This runs the LightDM Greeter
      Exec=$out/greeter
      Type=Application
      EOF
  '';
  services.xserver.displayManager.lightdm.greeters.gtk = {
    indicators = [ "~clock" "~spacer" "~session" "~language" "~power" ];
    clock-format = "%m %e %a %H:%M";
    theme.name = "Adapta-Nokto";
    theme.package = pkgs.adapta-gtk-theme;
    iconTheme.name = "Papirus-Adapta-Nokto";
    iconTheme.package = pkgs.papirus-icon-theme;
    extraConfig = ''
      font-name=Source Sans Pro 13
      cursor-theme-name = Numix
    '';
  };
  services.xserver.windowManager.bspwm.enable = true;
  services.compton = {
    enable = true;
    backend = "glx";
    fade = true;
    fadeDelta = 3;
    shadow = true;
    shadowOpacity = "0.46";
    shadowOffsets = [(-12) (-15)];
    shadowExclude = [
      "name = 'yabar'"
    ];
    extraOptions = ''
      shadow-radius = 22;
    '';
  };
  # services.gnome3.gnome-keyring.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.mnacamura = {
    isNormalUser = true;
    uid = 1000;
    description = "Mitsuhiro Nakamura";
    extraGroups = [ "wheel" "networkmanager" ];
    createHome = true;
    shell = "/run/current-system/sw/bin/fish";
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.03"; # Did you read the comment?

}