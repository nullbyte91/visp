FROM ubuntu:20.04
ENV TERM linux
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends locales ca-certificates &&  rm -rf /var/lib/apt/lists/*

# Set the locale to en_US.UTF-8, because the Yocto build fails without any locale set.
RUN locale-gen en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Install apt packages
# Combine update, install and clean commands into a single RUN instruction to reduce the number of layers
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
  git \
  ssh \
  software-properties-common \
  curl \
  locales \
  libfmt-dev \
  nlohmann-json3-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Add GitHub to known hosts for private repositories
RUN mkdir -p ~/.ssh \
  && ssh-keyscan github.com >> ~/.ssh/known_hosts

# Set locale to US English
RUN locale-gen en_US en_US.UTF-8 && \
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 && \
    export LANG=en_US.UTF-8

# Add universe repository
RUN add-apt-repository universe 

RUN apt-get update && apt-get install -y \
    curl \
    gnupg2 \
    lsb-release
    
# Add the ROS package repository
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -
RUN echo "deb http://packages.ros.org/ros/ubuntu focal main" > /etc/apt/sources.list.d/ros.list


# Update and upgrade the system
RUN apt-get update 

# Install pip3 
RUN apt-get -y install python3-pip

# Install ROS1 Desktop
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y ros-noetic-desktop 

# Install requested 3rd parties for ViSP
RUN apt-get update && apt-get -y upgrade
RUN apt --fix-broken install && apt remove -y libdc1394-dev libdc1394-22-dev && apt install -y libdc1394-dev
RUN apt-get -y install libopencv-dev libx11-dev liblapack-dev libeigen3-dev \
         libv4l-dev libzbar-dev libpthread-stubs0-dev libjpeg-dev             \
         libpng-dev libpcl-dev
RUN apt-get install -y liborocos-kdl-dev 

# Build ViSP from source
RUN mkdir -p ~/software/visp && cd ~/software/visp && git clone https://github.com/lagadic/visp.git && \
    mkdir -p visp-build && \
    cd visp-build && \
    cmake ../visp && \
    make -j4

# Build vision_visp ROS package
RUN apt-get install -y ros-noetic-camera-calibration* ros-noetic-image-proc*

SHELL ["/bin/bash", "-c"]
RUN mkdir -p ~/catkin_ws/src && \
    cd ~/catkin_ws/src && \
    git clone https://github.com/lagadic/vision_visp.git --branch noetic && \
    . /opt/ros/noetic/setup.bash && \
    cd ~/catkin_ws/ && \
    catkin_make --cmake-args -DCMAKE_BUILD_TYPE=Release -DVISP_DIR=~/software/visp/visp-build

# Build visp_ros
RUN cd ~/catkin_ws/src && \
    git clone https://github.com/lagadic/visp_ros.git --branch noetic && \
    . /opt/ros/noetic/setup.bash && \
    cd ~/catkin_ws/ && \
    catkin_make --cmake-args -DCMAKE_BUILD_TYPE=Release -DVISP_DIR=~/software/visp/visp-build

# Download Coppeliasim
RUN apt-get install -y wget
RUN mkdir -p ~/software/ && cd ~/software/ && \
    wget https://www.coppeliarobotics.com/files/CoppeliaSim_Edu_V4_2_0_Ubuntu20_04.tar.xz && \
    tar -xvf CoppeliaSim_Edu_V4_2_0_Ubuntu20_04.tar.xz -C ~/software/ 

RUN cd ~/software/CoppeliaSim_Edu_V4_2_0_Ubuntu20_04/programming && mv libPlugin/ libPlugin_orig/

# Get the last version of libPlugin
RUN cd ~/software/CoppeliaSim_Edu_V4_2_0_Ubuntu20_04/programming && \
    git clone https://github.com/CoppeliaRobotics/libPlugin.git --branch coppeliasim-v4.2.0 
    
# Get ROSInterface node source code
RUN cd ~/catkin_ws/src/ && \
    git clone --recursive https://github.com/CoppeliaRobotics/simExtROSInterface.git \
              --branch coppeliasim-v4.2.0 sim_ros_interface

# # Build ROSInterface node
RUN apt-get install -y python3-pip xsltproc 
RUN pip3 install xmlschema
RUN  . /opt/ros/noetic/setup.bash  && \
    export COPPELIASIM_ROOT_DIR=~/software/CoppeliaSim_Edu_V4_2_0_Ubuntu20_04  && \
    cd ~/catkin_ws && catkin_make --cmake-args -DCMAKE_BUILD_TYPE=Release && \
    cp devel/lib/libsimExtROS.so ~/software/CoppeliaSim_Edu_V4_2_0_Ubuntu20_04/

# Copy the entrypoint script into the container
COPY ./entrypoint.sh /

# Make the script executable
RUN chmod +x /entrypoint.sh

# Set the entrypoint script to be run
ENTRYPOINT ["/entrypoint.sh"]


