
Prerequisites:
* a karmic daily-live ISO image in the current directory
* squashfs-tools 4 (pick it from Karmic if you run this on Jaunty)

Then run
	./build.sh
to generate a new iso using default settings. However, you will
probably want to customize quite a bit. Make a configuration file
in the same directory and run:
	./build.sh ./my-custom.conf

After a successful run the original CD image will be unpacked in 
the "edit" and "extract-cd" directories. If the script detects these
directories on later runs, it will not look for and extract the
original image.

Any *.README files will be copied to the CD root.

Any *.deb packages in the $ADDDEBS directory (current directory by default)
will be installed. If this includes kernel packages, the old kernel
will be deleted first.

$ADDPACKAGES is a list of package names to be added.
$DELPACKAGES is a list of package names to be removed.

An $WALLPAPER file will be copied to the CD image and used as a desktop background.

An "live-cd.rc" file can be added to the CD root and will be called
by /etc/rc.local. This can be useful for making local tweaks to the
"live CD" if the CD is copied to a USB stick, since the live-cd.rc
file can be easily modified without rebuilding the squashfs.

