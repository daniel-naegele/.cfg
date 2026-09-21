# disko disk layout for xenon.
#
# All three device paths below are placeholders — read the real stable
# paths off `ls -la /dev/disk/by-id/` on the installer medium and fill
# them in before running disko. Never use /dev/sdX or /dev/nvmeXnY (not
# stable across boots).
#
# Layout: NVMe boot drive is LUKS -> LVM -> two LVs (one holding the ZFS
# root pool, one a raw hibernation-only swap device). The two extra
# drives are each LUKS -> their own single-disk ZFS pool (kept separate
# rather than combined/mirrored, since mixing an SSD and HDD in one vdev
# caps performance at the HDD's speed).
#
# All three `luks` blocks are independently password-protected (no shared
# keyfile) — at install time, give crypted-nvme, crypted-ssd870 and
# crypted-hdd the SAME passphrase. With `boot.initrd.systemd.enable = true;`
# (set in xenon.nix), systemd's cryptsetup caches whatever passphrase you
# type in the initrd and retries it automatically on the other LUKS
# volumes before prompting again — so in practice you're prompted once at
# boot, not three times, while every disk still carries real independent
# FDE (no plaintext keyfile on the unencrypted ESP).

{ ... }:
{
  disko.devices = {
    disk = {
      nvme = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-Samsung_SSD_990_1TB_S819NT0L834460D"; # fill in from installer
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
                name = "crypted-nvme";
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

      ssd870 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-Samsung_SSD_870_QVO_2TB_S5RPNF0R610785F";
        content = {
          type = "gpt";
          partitions.luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted-ssd870";
              settings.allowDiscards = true;
              content = {
                type = "zfs";
                pool = "ssdpool";
              };
            };
          };
        };
      };

      hdd = {
        type = "disk";
        device = "/dev/disk/by-id/ata-ST2000DM006-2DM164_Z4ZBNWYV";
        content = {
          type = "gpt";
          partitions.luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted-hdd";
              settings.allowDiscards = false; # no TRIM on spinning rust
              content = {
                type = "zfs";
                pool = "hddpool";
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
          size = "34G"; # > 32G RAM, headroom for hibernation image
          content = {
            type = "swap";
            resumeDevice = true; # wires boot.resumeDevice automatically
            randomEncryption = false; # MUST be false — required for hibernation resume
            priority = -2; # low priority: zram absorbs normal pressure,
            # this LV is only really touched for hibernate
          };
        };
        zpool = {
          size = "900G"; # remainder of the ~930G usable NVMe space; adjust/round as needed
          content = {
            type = "zfs";
            pool = "zroot";
          };
        };
      };
    };

    zpool = {
      zroot = {
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

      ssdpool = {
        type = "zpool";
        rootFsOptions = {
          compression = "zstd";
          acltype = "posixacl";
          xattr = "sa";
        };
        options = {
          ashift = "12";
          autotrim = "on";
        };
        datasets."games" = {
          type = "zfs_fs";
          mountpoint = "/mnt/ssdpool/games";
        };
      };

      hddpool = {
        type = "zpool";
        rootFsOptions = {
          compression = "zstd";
          acltype = "posixacl";
          xattr = "sa";
        };
        options.ashift = "12"; # no autotrim — spinning disk
        datasets = {
          "media" = {
            type = "zfs_fs";
            mountpoint = "/mnt/hddpool/media";
          };
          "backups" = {
            type = "zfs_fs";
            mountpoint = "/mnt/hddpool/backups";
          };
        };
      };
    };
  };
}
