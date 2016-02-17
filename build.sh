#!/bin/bash
#
# Egg-Omni build script
#
clear

MODE="$1"
if [ ! -z $MODE ]; then
    if [ "$MODE" == "r" ]; then
        echo "This is a stable release build!"
        export LOCALVERSION="-Egg-Stable"
    fi
else
    echo "This is a nightly build!"
    export LOCALVERSION="-Egg-Nightly"
fi

# Resources
THREAD="-j2"
KERNEL="zImage"
DTBIMAGE="dtb"

# Kernel Details
VARIANT=$(date +"%Y%m%d")
export ARCH=arm
export SUBARCH=arm
export CROSS_COMPILE=${HOME}/secret/chamber/cortex_a15/bin/arm-eabi-

# Paths
KERNEL_DIR="${HOME}/secret/oppo-omni"
ANYKERNEL_DIR="${HOME}/secret/chamber/anykernel"
PATCH_DIR="${HOME}/secret/chamber/anykernel/patch"
ZIMAGE_DIR="$KERNEL_DIR/arch/arm/boot"

# Functions
function defconfig {
		while read -p "Building find7op or find7? " cchoice
		do
		case "$cchoice" in
			find7op )
				DEVICE="find7op"
				DEFCONFIG=msm8974_find7op_defconfig
				break
				;;
			find7 )
				DEVICE="find7"
				DEFCONFIG=msm8974_find7_defconfig
				break
				;;
			* )
				echo
				echo "Invalid try again!"
				echo
				;;
		esac
		done
		ZIP_MOVE_STABLE="${HOME}/secret/out/$DEVICE"
		ZIP_MOVE_NIGHTLY="${HOME}/secret/out/$DEVICE/nightly"
}

function clean_all {
		cd $ANYKERNEL_DIR
		rm -rf $KERNEL
		rm -rf $DTBIMAGE
		rm -rf modules/*
		cd $KERNEL_DIR
		echo
		make clean && make mrproper
}

function make_kernel {
		echo
		make $DEFCONFIG
		make $THREAD
        cd $ANYKERNEL_DIR
        git checkout egg-omni
        cd $KERNEL_DIR
}

function make_dtb {
		$ANYKERNEL_DIR/tools/dtbToolCM -2 -o $ANYKERNEL_DIR/$DTBIMAGE -s 2048 -p scripts/dtc/ arch/arm/boot/
}

function make_modules {
		find $KERNEL_DIR -name "*.ko" -exec cp -v {} $ANYKERNEL_DIR/modules/ \;
}

function make_zip {
		cp -vr $ZIMAGE_DIR/$KERNEL $ANYKERNEL_DIR
		cd $ANYKERNEL_DIR
        if [ ! -z $MODE ]; then
            if [ "$MODE" == "r" ]; then
	            zip -r9 egg-omni6-$DEVICE-stable-$VARIANT.zip *
	            mv egg-omni6-$DEVICE-stable-$VARIANT.zip $ZIP_MOVE_STABLE
            fi
		else
		    zip -r9 egg-omni6-$DEVICE-nightly-$VARIANT.zip *
		    mv egg-omni6-$DEVICE-nightly-$VARIANT.zip $ZIP_MOVE_NIGHTLY
		fi
		cd $KERNEL_DIR
}

echo "Egg Kernel Creation Script:"

echo
defconfig
echo

while read -p "Do you want to clean stuffs (y/n)? " cchoice
do
case "$cchoice" in
	y|Y )
		clean_all
		echo
		echo "All Cleaned now."
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done
echo

DATE_START=$(date +"%s")

while read -p "Do you want to build kernel (y/n)? " dchoice
do
case "$dchoice" in
	y|Y)
		make_kernel
		if [ -f $ZIMAGE_DIR/$KERNEL ];
		then
			make_dtb
			make_modules
			make_zip
		else
			echo
			echo "Kernel build failed."
			echo
		fi
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo
