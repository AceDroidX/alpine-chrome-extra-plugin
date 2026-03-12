#!/bin/sh

set -eu

PIDS=""

start_log_forwarder() {
    logfile="$1"
    : > "$logfile"
    tail -n +1 -F "$logfile" &
    PIDS="$PIDS $!"
}

require_running() {
    pid="$1"
    name="$2"
    if ! kill -0 "$pid" 2>/dev/null; then
        echo "$name failed to start" >&2
        exit 1
    fi
}

cleanup() {
    if [ -n "$PIDS" ]; then
        kill $PIDS 2>/dev/null || true
        wait $PIDS 2>/dev/null || true
    fi
}

trap cleanup EXIT INT TERM

echo "Starting Xvfb on $DISPLAY"
start_log_forwarder /tmp/xvfb.log
Xvfb "$DISPLAY" -screen "$XVFB_SCREEN" "$XVFB_WHD" >/tmp/xvfb.log 2>&1 &
PIDS="$PIDS $!"

sleep 2
require_running "$!" "Xvfb"

if [ "${ENABLE_NOVNC:-false}" = "true" ]; then
    echo "Starting x11vnc on port $VNC_PORT"
    start_log_forwarder /tmp/x11vnc.log
    x11vnc -display "$DISPLAY" -forever -shared -nopw -rfbport "$VNC_PORT" -listen 0.0.0.0 -no6 -xkb >/tmp/x11vnc.log 2>&1 &
    PIDS="$PIDS $!"
    sleep 1
    require_running "$!" "x11vnc"

    echo "Starting websockify on port $NOVNC_PORT"
    start_log_forwarder /tmp/websockify.log
    websockify --web /usr/share/novnc 0.0.0.0:"$NOVNC_PORT" 127.0.0.1:"$VNC_PORT" >/tmp/websockify.log 2>&1 &
    PIDS="$PIDS $!"
    sleep 1
    require_running "$!" "websockify"
fi

echo "Starting socat on port $DEVTOOLS_PORT"
start_log_forwarder /tmp/socat.log
socat TCP-LISTEN:"$DEVTOOLS_PORT",fork,reuseaddr TCP:127.0.0.1:"$CHROME_DEBUG_PORT" >/tmp/socat.log 2>&1 &
PIDS="$PIDS $!"
sleep 1
require_running "$!" "socat"

echo "Starting node index.ts"
node index.ts
