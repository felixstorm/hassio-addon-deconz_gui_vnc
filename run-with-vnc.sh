#!/bin/sh

CONFIG_PATH=/data/options.json

HASSIO_DEBUG_INFO="$(jq --raw-output '.debug_info' $CONFIG_PATH)"
HASSIO_DEBUG_APS="$(jq --raw-output '.debug_aps' $CONFIG_PATH)"
HASSIO_DEBUG_ZCL="$(jq --raw-output '.debug_zcl' $CONFIG_PATH)"
HASSIO_DEBUG_ZDP="$(jq --raw-output '.debug_zdp' $CONFIG_PATH)"
HASSIO_DEBUG_OTAU="$(jq --raw-output '.debug_otau' $CONFIG_PATH)"
HASSIO_DECONZ_WEB_PORT="$(jq --raw-output '.web_port' $CONFIG_PATH)"
HASSIO_DECONZ_WS_PORT="$(jq --raw-output '.websockets_port' $CONFIG_PATH)"

HASSIO_DECONZ_VNC_PORT="$(jq --raw-output '.vnc_port' $CONFIG_PATH)"
HASSIO_DECONZ_VNC_PASSWORD="$(jq --raw-output '.vnc_password' $CONFIG_PATH)"
HASSIO_DECONZ_VNC_SCREEN="$(jq --raw-output '.vnc_screen' $CONFIG_PATH)"

echo "[Hass.io] Starting deCONZ Hass.io Addon..."
echo "[Hass.io] Current deCONZ version: $DECONZ_VERSION"
echo "[Hass.io] Web UI port: $HASSIO_DECONZ_WEB_PORT"
echo "[Hass.io] Websockets port: $HASSIO_DECONZ_WS_PORT"
echo "[Hass.io] VNC server port: $HASSIO_DECONZ_VNC_PORT"

export DISPLAY=:0
Xvfb :0 -screen 0 $HASSIO_DECONZ_VNC_SCREEN &
x11vnc -passwd $HASSIO_DECONZ_VNC_PASSWORD -display :0 -rfbport $HASSIO_DECONZ_VNC_PORT -forever &

/usr/bin/deCONZ \
    --auto-connect=1 \
    --dbg-info=$HASSIO_DEBUG_INFO \
    --dbg-aps=$HASSIO_DEBUG_APS \
    --dbg-zcl=$HASSIO_DEBUG_ZCL \
    --dbg-zdp=$HASSIO_DEBUG_ZDP \
    --dbg-otau=$HASSIO_DEBUG_OTAU \
    --http-port=$HASSIO_DECONZ_WEB_PORT \
    --ws-port=$HASSIO_DECONZ_WS_PORT