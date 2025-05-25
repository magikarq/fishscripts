#!/usr/bin/env bash

ask_user() {
    local prompt="$1"
    local response
    while true; do
        read -rp "$prompt (y/n): " response
        case "$response" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo "Please answer y or n." ;;
        esac
    done
}

# Check for root
if [[ "$EUID" -ne 0 ]]; then
  echo "Please run this script as root or using sudo."
  exit 1
fi

TARGET_USER=$(logname)
HOME_DIR="/home/$TARGET_USER"
SETUP_DIR="$HOME_DIR/Arch-setup"

mkdir -p "$SETUP_DIR"
chown "$TARGET_USER:$TARGET_USER" "$SETUP_DIR"

# Display logo
cat << 'EOF'

                   -`
                  .o+`
                 `ooo/
                `+oooo:
               `+oooooo:
               -+oooooo+:
             `/:-:++oooo+:
            `/++++/+++++++:
           `/++++++++++++++:
          `/+++ooooooooooooo/`
         ./ooosssso++osssssso+`
        .oossssso-````/ossssss+`
       -osssssso.      :ssssssso.
      :osssssss/        osssso+++.
     /ossssssss/        +ssssooo/-
   `/ossssso+/:-        -:/+osssso+-
  `+sso+:-`                 `.-/+oso:
 `++:.                           `-/+/

EOF

# Install base dependencies
if ask_user "Install base dependencies  and enable multilib repo?"; then
  pacman -Syu --noconfirm
  if ! grep -Pzo '\[multilib\]\n(?:#.*\n)*#?Include = /etc/pacman.d/mirrorlist' /etc/pacman.conf | grep -qv '^Include'; then
    sed -i '/^\[multilib\]$/,/^$/{s/^#\(Include = \/etc\/pacman\.d\/mirrorlist\)/\1/}' /etc/pacman.conf
    pacman -Sy
  fi
  pacman -S --needed --noconfirm reflector wget gnupg curl git base-devel
  cd /tmp
  sudo -u "$TARGET_USER" git clone https://aur.archlinux.org/yay.git
  cd yay
  sudo -u "$TARGET_USER" makepkg -si --noconfirm
else
  echo "Dependencies required. Exiting."
  exit 1
fi

# Set fastest mirrors
if ask_user "Set fastest mirrors?"; then
reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syy
fi

# Lutris installation
if ask_user "Install Lutris?"; then
  pacman -S --noconfirm --needed lutris
fi

# Steam installation
if ask_user "Install Steam?"; then
  pacman -S --noconfirm --needed steam
fi

# Heroic Games Launcher installation
if ask_user "Install Heroic Games Launcher from AUR?"; then
  sudo -u "$TARGET_USER" yay -S --noconfirm --needed heroic-games-launcher-bin
fi

# Prismlauncher
if ask_user "Install Prism Launcher(mooded launcher for minecraft)?"; then
  pacman -S --noconfirm --needed prismlauncher
fi

# Apply  optimizations
if ask_user "Apply gaming optimizations and ZRAM setup?"; then
  sudo -u "$TARGET_USER" yay -S --noconfirm --needed arch-gaming-meta cachyos-ananicy-rules
  systemctl enable --now ananicy-cpp.service

  echo -e 'vm.swappiness=100\nvm.vfs_cache_pressure=50\nvm.dirty_bytes=268435456\nvm.dirty_background_bytes=67108864\nvm.dirty_writeback_centisecs=1500\nkernel.nmi_watchdog=0\nkernel.unprivileged_userns_clone=1\nkernel.kptr_restrict=2\nnet.core.netdev_max_backlog=4096\nfs.file-max=2097152\nfs.xfs.xfssyncd_centisecs=10000' >> /etc/sysctl.conf
  sysctl -p

  pacman -S --noconfirm —-needed zram-generator
  TOTAL_MEM=$(awk '/MemTotal/ {print int($2 / 1024)}' /proc/meminfo)
  ZRAM_SIZE=$((TOTAL_MEM / 2))
  mkdir -p /etc/systemd/zram-generator.conf.d
  echo -e "[zram0]\nzram-size = ${ZRAM_SIZE}\ncompression-algorithm = zstd" > /etc/systemd/zram-generator.conf.d/00-zram.conf
  systemctl daemon-reexec
  systemctl start systemd-zram-setup@zram0.service
fi

if ask_user "Install NVIDIA drivers(RTX2000+)?"; then
 pacman -S --noconfirm --needed nvidia-open-dkms nvidia-utils nvidia-settings

if ask_user "Install AMD drivers?"; then
  pacman -S --noconfirm --needed mesa lib32-mesa mesa-vdpau lib32-mesa-vdpau lib32-vulkan-radeon vulkan-radeon glu lib32-glu vulkan-icd-loader lib32-vulkan-icd-loader
fi

if ask_user "Install Wine and Winetricks?"; then
  pacman -S --noconfirm --needed wine winetricks wine-mono
fi

if ask_user "Install system monitoring tool (Mission Center)?"; then
  pacman -S --noconfirm --needed mission-center
fi

if ask_user "Install lact (GPU control)?"; then
  pacman -S --noconfirm --needed lact
fi

if ask_user "Install protonplus from AUR?"; then
  sudo -u "$TARGET_USER" yay -S --noconfirm --needed protonplus
fi

if ask_user "Add Chaotic-AUR repository(Experimental only for experienced users)?"; then
  pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
  pacman-key --lsign-key 3056513887B78AEB
  pacman -U --noconfirm \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
  echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf
  pacman -Syyuu --noconfirm
fi

if ask_user "Install CachyOS repositories(Experimental only for experienced users)?"; then
  curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz
  tar xvf cachyos-repo.tar.xz && cd cachyos-repo
  ./cachyos-repo.sh
  pacman -Syyuu --noconfirm
fi

if ask_user "Install CachyOS kernel(This will take a really long time if you dont have CachyOS or Chaotic-AUR repos)?"; then
pacman -Syyuu --noconfirm
  sudo -u "$TARGET_USER" yay -S --noconfirm --needed linux-cachyos linux-cachyos-headers
fi
