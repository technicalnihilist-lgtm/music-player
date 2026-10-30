#!/bin/bash
# Build Glass Player without Gradle, using the Android SDK command line tools.
#
# Requirements:
#   - JDK 17
#   - Android SDK: platforms/android-34, build-tools/34.0.0
#
# Usage:
#   ANDROID_SDK_ROOT=/path/to/android-sdk bash build.sh
#
# Output: build/GlassPlayer.apk (debug-signed, ready to install)

set -e

: "${ANDROID_SDK_ROOT:?set ANDROID_SDK_ROOT to your Android SDK path}"
BT="$ANDROID_SDK_ROOT/build-tools/34.0.0"
PLAT="$ANDROID_SDK_ROOT/platforms/android-34/android.jar"
PROJ="$(cd "$(dirname "$0")" && pwd)/app"
OUT="$PROJ/build"

rm -rf "$OUT"
mkdir -p "$OUT/gen" "$OUT/classes"

echo "== aapt2 compile =="
"$BT/aapt2" compile --dir "$PROJ/src/main/res" -o "$OUT/res.zip"

echo "== aapt2 link =="
"$BT/aapt2" link -o "$OUT/app-unsigned.apk" \
  -I "$PLAT" \
  --manifest "$PROJ/src/main/AndroidManifest.xml" \
  -R "$OUT/res.zip" \
  -A "$PROJ/src/main/assets" \
  --java "$OUT/gen" \
  --min-sdk-version 24 --target-sdk-version 34 \
  --auto-add-overlay

echo "== javac =="
javac -nowarn -source 8 -target 8 -classpath "$PLAT" -d "$OUT/classes" \
  $(find "$PROJ/src/main/java" "$OUT/gen" -name '*.java')

echo "== d8 =="
"$BT/d8" --lib "$PLAT" --min-api 24 --output "$OUT" $(find "$OUT/classes" -name '*.class')

echo "== package dex =="
( cd "$OUT" && zip -q app-unsigned.apk classes.dex )

echo "== zipalign =="
"$BT/zipalign" -f -p 4 "$OUT/app-unsigned.apk" "$OUT/app-aligned.apk"

echo "== keystore =="
if [ ! -f "$PROJ/glassplayer.keystore" ]; then
  keytool -genkeypair -v -keystore "$PROJ/glassplayer.keystore" \
    -alias glassplayer -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass glassplayer -keypass glassplayer \
    -dname "CN=Glass Player, OU=Mobile, O=Glass Player, L=Mumbai, S=Maharashtra, C=IN"
fi

echo "== apksigner =="
"$BT/apksigner" sign --ks "$PROJ/glassplayer.keystore" \
  --ks-pass pass:glassplayer --key-pass pass:glassplayer \
  --ks-key-alias glassplayer \
  --out "$OUT/GlassPlayer.apk" "$OUT/app-aligned.apk"

"$BT/apksigner" verify --print-certs "$OUT/GlassPlayer.apk" | head -3
echo "built: $OUT/GlassPlayer.apk"
