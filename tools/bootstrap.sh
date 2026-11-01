#!/bin/bash
# Installs a build toolchain for Glass Player into /scratch/work/tools.
# Idempotent: skips anything already present. Safe to run on every scheduled job.
set -e

T=/scratch/work/tools
mkdir -p "$T"

JDK="$T/jdk-17.0.21+9"
if [ ! -x "$JDK/bin/java" ]; then
  echo "== fetching JDK 17 =="
  curl -sL -o "$T/jdk.tar.gz" \
    "https://api.adoptium.net/v3/binary/latest/17/ga/linux/x64/jdk/hotspot/normal/eclipse"
  tar -xzf "$T/jdk.tar.gz" -C "$T"
fi

BT="$T/sdk/build-tools/34.0.0"
if [ ! -x "$BT/aapt2" ]; then
  echo "== fetching build-tools 34 =="
  curl -sL -o "$T/bt34.zip" "https://dl.google.com/android/repository/build-tools_r34-linux.zip"
  mkdir -p "$T/sdk/build-tools"
  unzip -q -o "$T/bt34.zip" -d "$T/sdk/build-tools"
  [ -d "$T/sdk/build-tools/android-14" ] && mv "$T/sdk/build-tools/android-14" "$BT"
fi

PL="$T/sdk/platforms/android-34"
if [ ! -f "$PL/android.jar" ]; then
  echo "== fetching platform 34 =="
  curl -sL -o "$T/plat34.zip" \
    "https://dl.google.com/android/repository/platform-UpsideDownCake_r04.zip"
  mkdir -p "$T/sdk/platforms"
  unzip -q -o "$T/plat34.zip" -d "$T/sdk/platforms"
  [ -d "$T/sdk/platforms/android-UpsideDownCake" ] && mv "$T/sdk/platforms/android-UpsideDownCake" "$PL"
fi

# write an env file the runbook can source
cat > "$T/env.sh" <<EOF
export JAVA_HOME="$JDK"
export ANDROID_SDK_ROOT="$T/sdk"
export PATH="$JDK/bin:\$PATH"
# the sandbox caps address space at 1.5 GB; keep the JVM inside it
export JAVA_TOOL_OPTIONS="-Xmx224m -Xms32m -Xss256k -XX:MaxMetaspaceSize=96m -XX:CompressedClassSpaceSize=48m -XX:ReservedCodeCacheSize=16m -XX:TieredStopAtLevel=1 -XX:+UseSerialGC -XX:-UsePerfData -Xshare:off"
export JAVA_OPTS="$JAVA_TOOL_OPTIONS"
export D8_JOPTS="-JXmx224m -JXss256k -JXX:MaxMetaspaceSize=96m -JXX:CompressedClassSpaceSize=48m -JXX:ReservedCodeCacheSize=16m -JXX:TieredStopAtLevel=1 -JXX:+UseSerialGC -JXX:-UsePerfData -JXshare:off"
EOF

echo "toolchain ready: $JDK | $(ls "$BT" | wc -l) build-tools | $PL/android.jar"
