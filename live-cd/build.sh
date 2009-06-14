#!/bin/sh

# Build a customized live CD with packages from PPA
# Based on https://help.ubuntu.com/community/LiveCDCustomization
# Tormod Volden 2009

# Default values
CDVERSION=0.01
ORIGISO="karmic-desktop-i386.iso"
POCKET=karmic
PPA="deb http://ppa.launchpad.net/xorg-edgers/ppa/ubuntu $POCKET main"
PPAKEY=4F191A5A8844C542
WALLPAPER="ppa.png"
CDLABEL="ppa $CDVERSION"
ISONAME="ppa-$CDVERSION-i386.iso"
ADDDEBS=.

CDTREE="extract-cd"
NEWROOT="edit"
CHROOT="sudo chroot $NEWROOT"
INTERACTIVE=${INTERACTIVE:-yes}

if [ -n "$1" ]; then
    CONF="$1"
    if [ -r "$CONF" ]; then
	. "$CONF"
    else
	echo "$0: can not read configuration file $CONF"
	exit 1
    fi
fi

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
  rmdir squashfs
  sudo umount mnt
  rmdir mnt
fi

# set up for chroot
sudo cp /etc/resolv.conf $NEWROOT/etc
sudo mount --bind /dev/ $NEWROOT/dev
$CHROOT mount -t proc none /proc
$CHROOT mount -t sysfs none /sys

# make sure services etc does not start when installing packages
$CHROOT dpkg-divert --add --local --divert /usr/sbin/invoke-rc.d.live-cd --rename /usr/sbin/invoke-rc.d
sudo cp $NEWROOT/bin/true $NEWROOT/usr/sbin/invoke-rc.d

if [ -n "$DELPACKAGES" ]; then
    interact "delete unwanted packages"
    $CHROOT apt-get purge --assume-yes $DELPACKAGES
fi

if [ -e $ADDDEBS/linux-image*.deb ]; then
    interact "delete old kernel"
    ORIGKVER=$(ls $NEWROOT/boot/config-* | sed 's#.*/config-\(.*\)-generic#\1#')
    $CHROOT apt-get purge --assume-yes linux-headers-$ORIGKVER-generic linux-headers-$ORIGKVER linux-image-$ORIGKVER-generic
    sudo rm -f $NEWROOT/lib/modules/$ORIGKVER-generic/modules.*
    sudo rmdir $NEWROOT/lib/modules/$ORIGKVER-generic
fi

# install local packages
if [ -d "$ADDDEBS" ]; then
    interact "install local packages from directory $ADDDEBS"
    sudo cp $ADDDEBS/*.deb $NEWROOT/var/cache/apt/archives &&
        $CHROOT sh -c 'dpkg -i /var/cache/apt/archives/*.deb'
elif [ -n "$ADDDEBS" ]; then
    interact "install local packages from list"
    for DEB in $ADDDEBS; do
	sudo cp $DEB $NEWROOT/var/cache/apt/archives
	$CHROOT dpkg -i /var/cache/apt/archives/$DEB
    done
fi

interact "upgrade PPA packages"
echo $PPA | sudo tee $NEWROOT/etc/apt/sources.list.d/custom-live-cd.list > /dev/null
sudo mv $NEWROOT/etc/apt/sources.list $NEWROOT/etc/apt/sources.list.bak
if [ $PPAKEY ]; then
    $CHROOT apt-key adv --recv-keys --keyserver keyserver.ubuntu.com $PPAKEY
fi
$CHROOT apt-get update
$CHROOT apt-get --assume-yes --force-yes dist-upgrade
sudo mv $NEWROOT/etc/apt/sources.list.bak $NEWROOT/etc/apt/sources.list
$CHROOT apt-get update

if [ -n "$ADDPACKAGES" ]; then
    $CHROOT apt-get --assume-yes --force-yes install $ADDPACKAGES
fi

# fix kernel installation
sudo cp $NEWROOT/boot/vmlinuz-* $CDTREE/casper/vmlinuz
sudo cp $NEWROOT/boot/initrd.img-* $CDTREE/casper/initrd.gz
sudo rm -f $NEWROOT/boot/vmlinuz-* $NEWROOT/boot/initrd.img-*
sudo rm -f $NEWROOT/vmlinuz* $NEWROOT/initrd.img*

# customization and branding

grep -q "live-cd.rc" $NEWROOT/etc/rc.local ||
    sudo sed -i '/^exit 0$/i \
[ -r /cdrom/live-cd.rc ] && . /cdrom/live-cd.rc
' $NEWROOT/etc/rc.local

if [ -r "$WALLPAPER" ]; then
    sudo cp $WALLPAPER $NEWROOT/usr/share/backgrounds
    sudo sed -i "s/warty-final-ubuntu.png/$WALLPAPER/" $NEWROOT/usr/share/gnome-background-properties/ubuntu-wallpapers.xml
    sudo sed -i "s/warty-final-ubuntu.png/$WALLPAPER/" $NEWROOT/usr/share/gconf/defaults/16_ubuntu-wallpapers
fi

for README in *.README ; do
    [ -e $README ] && sudo cp $README $CDTREE
done

interact "clean up"
$CHROOT apt-get clean
# reinstate invoke.rc now that we are done with package installs
sudo rm -f $NEWROOT/usr/sbin/invoke-rc.d 
$CHROOT dpkg-divert --remove --rename /usr/sbin/invoke-rc.d
$CHROOT umount /proc
$CHROOT umount /sys
sudo umount $NEWROOT/dev
sudo rm $NEWROOT/etc/resolv.conf
# FIXME: delete this when Karmic gets it right again
sudo rm -f $NEWROOT/etc/X11/xorg.conf

# update some CD files
chmod +w $CDTREE/casper/filesystem.manifest
$CHROOT dpkg-query -W --showformat='${Package} ${Version}\n' > $CDTREE/casper/filesystem.manifest
sudo cp $CDTREE/casper/filesystem.manifest $CDTREE/casper/filesystem.manifest-desktop
sudo sed -i '/ubiquity/d' $CDTREE/casper/filesystem.manifest-desktop

interact "build squashfs"
sudo mksquashfs $NEWROOT $CDTREE/casper/filesystem.squashfs -noappend
sudo chmod 444 $CDTREE/casper/filesystem.squashfs

# branding in disk labels
sudo sed -i "s/- Alpha/- $CDLABEL/" $CDTREE/.disk/info
sudo sed -i "s/- Alpha/- $CDLABEL/" $CDTREE/README.diskdefines

# CD checksums
sudo rm $CDTREE/md5sum.txt
(cd $CDTREE && find . -type f -print0 | xargs -0 md5sum > ../md5sum.txt)
sed -i '/boot.cat/d' md5sum.txt
sudo cp md5sum.txt $CDTREE
rm md5sum.txt

interact "build ISO image"
cd $CDTREE
sudo mkisofs -D -r -V "$CDLABEL" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ../$ISONAME .

