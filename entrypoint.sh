#!/bin/bash
# source the ROS2 setup
source /opt/ros/noetic/setup.bash

# Execute the CMD from the Dockerfile
exec "$@"