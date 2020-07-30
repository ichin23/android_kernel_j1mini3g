#!/bin/bash
##
#  Copyright (C) 2015, Samsung Electronics, Co., Ltd.
#  Written by System S/W Group, S/W Platform R&D Team,
#  Mobile Communication Division.
#
#  Edited by Remilia Scarlet (remilia15) and Scenix 
##

set -e -o pipefail

PLATFORM=sc8830
DEFCONFIG=j1mini3g_defconfig
OC_DEFCONFIG=j1mini3g-OC_defconfig
NAME=Eternity_kernel
VERSION=Eternity-v8
OC_VERSION=Eternity-v8-OC

export ARCH=arm

KERNEL_PATH=$(pwd)
KERNEL_ZIP=${KERNEL_PATH}/kernel_zip
KERNEL_IMAGE=${KERNEL_ZIP}/tools/Image
DT_IMG=${KERNEL_ZIP}/tools/dt.img
EXTERNAL_MODULE_PATH=${KERNEL_PATH}/external_module
OUTPUT_PATH=${KERNEL_PATH}/out

JOBS=`grep processor /proc/cpuinfo | wc -l`

# Colors
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

function build() {
	clear;
	export LOCALVERSION=-${VERSION}
	KERNEL_ZIP_NAME=${VERSION}_kernel_$(date +%F).zip
	BUILD_START=$(date +"%s");
	echo -e "$cyan"
	echo "***********************************************";
	echo "              Compiling Eternity kernel          	     ";
	echo -e "***********************************************$nocol";
	echo -e "$red";

	if [ ! -e ${OUTPUT_PATH} ]; then
		mkdir ${OUTPUT_PATH};
	fi;

	echo -e "Initializing defconfig...$nocol";
	make O=out ${DEFCONFIG};
	echo -e "$red";
	echo -e "Building kernel...$nocol";
	if [ -d "out/arch/arm/boot/dts" ]; then
		rm out/arch/arm/boot/dts/*;
	fi;
	make O=out -j${JOBS};
	make O=out -j${JOBS} dtbs;
	./scripts/mkdtimg.sh -i ${KERNEL_PATH}/arch/arm/boot/dts/ -o dt.img;
	find ${KERNEL_PATH} -name "Image" -exec mv -f {} ${KERNEL_ZIP}/tools \;
	find ${KERNEL_PATH} -name "dt.img" -exec mv -f {} ${KERNEL_ZIP}/tools \;
	cp out/drivers/net/wireless/sc2331/sprdwl.ko ${KERNEL_ZIP}/tools;
	BUILD_END=$(date +"%s");
	DIFF=$(($BUILD_END - $BUILD_START));
	echo -e "$yellow";
	echo -e "Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol";
}


function oc_build() {
	clear;
	export LOCALVERSION=-${OC_VERSION}
	KERNEL_ZIP_NAME=${OC_VERSION}_kernel_$(date +%F).zip
	BUILD_START=$(date +"%s");
	echo -e "$cyan"
	echo "***********************************************";
	echo "              Compiling Eternity kernel (OC)          	     ";
	echo -e "***********************************************$nocol";
	echo -e "$red";

	if [ ! -e ${OUTPUT_PATH} ]; then
		mkdir ${OUTPUT_PATH};
	fi;

	echo -e "Initializing defconfig...$nocol";
	make O=out ${OC_DEFCONFIG};
	echo -e "$red";
	echo -e "Building kernel...$nocol";
	if [ -d "out/arch/arm/boot/dts" ]; then
		rm out/arch/arm/boot/dts/*;
	fi;
	make O=out -j${JOBS};
	make O=out -j${JOBS} dtbs;
	./scripts/mkdtimg.sh -i ${KERNEL_PATH}/arch/arm/boot/dts/ -o dt.img;
	find ${KERNEL_PATH} -name "Image" -exec mv -f {} ${KERNEL_ZIP}/tools \;
	find ${KERNEL_PATH} -name "dt.img" -exec mv -f {} ${KERNEL_ZIP}/tools \;
	cp out/drivers/net/wireless/sc2331/sprdwl.ko ${KERNEL_ZIP}/tools;
	BUILD_END=$(date +"%s");
	DIFF=$(($BUILD_END - $BUILD_START));
	echo -e "$yellow";
	echo -e "Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol";
}


function make_zip() {
	echo -e "$red";
	echo -e "Making flashable zip...$nocol";

	cd ${KERNEL_PATH}/kernel_zip;
	zip -r ${KERNEL_ZIP_NAME} ./;
	mv ${KERNEL_ZIP_NAME} ${KERNEL_PATH};
}

function rm_if_exist() {
	if [ -e $1 ]; then
		rm -rf $1;
	fi;
}

function clean() {
	echo -e "$red";
	echo -e "Cleaning build environment...$nocol";
	make -j${JOBS} mrproper;

	rm_if_exist ${KERNEL_ZIP_NAME};
	rm_if_exist ${OUTPUT_PATH};
	rm_if_exist ${DT_IMG};

	echo -e "$yellow";
	echo -e "Done!$nocol";
}

function main() {
	clear;
	read -p "Please specify Toolchain path: " tcpath;
	if [ "${tcpath}" == "" ]; then
		echo -e "$red"
		export CROSS_COMPILE=~/arm-eabi-6.x/bin/arm-eabi-;
		echo -e "No toolchain path found. Using default local one:$nocol ${CROSS_COMPILE}";
	else
		export CROSS_COMPILE=${tcpath};
		echo -e "$red";
		echo -e "Specified toolchain path: $nocol ${CROSS_COMPILE}";
	fi;
	if [ "${USE_CCACHE}" == "1" ]; then
		CCACHE_PATH=/usr/bin/ccache;
		export CROSS_COMPILE="${CCACHE_PATH} ${CROSS_COMPILE}";
		export JOBS=8;
		echo -e "$red";
		echo -e "You have enabled ccache through *export USE_CCACHE=1*, now using ccache...$nocol";
	fi;

	echo -e "***************************************************************";
	echo "      Eternity kernel for Samsung Galaxy J1 Mini                   ";
	echo -e "***************************************************************";
	echo "Choices:";
	echo "1. Cleanup source";
	echo "2. Build kernel";
	echo "3. Build kernel then make flashable ZIP";
	echo "4. Make flashable ZIP package";
	echo "5. Build overclocked kernel";
	echo "6. Build overclocked kernel then make flashable ZIP";
	echo "Leave empty to exit this script (it'll show invalid choice)";

	read -n 1 -p "Select your choice: " -s choice;
	case ${choice} in
		1) clean;;
		2) build;;
		3) build
		   make_zip;;
		4) make_zip;;
		5) oc_build;;
		6) oc_build
		   make_zip;;
		*) echo
		   echo "Invalid choice entered. Exiting..."
		   sleep 2;
		   exit 1;;
	esac
}

main $@
