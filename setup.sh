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

# Setup variables
TARGET_USER=$(logname)
HOME_DIR="/home/$TARGET_USER"
SETUP_DIR="$HOME_DIR/Arch-setup"
LOGFILE="$SETUP_DIR/setup.log"

sudo mkdir -p "$SETUP_DIR"
sudo chown "$TARGET_USER:$TARGET_USER" "$SETUP_DIR"

# Enable logging
exec > >(sudo tee -a "$LOGFILE") 2>&1

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

# Dependencies
if ask_user "Install base dependencies and enable multilib repo?"; then
  sudo pacman -Syyuu --noconfirm

  if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
    sudo pacman -Sy
  fi

  sudo pacman -S --needed --noconfirm reflector wget gnupg curl git base-devel
  cd /tmp
  git clone https://aur.archlinux.org/paru-bin.git
  cd paru-bin
  makepkg -si --noconfirm
else
  echo -e "\e[1;31mDependencies required. Exiting.\e[0m"
  exit 1
fi

# Mirrors
if ask_user "Set fastest mirrors?"; then
  sudo reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
  sudo pacman -Syy
fi

# Steam
if ask_user "Install steam?"; then
  sudo pacman -S --noconfirm --needed steam
fi

# Heroic
if ask_user "Install Heroic Games launcher (Epic Games/GOG Access?)"; then
  paru -S --noconfirm --needed heroic-games-launcher-bin
fi

# System optimizations
if ask_user "Apply general optimizationsand install gaming apps and launchers?"; then
  paru -S --noconfirm --needed arch-gaming-meta cachyos-ananicy-rules
  sudo systemctl enable --now ananicy-cpp.service

  echo -e "w! /sys/class/rtc/rtc0/max_user_freq - - - - 3072\nw! /proc/sys/dev/hpet/max-user-freq  - - - - 3072" | sudo tee /etc/tmpfiles.d/custom-rtc.conf
  sudo systemd-tmpfiles --create /etc/tmpfiles.d/custom-rtc.conf
  cat /sys/class/rtc/rtc0/max_user_freq
  cat /proc/sys/dev/hpet/max-user-freq

  echo -e "w! /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_none - - - - 409" | sudo tee /etc/tmpfiles.d/custom-thp.conf
  sudo systemd-tmpfiles --create /etc/tmpfiles.d/custom-thp.conf
  cat /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_none

  echo -e "w! /sys/kernel/mm/transparent_hugepage/defrag - - - - defer+madvise" | sudo tee /etc/tmpfiles.d/custom-thp-defrag.conf
  sudo systemd-tmpfiles --create /etc/tmpfiles.d/custom-thp-defrag.conf
  cat /sys/kernel/mm/transparent_hugepage/defrag

  cat <<EOF | sudo tee -a /etc/sysctl.conf
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
EOF
  sudo sysctl -p
fi

# NVIDIA drivers
if ask_user "Install NVIDIA drivers (RTX 2000+)?"; then
  echo -e "\e[1;34mInstalling NVIDIA drivers...\e[0m"
  sudo pacman -S --noconfirm --needed nvidia-open-dkms nvidia-utils nvidia-settings lib32-nvidia-utils

  cat <<EOM | sudo tee /etc/modprobe.d/nvidia.conf
options nvidia NVreg_UsePageAttributeTable=1 \\
    NVreg_InitializeSystemMemoryAllocations=0 \\
    NVreg_DynamicPowerManagement=0x02 \\
    NVreg_RegistryDwords=RMIntrLockingMode=1
options nvidia_drm modeset=1
EOM

  echo -e "blacklist nouveau\noptions nouveau modeset=0" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf

  sudo mkinitcpio -P

  sudo mkdir -p /etc/X11/xorg.conf.d
  cat <<EOM | sudo tee /etc/X11/xorg.conf.d/20-nvidia.conf
Section "Device"
    Identifier "NVIDIA Card"
    Driver "nvidia"
EndSection
EOM

  sudo nvidia-smi -pm 1
fi

# OpenRGB
if ask_user "Install OpenRGB-git from AUR and setup SMBUS access for RGB control?"; then
  sudo pacman -S --noconfirm --needed i2c-tools
  paru -S --noconfirm --needed openrgb-git
  cat <<EOF | sudo tee /etc/modules-load.d/openrgb-i2c.conf
i2c-dev
i2c-piix4
EOF
  sudo groupadd -f i2c
  sudo usermod -aG i2c "$TARGET_USER"
  sudo modprobe i2c-dev i2c-piix4
  sudo udevadm control --reload
  sudo udevadm trigger
fi

# lact
if ask_user "Install a GPU management app like afterburner (lact)"; then
  sudo pacman -S --noconfirm --needed lact
fi

# protonplus
if ask_user "Install a App to manage custom Proton versions from the AUR (protonplus)"; then
  paru -S --noconfirm --needed protonplus
fi

# CachyOS repo
if ask_user "Install CachyOS repositories (precopiled and natively compiled packages) (EXPERIMENTAL)?"; then
  curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz
  tar xvf cachyos-repo.tar.xz && cd cachyos-repo
  sudo ./cachyos-repo.sh
  sudo pacman -Syyuu --noconfirm
fi

# mesa-git
if ask_user "Compile mesa-git for newest feuture and compatibility (FSR4/RDNA4 etc.) drivers?(can be slow if you dont have the cachyos repo)"; then
  echo -e "\e[1;34m Compiling mesa-git...\e[0m"
  paru -S --noconfirm --needed mesa-git lib32-mesa-git
fi

# CachyOS kernel
if ask_user "Compile CachyOS kernel (can be slow if you dont have CachyOS or Chaotic-AUR repos)?"; then
  sudo pacman -Syyuu --noconfirm
  paru -S --noconfirm --needed linux-cachyos linux-cachyos-headers
fi

# Reboot
if ask_user "Do you want to reboot to apply changes?"; then
  sudo reboot
fi
