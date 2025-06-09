#!/usr/bin/env bash

# Ask user yes/no questions
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

# Root check
if [[ "$EUID" -ne 0 ]]; then
  echo -e "\e[1;31mPlease run this script as root or using sudo.\e[0m"
  exit 1
fi

# Setup variables
TARGET_USER=$(logname)
HOME_DIR="/home/$TARGET_USER"
SETUP_DIR="$HOME_DIR/Arch-setup"
LOGFILE="$SETUP_DIR/setup.log"

mkdir -p "$SETUP_DIR"
chown "$TARGET_USER:$TARGET_USER" "$SETUP_DIR"

# Enable logging
exec > >(tee -a "$LOGFILE") 2>&1

# Logo
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
 `++:.                           `-/+

EOF

# Base dependencies
if ask_user "Install base dependencies and enable multilib repo?"; then
  echo -e "\e[1;34mInstalling base dependencies...\e[0m"
  pacman -Syu --noconfirm

  if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
    pacman -Sy
  fi

  pacman -S --needed --noconfirm reflector wget gnupg curl git base-devel
  cd /tmp
  sudo -u "$TARGET_USER" git clone https://aur.archlinux.org/yay.git
  cd yay
  sudo -u "$TARGET_USER" makepkg -si --noconfirm
else
  echo -e "\e[1;31mDependencies required. Exiting.\e[0m"
  exit 1
fi

# Mirrors
if ask_user "Set fastest mirrors?"; then
  echo -e "\e[1;34mSetting fastest mirrors...\e[0m"
  reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
  pacman -Syy
fi

# Game launchers
[[ $(ask_user "Install Lutris?") ]] && pacman -S --noconfirm --needed lutris
[[ $(ask_user "Install Steam?") ]] && pacman -S --noconfirm --needed steam
[[ $(ask_user "Install Heroic Games Launcher from AUR?") ]] && sudo -u "$TARGET_USER" yay -S --noconfirm --needed heroic-games-launcher-bin
[[ $(ask_user "Install Prism Launcher (Minecraft)?") ]] && pacman -S --noconfirm --needed prismlauncher

# Gaming optimizations + ZRAM
if ask_user "Apply general optimizations and setup ZRAM ?"; then
  sudo -u "$TARGET_USER" yay -S --noconfirm --needed arch-gaming-meta cachyos-ananicy-rules
  systemctl enable --now ananicy-cpp.service

echo -e "w! /sys/class/rtc/rtc0/max_user_freq - - - - 3072\nw! /proc/sys/dev/hpet/max-user-freq  - - - - 3072" | tee /etc/tmpfiles.d/custom-rtc.conf
systemd-tmpfiles --create /etc/tmpfiles.d/custom-rtc.conf
cat /sys/class/rtc/rtc0/max_user_freq
cat /proc/sys/dev/hpet/max-user-freq

echo -e "w! /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_none - - - - 409" | tee /etc/tmpfiles.d/custom-thp.conf
systemd-tmpfiles --create /etc/tmpfiles.d/custom-thp.conf
cat /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_none

echo -e "w! /sys/kernel/mm/transparent_hugepage/defrag - - - - defer+madvise" | tee /etc/tmpfiles.d/custom-thp-defrag.conf
systemd-tmpfiles --create /etc/tmpfiles.d/custom-thp-defrag.conf
cat /sys/kernel/mm/transparent_hugepage/defrag

  cat <<EOF >> /etc/sysctl.conf
vm.swappiness=100
vm.vfs_cache_pressure=50
vm.dirty_bytes=268435456
vm.dirty_background_bytes=67108864
vm.dirty_writeback_centisecs=1500
kernel.nmi_watchdog=0
kernel.unprivileged_userns_clone=1
kernel.kptr_restrict=2
net.core.netdev_max_backlog=4096
fs.file-max=2097152
fs.xfs.xfssyncd_centisecs=10000
EOF
  sysctl -p

  pacman -S --noconfirm --needed zram-generator
  TOTAL_MEM=$(awk '/MemTotal/ {print int($2 / 1024)}' /proc/meminfo)
  ZRAM_SIZE=$((TOTAL_MEM / 2))
  mkdir -p /etc/systemd/zram-generator.conf.d
  echo -e "[zram0]\nzram-size = ${ZRAM_SIZE}M\ncompression-algorithm = zstd" > /etc/systemd/zram-generator.conf.d/00-zram.conf
  systemctl daemon-reexec
  systemctl enable --now systemd-zram-setup@zram0.service
  echo -e "w! /sys/module/zswap/parameters/enabled - - - - N" | tee /etc/tmpfiles.d/custom-zswap.conf
systemd-tmpfiles --create /etc/tmpfiles.d/custom-zswap.conf
echo -e "\e[1;32mzswap disabled:\e[0m"
cat /sys/module/zswap/parameters/enabled
fi

# NVIDIA drivers
if ask_user "Install NVIDIA drivers (RTX 2000+)?"; then
  echo -e "\e[1;34mInstalling NVIDIA drivers...\e[0m"
  pacman -S --noconfirm --needed nvidia-open-dkms nvidia-utils nvidia-settings lib32-nvidia-utils

  cat <<EOM > /etc/modprobe.d/nvidia.conf
options nvidia NVreg_UsePageAttributeTable=1 \\
    NVreg_InitializeSystemMemoryAllocations=0 \\
    NVreg_DynamicPowerManagement=0x02 \\
    NVreg_RegistryDwords=RMIntrLockingMode=1
options nvidia_drm modeset=1
EOM

  echo -e "blacklist nouveau\noptions nouveau modeset=0" > /etc/modprobe.d/blacklist-nouveau.conf

  mkinitcpio -P

  mkdir -p /etc/X11/xorg.conf.d
  cat <<EOM > /etc/X11/xorg.conf.d/20-nvidia.conf
Section "Device"
    Identifier "NVIDIA Card"
    Driver "nvidia"
EndSection
EOM

  # persistence mode
  nvidia-smi -pm 1
fi

# mesa-git
if ask_user "compile mesa-git for newest feuture and compatibility (FSR4/RDNA4 etc.) drivers?"; then
  echo -e "\e[1;34m Compiling mesa-git...\e[0m"
  yay -S --noconfirm --needed mesa-git lib32-mesa-git
fi


# Wine
if ask_user "Install Wine and Winetricks?"; then
  echo -e "\e[1;34mInstalling Wine...\e[0m"
  pacman -S --noconfirm --needed wine winetricks wine-mono
fi

# Mission Center
[[ $(ask_user "Install system monitoring tool (Mission Center)?") ]] && pacman -S --noconfirm --needed mission-center

# lact
[[ $(ask_user "Install lact (GPU control)?") ]] && pacman -S --noconfirm --needed lact

# protonplus
[[ $(ask_user "Install protonplus from AUR?") ]] && sudo -u "$TARGET_USER" yay -S --noconfirm --needed protonplus

# Chaotic AUR
if ask_user "Add Chaotic-AUR repository (experimental)?"; then
  pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
  pacman-key --lsign-key 3056513887B78AEB
  pacman -U --noconfirm \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
  echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf
  pacman -Syyuu --noconfirm
fi

# CachyOS repo
if ask_user "Install CachyOS repositories (experimental)?"; then
  curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz
  tar xvf cachyos-repo.tar.xz && cd cachyos-repo
  ./cachyos-repo.sh
  pacman -Syyuu --noconfirm
fi

# CachyOS kernel
if ask_user "Install CachyOS kernel (can be slow if you dont have CachyOS and Chaotic-AUR repos)?"; then
  pacman -Syyuu --noconfirm
  sudo -u "$TARGET_USER" yay -S --noconfirm --needed linux-cachyos linux-cachyos-headers
fi

echo -e "\e[1;32mAll Reboot your system to apply changes.\e[0m"
