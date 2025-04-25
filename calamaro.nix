# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./nfs-mounts.nix
    ];

  # Add kernel modules to the second stageog the boot (after initrd)
  boot.kernelModules = [ "thinkpad_acpi" ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;
  boot.loader.timeout = 1;

  # Enable mglru thrashing prevention, and add some latency tweaks from
  # https://wiki.archlinux.org/title/Gaming#Tweaking_kernel_parameters_for_response_time_consistency
  boot.postBootCommands = ''
    echo 3000 > /sys/kernel/mm/lru_gen/min_ttl_ms
    echo 5 > /sys/kernel/mm/lru_gen/enabled
    echo never > /sys/kernel/mm/transparent_hugepage/enabled
    echo never > /sys/kernel/mm/transparent_hugepage/shmem_enabled
    echo 0 > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag
  '';

  # Sysctl tweaks
  boot.kernel.sysctl = {
    "vm.swappiness" = 120;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.page-cluster" = 0;
    "vm.vfs_cache_pressure" = 50;
    # Reduce the maximum page lock acquisition latency while retaining adequate throughput
    "vm.page_lock_unfairness" = 1;
    # Disable proactive compaction because it introduces jitter
    "vm.compaction_proactiveness" = 0;
    # Disable zone reclaim (locking and moving memory pages that introduces latency spikes)
    "vm.zone_reclaim_mode" = 0;
    # These are the zen-kernel tweaks to CFS defaults (mostly)
    "kernel.sched_latency_ns" = 4000000;
    "kernel.sched_min_granularity_ns" = 500000;
    "kernel.sched_wakeup_granularity_ns" = 50000;
    "kernel.sched_migration_cost_ns" = 250000;
    "kernel.sched_cfs_bandwidth_slice_us" = 3000;
    "kernel.sched_nr_migrate" = 128;
  };

  networking.hostName = "calamaro";
  # networking.networkmanager.enable = true;  # By default NixOS uses DHCP. Use NetworkManager instead
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable network manager applet
  #programs.nm-applet.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Rome";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "it_IT.UTF-8";
    LC_IDENTIFICATION = "it_IT.UTF-8";
    LC_MEASUREMENT = "it_IT.UTF-8";
    LC_MONETARY = "it_IT.UTF-8";
    LC_NAME = "it_IT.UTF-8";
    LC_NUMERIC = "it_IT.UTF-8";
    LC_PAPER = "it_IT.UTF-8";
    LC_TELEPHONE = "it_IT.UTF-8";
    LC_TIME = "it_IT.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the Desktop Environment.
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.lxqt.enable = true;
  programs.xfconf.enable = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Disable systemd-oomd (we have mglru already)
  systemd.oomd.enable = false;
 
  # Configure console keymap
  console.keyMap = "it";

  # Enable mesa / opengl
  hardware.graphics.enable = true;
  hardware.graphics.extraPackages = [ pkgs.mesa.drivers ];

  # Configure X11
  services.xserver = {
    xkb.layout = "it";
    xkb.variant = "ibm";
  };

  # Enable sound with pipewire.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;

    # Better audio quality (probably not noticeable)
    extraConfig.pipewire = {
      "99-no-resample" = {
        context.properties = {
          default.clock.rate = 48000;
          default.clock.allowed-rates = [ 44100 48000 88200 96000 ];
	  default.clock.quantum = 64;
	  default.clock.min-quantum = 64;
          default.clock.max-quantum = 512;
	  resample.quality = 5;
	};
      };
    };
  };

  # Enable Zram swap
  zramSwap.enable = true;
  zramSwap.memoryPercent = 35;
  zramSwap.writebackDevice = "/dev/disk/by-uuid/3e5c22c8-adb7-4331-a37d-5e68629852b2";

  # Apparently, zram writeback needs to be triggered externally
  # https://github.com/systemd/zram-generator/issues/164
  systemd.timers."zram-writeback" = {
  wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "5m";
      Unit = "zram-writeback.service";
    };
  };

  systemd.services."zram-writeback" = {
    script = ''
      set -eu
      ${pkgs.coreutils}/bin/echo huge > /sys/block/zram0/writeback
      ${pkgs.coreutils}/bin/echo 'cat /sys/block/zram0/bd_stat'
      ${pkgs.coreutils}/bin/cat /sys/block/zram0/bd_stat
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };
 
  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.pol = {
    isNormalUser = true;
    description = "pol";
    extraGroups = [ "networkmanager" "wheel" "lp" ];
    packages = with pkgs; [
      firefox
      ungoogled-chromium

      vlc
      mpv
      celluloid
      totem
      xfce.parole

      deluge
      #qbittorrent
      tremotesf
      popcorntime
      telegram-desktop
    ];
  };

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "pol";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    wget
    killall
    alsa-utils
    glxinfo
    gitMinimal
    nfs-utils
    gparted
    themechanger
    dconf

    mate.mate-system-monitor

    lxqt.pavucontrol-qt

    xfce.xfwm4
    xfce.xfwm4-themes
    xfce.xfconf
    
    libsForQt5.qtstyleplugin-kvantum
    arc-theme

    tela-icon-theme
    vimix-icon-theme

    numix-cursor-theme
    catppuccin-cursors

    budgie-backgrounds
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # https://nixos.wiki/wiki/Storage_optimization
  nix.settings.auto-optimise-store = true;
  nix.optimise.automatic = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Update at least once a month with lowest possible priority
  # system.autoUpgrade.enable = true;
  system.autoUpgrade.dates = "monthly"; 
  nix.daemonIOSchedClass = "idle";
  nix.daemonCPUSchedPolicy = "idle";

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Enable syncthing
#  services.syncthing.enable = true;

  # Enable flatpak
  #services.flatpak.enable = true;

  # Enable Ananicy for automatic process niceness
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
    settings = { loglevel = "info"; log_applied_rule = true; };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}
