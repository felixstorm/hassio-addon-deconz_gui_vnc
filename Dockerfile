### Copied from https://github.com/marthoc/docker-deconz/blob/master/armhf/Dockerfile
###

FROM resin/armv7hf-debian:stretch

# Build environment variables
ENV TINI_VERSION=0.18.0 \
    DECONZ_VERSION=2.05.44 \
    WIRINGPI_VERSION="2.44+1"

# Runtime environment variables
ENV DECONZ_WEB_PORT=80 \
    DECONZ_WS_PORT=443 \
    DEBUG_INFO=1 \
    DEBUG_APS=0 \
    DEBUG_ZCL=0 \
    DEBUG_ZDP=0 \
    DEBUG_OTAU=0

# Install deCONZ dependencies (except for WiringPi)
RUN apt-get update && \
    apt-get install -y \
        curl \
        jq \
        kmod \
        libcap2-bin \
        libqt5core5a \
        libqt5gui5 \
        libqt5network5 \
        libqt5serialport5 \
        libqt5sql5 \
        libqt5websockets5 \
        libqt5widgets5 \
        sqlite3 \
        wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add WiringPi, install WiringPi
ADD https://archive.raspberrypi.org/debian/pool/main/w/wiringpi/wiringpi_${WIRINGPI_VERSION}_armhf.deb /wiringpi.deb
RUN dpkg -i /wiringpi.deb && \
    rm -f /wiringpi.deb

# Add tini, start.sh, and Conbee udev data; set execute permissions
ADD https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-armhf /tini
COPY root /
RUN chmod +x /tini && \
    chmod +x /start.sh && \
    chmod +x /firmware-update.sh

# Add deCONZ, install deCONZ, make OTAU dir
ADD https://www.dresden-elektronik.de/rpi/deconz/beta/deconz-${DECONZ_VERSION}-qt5.deb /deconz.deb
RUN dpkg -i /deconz.deb && \
    rm -f /deconz.deb && \
    mkdir /root/otau && \
    chown root:root /usr/bin/deCONZ*

VOLUME [ "/root/.local/share/dresden-elektronik/deCONZ" ]

EXPOSE ${DECONZ_WEB_PORT} ${DECONZ_WS_PORT}


### Copied from https://github.com/felixstorm/hassio-addon-deconz_gui_vnc/blob/master/Dockerfile
### and added VNC, deconz-cli-plugin etc.
###

# Install vnc, xvfb in order to create a 'fake' display
RUN apt-get update && apt-get install -y \
        x11vnc \
        xvfb \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install deCONZ development package for deconz-cli-plugin & deconz-rest-plugin
ADD http://www.dresden-elektronik.de/rpi/deconz-dev/deconz-dev-${DECONZ_VERSION}.deb /deconz-dev.deb
RUN apt update && apt install -y \
        build-essential \
        git \
        libqt5serialport5-dev \
        libqt5websockets5-dev \
        libsqlite3-dev \
        netcat \
        qt5-default \
        qt5-qmake \
    && dpkg -i /deconz-dev.deb && \
    apt clean && rm -rf /var/lib/apt/lists/* && rm -f /deconz-dev.deb
# Install deconz-cli-plugin
RUN git clone https://github.com/ma-ca/deconz-cli-plugin.git && \
    cd deconz-cli-plugin && \
    qmake && make -j2 && \
    cp libdeconz_cli_plugin.so /usr/share/deCONZ/plugins && \
    cd .. && \
    rm -rf deconz-cli-plugin
# Install deconz-rest-plugin
RUN git clone https://github.com/felixstorm/deconz-rest-plugin.git && \
    cd deconz-rest-plugin && \
    qmake && make -j2 && \
    cp ../libde_rest_plugin.so /usr/share/deCONZ/plugins && \
    cd .. && \
    rm -rf deconz-rest-plugin

# Add Hass.io-specific start script
COPY run-with-vnc.sh /
RUN chmod +x /run-with-vnc.sh

# Copy ZCL Definitions for ubisys J1
COPY deconz_zcl_ubisys_j1.xml /usr/share/deCONZ/zcl

# Create directory for persistent Hass.io config data
# Workaround to persist ZigBee network data: change root's home dir to /data
RUN mkdir /data && \
    sed -i 's/\/root/\/data/' /etc/passwd && \
    chown root:root /usr/bin/deCONZ*
VOLUME [ "/data" ]

# Hass.io-specific labels
LABEL io.hass.version="${DECONZ_VERSION}" \ 
      io.hass.type="addon" \
      io.hass.arch="armhf"

ENTRYPOINT [ "/tini", "-s", "--", "/run-with-vnc.sh" ]
