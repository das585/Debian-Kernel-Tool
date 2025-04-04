#!/bin/bash

#Deb Kernel Build Helper: As the name suggests, this is a script to help download,
#build, and install a kernel for debian-based distros. More detailed usage can be
#found in the README, but the simplest case is as follows:
#
#   ./deb_kernel_helper [install_version](optional)
#
#This will create a setup directory structure, download the given 6.X kernel version - if provided
#and not already in the kernel dir

#Error handler
set -o errtrace
function err_handler() {
    if [[ $BASH_LINENO -gt 107 && $BASH_LINENO -lt 114 ]]; then #Error caused by file check, pass
        echo ''
    else
        echo "ERROR: ${BASH_SOURCE[1]} around ${BASH_LINENO[0]}"
    fi
}
trap err_handler ERR


#Takes in the name of a directory to check for the existance of
#Creates the directory if it doesn't exist.
#Returns true if created and false otherwise
function mkdir_if_not_exists() {
    if [[ !(-e $1) && !(-d $1) ]]; then
        mkdir $1
        echo "true"
    else
        echo "false"
    fi
}


#Setup the dir structure for the project

#The dir that will contain kernel work for the future
created=$(mkdir_if_not_exists "../kernel") 
if [[ $created == "true" ]]; then #This is the first run, copy to working dir
    cp ./helper.sh ../kernel
fi
cd ../kernel

#Old builds and their build files can be moved here
created=$(mkdir_if_not_exists "old")

#Grab the given version of the kernel from the web, if that isn't in the working dir
kernel_name=$(ls -d */ | grep -i linux)
if [[ $# != 0 && "$kernel_name" != *"$1" ]]; then #A version was given and is different then the working dir version
    echo "Downloading and unpacking kernel version $1"
    wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$1.tar.xz
    tar xf *.tar.xz
    rm *.tar.xz
    kernel_name=$(ls -d */ | grep -i linux)
fi

#Get kernel name, cd and open menuconfig or nconfig 
echo "Cleaning previous build and opening config"
cd $kernel_name/
make clean > /dev/null

#I like nconfig and its simplicity. Replace with menuconfig if preferred
make nconfig #menuconfig

#Prompt to build, we'll prompt later to install. Skip option allows for installing an
#already built kernel
echo "Kernel name will be ${kernel_name}-cust"
read -p "Build this kernel version for dpkg install? (Y/n/(s)kip) " build_resp
case $build_resp in
    #Yes, build the kernel
    [Yy]* ) 
        #Disabling settings that may impact the build
        scripts/config --disable SYSTEM_TRUSTED_KEYS
        scripts/config --disable SYSTEM_REVOCATION_KEYS

        scripts/config --disable DEBUG_INFO
        scripts/config --enable DEBUG_INFO_NONE
        scripts/config --disable CONFIG_DEBUG_INFO

        #Leave some cores depending on how busy you are
        jobs=$(nproc)
        jobs=$(( jobs - 1 ))
        read -p "How busy are you? ie. how many cores to leave free (0-$jobs) " busy_factor
        if [[ $(( jobs - busy_factor )) -le 0 ]]; then           
            busy_factor=$(( jobs - 1 ))
        elif [[ $busy_factor -lt 0 ]]; then
            busy_factor=0
        fi

        #Use the given value to build the kernel
        jobs=$(( jobs - busy_factor ))
        load=$(( jobs + 1 ))
        
        make -j$jobs -l$load bindeb-pkg LOCALVERSION=-cust
        ;;
    
    [Ss]* ) 
        #Skip option, pass to the install portion
        ;;
    
    #No or else -> drop out
    [Nn]* )
        echo "Exiting, kernel will not be built"
        exit
        ;;
    
    * ) 
        echo "Invalid response, exiting without building"
        exit
        ;;
esac

#Check that build completed and output the needed files
ls *.deb &> /dev/null
if [[ $(echo $?) != "0" ]]; then
    echo "Build failed, exiting"
    exit
fi

#Prompt to install
read -p "Install new kernel: $kernel_name -cust? (Y/n)? " inst_resp
case $inst_resp in
    [Yy]* )
        cd ..
        sudo dpkg -i linux-image-*_amd64.deb
        sudo dpkg -i linux-headers-*_amd64.deb
        ;;
    [Nn]* )
        echo "Exiting kernel tool. The kernel can be manually installed by running the following:"
        echo "sudo dpkg -i linux-image-*_amd64.deb && sudo dpkg -i linux-headers-*_amd64.deb"
        exit
        ;;
    * )
        echo "Invalid response, exiting without installing. The kernel can be installed manually by running the following:"
        echo "sudo dpkg -i linux-image-*_amd64.deb && sudo dpkg -i linux-headers-*_amd64.deb"
        exit
        ;;
esac

if [[ $(echo $?) != 0 ]]; then
    echo "The install was unsuccessful. Please review the errors and retry the installation."
fi

echo "Process complete, please restart to boot into the new kernel."
