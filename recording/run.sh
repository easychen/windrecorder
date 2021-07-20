#!/bin/bash

set -xeo pipefail

BROWSER_URL="$1"
SCREEN_WIDTH=${RECORDING_SCREEN_WIDTH:-'1920'}
SCREEN_HEIGHT=${RECORDING_SCREEN_HEIGHT:-'1080'}
SCREEN_RESOLUTION=${SCREEN_WIDTH}x${SCREEN_HEIGHT}
COLOR_DEPTH=24
X_SERVER_NUM=1

# Start PulseAudio server so Firefox will have somewhere to which to send audio
pulseaudio -D --exit-idle-time=-1
pacmd load-module module-virtual-sink sink_name=v1  # Load a virtual sink as `v1`
pacmd set-default-sink v1  # Set the `v1` as the default sink device
pacmd set-default-source v1.monitor  # Set the monitor of the v1 sink to be the default source

# Start X11 virtual framebuffer so Firefox will have somewhere to draw
Xvfb :${X_SERVER_NUM} -ac -screen 0 ${SCREEN_RESOLUTION}x${COLOR_DEPTH} > /dev/null 2>&1 &
export DISPLAY=:${X_SERVER_NUM}.0
sleep 0.5  # Ensure this has started before moving on

# Create a new Firefox profile for capturing preferences for this
firefox --no-remote --new-instance --createprofile "foo4 /tmp/foo4"

# Install the OpenH264 plugin for Firefox
mkdir -p /tmp/foo4/gmp-gmpopenh264/1.8.1.1/

cp -rf /tmp/h264/* /tmp/foo4/gmp-gmpopenh264/1.8.1.1/

# pushd /tmp/foo4/gmp-gmpopenh264/1.8.1.1 >& /dev/null
# curl -s -O http://ciscobinary.openh264.org/openh264-linux64-2e1774ab6dc6c43debb0b5b628bdf122a391d521.zip
# unzip openh264-linux64-2e1774ab6dc6c43debb0b5b628bdf122a391d521.zip
# rm -f openh264-linux64-2e1774ab6dc6c43debb0b5b628bdf122a391d521.zip
# popd >& /dev/null

# Set the Firefox preferences to enable automatic media playing with no user
# interaction and the use of the OpenH264 plugin.
# media.setsinkid.enabled is recommended for firefox: https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/setSinkId
cat <<EOF >> /tmp/foo4/prefs.js
user_pref("media.autoplay.default", 0);
user_pref("media.autoplay.enabled.user-gestures-needed", false);
user_pref("media.navigator.permission.disabled", true);
user_pref("media.gmp-gmpopenh264.abi", "x86_64-gcc3");
user_pref("media.gmp-gmpopenh264.lastUpdate", 1571534329);
user_pref("media.gmp-gmpopenh264.version", "1.8.1.1");
user_pref("doh-rollout.doorhanger-shown", true);
user_pref("media.setsinkid.enabled", true);
EOF

# Start Firefox browser and point it at the URL we want to capture
#
# NB: The `--width` and `--height` arguments have to be very early in the
# argument list or else only a white screen will result in the capture for some
# reason.

firefox \
  -P foo4 \
  --width ${SCREEN_WIDTH} \
  --height ${SCREEN_HEIGHT} \
  --new-instance \
  --first-startup \
  --foreground \
  --kiosk \
  --ssb ${BROWSER_URL} \
  &
sleep 1  # Ensure this has started before moving on
xdotool mousemove 1 1 click 1  # Move mouse out of the way so it doesn't trigger the "pause" overlay on the video tile

x11vnc -display :1 &

exec node /recording/record.js ${BROWSER_URL} ${SCREEN_WIDTH} ${SCREEN_HEIGHT}

# tail -f /data/demo.txt
