# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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
  };

  networking.hostName = "prometheus"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable network manager applet
  programs.nm-applet.enable = true;

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

  # Enable the LXQT Desktop Environment.
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.lxqt.enable = true;
  programs.xfconf.enable = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Disable systemd-oomd (we have mglru already)
  systemd.oomd.enable = false;
  
  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "it";
    variant = "ibm";
  };

  # Configure console keymap
  console.keyMap = "it";

  # Enable mesa / opengl
  hardware.graphics.enable = true;
  hardware.graphics.extraPackages = [ pkgs.mesa.drivers ];

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
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
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Enable Zram swap
  zramSwap.enable = true;
  zramSwap.memoryPercent = 25;

  # Add a swapfile and use it for hybernation/resume
  # see:https://discourse.nixos.org/t/is-it-possible-to-hibernate-with-swap-file/2852/5
  boot.initrd.systemd.enable = true;
  swapDevices = [ {
    device = "/var/lib/swapfile";
    size = 32*1024;
  } ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.pol = {
    isNormalUser = true;
    description = "Pol";
    extraGroups = [ "networkmanager" "wheel" "syncthing" ];
    packages = with pkgs; [
       flatpak
       syncthing
       syncthingtray
       pass
       passExtensions.pass-otp
       ffmpeg
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim-full
    wget
    killall
    alsa-utils
    glxinfo
    gitMinimal
    nfs-utils
    gparted
    themechanger
    dconf
    fsarchiver
    galculator
    p7zip-rar
    zip
    unzip
    xz
    sshfs
    usbutils
    gnupg
    pinentry

    system-config-printer

    wineWowPackages.stable

    mate.mate-system-monitor

    lxqt.pavucontrol-qt
    lxtask

    xfce.xfwm4
    xfce.xfwm4-themes
    xfce.xfconf
    xfce.mousepad
    
    libsForQt5.qtstyleplugin-kvantum
    arc-theme
    tela-icon-theme
    vimix-icon-theme
    numix-cursor-theme
  ];

  # Inspired from https://discourse.nixos.org/t/declare-firefox-extensions-and-settings/36265?page=2
  programs.firefox = {
    enable = true;
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      EnableTrackingProtection = {
        Value= true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
      DisablePocket = true;
    };
  };

  programs.gnupg.agent.enable= true;

  # Take automatic snapshot of the /home partition
  services.btrbk = {
    instances."home" = {
      onCalendar = "hourly";
      settings = {
        snapshot_preserve_min = "1d";
        snapshot_preserve = "1d 2w 3m";
        volume."/home" = {
            snapshot_dir = "/home/snapshots";
            subvolume = ".";
        };
      };
    };
  };

  # https://nixos.wiki/wiki/Storage_optimization
  nix.settings.auto-optimise-store = true;
  nix.optimise.automatic = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
    persistent = true;
  };

  # Update at least once a month with lowest possible priority
  system.autoUpgrade = {
    enable = true;
    dates = "monthly";
    persistent = true;
  };
  nix.daemonIOSchedClass = "idle";
  nix.daemonCPUSchedPolicy = "idle";

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Enable flatpak
  services.flatpak.enable = true;
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };
  # To use Flatpaks you must enable XDG Desktop Portals
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
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
  system.stateVersion = "24.11"; # Did you read the comment?

}
