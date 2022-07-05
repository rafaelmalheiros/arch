#!/usr/bin/env zsh
MOUNT_OPTIONS=noatime,space_cache=v2,compress=zstd,ssd,discard=async
echo -ne "
/**************************************************************/
/                   Installing Arch Linux                      /
/**************************************************************/
"
sleep 3s
clear
echo -ne "
/**************************************************************/
/                   Updating mirrors                           /
/**************************************************************/
"
sleep 3s
echo "Setting Keyboard Layout"
loadkeys br-abnt2
echo "Setting NTP"
timedatectl set-ntp true
echo "Updating Keyring"
pacman -Sy --noconfirm archlinux-keyring
echo "Changing font"
pacman -S --noconfirm --needed pacman-contrib terminus-font
setfont ter-v22b
reflector -a 48 -f 5 -l 20 -p https --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syy
clear
echo -ne "
/**************************************************************/
/                   Preparing Disk                             /
/**************************************************************/
"
lsblk
echo "What of the above disks should I use to install? /dev/???"
read drive
DISK=/dev/$drive
echo "Formating Disk $drive"
umount -A --recursive /mnt
sgdisk -Z ${DISK} 
sgdisk -a 2048 -o ${DISK} 

# create partitions
sgdisk -new 1::+512M --typecode=1:ef00 --change-name=1:'EFIBOOT' ${DISK} 
sgdisk -new 2::-0 --typecode=2:8300 --change-name=2:'ROOT' ${DISK}

partprobe ${DISK} 

mkfs.fat -F32 /dev/$drive\1
cryptsetup --cipher aes-xts-plain64 --hash sha512 --use-random --verify-passphrase /dev/$drive\2
cryptsetup open /dev/$drive\2 root
mkfs.btrfs /dev/mapper/root
lsblk
echo -ne "
/**************************************************************/
/                   Mounting partitions                        /
/**************************************************************/
"
mount /dev/mapper/root /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@development

umount /mnt
mount -o ${MOUNT_OPTIONS},subvol=@ /dev/mapper/root /mnt
mkdir /mnt{boot,home.var.development}
mount -o ${MOUNT_OPTIONS},subvol=@home /dev/mapper/root /mnt/home
mount -o ${MOUNT_OPTIONS},subvol=@var /dev/mapper/root /mnt/var
mount -o ${MOUNT_OPTIONS},subvol=@development /dev/mapper/root /mnt/development
mount /dev/$drive\1 /mnt/boot
sleep 3s
clear
echo -ne "
/**************************************************************/
/                   Installing Base                            /
/**************************************************************/
"
pacstrap /mnt
genfstab -U /mnt >> /etc/etc/fstab
sleep 3s
echo -ne "
/**************************************************************/
/                   Getting Inside New Installation            /
/**************************************************************/
After getting control, run next script.
When done, type exit to reboot.
"
arch-chroot /mnt
# dracult, qtile, vim, tmux, git, doas, docker, pipewire, btrfs, linux, 
