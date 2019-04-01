
#!/usr/bin/env bash

###################################################################################################
# Step #0: Setup
###################################################################################################

# Path to OpenCV4 download directory
cv_download_dir=/home/miro/opencv_install
# Path to OpenCV4 install directory
# For system wide installation of OpenCV, change cv_install_dir to /usr/local
cv_install_dir=/home/miro/workspace/packages/opencv4
# Path, where you wnat to create your python virtual environment
py3_virtualenv_dir=/home/miro/virtualenv
# Name of your python3 virtual environment
virtualenv_name=env_cv4
# Current directory
curr_dir=`pwd`


##### OPTIONAL #####
# Path to your list with pip packages
# If a package list is not available, leave empy --> packages=""
packages=/home/miro/workspace/requirements/env_cv4


###################################################################################################
# Step #1: Install OpenCV 4 dependencies on Ubuntu
###################################################################################################

echo -e "\n\033[91mStep #1: Install OpenCV 4 dependencies on Ubuntu\033[0m"

# System update
echo -e "\n\033[91m... System update\033[0m"
sudo apt -y update
sudo apt -y upgrade

# Install developer tools
echo -e "\n\033[91m... Install developer tools\033[0m"
sudo apt -y install build-essential cmake ninja unzip pkg-config

# Install image and video I/O libraries
echo -e "\n\033[91m... Install image and video I/O libraries\033[0m"
sudo apt -y install libjpeg-dev libpng-dev libtiff-dev
sudo apt -y install libavcodec-dev libavformat-dev libswscale-dev libv4l-dev
sudo apt -y install libxvidcore-dev libx264-dev
sodo apt -y install libtbb2 libtbb-dev libdc1394-22-dev libavresample-dev

# Install GTK for our GUI backend
echo -e "\n\033[91m... Install GTK for our GUI backend\033[0m"
sudo apt -y install libgtk-3-dev libgtkglext1 libgtkglext1-dev

# Install packages containing mathematical optimizations for OpenCV
echo -e "\n\033[91m... Install packages containing mathematical optimizations for OpenCV\033[0m"
sudo apt -y install libatlas-base-dev gfortran

# Install the Python 3 development headers
echo -e "\n\033[91m... Install the Python 3 development headers\033[0m"
sudo apt -y install python3-dev


###################################################################################################
# Step #2: Download OpenCV 4
###################################################################################################

echo -e "\n\033[91mStep #2: Download OpenCV 4\033[0m"

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
# Step #3: Configure your Python 3 virtual environment for OpenCV 4
###################################################################################################

echo -e "\n\033[91mStep #3: Configure your Python 3 virtual environment for OpenCV 4\033[0m"

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
# Step #4: CMake and compile OpenCV 4 for Ubuntu
###################################################################################################

echo -e "\n\033[91mStep #4: CMake and compile OpenCV 4 for Ubuntu\033[0m"

cd opencv
if [ ! -d "build" ]; then
  mkdir build
fi
cd build

# Run cmake for OpenCV4
cmake -D CMAKE_BUILD_TYPE=RELEASE \
	    -D CMAKE_INSTALL_PREFIX=$cv_install_dir \
	    -D INSTALL_PYTHON_EXAMPLES=ON \
	    -D INSTALL_C_EXAMPLES=ON \
      -D OPENCV_ENABLE_NONFREE=ON \
	    -D OPENCV_EXTRA_MODULES_PATH=$cv_download_dir/opencv_contrib/modules \
	    -D PYTHON_EXECUTABLE=$virtualenv_path/bin/python \
	    -D BUILD_EXAMPLES=ON ..

      # -D WITH_TBB=ON \
      # -D WITH_V4L=ON \
      # -D WITH_QT=ON \
      # -D WITH_OPENGL=ON ..

# Compile OpenCV4
make -j16
sudo make install
sudo ldconfig


###################################################################################################
# Step #5: Link OpenCV 4 into your Python 3 virtual environment
###################################################################################################

echo -e "\n\033[91mStep #5: Link OpenCV 4 into your Python 3 virtual environment\033[0m"

# Rename python bidings
py3_bindings_path=`find $cv_install_dir -name "cv2.cpython-*-x86_64-linux-gnu.so"`
dir_name=`dirname $py3_bindings_path`
file_name=`basename $py3_bindings_path`
sudo mv $dir_name/$file_name $dir_name/cv2.so

# Link the bindings to your virtual environment
cd `find $py3_virtualenv_dir/$virtualenv_name -name "site-packages"`
ln -s $dir_name/cv2.so cv2.so
###################################################################################################

echo -e "\n\033[91mDone\033[0m"
cd $curr_dir
