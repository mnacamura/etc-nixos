# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "rtsx_pci_sdmmc" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/863fcc4f-12ba-4c84-9b3b-62c6b27c00f2";
      fsType = "btrfs";
      options = [ "subvol=volumes/root" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/B7BA-D513";
      fsType = "vfat";
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/863fcc4f-12ba-4c84-9b3b-62c6b27c00f2";
      fsType = "btrfs";
      options = [ "subvol=volumes/nix" ];
    };

  fileSystems."/var" =
    { device = "/dev/disk/by-uuid/863fcc4f-12ba-4c84-9b3b-62c6b27c00f2";
      fsType = "btrfs";
      options = [ "subvol=volumes/var" ];
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/863fcc4f-12ba-4c84-9b3b-62c6b27c00f2";
      fsType = "btrfs";
      options = [ "subvol=volumes/home" ];
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/53a7b9a9-2851-4e90-a7d9-53c66af1ffb1"; }
    ];

  nix.maxJobs = lib.mkDefault 8;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
