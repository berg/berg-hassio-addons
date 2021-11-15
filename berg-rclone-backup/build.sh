#!/bin/bash

RCLONE_VERSION="v1.57.0"

case "$(uname -m)" in
  x86_64)
    rclone_arch='amd64'
    ;;
  i?86)
    rclone_arch='386'
    ;;
  aarch64)
    rclone_arch='arm64'
    ;;
  arm*)
    rclone_arch='arm'
    ;;
  *)
    exit 1
    ;;
esac

rclone_dir="rclone-${RCLONE_VERSION}-linux-${rclone_arch}"
rclone_filename="${rclone_dir}.zip"

mkdir /tmp/rclone-build
cd /tmp/rclone-build
curl -O "https://downloads.rclone.org/${RCLONE_VERSION}/${rclone_filename}"
unzip "${rclone_filename}"
cd "${rclone_dir}"
mkdir -p /usr/local/bin
mv rclone /usr/local/bin/
cd /
rm -rf /tmp/rclone-build

mkdir -p -m 0700 /rclone-config