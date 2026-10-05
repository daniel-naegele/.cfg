# disko disk layout for neon.
#
# Same scheme as xenon's boot drive: LUKS -> LVM -> swap LV (hibernation)
# + ZFS root pool.

{ ... }:
{
  disko.devices = {
    disk.nvme = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-WDS100T1X0E-00AFY0_215228800045";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "nofail"
                "umask=0077"
              ];
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted";
              settings.allowDiscards = true;
              content = {
                type = "lvm_pv";
                vg = "pool";
              };
            };
          };
        };
      };
    };

    lvm_vg.pool = {
      type = "lvm_vg";
      lvs = {
        swap = {
          size = "18G"; # > 16G RAM, headroom for hibernation image
          content = {
            type = "swap";
            resumeDevice = true;
            randomEncryption = false; # required for hibernation resume
            priority = -2;
          };
        };
        zpool = {
          size = "100%FREE";
          content = {
            type = "zfs";
            pool = "zroot";
          };
        };
      };
    };

    zpool.zroot = {
      type = "zpool";
      rootFsOptions = {
        mountpoint = "none";
        compression = "zstd";
        acltype = "posixacl";
        xattr = "sa";
        "com.sun:auto-snapshot" = "true";
      };
      options = {
        ashift = "12";
        autotrim = "on";
      };
      datasets = {
        "root" = {
          type = "zfs_fs";
          mountpoint = "/";
        };
        "root/nix" = {
          type = "zfs_fs";
          mountpoint = "/nix";
        };
        "root/home" = {
          type = "zfs_fs";
          mountpoint = "/home";
        };
      };
    };
  };
}
