# BASE STAGE -----------------------------------------------

FROM ros:lyrical-ros-base AS base

ENV DEBIAN_FRONTEND=noninteractive \
    ROS_DISTRO=lyrical \
    ROS_DOMAIN_ID=0

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python-is-python3 \
    python3-rosdep \
    python3-colcon-common-extensions \
    python3-vcstool \
    git \
    cmake \
    build-essential \
    ros-lyrical-desktop-full \
    ros-lyrical-nav2-bringup \
    ros-lyrical-foxglove-bridge \
    && rm -rf /var/lib/apt/lists/* \
    && (rosdep init || true)

# BUILD STAGE ----------------------------------------------

FROM base AS builder

WORKDIR /ros2_ws
COPY tortoisebot.repos /ros2_ws/tortoisebot.repos
COPY colcon.meta /ros2_ws/colcon.meta
COPY src /ros2_ws/src

RUN apt-get update \
    && vcs import --skip-existing src < /ros2_ws/tortoisebot.repos \
    && . /opt/ros/lyrical/setup.sh \
    && rosdep update --rosdistro lyrical \
    && rosdep install --from-paths src --ignore-src --rosdistro lyrical -y --skip-keys ament_python \
    && rm -rf /var/lib/apt/lists/* \
    && colcon build --metas /ros2_ws/colcon.meta

# PRODUCTION STAGE -----------------------------------------

FROM base AS runner

WORKDIR /ros2_ws
COPY --from=builder /ros2_ws/src /ros2_ws/src
COPY --from=builder /ros2_ws/install /ros2_ws/install
COPY entrypoint.sh /ros2_ws/entrypoint.sh

RUN apt-get update \
    && chmod +x /ros2_ws/entrypoint.sh \
    && . /opt/ros/lyrical/setup.sh \
    && rosdep update --rosdistro lyrical \
    && rosdep install --from-paths src --ignore-src --rosdistro lyrical -y --skip-keys ament_python \
    && rm -rf /var/lib/apt/lists/* \
    && usermod -a -G dialout,video root \
    && echo "source /opt/ros/lyrical/setup.bash" >> ~/.bashrc \
    && echo "source /ros2_ws/install/setup.bash" >> ~/.bashrc

EXPOSE 8000 8080 8765 9090
EXPOSE 7400-8000/udp

ENTRYPOINT ["/ros2_ws/entrypoint.sh"]
CMD ["ros2", "launch", "tortoisebot_bringup", "bringup.launch.py"]
