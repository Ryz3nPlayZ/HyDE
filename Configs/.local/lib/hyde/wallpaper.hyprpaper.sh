#!/usr/bin/env bash
# shellcheck disable=SC2154

# Source global control file
# shellcheck disable=SC1091
source "$(dirname "$(realpath "$0")")"/globalcontrol.sh

# Set the wallpaper using hyprpaper
# The image path is passed as the first argument

if [ -z "$1" ]; then
    echo "Error: No wallpaper path provided."
    exit 1
fi

wallpaper_path="$1"

# Check if hyprpaper is running
if pgrep -x "hyprpaper" > /dev/null; then
    # Reload hyprpaper and set the wallpaper
    hyprctl hyprpaper unload all
    hyprctl hyprpaper preload "$wallpaper_path"
    hyprctl hyprpaper wallpaper "eDP-1,$wallpaper_path"
    # You might need to adjust 'eDP-1' to your monitor's name
    # or make it dynamic if you have multiple monitors.
else
    echo "hyprpaper is not running. Please start it manually."
    # Optionally, start hyprpaper here if it's not running.
    # hyprpaper &
fi
