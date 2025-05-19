#!/usr/bin/env bash

# Check if the script is run as root
if [[ "$EUID" -ne 0 ]]; then
  echo "Please run this script as root or using sudo."
  exit 1
fi

# Determine target user (assumes script is run via sudo)
TARGET_USER=$(logname)
HOME_DIR="/home/$TARGET_USER"
SETUP_DIR="$HOME_DIR/Arch-setup"

# Create setup directory
mkdir -p "$SETUP_DIR"
chown "$TARGET_USER:$TARGET_USER" "$SETUP_DIR"

# Display logo
echo -e " $(cat << 'EOF'


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
)"


# Ask to install necessary base dependencies and add multilib repo
while true; do
    echo "Would you like to install required dependencies (yay reflector,wget, gnupg, curl, flatpak, etc.) and add the multilib repository? (y/n)"
    read -r deps_answer

if [[ "$deps_answer" == "y" || "$deps_answer" == "Y" ]]; then
    echo "Updating and upgrading system packages..."
    pacman -Syu --noconfirm
    echo "Checking and installing required dependencies..."
    pacman -S --needed --noconfirm reflector wget gnupg curl git flatpak base-devel
    cd /tmp
sudo -u "$TARGET_USER" git clone https://aur.archlinux.org/yay.git
cd yay
sudo -u "$TARGET_USER" makepkg -si --noconfirm
    break
elif [[ "$deps_answer" == "n" || "$deps_answer" == "N" ]]; then
    echo "Dependency installation is required for this script to work. Exiting."
    exit 1
else
    echo "Invalid input. Please enter 'y' or 'n'."
fi
done

# Chaotic-AUR
while true; do
    echo "Would you like to add the Chaotic-AUR Repository? (y/n)"
    read -r chaotic_answer

    if [[ "$chaotic_answer" == "y" || "$chaotic_answer" == "Y" ]]; then
        echo "Downloading and installing chaotic-AUR..."
        pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
        pacman-key --lsign-key 3056513887B78AEB
        pacman -U --noconfirm \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
        echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf
        pacman -Syyuu --noconfirm
        break
    elif [[ "$chaotic_answer" == "n" || "$chaotic_answer" == "N" ]]; then
        echo "Chaotic-AUR installation skipped."
        break
    else
        echo "Invalid input. Please enter 'y' or 'n'."
    fi
done

# Lutris installation
while true; do
    echo "Would you like to install Lutris (EA/EPIC/UBISOFT support)? (y/n)"
    read -r lutris_answer

    if [[ "$lutris_answer" == "y" || "$lutris_answer" == "Y" ]]; then
        echo "Downloading and installing Lutris..."
       pacman -S --noconfirm --needed lutris
        break
    elif [[ "$lutris_answer" == "n" || "$lutris_answer" == "N" ]]; then
        echo "Lutris installation skipped."
        break
    else
        echo "Invalid input. Please enter 'y' or 'n'."
    fi
done

# Steam installation
while true; do
    echo "Would you like to install steam? (y/n)"
    read -r steam_answer

    if [[ "$steam_answer" == "y" || "$steam_answer" == "Y" ]]; then
       sudo pacman -S --noconfirm --needed steam
        break
    elif [[ "$steam_answer" == "n" || "$steam_answer" == "N" ]]; then
        echo "Steam installation skipped."
        break
    else
        echo "Invalid input. Please enter 'y' or 'n'."
    fi
done

# lug-helperr installation
while true; do
    echo "Would you like to install lug-helper (Star-citizen)? (y/n)"
    read -r lug_answer

    if [[ "$lug_answer" == "y" || "$lug_answer" == "Y" ]]; then
        sudo -u "$TARGET_USER" yay -S --noconfirm --needed lug-helper
        break
    elif [[ "$lug_answer" == "n" || "$lug_answer" == "N" ]]; then
        echo "lug-helper installation skipped."
        break
    else
        echo "Invalid input. Please enter 'y' or 'n'."
    fi
done

# Heroic Games Launcher installation
while true; do
    echo "Would you like to install Heroic Games Launcher (Epic/GOG/PRIME support)? (y/n)"
    read -r heroic_answer

    if [[ "$heroic_answer" == "y" || "$heroic_answer" == "Y" ]]; then
       sudo -u "$TARGET_USER" yay -S --noconfirm --needed heroic-games-launcher-bin
        break

    elif [[ "$heroic_answer" == "n" || "$heroic_answer" == "N" ]]; then
        echo "Heroic Games Launcher installation skipped."
        break
    else
        echo "Invalid input. Please enter 'y' or 'n'."
    fi
done

# Install prismlauncher
while true; do
    echo "Install prismlauncher (Minecraft launcher for mods? (y/n)"
    read -r prism_answer

    if [[ "$prism_answer" == "y" || "$prism_answer" == "Y" ]]; then
     pacman -S --noconfirm --needed prismlauncher
    echo "Prismlauncher installed successfully."
    break
    elif [[ "$prism_answer" == "n" || "$prism_answer" == "N" ]]; then
        echo "Prismlauncher Driver installation skipped."
        break
    else
        echo "Invalid input. Please enter 'y' or 'n'."
    fi
done


# General Gaming Optimizations
while true; do
    echo "Apply General Gaming optimizations and install necessary software(arch-gaming-meta)? (y/n)"
    read -r General_answer

    if [[ "$General_answer" == "y" || "$General_answer" == "Y" ]]; then
# Install software
       sudo -u "$TARGET_USER" yay -S --noconfirm --needed arch-gaming-meta
       
#systctl.d tweaks
       sysctl -w vm.swappiness=100
       echo 'vm.swappiness=100' | sudo tee -a /etc/sysctl.conf
       sysctl -w vm.vfs_cache_pressure=50
       echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
       sysctl -w vm.dirty_bytes=268435456
       echo 'vm.dirty_bytes=268435456' | sudo tee -a /etc/sysctl.conf
       sysctl -w vm.dirty_background_bytes=67108864
       echo 'vm.dirty_background_bytes=67108864' | sudo tee -a /etc/sysctl.conf
       sysctl -w vm.dirty_writeback_centisecs=1500
       echo 'vm.dirty_writeback_centisecs=1500' | sudo tee -a /etc/sysctl.conf
       sysctl -w kernel.nmi_watchdog=0
       echo 'kernel.nmi_watchdog=0' | sudo tee -a /etc/sysctl.conf
       sysctl -w kernel.unprivileged_userns_clone=1
       echo 'kernel.unprivileged_userns_clone=1' | sudo tee -a /etc/sysctl.conf
       sysctl -w kernel.kptr_restrict=2
       echo 'kernel.kptr_restrict=2' | sudo tee -a /etc/sysctl.conf
       sysctl -w net.core.netdev_max_backlog=4096
       echo 'net.core.netdev_max_backlog=4096' | sudo tee -a /etc/sysctl.conf
       sysctl -w fs.file-max=2097152
       echo 'fs.file-max=2097152' | sudo tee -a /etc/sysctl.conf
       sysctl -w fs.xfs.xfssyncd_centisecs=10000
       echo 'echo 'fs.xfs.xfssyncd_centisecs=10000' | sudo tee -a /etc/sysctl.conf' | sudo tee -a /etc/sysctl.conf

# ZRAM Setup
echo "Setting up zram swap (half of total RAM)..."

# Install zram-generator if not present
if ! command -v zramctl >/dev/null || ! [[ -f /usr/lib/systemd/system-generators/zram-generator ]]; then
  echo "Installing zram-generator..."
  pacman -S --noconfirm zram-generator
fi

# Get total memory in MiB
TOTAL_MEM=$(awk '/MemTotal/ {print int($2 / 1024)}' /proc/meminfo)
ZRAM_SIZE=$((TOTAL_MEM / 2))

# Create zram config
mkdir -p /etc/systemd/zram-generator.conf.d

cat > /etc/systemd/zram-generator.conf.d/00-zram.conf <<EOF
[zram0]
zram-size = ${ZRAM_SIZE}
compression-algorithm = zstd
EOF

# Trigger zram generator
systemctl daemon-reexec

# Start zram swap
if systemctl start systemd-zram-setup@zram0.service; then
  echo "ZRAM swap started successfully with size ${ZRAM_SIZE}MiB."
else
  echo "Failed to start ZRAM swap. Check configuration and journal logs."
fi


        break
    elif [[ "$General_answer" == "n" || "$General_answer" == "N" ]]; then
        echo "General Gaming Optimizations skipped."
        break
    else
        echo "Invalid input. Please enter 'y' or 'n'."
    fi
done

# Install nvidia drivers
while true; do
    echo "Install Nvidia drivers? (y/n)"
    read -r driver_answer

    if [[ "$driver_answer" == "y" || "$driver_answer" == "Y" ]]; then
     pacman -S --noconfirm --needed nvidia-dkms nvidia-settings nvidia-utils lib32-nvidia-utils lib32-opencl-nvidia opencl-nvidia libvdpau libxnvctrl vulkan-icd-loader lib32-vulkan-icd-loader
    mkinitcpio -P
    echo "NVIDIA drivers installed successfully."
    break
    elif [[ "$driver_answer" == "n" || "$driver_answer" == "N" ]]; then
        echo "Nvidia Driver installation skipped."
        break
    else
        echo "Invalid input. Please enter 'y' or 'n'."
    fi
done

# Install amd drivers
while true; do
    echo "Install amd drivers? (y/n)"
    read -r amd_answer

    if [[ "$amd_answer" == "y" || "$amd_answer" == "Y" ]]; then
    pacman -S --noconfirm --needed mesa lib32-mesa mesa-vdpau lib32-mesa-vdpau lib32-vulkan-radeon vulkan-radeon glu lib32-glu vulkan-icd-loader lib32-vulkan-icd-loader
    echo "AMD drivers installed successfully."
    break
    elif [[ "$amd_answer" == "n" || "$amd_answer" == "N" ]]; then
        echo "AMD river installation skipped."
        break
    else
        echo "Invalid input. Please enter 'y' or 'n'."
    fi
done

# Install Wine and Winetricks
while true; do
    echo "Install Wine and Winetricks? (y/n)"
    read -r wine_answer
    if [[ "$wine_answer" =~ ^[Yy]$ ]]; then
        pacman -S --noconfirm --needed wine-staging winetricks wine-mono
        echo "Wine and Winetricks installed succesfully."
        break
    elif [[ "$wine_answer" =~ ^[Nn]$ ]]; then
        echo "wine installation skipped."
        break
    else
        echo "Invalid input. Please enter 'y' or 'n'."
    fi
done

# Installsystem monitoring tools
while true; do
    echo "Install system monitoring tools (fastfetch/nvtop/htop/btop? (y/n)"
    read -r monitoring_answer
    if [[ "$monitoring_answer" =~ ^[Yy]$ ]]; then
        pacman -S --noconfirm --needed fastfetch nvtop htop btop
        echo "System monitoring tools installed succesfully."
        break
    elif [[ "$monitoring_answer" =~ ^[Nn]$ ]]; then
        echo "Monitoring tools installation skipped."
        break
    else
        echo "Invalid input. Please enter 'y' or 'n'."
    fi
done

# Install linutil
while true; do
    echo "Install linutil for extra setup options ? (y/n)"
    read -r linutil_answer
    if [[ "$linutil_answer" =~ ^[Yy]$ ]]; then
        sudo -u "$TARGET_USER" yay -S --noconfirm --needed linutil-bin 
        echo "Linutil installed succesfully."
        break
    elif [[ "$linutil_answer" =~ ^[Nn]$ ]]; then
        echo "Linutil installation skipped."
        break
    else
        echo "Invalid input. Please enter 'y' or 'n'."
    fi
done

# Install lact
while true; do
    echo "Install lact (manage and/or overclock your GPU)? (y/n)"
    read -r lact_answer
    if [[ "$lact_answer" =~ ^[Yy]$ ]]; then
        pacman -S --noconfirm --needed lact
        echo "lact installed succesfully."
        break
    elif [[ "$lact_answer" =~ ^[Nn]$ ]]; then
        echo "lact installation skipped."
        break
    else
        echo "Invalid input. Please enter 'y' or 'n'."
    fi
done

# Install and configure Firewall
while true; do
    echo "Install and configure Firewall(UFW)? (y/n)"
    read -r ufw_answer
    if [[ "$ufw_answer" =~ ^[Yy]$ ]]; then
        pacman -S --noconfirm --needed ufw
        systemctl enable ufw
        echo "ufw installed succesfully."
        break
    elif [[ "$ufw_answer" =~ ^[Nn]$ ]]; then
        echo "ufw installation skipped."
        break
    else
        echo "Invalid input. Please enter 'y' or 'n'."
    fi
done

# Install protonplus
while true; do
    echo "Install protonplus (manage compatibility tools like PROTON)? (y/n)"
    read -r proton_answer
    if [[ "$proton_answer" =~ ^[Yy]$ ]]; then
        sudo -u "$TARGET_USER" yay -S --noconfirm --needed protonplus
        echo "protonplus installed succesfully."
        break
    elif [[ "proton_answer" =~ ^[Nn]$ ]]; then
        echo "proton installation skipped."
        break
    else
        echo "Invalid input. Please enter 'y' or 'n'."
    fi
done

# Install TKG kernel
while true; do
    echo "Compile TKG Kernel? (y/n)"
    read -r kernel_answer
    if [[ "$kernel_answer" =~ ^[Yy]$ ]]; then
        git clone https://github.com/Frogging-Family/linux-tkg.git
cd linux-tkg
makepkg -si
        echo "Kernel compiled succesfully."
        break
    elif [[ "kernel_answer" =~ ^[Nn]$ ]]; then
        echo "Kernel compilation skipped."
        break
    else
        echo "Invalid input. Please enter 'y' or 'n'."
    fi
done
