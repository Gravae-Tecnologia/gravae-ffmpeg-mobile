#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

aar="$(find "$SOURCE_DIR/prebuilt" -type f -name 'ffmpeg-kit.aar' -print -quit)"
if [[ -z "$aar" ]]; then
  echo "[ffmpeg-mobile] AAR não encontrado." >&2
  exit 1
fi

stage="$WORK_DIR/package-android"
"$SCRIPT_DIR/fetch-ca-bundle.sh"
artifact_path="${ANDROID_MAVEN_GROUP//./\/}/$ANDROID_MAVEN_ARTIFACT/$ANDROID_MAVEN_VERSION"
rm -rf "$stage"
mkdir -p "$stage/android/maven/$artifact_path" "$stage/metadata"
cp "$aar" "$stage/android/maven/$artifact_path/$ANDROID_MAVEN_ARTIFACT-$ANDROID_MAVEN_VERSION.aar"
cat > "$stage/android/maven/$artifact_path/$ANDROID_MAVEN_ARTIFACT-$ANDROID_MAVEN_VERSION.pom" <<POM
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>$ANDROID_MAVEN_GROUP</groupId>
  <artifactId>$ANDROID_MAVEN_ARTIFACT</artifactId>
  <version>$ANDROID_MAVEN_VERSION</version>
  <packaging>aar</packaging>
  <dependencies>
    <dependency>
      <groupId>com.arthenica</groupId>
      <artifactId>smart-exception-java</artifactId>
      <version>0.2.1</version>
    </dependency>
  </dependencies>
</project>
POM
cp "$ROOT_DIR/config/build.env" "$stage/metadata/build.env"
cp "$ROOT_DIR/config/required-capabilities.txt" "$stage/metadata/required-capabilities.txt"
cp "$ROOT_DIR/THIRD_PARTY_NOTICES.md" "$stage/metadata/THIRD_PARTY_NOTICES.md"
cp "$WORK_DIR/cacert.pem" "$stage/metadata/cacert.pem"
cp "$SOURCE_DIR/build.log" "$stage/metadata/android-build.log"

mkdir -p "$DIST_DIR"
tar -czf "$DIST_DIR/gravae-ffmpeg-android-$FFMPEG_MOBILE_VERSION.tar.gz" -C "$stage" .
