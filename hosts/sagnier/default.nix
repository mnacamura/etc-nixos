{ config, pkgs, ... }:

{
  # LEVEL-R0X3-R8X-XZL (BTO PC)
  networking.hostName = "sagnier";

  imports = [
    ./hardware-configuration.nix
    ../../common/linux.nix
  ];

  boot = {
    blacklistedKernelModules = [
      # sp5100_tco: I/O address 0x0cd6 already in use
      # http://tsueyasu.blogspot.jp/2012/03/amdwatchdog.html
      "sp5100_tco"
    ];

    extraModprobeConfig = ''
      options snd_hda_intel model=generic
    '';
  };

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

  hardware = {
    # cpu.amd.updateMicrocode = true;
  };

  nix.settings.cores = 8;

  services = {
    # TODO: Fix it to run correctly.
    # thermald.enable = true;

    openssh.enable = true;
  };

  services.xserver = {
    videoDrivers = [ "amdgpu" ];

    xrandrHeads = [
      { output = "DisplayPort-1"; primary = true; }
    ];
  };
}
