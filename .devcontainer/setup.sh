#!/usr/bin/env bash
#-------------------------------------------------------------------------------
# POST-CREATE WORKSPACE SETUP (.devcontainer/setup.sh)
#-------------------------------------------------------------------------------
# Dispatched by devcontainer.json's postCreateCommand.
#
# Always targets /home/ubuntu/ros2_ws — the bind-mounted workspace root.
# Ensures src/ exists, installs deps from packages under src/, then
# runs colcon build from the workspace root.
#-------------------------------------------------------------------------------

set -euo pipefail

readonly UBUNTU_BASHRC="/home/ubuntu/.bashrc"
readonly WORKSPACE_ROOT="/home/ubuntu/ros2_ws"
readonly ROS_DISTRO="lyrical"

cd "$WORKSPACE_ROOT"
mkdir -p "$WORKSPACE_ROOT/src"
if [ -f "$WORKSPACE_ROOT/tortoisebot.repos" ]; then
    vcs import --skip-existing "$WORKSPACE_ROOT/src" < "$WORKSPACE_ROOT/tortoisebot.repos"
fi

#-------------------------------------------------------------------------------
# SYSTEM DEPENDENCIES & LOCALES
#-------------------------------------------------------------------------------

sudo apt-get update &> /dev/null
sudo apt-get install -y --no-install-recommends \
    locales git cmake build-essential \
    python3-colcon-common-extensions python3-rosdep python3-vcstool
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

source "/opt/ros/$ROS_DISTRO/setup.bash"
sudo rosdep init 2>/dev/null || true
rosdep update --rosdistro "$ROS_DISTRO"
rosdep install --from-paths src --ignore-src --rosdistro "$ROS_DISTRO" -y --skip-keys ament_python

#-------------------------------------------------------------------------------
# WORKSPACE BUILD
#-------------------------------------------------------------------------------

colcon build --symlink-install --metas colcon.meta

#-------------------------------------------------------------------------------
# TERMINAL SPECIFIC CONFIGURATION
#-------------------------------------------------------------------------------

{
    echo "export ROS_DOMAIN_ID=\${ROS_DOMAIN_ID:-0}"
    echo "export PYTHONUNBUFFERED=1"
    echo "source /opt/ros/$ROS_DISTRO/setup.bash"
    echo "source $WORKSPACE_ROOT/install/setup.bash"
    echo "alias run_bridge='ros2 run foxglove_bridge foxglove_bridge'"
    echo "cd $WORKSPACE_ROOT/"
} >> "$UBUNTU_BASHRC"

echo "✓ Workspace ready at $WORKSPACE_ROOT"
