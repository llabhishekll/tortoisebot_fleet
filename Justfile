set shell := ["bash", "-c"]

@default:
    just --list

# SETUP ----------------------------------------------------

# Import sources, install deps, and build the workspace.
[group("Setup")]
setup:
    just import
    just deps
    just build
    @echo "[✓] Setup complete."

# Clone the tortoisebot packages into src/.
[group("Setup")]
import:
    mkdir -p src
    vcs import --skip-existing src < tortoisebot.repos

# Install ROS package dependencies with rosdep.
[group("Setup")]
deps:
    #!/usr/bin/env bash
    source /opt/ros/lyrical/setup.bash
    sudo rosdep init 2>/dev/null || true
    rosdep update --rosdistro lyrical
    rosdep install --from-paths src --ignore-src --rosdistro lyrical -y --skip-keys ament_python

# Build the workspace with colcon.
[group("Setup")]
build *ARGS:
    #!/usr/bin/env bash
    source /opt/ros/lyrical/setup.bash
    if [ -f install/setup.bash ]; then source install/setup.bash; fi
    colcon build --symlink-install --metas colcon.meta {{ARGS}}

# DOCKER ---------------------------------------------------

# Run the Gazebo simulation stack.
[group("Docker")]
sim:
    xhost +local:docker 2>/dev/null || true
    docker compose --profile sim up --build

# Run the real robot stack.
[group("Docker")]
real:
    docker compose --profile real up --build

# DEVCONTAINER ---------------------------------------------

# Open the project in a devcontainer.
[group("Devcontainer")]
dev:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v devcontainer >/dev/null 2>&1; then
      echo "Install the Dev Containers CLI: npm i -g @devcontainers/cli"
      exit 1
    fi
    devcontainer up --workspace-folder .

# MAINTENANCE ----------------------------------------------

# Delete build, install, and log folders.
[group("Maintenance")]
clean:
    rm -rf build install log
    find . -type d -name "__pycache__" -exec rm -r {} + 2>/dev/null || true
    @echo "[✓] Build artifacts cleaned."
