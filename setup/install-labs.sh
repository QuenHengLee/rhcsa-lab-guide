#!/bin/bash
# install-labs.sh — deploy the RHCSA practice lab framework onto a
# RHEL 10 / Rocky Linux 10 machine (run as root on your practice VM).
#
#   sudo ./setup/install-labs.sh
#
# Afterwards, as any sudo-capable user:
#   lab list
#   lab start storage-partition
#   lab grade storage-partition
#   lab finish storage-partition
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root:  sudo $0" >&2
    exit 1
fi

SRC="$(cd "$(dirname "$0")/.." && pwd)"     # repo root
DEST=/usr/local/share/rhcsa-labs

echo "Installing lab framework into $DEST ..."
install -d -m 755 "$DEST/labs" "$DEST/lib"
install -m 644 "$SRC"/labs/*.lab          "$DEST/labs/"
install -m 644 "$SRC"/setup/lib/common.sh "$DEST/lib/"
install -m 755 "$SRC"/setup/lab           /usr/local/bin/lab

echo "Done. Installed $(ls "$DEST"/labs/*.lab | wc -l) exercises."
echo
echo "Try it:   lab list"
