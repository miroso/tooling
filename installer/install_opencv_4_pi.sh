###################################################################################################
# Step #0: Setup
###################################################################################################

# Path to OpenCV4 download directory
cv_download_dir=/home/pi/opencv_install

# Path to OpenCV4 install directory
# For system wide installation of OpenCV, change cv_install_dir to /usr/local
cv_install_dir=/home/pi/workspace/packages/opencv4

# Path, where you want to create your python virtual environment
py3_virtualenv_dir=/home/pi/virtualenv

# Name of your python3 virtual environment
virtualenv_name=env_cv4

# Current directory
curr_dir=`pwd`

##### OPTIONAL #####
# Path to your list with pip packages
# If a package list is not available, leave empy --> packages=""
packages=/home/pi/workspace/requirements/env_cv4


###################################################################################################
# Step #1: Expand filesystem on your Raspberry Pi
###################################################################################################
#
# sudo raspi-config
# advanced options
# expand filesystem
# sudo reboot


###################################################################################################
# Step #2: Install OpenCV 4 dependencies on your Raspberry Pi
###################################################################################################

echo -e "\n\033[91mStep #2: Install OpenCV 4 dependencies on your Raspberry Pi\033[0m"

# System update
echo -e "\n\033[91m... System update\033[0m"
sudo apt -y update
sudo apt -y upgrade

# Install developer tools:
echo -e "\n\033[91m... Install developer tools\033[0m"
sudo apt -y install build-essential cmake ninja unzip pkg-config

# Install image and video libraries:
echo -e "\n\033[91m... Install image and video libraries\033[0m"
sudo apt -y install libjpeg-dev libpng-dev libtiff-dev
sudo apt -y install libavcodec-dev libavformat-dev libswscale-dev libv4l-dev
sudo apt -y install libxvidcore-dev libx264-dev

# install GTK, our GUI backend
echo -e "\n\033[91m... Install GTK, our GUI backend\033[0m"
sudo apt -y install libgtk-3-dev

# Install a package which may reduce pesky GTK warnings
# the asterisk will grab the ARM specific GTK
echo -e "\n\033[91m... Install a package which may reduce pesky GTK warnings\033[0m"
sudo apt -y install libcanberra-gtk*

# Install numerical optimizations for OpenCV
echo -e "\n\033[91m... Install numerical optimizations for OpenCV\033[0m"
sudo apt -y install libatlas-base-dev gfortran

# install the Python 3 development headers
echo -e "\n\033[91m... Install the Python 3 development headers\033[0m"
sudo apt -y install python3-dev

###################################################################################################
# Step #3: Download OpenCV 4 for your Raspberry Pi
###################################################################################################

echo -e "\n\033[91mDownload OpenCV 4 for your Raspberry Pi\033[0m"

if [ ! -d $cv_download_dir ]; then
  mkdir -p $cv_download_dir
fi
cd $cv_download_dir

# Change version if necessary
wget -O opencv.zip https://github.com/opencv/opencv/archive/4.0.1.zip
wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/4.0.1.zip

unzip opencv.zip
unzip opencv_contrib.zip

mv opencv-4.0.1 opencv
mv opencv_contrib-4.0.1 opencv_contrib

rm opencv.zip
rm opencv_contrib.zip


###################################################################################################
# Step #4: Configure your Python 3 virtual environment for OpenCV 4
###################################################################################################

echo -e "\n\033[91mConfigure your Python 3 virtual environment for OpenCV 4\033[0m"

# Create python 3 virtual environment
virtualenv_path=$py3_virtualenv_dir/$virtualenv_name
virtualenv -p python3 $virtualenv_path
source $virtualenv_path/bin/activate

# Install python 3 packages
if [ -z $packages ]; then
  pip install numpy
else
  pip install -r $packages
fi

###################################################################################################
# Step #5: CMake and compile OpenCV 4 for your Raspberry Pi
###################################################################################################

echo -e "\n\033[91mStep #5: CMake and compile OpenCV 4 for your Raspberry Pi\033[0m"

cd opencv
if [ ! -d "build" ]; then
  mkdir build
fi
cd build

# Run cmake for OpenCV4
cmake -D CMAKE_BUILD_TYPE=RELEASE \
	    -D CMAKE_INSTALL_PREFIX=$cv_install_dir \
	    -D OPENCV_EXTRA_MODULES_PATH=$cv_download_dir/opencv_contrib/modules \
	    -D ENABLE_NEON=ON \
	    -D ENABLE_VFPV3=ON \
            -D BUILD_TESTS=OFF \
            -D OPENCV_ENABLE_NONFREE=ON \
            -D INSTALL_PYTHON_EXAMPLES=OFF \
	    -D INSTALL_C_EXAMPLES=OFF \
	    -D PYTHON_EXECUTABLE=$virtualenv_path/bin/python \
            -D BUILD_EXAMPLES=OFF ..


echo -e "\n\033[91mIncrease the SWAP on the Raspberry Pi\033[0m"
# Increasing the SWAP size will enable to compile OpenCV with all four cores of the Raspberry Pi.
# without the install hanging due to memory exhausting.
		
sudo cp /etc/dphys-swapfile /etc/dphys-swapfile_copy
sudo rm /etc/dphys-swapfile 
echo "CONF_SWAPSIZE=2048" > dphys-swapfile
sudo mv dphys-swapfile /etc/

sudo /etc/init.d/dphys-swapfile stop
sudo /etc/init.d/dphys-swapfile start
	 

# Compile OpenCV4
make -j4
sudo make install
sudo ldconfig

echo -e "\n\033[91mDecrease the SWAP on the Raspberry Pi\033[0m"
sudo rm /etc/dphys-swapfile
sudo mv /etc/dphys-swapfile_copy /etc/dphys-swapfile

sudo /etc/init.d/dphys-swapfile stop
sudo /etc/init.d/dphys-swapfile start


###################################################################################################
Step #6: Link OpenCV 4 into your Python 3 virtual environment
###################################################################################################

echo -e "\n\033[91mStep #5: Link OpenCV 4 into your Python 3 virtual environment\033[0m"

# Rename python bidings
py3_bindings_path=`find $cv_install_dir -name "cv2.cpython-*-arm-linux-gnueabihf.so"`
dir_name=`dirname $py3_bindings_path`
file_name=`basename $py3_bindings_path`
sudo mv $dir_name/$file_name $dir_name/cv2.so

# Link the bindings to your virtual environment
cd `find $py3_virtualenv_dir/$virtualenv_name -name "site-packages"`
ln -s $dir_name/cv2.so cv2.so
###################################################################################################

echo -e "\n\033[91mDone\033[0m"
cd $curr_dir

# to make the file executable, run
# sudo chmod +x install_opencv_4_pi.sh 


