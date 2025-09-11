#!/usr/bin/env bash

# sudo/root check
if [ "$EUID" -eq 0 ]; then
  echo "This script cant be run as root or with sudo. Exiting..."
  exit 1
fi

# Detect distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "arch" || "$ID" == "manjaro" || "$ID" == "endeavouros" ]]; then
            echo "arch"
        elif [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
            echo "ubuntu"
        else
            echo "unknown"
        fi
    else
        echo "unknown"
    fi
}

DISTRO=$(detect_distro)
echo "Detected distribution: $DISTRO"

# Ask yes/no questions
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
SETUP_DIR="$HOME_DIR/Gaming-setup"
LOGFILE="$SETUP_DIR/setup.log"

sudo mkdir -p "$SETUP_DIR"
sudo chown "$TARGET_USER:$TARGET_USER" "$SETUP_DIR"

# Enable logging
exec > >(sudo tee -a "$LOGFILE") 2>&1

# Logo
cat << 'EOF'

⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⣀⠀⠀⠀⠆⣃⠀⠀⢀⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⢂⠑⣤⠁⢰⣤⠂⠒⡃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠘⡀⠀⠀⠀⠀⠀⠀⡎⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⢤
⠀⠀⠀⠀⠀⡠⢼⠋⢫⣻⣉⠈⠉⠉⠉⠙⠫⢭⣒⣠⣀⠀⠀⠀⠀⠀⠀⠀⡠⣺⠶⠉⢘⠀⠀
⠀⠀⠀⣴⠋⠈⠀⠀⠀⣷⠞⡂⠀⢀⣠⣴⠶⢶⠫⠯⠛⠿⣦⣀⠀⠀⡴⡇⠊⠁⠀⠀⢸⠀⠀
⠠⣤⡭⠀⠀⢰⢋⢱⠀⠀⡹⢀⡾⠃⢀⣠⠴⠾⡆⠨⠀⠀⠈⢷⣽⡮⣆⠂⢀⡠⠔⠒⡺⠀⠀
⠀⢹⣿⡂⠀⠘⠒⠚⠀⠀⢸⣹⡓⡋⠁⠀⢀⣀⣸⡿⠄⠀⠀⠀⣿⣏⣧⠞⠉⠀⠀⢀⠏⠀⠀
⠀⠀⡿⣟⠀⠀⠉⢻⣆⠀⠀⣯⠍⠉⠉⠉⠉⠁⠀⠀⠀⠇⠀⢀⣷⢻⠧⡀⠀⠀⠀⢸⠁⠀⠀
⠀⢸⠿⣷⢖⡄⠀⠀⢻⡇⠈⣏⣙⠆⠀⠀⠀⠀⠀⠀⠀⢇⣴⠟⠅⣾⣅⠙⠒⠦⠤⡇⠀⠀⠀
⠀⠀⠀⣻⡀⠈⠑⠦⣔⡇⢀⡓⡖⠃⠀⠀⠀⣀⣀⡶⡇⠁⠀⠀⠀⠈⣷⡀⠀⠀⠀⠸⡄⠀⠀
⠀⠀⠀⠀⠉⢃⠀⠀⠀⢹⠛⠋⠉⠉⢏⠉⠉⡉⠲⣤⣙⣦⡀⠀⠀⠀⠠⢳⣄⡀⠀⢸⠀⠀⠀
⠀⠀⠀⠀⠀⠈⣣⠀⠀⠘⣆⠀⠀⠀⠀⠙⡂⢻⠓⢄⡸⠁⠀⠀⠀⠀⠀⠀⠀⠈⠧⡴⠃⠀⠀
⠀⠀⠀⠀⠀⢀⣷⠀⠀⠀⠈⠷⠄⠀⠀⠀⠘⠏⠀⠈⠙⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠈⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀

EOF

# Arch Linux section
if [[ "$DISTRO" == "arch" ]]; then
    echo "=== Arch Linux Setup ==="
    
    # Dependencies
    if ask_user "Install base dependencies and enable multilib repo?"; then
      sudo pacman -Syyuu --noconfirm

      if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
        sudo pacman -Sy
      fi

      sudo pacman -S --needed --noconfirm reflector wget gnupg curl git base-devel flatpak
      if ! command -v paru &> /dev/null; then
        cd /tmp
        git clone https://aur.archlinux.org/paru-bin.git
        cd paru-bin
        makepkg -si --noconfirm
      fi
    else
      echo -e "\e[1;31mDependencies required. Exiting...\e[0m"
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
    if ask_user "Install Heroic Games launcher from AUR (Epic Games/GOG Access?)"; then
      paru -S --noconfirm --needed heroic-games-launcher-bin
    fi

    # System optimizations
    if ask_user "Apply general optimizations and setup gamemode?"; then
      sudo pacman -S --noconfirm --needed gamemode
      systemctl --user enable gamemoded.service
      paru -S --noconfirm --needed cachyos-ananicy-rules
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

    # pamac
    if ask_user "Install a appstore (pamac-aur)?"; then
      paru -S --noconfirm --needed pamac-aur
    fi

    # OpenRGB
    if ask_user "Install an RGB control app (OpenRGB)?"; then
      flatpak install -y flathub org.openrgb.OpenRGB
    fi

     # mangojuice
    if ask_user "Install a peformance monitoring overlay like RivaTunerStatistics (mangojuice)"; then
      flatpak install -y flathub com.mango_juice.MangoJuice
    fi

    # lact
    if ask_user "Install a GPU management/overclocking app like afterburner (lact)"; then
      sudo pacman -S --noconfirm --needed lact
    fi

    # protonplus
    if ask_user "Install a App to manage custom Proton versions like Proton-GE (protonplus)"; then
      flatpak install -y flathub com.vysp3r.ProtonPlus
    fi

    # CachyOS repo
    if ask_user "Install CachyOS repositories (precopiled and natively compiled packages)?"; then
      curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz
      tar xvf cachyos-repo.tar.xz && cd cachyos-repo
      sudo ./cachyos-repo.sh
      sudo pacman -Syyuu --noconfirm
    fi

    # CachyOS kernel
    if ask_user "Compile/install CachyOS kernel (can be slow if you dont have CachyOS repo)?"; then
      sudo pacman -Syyuu --noconfirm
      paru -S --noconfirm --needed linux-cachyos linux-cachyos-headers
      sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi

# Ubuntu section
elif [[ "$DISTRO" == "ubuntu" ]]; then
    echo "=== Ubuntu Setup ==="
    
    # Dependencies
    if ask_user "Install base dependencies?"; then
      sudo apt update && sudo apt upgrade -y
      sudo apt install -y build-essential curl wget gnupg git software-properties-common flatpak
      if ! flatpak remote-list | grep -q flathub; then
        sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      fi
    else
      echo -e "\e[1;31mDependencies required. Exiting...\e[0m"
      exit 1
    fi

    # Steam
    if ask_user "Install Steam?"; then
      TMP_DEB="/tmp/steam_latest.deb"
      echo "Downloading latest Steam .deb package..."
      wget -O "$TMP_DEB" "https://cdn.fastly.steamstatic.com/client/installer/steam.deb"
      sudo dpkg -i "$TMP_DEB" || sudo apt-get install -f -y
      rm -f "$TMP_DEB"
    fi

    # Heroic Games Launcher
    if ask_user "Install Heroic Games Launcher (Epic/GOG) via Flatpak?"; then
      flatpak install -y flathub com.heroicgameslauncher.hgl
    fi

    # System optimizations
    if ask_user "Apply general optimizations and install gamemode?"; then
      sudo apt install -y gamemode
      systemctl --user enable gamemoded.service

            cat <<EOF | sudo tee -a /etc/sysctl.conf
vm.swappiness=10
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
    if ask_user "Install newest NVIDIA drivers ?"; then
    sudo apt install pkg-config libglvnd-dev dkms build-essential libegl-dev libegl1 libgl-dev libgl1 libgles-dev libgles1 libglvnd-core-dev libglx-dev libopengl-dev gcc make -y
    sudo apt remove --purge '^nvidia-.*'
    sudo apt autoremove -y
      sudo add-apt-repository -y ppa:graphics-drivers/ppa
      ubuntu-drivers devices
      sudo ubuntu-drivers autoinstall
sudo apt update

    # OpenRGB (via Flatpak)
    if ask_user "Install an RGB control app (OpenRGB)?"; then
      flatpak install -y flathub org.openrgb.OpenRGB
    fi

    # mangojuice
    if ask_user "Install a peformance monitoring overlay like RivaTunerStatistics (mangojuice)?"; then
      flatpak install flathub io.github.radiolamp.mangojuice
    fi

    # lact
    if ask_user "Install a GPU management/overclocking app like afterburner (lact)?"; then
        flatpak install -y flathub io.github.ilya_zlobintsev.LACT
    fi
    # protonplus
    if ask_user "Install a App to manage/install custom Proton versions like Proton-GE (protonplus)?"; then
        flatpak install -y flathub com.vysp3r.ProtonPlus
    fi

    # Updated mesa
    if ask_user "Install updated mesa (AMD Drivers) ?"; then
       sudo add-apt-repository ppa:kisak/kisak-mesa
       sudo apt update
       sudo apt upgrade      
    fi

    # Liquorix kernel
    if ask_user "Install Liquorix kernel for better performance and responsiveness (Will break secure boot)?"; then
      sudo apt install -y software-properties-common
      sudo add-apt-repository ppa:damentz/liquorix -y
      sudo apt update
      sudo apt install -y linux-image-liquorix-amd64 linux-headers-liquorix-amd64
      sudo sed -i 's/GRUB_DEFAULT=0/GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux liquorix-amd64"/' /etc/default/grub
      sudo update-grub
    fi

else
    echo "Unsupported distribution: $DISTRO"
    echo "This script only supports Arch and Ubuntu. Exiting..."
    exit 1
fi

# Reboot
if ask_user "Do you want to reboot to apply changes?"; then
reboot
fi
