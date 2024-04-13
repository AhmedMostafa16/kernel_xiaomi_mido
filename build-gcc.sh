#!/bin/bash

# Bash Colors
GREEN='\033[01;32m'
RED='\033[01;31m'
BLINK_RED='\033[05;31m'
YELLOW='\e[0;33m'
BLUE='\e[0;34m'
PURPLE='\e[0;35m'
CYAN='\e[0;36m'
WHITE='\e[0;37m'
RESET='\033[0m'

# Resources
# export PATH="$HOME/dev/toolchains/neutron-clang/bin:$PATH"
export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE="/home/ahmed/dev/toolchains/gcc-arm64/bin/aarch64-elf-"
export CROSS_COMPILE_ARM32="/home/ahmed/dev/toolchains/gcc-arm/bin/arm-eabi-"
# export CLANG_TRIPLE="aarch64-linux-gnu-"
# export CC=clang
KERNEL="Electra"
THREAD="-j$(nproc --all)"
IMAGE="Image"
DTB="dtb"
DEFCONFIG="mido_defconfig"

# Paths
KERNEL_DIR=$PWD
REPACK_DIR=/home/ahmed/dev/AnyKernel3
ZIMAGE_DIR=$KERNEL_DIR/arch/arm64/boot
OUT=$KERNEL_DIR/out

# Date
DATE_START=$(date +"%s")

# Functions
clean_all() 
{
		rm -rf out
		mkdir out
		make O=out -j16 clean mrproper
}

make_kernel()
{
		echo
 		make -j16 $DEFCONFIG
 		#make CC="ccache clang" O=out -j16 KCFLAGS="-O3 -pipe -march=armv8-a+crc+simd+crypto -mtune=cortex-a53 -mcpu=cortex-a53+crc+crypto+simd -fstack-protector-strong -mllvm -polly -mllvm -polly-run-inliner -mllvm -polly-ast-use-context -mllvm -polly-vectorizer=stripmine -mllvm -polly-invariant-load-hoisting -mllvm -polly-run-dce -Wno-enum-conversion -Wno-strict-prototypes -D_FORTIFY_SOURCE=2 -fstack-clash-protection"
		#make O=out -j16 KCFLAGS="-O2 -pipe -march=armv8-a+crc+simd+crypto+fp+sve+lse+rdma+aes+sha2+sve2+rng+sve2-aes -mtune=cortex-a53 -mcpu=cortex-a53+crc+simd+crypto+fp+sve+lse+rdma+aes+sha2+sve2+rng+sve2-aes -D_FORTIFY_SOURCE=2 -fstack-protector-strong -fstack-clash-protection -ftree-vectorize -fgraphite-identity -floop-nest-optimize -fvect-cost-model=dynamic -fpeel-loops"

		make O=out -j16 KCFLAGS="-O2 -pipe -march=armv8-a+crc+simd+crypto+fp+sve+lse+rdma+aes+sha2+sve2+rng+sve2-aes -mtune=cortex-a53 -mcpu=cortex-a53+crc+simd+crypto+fp+sve+lse+rdma+aes+sha2+sve2+rng+sve2-aes -D_FORTIFY_SOURCE=2 -fstack-protector-strong -fstack-clash-protection -fpeel-loops"

		# make LD=/home/ahmed/dev/toolchains/neutron-clang/bin/ld.lld CC=clang O=out CFLAGS='-O2 -pipe -march=armv8-a+crc+simd+crypto+sb+predres+aes+sha2+sha3+sve2+fp16 -mtune=cortex-a53 -flto -fvisibility=hidden -fstack-protector-all -fstack-clash-protection -fcf-protection -fuse-ld=/home/ahmed/dev/toolchains/neutron-clang/bin/ld.lld -fpie -Wl,-pie -D_FORTIFY_SOURCE=2' -j16
}

make_zip()
{
		cd $REPACK_DIR
		cp $KERNEL_DIR/arch/arm64/boot/Image.gz-dtb $REPACK_DIR/
		zip -r9 `echo $ZIP_NAME`.zip *
		cp *.zip ../
		rm *.zip
		rm Image.gz-dtb
		cd $KERNEL_DIR
		rm arch/arm64/boot/Image.gz-dtb
}

make_dir()
{
		if [ -d out ]; then
		echo ""
		else
		mkdir out
		fi
}

show_output()
{
		echo -e "${GREEN}"
		echo "======================"
		echo "= Build Successful!! ="
		echo "======================"
		echo -e "${RESET}"
		DATE_END=$(date +"%s")
		DIFF=$(($DATE_END - $DATE_START))
		echo "Your zip is here: $(tput setaf 229)"$OUT"/$(tput sgr0)$(tput setaf 226)"$ZIP_NAME".zip$(tput sgr0)"
		echo
		echo "Your build time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
}

show_fail()
{
		echo -e "${RED}"
		echo "======================"
		echo "=   Build Failed!!   ="
		echo "======================"
		echo -e "${RESET}"
		DATE_END=$(date +"%s")
		DIFF=$(($DATE_END - $DATE_START))
		echo
		echo "Your build time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
}

# Header
tput reset
echo -e "$GREEN"
echo "======================"
echo "= Electra Kernel ="
echo "======================"
echo -e "$RESET"


# Kernel Details
VERSION="23.08.10"
VENDOR="xiaomi"
DEVICE="mido"
export KBUILD_BUILD_USER=ahmed
export KBUILD_BUILD_HOST=z600
DATE=`date +"%Y%m%d-%H%M"`
ZIP_NAME="$KERNEL"-"$VERSION"-"$DATE"-"$DEVICE"

# Check old build
if [ -f arch/arm64/boot/"Image.gz-dtb" ]; then
echo "$(tput setaf 4)Previous build found! Creating Zip.$(tput sgr0)"
	make_zip
	show_output
exit 0;
else
echo "No previous build found!"
fi

echo

# Asks for a clean build
while read -p "$(tput setaf 209)Do you want to clean stuffs? (y/n):$(tput sgr0) " cchoice
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
		echo "Invalid input! Try again (-_-)"
		exit 0;
		break
		echo
		;;
esac
done

echo

# Asks to build
while read -p "$(tput setaf 6)Do you want to build? (y/n):$(tput sgr0) " dchoice
do
case "$dchoice" in
	y|Y )
		make_dir
		make_kernel
		if [ -f out/arch/arm64/boot/"Image.gz-dtb" ]; then
		make_zip
		show_output
		else
		show_fail
		fi
		break
		;;
	n|N )
		echo
		echo "Nothing has been made. Terminating the script ;_;"
		exit 0;
		break
		;;
	* )
		echo
		echo "Invalid input! Try again you noob (-_-)"
		echo
		exit 0;
		break
		;;
esac
done
