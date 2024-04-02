FROM ros:humble-ros-base-jammy

ARG DEBIAN_FRONTEND=noninteractive
ARG USER_NAME=ardupilot
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd ${USER_NAME} --gid ${USER_GID}\
    && useradd -l -m ${USER_NAME} -u ${USER_UID} -g ${USER_GID} -s /bin/bash

## Install required packages
RUN apt-get update -qq \
    && apt-get upgrade -y \
    && apt-get install --no-install-recommends -y \
    tmux \
    python3-pip

## Install Gazebo 11
# RUN apt-get install aptitude -y \
#     && aptitude install gazebo libgazebo11 libgazebo-dev -y

# RUN apt-get update -qq \
#     && apt-get install -y libboost-thread-dev \
#     libboost-filesystem-dev \
#     libopencv-dev \
#     libeigen3-dev \
#     libgstreamer1.0-dev

## Install Gazebo Harmonic
RUN apt-get update -qq \
    && apt-get install -y lsb-release \
    wget \
    nano \
    gnupg

RUN wget https://packages.osrfoundation.org/gazebo.gpg \
    -O /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg \
    && echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] \
    http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" \
    | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null \
    && apt-get update -qq \
    && apt-get install -y gz-harmonic

## Clone and build Ardupilot Gazebo plugin
# RUN git clone https://github.com/khancyr/ardupilot_gazebo
# RUN cd /ardupilot_gazebo \
#     && mkdir build \
#     && cd build \
#     && cmake .. \
#     && make -j4 \
#     && make install

# RUN echo 'source /usr/share/gazebo/setup.sh' >> ~/.bashrc
# RUN echo 'export GAZEBO_MODEL_PATH=~/ardupilot_gazebo/models' >> ~/.bashrc
# RUN echo 'export GAZEBO_RESOURCE_PATH=~/ardupilot_gazebo/worlds:${GAZEBO_RESOURCE_PATH}' >> ~/.bashrc

## Install Ardupilot Gazebo plugin
RUN apt-get update -qq \
    && apt install -y libgz-sim8-dev rapidjson-dev

RUN export GZ_VERSION=harmonic \
    && git clone https://github.com/ArduPilot/ardupilot_gazebo \
    && cd /ardupilot_gazebo \
    && mkdir build && cd build \
    && cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    && make -j4

ENV GZ_SIM_SYSTEM_PLUGIN_PATH=/ardupilot_gazebo/build:${GZ_SIM_SYSTEM_PLUGIN_PATH}
ENV GZ_SIM_RESOURCE_PATH=/ardupilot_gazebo/models:/ardupilot_gazebo/worlds:${GZ_SIM_RESOURCE_PATH}

## Install Ardupilot Toolchain
COPY Tools/environment_install/install-prereqs-ubuntu.sh /ardupilot/Tools/environment_install/
COPY Tools/completion /ardupilot/Tools/completion

# Create non root user for pip
ENV USER=${USER_NAME}

RUN echo "ardupilot ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER_NAME}
RUN chmod 0440 /etc/sudoers.d/${USER_NAME}

RUN chown -R ${USER_NAME}:${USER_NAME} /${USER_NAME}

USER ${USER_NAME}

RUN /ardupilot/Tools/environment_install/install-prereqs-ubuntu.sh -y

# Remove copied folders
RUN rm -r -f /ardupilot/Tools/

# # Check that local/bin are in PATH for pip --user installed package
RUN echo "if [ -d \"\$HOME/.local/bin\" ] ; then\nPATH=\"\$HOME/.local/bin:\$PATH\"\nfi" >> ~/.ardupilot_env

# Create entrypoint as docker cannot do shell substitution correctly
RUN export ARDUPILOT_ENTRYPOINT="/home/${USER_NAME}/ardupilot_entrypoint.sh" \
    && echo "#!/bin/bash" > $ARDUPILOT_ENTRYPOINT \
    && echo "set -e" >> $ARDUPILOT_ENTRYPOINT \
    && echo "source /home/${USER_NAME}/.ardupilot_env" >> $ARDUPILOT_ENTRYPOINT \
    && echo 'exec "$@"' >> $ARDUPILOT_ENTRYPOINT \
    && chmod +x $ARDUPILOT_ENTRYPOINT \
    && sudo mv $ARDUPILOT_ENTRYPOINT /ardupilot_entrypoint.sh

# Cleanup
RUN sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /ardupilot

ENV CCACHE_MAXSIZE=1G
ENTRYPOINT ["/ardupilot_entrypoint.sh"]
CMD ["bash"]
