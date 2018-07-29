# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  networking.hostName = "louise";

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./common.nix
    ];

  boot = {
    kernelParams = [
      # See https://gist.github.com/greigdp/bb70fbc331a0aaf447c2d38eacb85b8f#sleep-mode-power-usage
      "mem_sleep_default=deep"
      # DMAR: DRHD: handling fault status reg 2
      # See https://bbs.archlinux.org/viewtopic.php?id=230362
      "intel_iommu=off"
      # See https://wiki.archlinux.org/index.php/Power_management#Bus_power_management
      # "pcie_aspm=force"  # questionable if it is effective on Dell XPS 9370
    ];
    blacklistedKernelModules = [
      # See https://wiki.archlinux.org/index.php/Dell_XPS_13_(9360)#Remove_psmouse_errors_from_dmesg
      "psmouse"
    ];
    extraModprobeConfig = ''
      # See https://wiki.archlinux.org/index.php/Dell_XPS_13_(9360)#Module-based_Powersaving_Options
      options i915 modeset=1 enable_rc6=1 enable_guc_loading=1 enable_guc_submission=1 enable_psr=0
    '';
    kernel.sysctl."vm.swappiness" = 10;
    earlyVconsoleSetup = true;  # For HiDPI display
  };

  i18n.consoleFont = "latarcyrheb-sun32";  # for HiDPI display

  nix.buildCores = 8;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    btops
    dunst
    feh
    scrot
    lightlocker
    rofi
    termite
    yabar-unstable
    xorg.xbacklight
    pavucontrol
  ] ++ [
    gtk3  # Required to use Emacs key bindings in GTK apps
    arc-theme
    papirus-icon-theme
    numix-cursor-theme
  ];
  programs.fish = {
    enable = true;
    shellInit = ''
      umask 077
    '';
    # Don't override aliases after loading snippets in ~/.config/fish.
    shellAliases = {};
  };
  programs.vim.defaultEditor = true;

  environment.variables = {
    # Apps launched in ~/.xprofile need it if they use SVG icons.
    GDK_PIXBUF_MODULE_FILE = "${pkgs.librsvg.out}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache";

    # For HiDPI display
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    GDK_SCALE = "2";
    GDK_DPI_SCALE = "0.5";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.bash.enableCompletion = true;
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # List services that you want to enable:

  # Services for hardware optimizations.
  services.fstrim.enable = true;
  services.thermald.enable = true;
  services.tlp.enable = true;
  services.tlp.extraConfig = ''
    CPU_SCALING_GOVERNOR_ON_AC=powersave
    CPU_SCALING_GOVERNOR_ON_BAT=powersave
  '';

  # Enable the chrony deamon.
  services.chrony.enable = true;

  # Enable the autofs daemon.
  services.autofs = {
    enable = true;
    autoMaster = let
      mapConf = pkgs.writeText "auto" ''
        usbdisk  -fstype=noauto,async,group,gid=100,fmask=117,dmask=007  :/dev/sda1
      '';
    in ''
      /media  file:${mapConf}  --timeout=10
    '';
  };

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.gutenprint ];

  # Enjoy Steam.
  hardware.pulseaudio.support32Bit = true;
  hardware.opengl.driSupport32Bit = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  # services.xserver.exportConfiguration = true;
  services.xserver.dpi = 192;  # for HiDPI (96dpi * 2)
  services.xserver.layout = "us";
  services.xserver.xkbOptions = "terminate:ctrl_alt_bksp,ctrl:swapcaps";

  # Enable touchpad support.
  services.xserver.libinput.enable = true;
  services.xserver.libinput.accelSpeed = "1";
  services.xserver.libinput.naturalScrolling = true;

  # Set the video card driver.
  services.xserver.videoDrivers = [ "intel" ];
  services.xserver.deviceSection = ''
    Option "Backlight" "intel_backlight"
  '';

  # Extra devices.
  services.xserver.inputClassSections = [
    ''
      Identifier             "HHKB-BT"
      MatchIsKeyboard        "on"
      MatchDevicePath        "/dev/input/event*"
      MatchProduct           "HHKB-BT"
      Option "XkbModel"      "pc104"
      Option "XkbLayout"     "us"
      Option "XkbOptions"    "terminate:ctrl_alt_bksp"
      Option "XkbVariant"    ""
    ''
  ];

  # Enable LightDM.
  services.xserver.displayManager.lightdm = {
    enable = true;
    background = "/var/pixmaps/default.jpg";
  };
  services.xserver.displayManager.lightdm.greeters.mini = {
    enable = true;
    user = "mnacamura";
    extraConfig = ''
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

  # Enable bspwm.
  services.xserver.windowManager.bspwm.enable = true;
  services.xserver.desktopManager.default = "none";
  services.xserver.windowManager.default = "bspwm";

  # Enable compton.
  services.compton = {
    enable = true;

    fade = true;
    fadeDelta = 5;
    fadeSteps = [ "0.03" "0.03" ];

    shadow = true;
    shadowOpacity = "0.46";
    shadowOffsets = [(-24) (-30)];

    backend = "glx";
    vSync = "opengl-swc";
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

      shadow-radius = 44;
      shadow-ignore-shaped = false;
      no-dnd-shadow = true;
      no-dock-shadow = true;
      clear-shadow = true;
    '';
  };
}