#!/bin/bash

# -----------------------------------------------------------------------------
# H Navigator Installer - Version 4.0.0-2
# Copyright (c) 2026 Harmonious Platform Systems
# https://www.freedompublishersunion.net/h-linux.html
#
# This Source Code Form is subject to the terms of the Mozilla Public 
# License, v. 2.0. If a copy of the MPL was not distributed with this 
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
# -----------------------------------------------------------------------------

# Installation script for H Navigator

# Build and Install the packages
makepkg -iC || { echo "Build failed. Aborting."; exit 1; }
# -i = install, C = clean build

# Backup original launch script
echo "Engaging in pre-patch safety procedure..."
sudo cp /opt/hlinux/brave-nightly/brave-browser-nightly /opt/hlinux/brave-nightly/brave-browser-nightly.bk

# Patch the launch script
echo "Installing patch..."
sudo cp patch/brave-browser-nightly /opt/hlinux/brave-nightly/brave-browser-nightly
echo "Patched."
echo

# Clean up installation archives
echo "Cleaning up my mess..."
rm *.deb *.zst
echo "Phew... that's done."
echo

# Install additional components for Blackbox-hwm integration
echo "Installing additional system components..."
  # If these two dirs are not created already you are doing something wrong
mkdir -p $HOME/.hwm
mkdir -p $HOME/.hwm/scripts
cp components/h_navigator* $HOME/.hwm/scripts
cp components/sextant* $HOME/.hwm/scripts
  # Can be executed by pointing H Core to *exec, but symlinked for compatibility
ln -s $HOME/.hwm/scripts/h_navigator_exec $HOME/.hwm/scripts/h_navigator
cp assets/w3c.png $HOME/Pictures/w3c.png
echo "Additional components installed."
echo

# Build and Installation confirmation
echo
echo "You have successfully installed H Navigator!"
echo

#end
