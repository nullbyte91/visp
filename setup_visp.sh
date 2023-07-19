#!/bin/bash

# Set your workspace path
VISP_WS=$HOME/visp-ws

# Define a function for installations
install_packages() {
    sudo apt-get update -y
    sudo apt-get install -y build-essential cmake-curses-gui git subversion wget libopencv-dev libx11-dev liblapack-dev libeigen3-dev libv4l-dev libzbar-dev libpthread-stubs0-dev libjpeg-dev libpng-dev libdc1394-22-dev
}

# Define a function for setting environment variables
set_environment() {
    echo "export VISP_WS=$VISP_WS" >> ~/.bashrc
    echo "export VISP_DIR=$VISP_WS/visp-build" >> ~/.bashrc
    echo "export VISP_INPUT_IMAGE_PATH=$VISP_WS/visp-images-3.5.0" >> ~/.bashrc
    source ~/.bashrc
}

# Define a function for building ViSP
build_visp() {
    mkdir -p $VISP_WS
    cd $VISP_WS
    git clone https://github.com/lagadic/visp.git
    mkdir -p $VISP_WS/visp-build
    cd $VISP_WS/visp-build
    cmake ../visp
    make -j4
}

# Define a function for downloading ViSP images
download_images() {
    wget https://visp-doc.inria.fr/download/dataset/visp-images-3.5.0.tar.gz
    tar -xvf visp-images-3.5.0.tar.gz
}

# Start the installations, build, and download processes
install_packages
set_environment
build_visp
download_images

# Test
./example/device/display/displayX

echo "Installation completed!"
