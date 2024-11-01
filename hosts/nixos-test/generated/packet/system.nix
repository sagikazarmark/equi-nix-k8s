{
  imports = [
    ({
      boot.kernelModules = [ "dm_multipath" "dm_round_robin" "ipmi_watchdog" ];
      services.openssh.enable = true;
    }
    )
    ({
      nixpkgs.config.allowUnfree = true;

      boot.initrd.availableKernelModules = [
        "xhci_pci"
        "ahci"
        "usbhid"
        "sd_mod"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.kernelParams = [ "console=ttyS1,115200n8" ];
      boot.extraModulePackages = [ ];

      hardware.enableAllFirmware = true;
    }
    )
    ({ lib, ... }:
      {
        boot.loader = {
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
        };
        nix.settings.max-jobs = lib.mkDefault 64;
      }
    )
    ({
      swapDevices = [

        {
          device = "/dev/disk/by-id/ata-Micron_5300_MTFDDAK480TDT_2204345F033A-part2";
        }

      ];

      fileSystems = {

        "/boot/efi" = {
          device = "/dev/disk/by-id/ata-Micron_5300_MTFDDAK480TDT_2204345F033A-part1";
          fsType = "vfat";

        };


        "/" = {
          device = "/dev/disk/by-id/ata-Micron_5300_MTFDDAK480TDT_2204345F033A-part3";
          fsType = "ext4";

        };

      };

      boot.loader.efi.efiSysMountPoint = "/boot/efi";
    })
    ({ networking.hostId = "d665a7a4"; }
    )
    ({ modulesPath, ... }: {
      networking.hostName = "nixos-test";
      networking.useNetworkd = true;


      systemd.network.networks."40-bond0" = {
        matchConfig.Name = "bond0";
        linkConfig = {
          RequiredForOnline = "carrier";
          MACAddress = "50:7c:6f:43:56:3a";
        };
        networkConfig.LinkLocalAddressing = "no";
        dns = [
          "147.75.207.207"
          "147.75.207.208"
        ];
      };


      boot.extraModprobeConfig = "options bonding max_bonds=0";
      systemd.network.netdevs = {
        "10-bond0" = {
          netdevConfig = {
            Kind = "bond";
            Name = "bond0";
          };
          bondConfig = {
            Mode = "802.3ad";
            LACPTransmitRate = "fast";
            TransmitHashPolicy = "layer3+4";
            DownDelaySec = 0.2;
            UpDelaySec = 0.2;
            MIIMonitorSec = 0.1;
          };
        };
      };


      systemd.network.networks."30-enp1s0f0" = {
        matchConfig = {
          Name = "enp1s0f0";
          PermanentMACAddress = "50:7c:6f:43:56:3a";
        };
        networkConfig.Bond = "bond0";
      };


      systemd.network.networks."30-enp1s0f1" = {
        matchConfig = {
          Name = "enp1s0f1";
          PermanentMACAddress = "50:7c:6f:43:56:3b";
        };
        networkConfig.Bond = "bond0";
      };



      systemd.network.networks."40-bond0".addresses = [
        {
          addressConfig.Address = "86.109.5.3/31";
        }
        {
          addressConfig.Address = "2604:1380:4091:1a00::1/127";
        }
        {
          addressConfig.Address = "10.25.11.129/31";
        }
      ];
      systemd.network.networks."40-bond0".routes = [
        {
          routeConfig.Gateway = "86.109.5.2";
        }
        {
          routeConfig.Gateway = "2604:1380:4091:1a00::";
        }
        {
          routeConfig.Gateway = "10.25.11.128";
        }
      ];
    }
    )
  ];
}
