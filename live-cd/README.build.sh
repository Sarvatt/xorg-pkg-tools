
Prerequisites:
* a karmic daily-live ISO image in the current directory
* squashfs-tools 4 (pick it from Karmic if you run this on Jaunty)

Then run
	./build.sh
to generate a new iso.

After a successful run the original CD image will be unpacked in 
the "edit" and "extract-cd" directories. If the script detects these
directories on later runs, it will not look for and extract the
original image.

An "xorg-edgers-bg.png" file in the current directory will be copied to 
the CD image and used as a desktop background.

An "xorg-edgers.rc" file can be added to the cd root and will be called
by /etc/rc.local. This can be useful for making local tweaks to the
"live CD" if the cd is copied to a USB stick, since the xorg-edgers.rc
file can be easily modified without rebuilding the squashfs.

