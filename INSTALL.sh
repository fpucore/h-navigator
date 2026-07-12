#!/bin/bash

# -----------------------------------------------------------------------------
# H Navigator Installer - Version 4.1.0-1
# Copyright (c) 2026 Harmonious Platform Systems
# https://www.freedompublishersunion.net/h-linux.html
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
# -----------------------------------------------------------------------------

# Installation script for H Navigator

# Build package with -i argument removed. Install handled seperately by NLP
makepkg -fC || { echo "Build failed. Aborting."; exit 1; }
#-f - force build
#-C = clean build

# Install package with NLP
nlp -U *.zst

# Backup original launch script
echo "Engaging in pre-patch safety procedure..."
elevate cp -f /opt/hlinux/brave-nightly/brave-browser-nightly /opt/hlinux/brave-nightly/brave-browser-nightly.bk

# Patch the launch script
echo "Installing patch..."
elevate cp -f patch/brave-browser-nightly /opt/hlinux/brave-nightly/brave-browser-nightly
echo "Patched."
echo

# Clean up installation archives
echo "Cleaning up my mess..."
rm *.deb *.zst
rm -fr src/
rm -fr pkg/
echo "Phew... that's done."
echo

# Install additional components for Blackbox-hwm integration
echo "Installing additional system components..."
  # If these two dirs are not created already you are doing something wrong
mkdir -p $HOME/.hwm
mkdir -p $HOME/.hwm/scripts
cp -f components/h_navigator* $HOME/.hwm/scripts
cp -f components/sextant* $HOME/.hwm/scripts
  # Can be executed by pointing H Core to *exec, but symlinked for compatibility
ln -s -f $HOME/.hwm/scripts/h_navigator_exec $HOME/.hwm/scripts/h_navigator
cp -f assets/w3c.png $HOME/Pictures/w3c.png
echo "Additional components installed."
echo

# Build and Installation confirmation
echo
echo "You have successfully installed H Navigator!"
echo

#end
