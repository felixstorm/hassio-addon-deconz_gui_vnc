FROM marthoc/deconz:armhf

# Install vnc, xvfb in order to create a 'fake' display
RUN apt-get update && \
    apt-get install -y \
        x11vnc \
        xvfb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

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
