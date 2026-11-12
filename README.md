# TortoiseBot Fleet

Colcon workspace and packaging for TortoiseBot on **ROS 2 Lyrical**. This repo clones the robot packages, builds the Docker image, and runs bringup + Cartographer in Gazebo Sim on a laptop or on the Raspberry Pi.

Robot packages (launches, topics, TF, and hardware specs) live in **[tortoisebot](https://github.com/llabhishekll/tortoisebot)**. `tortoisebot.repos` clones that repo into `src/tortoisebot`.

![ros](https://img.shields.io/badge/ROS2-lyrical-red)
![python](https://img.shields.io/badge/python-3.14-blue)
![gz](https://img.shields.io/badge/Gazebo_Sim-10-orange)
![docker](https://img.shields.io/badge/docker-ghcr-blue)
[![docker](https://github.com/llabhishekll/tortoisebot_fleet/actions/workflows/docker.yml/badge.svg)](https://github.com/llabhishekll/tortoisebot_fleet/actions/workflows/docker.yml)
[![tests](https://github.com/llabhishekll/tortoisebot_fleet/actions/workflows/tests.yml/badge.svg)](https://github.com/llabhishekll/tortoisebot_fleet/actions/workflows/tests.yml)

## Structure

```text
.
├── src/                          # vcs import → tortoisebot
├── tortoisebot.repos             # tortoisebot @ main
├── Justfile                      # setup, sim, real, dev, clean
├── Dockerfile                    # ros:lyrical-ros-base + desktop-full
├── compose.yaml                  # --profile sim | real
├── ansible.yaml                  # Docker or ROS 2 install
├── colcon.meta                   # vendor CMake flags
├── .github/                      # Docker, tests, release, Trivy
├── .vscode/                      # Python, Ruff, ROS 2, Docker
├── .devcontainer/                # VS Code / Cursor
└── entrypoint.sh                 # source ROS + install, then exec
```

This folder **is** the workspace.

## Robot

Specs, topics, TF, and `ros2 launch` lines are in [tortoisebot](https://github.com/llabhishekll/tortoisebot).

## Docker

Compose builds and runs `tortoisebot:lyrical`. Gazebo and RViz on a laptop need `xhost +local:docker` first.

```bash
docker compose --profile sim up --build
docker compose --profile real up --build
```

| Profile | Services                    | Starts                                      |
| ------- | --------------------------- | ------------------------------------------- |
| `sim`   | `bringup_sim`, `slam_sim`   | Gazebo bringup + Cartographer, RViz on slam |
| `real`  | `bringup_real`, `slam_real` | Pi bringup + Cartographer                   |

Nav2, waypoints, and intelligence are not in the profile. Open a shell on the bringup service and use the launch lines from tortoisebot:

```bash
docker compose --profile sim exec bringup_sim bash
docker compose --profile real exec bringup_real bash
```

Saved maps are the volumes `tortoisebot_maps_sim` and `tortoisebot_maps_real`. `docker compose down` keeps them.

The published image skips a local Compose build. Tag it `tortoisebot:lyrical` so Compose uses it (`linux/amd64` and `linux/arm64`):

```bash
docker pull ghcr.io/llabhishekll/tortoisebot:latest
docker tag ghcr.io/llabhishekll/tortoisebot:latest tortoisebot:lyrical
```

## Ansible

`ansible.yaml` installs Docker (default) or a ROS 2 workspace and stops. Run it over SSH from a laptop, or on the Pi with the commands below.

From a laptop:

```bash
ansible-playbook ansible.yaml -e host=tortoisebot.local -e user=ubuntu
```

On the Pi, inside a clone:

```bash
ansible-playbook ansible.yaml -e host=localhost -e route=ros2
```

From the playbook file alone:

```bash
sudo apt update && sudo apt install -y ansible
curl -fsSL -o ansible.yaml \
  https://raw.githubusercontent.com/llabhishekll/tortoisebot_fleet/main/ansible.yaml
ansible-playbook ansible.yaml -e host=localhost
```

| Argument | Default                             | Meaning                                       |
| -------- | ----------------------------------- | --------------------------------------------- |
| `host`   | `ROBOT_HOST` or `tortoisebot.local` | SSH target. `localhost` runs on this machine. |
| `user`   | `ROBOT_USER` or `ubuntu`            | SSH user. Unused when `host=localhost`.       |
| `route`  | `docker`                            | `docker` or `ros2`.                           |

Both routes clone `main` into `~/tortoisebot_fleet` and then stop. Add `--ask-become-pass` when sudo needs a password.

## Devcontainer

Browser desktop for editing this workspace. It uses `ghcr.io/tiryoh/ros2-desktop-vnc:lyrical`, not the `tortoisebot` image. The folder is bind-mounted, and the first start imports sources and builds.

Open the folder with the Dev Containers extension in Cursor or VS Code. From a shell:

```bash
npm i -g @devcontainers/cli
just dev
```

Forwarded port **80** is the desktop. The bringup ports from tortoisebot are forwarded as well.

## Just

`just setup` is the native workspace when `/opt/ros/lyrical` is already installed, outside Docker and the devcontainer. Docker profiles are `just sim` and `just real`.

```bash
just setup    # import, rosdep, colcon
just build    # colcon only
just clean    # remove build, install, log
```

## Tools

- **Docker Compose:** [sim and real profiles](https://docs.docker.com/compose/) in `compose.yaml`.
- **just:** [command runner](https://github.com/casey/just) for setup, sim, real, and the devcontainer.
- **Ansible:** [playbook](https://docs.ansible.com/) that installs Docker or ROS 2 and stops.
- **Dev Containers:** [browser desktop](https://containers.dev/) for editing the workspace.
- **ROS image:** [`ros:lyrical-ros-base`](https://hub.docker.com/_/ros), multi-arch base of `tortoisebot:lyrical`.

## License

Apache-2.0. See [`LICENSE`](LICENSE). Vendor trees in `src/tortoisebot/third_party/` keep their upstream licenses.
