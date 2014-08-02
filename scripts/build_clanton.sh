#!/bin/bash -e

########################################################################################################################
# Author : Rushang Karia 						                                	
#           - Rushang.Karia@asu.edu														                                                        
#           - 4806283130									    					                                                        
#           - github.com/RushangKaria
#			
# Description : 											                                                        
#     This script is used to automate the building of BSP for Intel Galileo Fab-D					                
#     The BSP guide can be found at https://communities.intel.com/community/makers/documentation/galileodocuments   
#     Type build_clanton.sh --help for more information how to use this script					                
#														                                                        
#														                                                        
#     This script will stop on any error in the build process since it will eventually cause failure		        
# 
#     Copyright (C) 2014  Rushang Karia
# 
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
# 
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
######################################################################################################################## 

VERSION="v1.0.1"

display_help()
{
	echo "Automated script #  Rushang Karia (Rushang.Karia@asu.edu)"
	echo "Leave the arguments blank for default configuration"
	echo "To overide insert the following variables in the form <NAME>=<VALUE>"
	echo "The following lists the variables and the set of values that they can take"
	echo "BUILD_ROOT={put_the_build_directory_here} -----> set the root dir for the build"
	echo "DISTRO={clanton-tiny, clanton-full}       -----> set the DISTRO type for the build"
	echo "TCLIBC={uclibc,eglibc}			-----> set the C library to be used"
	echo "RETRY={true,false}			-----> if bitbake failed then use this option to continue from the point of failure"
}

check_for_bad_install()
{
if [ -d $BUILD_ROOT ]; then
echo "CLEANING UP BUILD DIRECTORY FOR A FRESH INSTALL"
rm -fr $BUILD_ROOT
fi
}

display_welcome_msg()
{
echo "==================== CSE 438/598 CLANTON AUTOBUILD ===================="
echo "            #####       ##############      ####      ####"
echo "          ###   ###	###	            ####      ####"
echo "        ###       ###	###      	    ####      ####"
echo "       ####       #### 	###    		    ####      ####"
echo "       ####=======####	##############	    ####      ####"
echo "       ####       ####		   ###	    ####      ####"
echo "       ####       ####		   ### 	    ####      ####"
echo "       ####       ####		   ### 	    ####      ####"
echo "       ####       ####	##############	      ##########"			  
echo "								"
echo "					 /\			"
echo "					/  \			"
echo "				        |  |			"
echo "				        |  |			"
echo "				  /\    |  |    /\ 		"
echo "				  ||    |  |    ||		"
echo "				  ||    |  |    ||		"
echo "				  ||    |  |    ||		"
echo "				  ||    |  |    ||		"
echo "				  '' 	|  |	''		"
echo "				  ''	|  |    ''		"
echo "				   ''	|  |   '' 		"
echo "				    '' _|  |_ ''		"
echo "				     ' _|  |_ '			"
echo "					|  |			"
echo "					|  |			"
echo "					|  |			"
echo "					\  /			"
echo "					 \/   			"
}

run_dependency_installer()
{
echo "RUNNING DOWNLOAD SCRIPTS..."
sudo apt-get update > /dev/null

sudo apt-get -y install build-essential gcc-multilib vim-common texinfo chrpath gawk diffstat git file p7zip-full > /dev/null
}


build_setup()
{
CLANTON_DIR=$1

echo "CREATING DIRECTORIES..."
mkdir $BUILD_ROOT 

cd $BUILD_ROOT

wget -q http://downloadmirror.intel.com/23197/eng/Board_Support_Package_Sources_for_Intel_Quark_$VERSION.7z -P ./ 
wget -q http://downloadmirror.intel.com/24000/eng/BSP-Patches-and-Build_Instructions.tar.gz -P ./

echo "EXTRACTING..."
7z e *7z > /dev/null
tar -xf BSP-Patches*gz

if [ $VERSION == "v0.7.5" ]; then
rmdir B*5
fi

tar -xf meta-clanton_$VERSION.tar.gz
cd $CLANTON_DIR

echo "SETTING UP ENVIRONMENT..."
./setup.sh 2> /dev/null 

source poky/oe-init-build-env yocto_build

sed -i "s/\"clanton-tiny\"/\"$DISTRO\"/" conf/local.conf
echo TCLIBC = \"$TCLIBC\" | cat >> conf/local.conf

if [ $TCLIBC == "eglibc" ]; then 
sed -i 's/FILESEXTRAPATHS/#FILESEXTRAPATHS/' $BUILD_ROOT/$CLANTON_DIR/meta-clanton-distro/recipes-multimedia/v4l2apps/v4l-utils_0.8.8.bbappend
sed -i 's/SRC_URI/#SRC_URI/' $BUILD_ROOT/$CLANTON_DIR/meta-clanton-distro/recipes-multimedia/v4l2apps/v4l-utils_0.8.8.bbappend
sed -i 's/DEPENDS/#DEPENDS/' $BUILD_ROOT/$CLANTON_DIR/meta-clanton-distro/recipes-multimedia/v4l2apps/v4l-utils_0.8.8.bbappend
fi

pushd $BUILD_ROOT/$CLANTON_DIR/meta-oe/meta-oe/recipes-multimedia/x264/
sed -i 's|1cffe9f406cc54f4759fc9eeb85598fb8cae66c7|bfed708c5358a2b4ef65923fb0683cefa9184e6f|' x264_git.bb
popd

        pushd $BUILD_ROOT
        cd $CLANTON_DIR
        patch -p1 < ../patches/uart-reverse-8.patch
        popd
     
pushd  $BUILD_ROOT/$CLANTON_DIR/poky/meta/recipes-connectivity/openssl/
        
        mv openssl-1.0.1e    openssl-1.0.1h
        mv openssl_1.0.1e.bb openssl_1.0.1h.bb
        sed -i 's|66bf6f10f060d561929de96f9dfe5b8c|8d6d684a9430d5cc98a62a5d8fbda8cf|' openssl_1.0.1h.bb
        sed -i 's|f74f15e8c8ff11aa3d5bb5f276d202ec18d7246e95f961db76054199c69c1ae3|9d1c8a9836aa63e2c6adb684186cbd4371c9e9dcc01d6e3bb447abf2d4d3d093|' openssl_1.0.1h.bb
        sed -i 's|file://openssl-fix-doc.patch||' openssl_1.0.1h.bb
        sed -i 's|file://0001-Fix-for-TLS-record-tampering-bug-CVE-2013-4353.patch||' openssl_1.0.1h.bb
        sed -i 's|file://0001-Fix-DTLS-retransmission-from-previous-session.patch||' openssl_1.0.1h.bb
        sed -i 's|file://0001-Use-version-in-SSL_METHOD-not-SSL-structure.patch||' openssl_1.0.1h.bb
        sed -i 's|file://CVE-2014-0160.patch||' openssl_1.0.1h.bb
popd

        
}

bitbake_execute()
{

clear

echo "STARTING THE BUILD..DEPENDING ON THE NETWORK AND COMPUTER SPEED THIS PROCESS MIGHT TAKE UPTO 10-15 HOURS"
echo "IF FOR SOME REASON THE BUILD DOES NOT COMPLETE DO NOT RUN THIS SCRIPT AGAIN"
echo "INSTEAD RUN IT LIKE ./build_clanton.sh BUILD_ROOT=wherever_you_pointed_it/leave_blank_for_default RETRY=true"

bitbake $IMAGE_TYPE

if [ $SDK_BUILD == true ]; then
bitbake $IMAGE_TYPE -c populate_sdk
fi

}

restart_bitbake()
{
CLANTON_DIR=$1
cd $BUILD_ROOT
cd $CLANTON_DIR
source poky/oe-init-build-env yocto_build
}

set_environment()
{
for variable in $*
do
export $variable
done
}

########## SCRIPT START ##########

clear

BUILD_ROOT=~/build
DISTRO=clanton-full
TCLIBC=eglibc
RETRY=false
IMAGE_TYPE=image-full-galileo
SDK_BUILD=false

display_welcome_msg

if [ $1 ]; then

	if [ $1 == "--help" ]; then
	display_help
	exit
	fi

set_environment $*

fi


 	if [ $RETRY = true ]; then
 	restart_bitbake "meta-clanton_$VERSION"
 	bitbake_execute
 	else
 	check_for_bad_install
 	run_dependency_installer 
 	build_setup "meta-clanton_$VERSION"
 	bitbake_execute
 	fi
 

if [ "$?" = "0" ]; then
echo "SUCESSFULLY COMPLETED BUILDING!!"
fi






