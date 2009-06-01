#!/bin/sh

# Build an xorg-edgers live CD
# Based on https://help.ubuntu.com/community/LiveCDCustomization
# Tormod Volden 2009

# FIXME: use fakeroot instead of sudo etc

CDVERSION=0.1
ORIGISO="karmic-desktop-i386.iso"
ORIGKVER=2.6.30-6
POCKET="karmic"

ISONAME="xorg-edgers-$CDVERSION-i386.iso"
NEWROOT="edit"
CHROOT="sudo chroot $NEWROOT"
CDTREE="extract-cd"

INTERACTIVE=yes

interact() {
    if [ "$INTERACTIVE" = "yes" ]; then
        echo -n "Press enter to $1 ..."
        read nothing
    else
	echo "Proceeding to $1"
    fi
}

if ! which mksquashfs >/dev/null; then
    echo "you need to install mksquashfs-tools"
    exit 1
fi

if ! which genisoimage >/dev/null; then
    echo "you need to install genisoimage"
    exit 1
fi

if ! mksquashfs -version | grep -q "^mksquashfs version 4" ; then
    echo "you need mksquashfs-tools 4 or newer"
    exit 1
fi

if [ ! -r "$ORIGISO" ]; then
    echo "can not find cd image $ORIGISO"
fi

if [ ! -d $CDTREE ] || [ ! -d $NEWROOT ]; then

interact "unpack original CD image"
mkdir mnt
sudo mount -o loop,ro "$ORIGISO" mnt
mkdir $CDTREE
rsync --exclude=/casper/filesystem.squashfs -a mnt/ $CDTREE
mkdir squashfs
sudo mount -t squashfs -o loop,ro mnt/casper/filesystem.squashfs squashfs
mkdir $NEWROOT
sudo cp -a squashfs/* $NEWROOT
sudo umount squashfs
sudo umount mnt

fi

# set up for chroot
sudo cp /etc/resolv.conf $NEWROOT/etc
sudo mount --bind /dev/ $NEWROOT/dev

#proc and sys
$CHROOT mount -t proc none /proc
$CHROOT mount -t sysfs none /sys

interact "delete unnecessary packages"
$CHROOT apt-get remove --purge --assume-yes openoffice* ubuntu-docs evolution-common evolution-data-server libmono* mono-jit mono-common

if [ -e linux-image*.deb ]; then
    interact "install new kernel"
    sudo cp linux-image*.deb $NEWROOT/var/cache/apt/archives
    $CHROOT sh -c 'dpkg -i /var/cache/apt/archives/linux-image*.deb'
    sudo cp $NEWROOT/boot/vmlinuz-* $CDTREE/casper/vmlinuz
    sudo cp $NEWROOT/boot/initrd.img-* $CDTREE/casper/initrd.gz
    sudo rm $NEWROOT/boot/vmlinuz-* $NEWROOT/boot/initrd.img-*
    sudo rm $NEWROOT/vmlinuz* $NEWROOT/initrd.img*

    interact "delete old kernel"
    $CHROOT apt-get remove --purge --assume-yes linux-headers-$ORIGKVER-generic linux-headers-$ORIGKVER linux-image-$ORIGKVER-generic
    sudo rm -f $NEWROOT/lib/modules/$ORIGKVER-generic/modules.*
    sudo rmdir $NEWROOT/lib/modules/$ORIGKVER-generic
fi

interact "upgrade xorg-edgers packages"
echo "deb http://ppa.launchpad.net/xorg-edgers/ppa/ubuntu $POCKET main" | sudo tee $NEWROOT/etc/apt/sources.list.d/xorg-edgers.list > /dev/null

sudo mv $NEWROOT/etc/apt/sources.list $NEWROOT/etc/apt/sources.list.bak
$CHROOT apt-get update
$CHROOT apt-get --assume-yes --force-yes upgrade
sudo mv $NEWROOT/etc/apt/sources.list.bak $NEWROOT/etc/apt/sources.list
$CHROOT apt-get update

# useful for PTS
$CHROOT apt-get install php5-cli php5-common patch

# customization and branding

[ -r rc.local ] && sudo cp rc.local $NEWROOT/etc/rc.local && sudo chmod 755 $NEWROOT/etc/rc.local

if [ -r xorg-edgers-bg.png ]; then
    sudo cp xorg-edgers-bg.png $NEWROOT/usr/share/backgrounds
    sudo sed -i 's/warty-final-ubuntu.png/xorg-edgers-bg.png/' $NEWROOT/usr/share/gnome-background-properties/ubuntu-wallpapers.xml
    sudo sed -i 's/warty-final-ubuntu.png/xorg-edgers-bg.png/' $NEWROOT/usr/share/gconf/defaults/16_ubuntu-wallpapers
fi

if [ -r README.for.CD ]; then
    sudo cp README.for.CD $CDTREE/README.xorg-edgers
fi

interact "clean up"
$CHROOT apt-get clean
$CHROOT umount /proc
$CHROOT umount /sys
sudo umount $NEWROOT/dev

# update some CD files
chmod +w $CDTREE/casper/filesystem.manifest
$CHROOT dpkg-query -W --showformat='${Package} ${Version}\n' > $CDTREE/casper/filesystem.manifest
sudo cp $CDTREE/casper/filesystem.manifest $CDTREE/casper/filesystem.manifest-desktop
sudo sed -i '/ubiquity/d' $CDTREE/casper/filesystem.manifest-desktop

interact "build squashfs"
sudo mksquashfs $NEWROOT $CDTREE/casper/filesystem.squashfs
sudo chmod 444 $CDTREE/casper/filesystem.squashfs

# branding in disk labels
sudo sed -i 's/- Alpha/- xorg-edgers $CDVERSION Alpha/' $CDTREE/.disk/info
sudo sed -i 's/- Alpha/- xorg-edgers $CDVERSION Alpha/' $CDTREE/README.diskdefines

# CD checksums
sudo rm $CDTREE/md5sum.txt
(cd $CDTREE && find . -type f -print0 | xargs -0 md5sum > ../md5sum.txt)
sed -i '/boot.cat/d' md5sum.txt
sudo cp md5sum.txt $CDTREE
rm md5sum.txt

interact "build ISO image"
cd $CDTREE
sudo mkisofs -D -r -V "xorg-edgers $CDVERSION" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ../$ISONAME .
