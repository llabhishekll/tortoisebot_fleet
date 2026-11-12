#!/bin/bash
set -e

# setup ros environment
source "/opt/ros/lyrical/setup.bash"
if [ -f "/ros2_ws/install/setup.bash" ]; then
    source "/ros2_ws/install/setup.bash"
fi

# execute user cmd
exec "$@"
