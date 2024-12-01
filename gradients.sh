#!/usr/bin/env bash
#
# File: gradients.sh
# Author: Wadih Khairallah
# Description: 
# Created: 2024-11-30 23:49:55
# Modified: 2024-12-01 06:17:22

# Define gradient themes
declare -A gradients=(
    ["sunset"]="#FF4500:#FFD700"
    ["ocean"]="#1E90FF:#00CED1"
    ["forest"]="#2E8B57:#ADFF2F"
    ["fire"]="#FF0000:#FFA500"
    ["rainbow"]="#9400D3:#FF0000"
    ["cotton_candy"]="#FFB6C1:#ADD8E6"
    ["lava"]="#800000:#FF4500"
    ["electric"]="#00FFFF:#7B68EE"
    ["peach"]="#FFDAB9:#FF6347"
    ["aurora"]="#4B0082:#00FF00"
    ["twilight"]="#8A2BE2:#FF69B4"
    ["neon_city"]="#00FF00:#FF00FF"
    ["desert"]="#EDC9AF:#FF4500"
    ["iceberg"]="#00FFFF:#FFFFFF"
    ["galaxy"]="#000080:#8A2BE2"
    ["rose_garden"]="#FF007F:#FF69B4"
    ["sunrise"]="#FFD700:#FF4500"
    ["serenity"]="#00CED1:#4682B4"
    ["midnight"]="#191970:#000000"
    ["golden_hour"]="#FFD700:#FFA500"
)

# Convert a hex color to its RGB components
hex_to_rgb() {
    local hex=$1
    echo $((16#${hex:1:2})) $((16#${hex:3:2})) $((16#${hex:5:2}))
}

# Generate a gradient color based on the position
interpolate_color() {
    local start_r=$1 start_g=$2 start_b=$3
    local end_r=$4 end_g=$5 end_b=$6
    local steps=$7 position=$8

    local ratio=$(awk "BEGIN {print $position / $steps}")
    local r=$(awk "BEGIN {print int($start_r + ($end_r - $start_r) * $ratio)}")
    local g=$(awk "BEGIN {print int($start_g + ($end_g - $start_g) * $ratio)}")
    local b=$(awk "BEGIN {print int($start_b + ($end_b - $start_b) * $ratio)}")

    echo "$r;$g;$b"
}

# Apply gradient to text
apply_gradient() {
    local text="$1"
    local theme="$2"

    if [[ -z "${gradients[$theme]}" ]]; then
        echo "Theme '$theme' not found."
        return 1
    fi

    local colors=(${gradients[$theme]//:/ })
    local start_rgb=($(hex_to_rgb "${colors[0]}"))
    local end_rgb=($(hex_to_rgb "${colors[1]}"))

    local length=${#text}
    local gradient_text=""
    for ((i = 0; i < length; i++)); do
        local char="${text:i:1}"
        local rgb=$(interpolate_color "${start_rgb[@]}" "${end_rgb[@]}" "$length" "$i")
        gradient_text+="\033[38;2;${rgb}m$char"
    done
    gradient_text+="\033[0m"

    echo -e "$gradient_text"
}

# Example usage
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    clear
    for theme in "${!gradients[@]}"; do
        echo "Theme: $theme"
        apply_gradient "Welcome to PromptTui!" "$theme"
        apply_gradient "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿" "$theme"
        echo
        sleep 0.2
    done
fi

