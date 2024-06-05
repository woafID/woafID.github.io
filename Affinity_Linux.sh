#!/usr/bin/env bash

trap '
    echo "Operation interrupted... Cleaning up..."

    # Remove temporary setup files
    rm -fr $HOME/affinity_setup_tmp

    # Remove Affinity-related files and directories
    rm -fr $HOME/.wineAffinity
    rm $HOME/.local/share/applications/affinity_designer.desktop
    rm $HOME/.local/share/applications/affinity_photo.desktop
    rm $HOME/.local/share/applications/affinity_publisher.desktop

    # Remove the rum command
    sudo rm /usr/local/bin/rum
    
    # Remove wines directory
    sudo rm -fr /opt/wines

    # Exit the script gracefully
    exit 0
' SIGINT

# Root check
if [ "$EUID" -eq 0 ]; then
    echo "Please run as a regular user."
    exit 1
fi

# Install Dependencies (we need firejail to prevent the apps from accessing the network.) If you have trouble with the activation window and you uncommented the lines responsible for cracking the software, this is especially relevant, since you never want patched software to access the network. Even though i included the safest version out there, its still good practice.

# VirusTotal results of the cracks for reference:
# Designer	https://www.virustotal.com/gui/file/a30ea21111d5d7e3b2d72c5f65ea0eb068aac0d4e355579f1afec5206793d387
# Photo		https://www.virustotal.com/gui/file/863d7d1f26fb61da452f6e6dc68a2d6ca6335c98d06541e3d9fddc703f74edf7
# Publisher	https://www.virustotal.com/gui/file/f43fbc18682196b3da9b5fd1ef82aad45172319617c3a3dc42b6f435f919367f

if command -v apt &> /dev/null; then
  sudo apt install git winetricks firejail p7zip zenity -y
elif command -v pacman &> /dev/null; then
  sudo pacman -S git winetricks firejail p7zip zenity --noconfirm
elif command -v dnf &> /dev/null; then
  sudo dnf install git winetricks firejail p7zip zenity -y
else
  echo "Error: Package manager (apt, pacman, or dnf) not found."
  exit
fi

# Install rum
git clone https://gitlab.com/xkero/rum.git/ $HOME/affinity_setup_tmp/rum
sudo cp $HOME/affinity_setup_tmp/rum/rum /usr/local/bin/rum

## Getting Wine
echo "downloading wine..."
wget -q --show-progress https://github.com/woafID/psychic-engine/releases/download/wine/ElementalWarrior-wine.7z -O $HOME/affinity_setup_tmp/ElementalWarrior-wine.7z

echo "extracting..."
7z x $HOME/affinity_setup_tmp/ElementalWarrior-wine.7z -o$HOME/affinity_setup_tmp/

if [ ! -d "/opt/wines" ]; then
  sudo mkdir -p "/opt/wines"
fi

sudo cp --recursive "$HOME/affinity_setup_tmp/ElementalWarrior-wine/wine-install" "/opt/wines/ElementalWarrior-8.14"

# Link wine to fix an issue because it does not have a 64bit binary?
sudo ln -s /opt/wines/ElementalWarrior-8.14/bin/wine /opt/wines/ElementalWarrior-8.14/bin/wine64

zenity --info --text="You may get prompted to install Wine Mono, in the next section. Please proceed with installing it. dotnet installation will be silent. Be patient."

y | rum ElementalWarrior-8.14 $HOME/.wineAffinity wineboot --init
rum ElementalWarrior-8.14 $HOME/.wineAffinity winetricks -q dotnet48 corefonts | zenity --progress --pulsate --title="Installing Dependencies" --text="This will take a few minutes... If you're curious, you can see the running installers in the System Monitor app." --auto-close --no-cancel
rum ElementalWarrior-8.14 $HOME/.wineAffinity wine winecfg -v win11

# You can extract these files yourself manually from any windows 10 or 11 installation. Just copy the WinMetadata folder from System32 to this path i specified.
wget -q --show-progress https://github.com/woafID/psychic-engine/releases/download/winmd/winmd.7z -O $HOME/affinity_setup_tmp/winmd.7z
7z x $HOME/affinity_setup_tmp/winmd.7z -o$HOME/.wineAffinity/drive_c/windows/system32/WinMetadata

# Download signed installers
echo "Downloading installers... Dont interrupt it, even if you dont need a specific app. You can remove them afterwards. This script doesn't do propper error handling."
wget -q --show-progress https://github.com/woafID/psychic-engine/releases/download/setup/affinity-designer-msi-2.3.1.exe -O $HOME/affinity_setup_tmp/affinity-designer-msi-2.3.1.exe
wget -q --show-progress https://github.com/woafID/psychic-engine/releases/download/setup/affinity-photo-msi-2.3.1.exe -O $HOME/affinity_setup_tmp/affinity-photo-msi-2.3.1.exe
wget -q --show-progress https://github.com/woafID/psychic-engine/releases/download/setup/affinity-publisher-msi-2.3.1.exe -O $HOME/affinity_setup_tmp/affinity-publisher-msi-2.3.1.exe

# Run setups
zenity --info --text="Please run all of the installers."
rum ElementalWarrior-8.14 $HOME/.wineAffinity wine $HOME/affinity_setup_tmp/affinity-designer-msi-2.3.1.exe
rum ElementalWarrior-8.14 $HOME/.wineAffinity wine $HOME/affinity_setup_tmp/affinity-photo-msi-2.3.1.exe
rum ElementalWarrior-8.14 $HOME/.wineAffinity wine $HOME/affinity_setup_tmp/affinity-publisher-msi-2.3.1.exe

# Prevent crash_handler from running by renaming it, because its not needed. App wont have network access anyways.
mv $HOME/.wineAffinity/drive_c/Program\ Files/Affinity/Designer\ 2/crashpad_handler.exe $HOME/.wineAffinity/drive_c/Program\ Files/Affinity/Designer\ 2/crashpad_handler.exe.bak
mv $HOME/.wineAffinity/drive_c/Program\ Files/Affinity/Photo\ 2/crashpad_handler.exe $HOME/.wineAffinity/drive_c/Program\ Files/Affinity/Photo\ 2/crashpad_handler.exe.bak
mv $HOME/.wineAffinity/drive_c/Program\ Files/Affinity/Publisher\ 2/crashpad_handler.exe $HOME/.wineAffinity/drive_c/Program\ Files/Affinity/Publisher\ 2/crashpad_handler.exe.bak

# Uncomment the following lines if you have trouble with the activation window. I'am not responsible for any use of the products without valid licenses.
#echo "applying medicine..."
#wget -q --show-progress https://github.com/woafID/psychic-engine/releases/download/patched_dlls/patched_dlls.7z -O $HOME/affinity_setup_tmp/patched_dlls.7z
#7z x $HOME/affinity_setup_tmp/patched_dlls.7z -o$HOME/affinity_setup_tmp/
#cp -f $HOME/affinity_setup_tmp/patched_dlls/for_designer/libaffinity.dll	$HOME/.wineAffinity/drive_c/Program\ Files/Affinity/Designer\ 2/
#cp -f $HOME/affinity_setup_tmp/patched_dlls/for_photo/libaffinity.dll		$HOME/.wineAffinity/drive_c/Program\ Files/Affinity/Photo\ 2/
#cp -f $HOME/affinity_setup_tmp/patched_dlls/for_publisher/libaffinity.dll 	$HOME/.wineAffinity/drive_c/Program\ Files/Affinity/Publisher\ 2/

echo "creating launchers..."
mkdir $HOME/.wineAffinity/drive_c/launchers
echo 'firejail --noprofile --net=none rum ElementalWarrior-8.14 $HOME/.wineAffinity wine "$HOME/.wineAffinity/drive_c/Program Files/Affinity/Designer 2/Designer.exe"' > $HOME/.wineAffinity/drive_c/launchers/designer2.sh
echo 'firejail --noprofile --net=none rum ElementalWarrior-8.14 $HOME/.wineAffinity wine "$HOME/.wineAffinity/drive_c/Program Files/Affinity/Photo 2/Photo.exe"' > $HOME/.wineAffinity/drive_c/launchers/photo2.sh
echo 'firejail --noprofile --net=none rum ElementalWarrior-8.14 $HOME/.wineAffinity wine "$HOME/.wineAffinity/drive_c/Program Files/Affinity/Publisher 2/Publisher.exe"' > $HOME/.wineAffinity/drive_c/launchers/publisher2.sh

chmod u+x $HOME/.wineAffinity/drive_c/launchers/designer2.sh
chmod u+x $HOME/.wineAffinity/drive_c/launchers/photo2.sh
chmod u+x $HOME/.wineAffinity/drive_c/launchers/publisher2.sh


echo "adding desktop icons..."
mkdir -p $HOME/.wineAffinity/drive_c/launchers/icos
wget -q --show-progress https://github.com/woafID/psychic-engine/releases/download/icons/designer.svg -O 	$HOME/.wineAffinity/drive_c/launchers/icos/designer.svg
wget -q --show-progress https://github.com/woafID/psychic-engine/releases/download/icons/photo.svg -O 		$HOME/.wineAffinity/drive_c/launchers/icos/photo.svg
wget -q --show-progress https://github.com/woafID/psychic-engine/releases/download/icons/publisher.svg -O	$HOME/.wineAffinity/drive_c/launchers/icos/publisher.svg

# Create folder if not exitsts
if [ ! -d "$HOME/.local/share/applications" ]; then
  mkdir -p "$HOME/.local/share/applications"
fi

# Get the current user's home directory
HOME_DIR=$HOME

#Create icons
#The backslashes (\) before and after the variable $HOME_DIR in the Exec line are used to escape the double quotes (") surrounding the path.
DESKTOP_CONTENT_DESIGNER="[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/bin/bash -c \"$HOME_DIR/.wineAffinity/drive_c/launchers/designer2.sh\" %U
Name=Affinity Designer 2
Icon=$HOME_DIR/.wineAffinity/drive_c/launchers/icos/designer.svg
Categories=ConsoleOnly;System;"

echo "$DESKTOP_CONTENT_DESIGNER" > "$HOME/.local/share/applications/affinity_designer.desktop"



DESKTOP_CONTENT_PHOTO="[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/bin/bash -c \"$HOME_DIR/.wineAffinity/drive_c/launchers/photo2.sh\" %U
Name=Affinity Photo 2
Icon=$HOME_DIR/.wineAffinity/drive_c/launchers/icos/photo.svg
Categories=ConsoleOnly;System;"

echo "$DESKTOP_CONTENT_PHOTO" > "$HOME/.local/share/applications/affinity_photo.desktop"


DESKTOP_CONTENT_PUBLISHER="[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/bin/bash -c \"$HOME_DIR/.wineAffinity/drive_c/launchers/publisher2.sh\" %U
Name=Affinity Publisher 2
Icon=$HOME_DIR/.wineAffinity/drive_c/launchers/icos/publisher.svg
Categories=ConsoleOnly;System;"

echo "$DESKTOP_CONTENT_PUBLISHER" > "$HOME/.local/share/applications/affinity_publisher.desktop"

# Set renderrer to vulkan, to better support recent hardware. If you have issues, try replacing "vulkan" with "gl"
rum ElementalWarrior-8.14 $HOME/.wineAffinity winetricks renderer=vulkan

rm -fr $HOME/affinity_setup_tmp
echo All done!
sleep 1.5
exit 0
