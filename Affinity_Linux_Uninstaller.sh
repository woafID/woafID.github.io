#!/usr/bin/env bash

trap '
    echo "Removal of Linux Affinity has been cancelled."
    exit 0
' SIGINT

if [ "$EUID" -eq 0 ]; then
    echo "Please run as a regular user."
    exit 1
fi

echo "Are you sure you want to remove Linux Affinity and all of its related files? (Y/N)"
read -r response

if [[ $response =~ ^[Yy]$ ]]; then
    rm -fr $HOME/affinity_setup_tmp
    rm -fr $HOME/.wineAffinity
    rm $HOME/.local/share/applications/affinity_designer.desktop
    rm $HOME/.local/share/applications/affinity_photo.desktop
    rm $HOME/.local/share/applications/affinity_publisher.desktop
    sudo rm /usr/local/bin/rum
    sudo rm -fr /opt/wines
    echo Removal of Linux Affinity has finished.
else
    echo "Removal of Linux Affinity has been cancelled."
fi
