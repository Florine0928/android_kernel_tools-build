#!/bin/bash
# 
# Copyright 2024 Florine0928
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

########################################################################
# Function for Toolchain                                               # 
########################################################################

if [ ! -d "Toolchain" ]; then
    echo "Toolchain directory is missing, we will create it"
    mkdir Toolchain
    mkdir Toolchain/GCC
    mkdir Toolchain/TEMP
    mkdir Toolchain/CLANG
fi

#############################################
# X86 Specific                              #
#############################################

x86_init() {
    unset CROSS_COMPILE
}

#############################################
# Source the variables from the config file #
source ./config.sh                          #
#############################################

# ExremeXT lurks in this script
usage() {
    echo "Usage: $0 [-b <device>] (-m <clean/dirty>)"
    echo "Example Usage: $0 -d $DEV_AC -t gcc -m dirty -e"
    echo "Options:"
    echo "  -b          Build Kernel for $DEV_AC,$DEV_BC,$DEV_CC,X86_64"
    echo "  -e          Install kernel or create boot.img if android (grub / boot)"
    echo "  -d          Use custom defconfig"
    echo "  -m          Build Mode (clean / dirty)"
    echo "  -t          Toolchain for building"
    echo "  -h          Display this help message"
    echo "Available Toolchains:"
    echo "   1: $TC_A"
    echo "   2: $TC_B"
    exit 1
}

# Parse options
while getopts "dm:b:e:t:h" opt; do
    case $opt in
        b)
            arg=$OPTARG  # Capture the argument for -b

            if [[ "$arg" == "$DEV_AC" ]]; then
                echo "Building kernel for: $arg"
                export DEVICE=$DEV_A
                export DEV_DTB=$DEV_AD
                export IMG_OUT="$IMAGE_NAME-$arg-$PLATFORM_BUILD" # boot.img name
            elif [[ "$arg" == "$DEV_BC" ]]; then
                echo "Building kernel for: $arg"
                export DEVICE=$DEV_B
                export DEV_DTB=$DEV_BD
                export IMG_OUT="$IMAGE_NAME-$arg-$PLATFORM_BUILD" # boot.img name
            elif [[ "$arg" == "$DEV_CC" ]]; then
                echo "Building kernel for: $arg"
                export DEVICE=$DEV_C
                export DEV_DTB=$DEV_CD
                export IMG_OUT="$IMAGE_NAME-$arg-$PLATFORM_BUILD" # boot.img name
            elif [[ "$arg" == "X86_64" ]]; then
                echo "Building kernel for: $arg"
                export DEVICE="X86_64"
                export ARCH="x86"
                export SUBARCH="x86"
                export TARGET_CUSTOM_DEFCONFIG_PATH="$DIR/arch/$ARCH/configs/$IMAGE_NAME"
                x86_init
            else            
                echo "Invalid argument for -b: promptly exiting.."
                exit
            fi
            ;;
        e)
            arg4=$OPTARG  # Capture the argument for -e
            export TARGET_MAKE_INSTALL="true"
            if [[ $arg4 == "grub" ]] && [[ $DEVICE == "X86_64" ]]; then
                export TARGET_MAKE_INSTALL_GRUB="true"
                export TARGET_MAKE_INSTALL="true"
            elif [[ $arg4 == "boot" ]] && [[ $DEVICE != "X86_64" ]]; then
                export TARGET_MAKE_INSTALL="true"
            else
                echo "Invalid argument for -e: promptly exiting.."
                exit
            fi
            ;;
        m)
            arg2=$OPTARG  # Capture the argument for -m

            if [[ "$arg2" == "clean" ]]; then
                unset MODE
                unset CCACHE
                # This is used for when we build kernel
            elif [[ "$arg2" == "dirty" ]]; then
                export MODE="dirty"
            else            
                echo "invalid argument for -m: defaulting to dirty"
                export MODE="dirty"
                export $CCACHE="ccache"
            fi
            ;;
        h)
            # Print Help Option (ex: ./init.sh -h)
            usage
            ;;
        d)
            export TARGET_CUSTOM_DEFCONFIG_VAR="true"    
            echo "BUILDSYSTEM: Using custom defconfig"        
            ;;
        t)
            arg3=$OPTARG  # Capture the argument for -t
            if [[ "$arg3" == "$TC_A" ]]; then
            export TC="$TC_AD/bin/$TC_AB"
            elif [[ "$arg3" == "$TC_B" ]]; then
            export TC=$TC_BB
            else            
            echo "WARNING: No toolchain selected, falling back to GNU GCC"
            echo "Toolchains: $TC_A | $TC_B"
            export TC=$TC_BB
            fi

        ;;
    esac
done

########################################################################
#                                                                      #
########################################################################

# Shift arguments so that $@ contains remaining arguments
shift $((OPTIND -1))

# Check if any arguments are left
if [ $# -ne 0 ]; then
    echo "Invalid option: $@"
    usage
fi

if [ "$OPTIND" -eq 1 ]; then
    usage
fi

########################################################################
# Functions for Building the Kernel                                    # 
########################################################################

# Cleanup defconfigs
cleanup_arm_defconfig() {
    if [ -e "$TARGET_CUSTOM_DEFCONFIG_PATH" ]; then
        rm $TARGET_CUSTOM_DEFCONFIG_PATH
    fi
}

# Populate defconfig
populate_arm_defconfig() {
    touch "$DEFCONFIG/temp_defconfig"
    cat $DEVICE >> "$DEFCONFIG/temp_defconfig"
    cat $TARGET_CUSTOM_DEFCONFIG_PATH >> "$DEFCONFIG/temp_defconfig"
}

# Build Defconfig for Device
defconfig() {
    if [[ "$DEVICE" != "X86_64" ]] && [[ "$TARGET_CUSTOM_DEFCONFIG_VAR" != "true" ]]; then
        make $DEVICE
    elif [[ "$DEVICE" != "X86_64" ]] && [[ "$TARGET_CUSTOM_DEFCONFIG_VAR" == "true" ]]; then
        cleanup_arm_defconfig
        populate_arm_defconfig
        make temp_defconfig # combination device + custom defconfig
    elif [[ "$DEVICE" == "X86_64" ]] && [[ "$TARGET_CUSTOM_DEFCONFIG_VAR" == "true" ]]; then
        make menuconfig
    fi
}

# Build Kernel
build() {
    #If in dirty mode then make kernel while not cleaning workdir 
    make -j$(nproc)
    # If not in dirty mode a extra function with be invoked, refer to func/build_clean at line #145
}

build_modules() {
    if [[ "$DEVICE" == "X86_64" ]]; then
        make modules -j$(nproc)
    fi
}

build_clean() {
    make clean && make mrproper && ccache -C
}

########################################################################
# Function for creating boot.img --- Credits to Apollo for Function    #
########################################################################

# Ramdisk Function
PACK_BOOT_IMG()
{
	echo "----------------------------------------------"
	echo " "
	echo "Building Boot.img for $DEVICE"
	# Copy Ramdisk
	cp -rf $RAMDISK/* $AIK
	# Move Compiled kernel and dtb to A.I.K Folder
	mv $KERNEL $AIK/split_img/boot.img-zImage
	mv $DEV_DTB $AIK/split_img/boot.img-dtb
	# Create boot.img
	$AIK/repackimg.sh
	if [ ! -e $AIK/image-new.img ]; then
        exit 0;
        echo "Boot Image Failed to pack"
        echo " Abort "
	fi
	# Remove red warning at boot
	echo -n "SEANDROIDENFORCE" >> $AIK/image-new.img
	# Copy boot.img to Production folder
	if [ ! -e $PRODUCT ]; then
        mkdir $PRODUCT
	fi
	cp $AIK/image-new.img $PRODUCT/$IMG_OUT.img
	# Move boot.img to out dir
	if [ ! -e $OUT ]; then
        mkdir $OUT
	fi
	mv $AIK/image-new.img $OUT/$IMAGE_NAME.img
	du -k "$OUT/$IMAGE_NAME.img" | cut -f1 >sizkT
	sizkT=$(head -n 1 sizkT)
	rm -rf sizkT
	echo " "
	$AIK/cleanup.sh
}

########################################################################
# Initialize Kernel Building                                           #
########################################################################

# IF mode is dirty, proceed, else, invoke clean build process.
if [[ "$MODE" == "dirty" ]]; then
    echo "WARNING: Kernel Build initialized in Dirty mode"
else
    build_clean
fi


# Make Defconfig
defconfig

# Make Kernel
build

# X86: Build modules
build_modules

if [[ $TARGET_MAKE_INSTALL == "true" ]]; then
    if [[ $DEVICE == "X86_64" ]]; then
        sudo make install
        sudo make modules_install
        if [[ "$TARGET_MAKE_INSTALL_GRUB" == "true" ]]; then
            sudo grub2-mkconfig -o /boot/grub2/grub.cfg
        fi
    else
        PACK_BOOT_IMG
    fi
fi
