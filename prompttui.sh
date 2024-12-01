#!/usr/bin/env bash
#
# File: prompttui.sh
# Author: Wadih Khairallah 
# Description: 
# Created: 2024-11-26 03:42:35
# Modified: 2024-12-01 06:15:26

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

generate_rule_line() {
    local width=${1:-60}    # Total width of the rule line (default: 60)
    local text="${2:-}"     # Optional centered text
    local char="${3:-═}"    # Character for the line (default: ═)

    # Usable width for the rule (subtract 2 for borders)
    local usable_width=$((width - 4))

    # If text is provided, center it
    if [[ -n "$text" ]]; then
        local text_length=${#text}
        local padding_length=$(((usable_width - 1 - text_length) / 2)) # Space on each side
        local left_padding=$(printf "%-${padding_length}s" "" | tr ' ' "$char")
        local right_padding_length=$((usable_width - 2 - text_length - padding_length))
        local right_padding=$(printf "%-${right_padding_length}s" "" | tr ' ' "$char")

        # Assemble the line with text
        echo -e "╟${left_padding} ${text} ${right_padding}╢"
    else
        # Generate a plain rule line
        local full_line=$(printf "%-${usable_width}s" "" | tr ' ' "$char")
        echo -e "╟${full_line}╢"
    fi
}

# Plain rule line
# generate_rule_line 60 ""
#
# Rule line with text
# generate_rule_line 60 "Centered Text"
#
# Rule line with custom character
# generate_rule_line 60 "Custom Character" "─"


generate_panel_with_content() {
    local title="$1"               # Panel title
    local width=${2:-60}           # Total panel width (default: 60)
    local content=("${@:3}")       # Content lines passed as additional arguments
    local usable_width=$((width - 4))  # Usable space between the borders (subtract 4 for ║ and padding)

    # Calculate padding for the title
    local title_padding_length=$((usable_width - ${#title} - 2)) # -2 for "═ " after the title
    local title_padding=$(printf "%-${title_padding_length}s" "" | tr ' ' "═")
    local title_line="╔═${title}${title_padding}═╗"

    # Generate the bottom border
    local bottom_line="╚$(printf '═%.0s' $(seq 1 ${usable_width}))╝"

    # Generate content rows
    local content_rows=()
    for line in "${content[@]}"; do
        local usable_content_width=$((width - 7)) # Account for borders and padding spaces
        local padded_content=$(printf "%-${usable_content_width}s" "${line}")
        content_rows+=("║  $padded_content ║") # Add spaces for padding inside the box
    done

    # Render the panel
    echo -e "${title_line}"
    for row in "${content_rows[@]}"; do
        echo -e "${row}"
    done
    echo -e "${bottom_line}"
}

# Example Usage
# generate_panel_with_content "System Stats" 60 \
#     "CPU Usage:    45%" \
#     "Memory Usage: 72%" \
#     "Disk Usage:   85%"

# Function to render a tree structure dynamically
render_tree() {
    local -n tree_data=$1  # Accept a named array of tree nodes
    local output=""

    # Render the root node
    output+="Root\n"

    # Iterate through the tree structure and render dynamically
    for key in "${!tree_data[@]}"; do
        if [[ "${tree_data[$key]}" == "node" ]]; then
            output+=" ╠═ $key\n"
        elif [[ "${tree_data[$key]}" == "subnode" ]]; then
            output+=" ║   ╠═ $key\n"
        elif [[ "${tree_data[$key]}" == "end" ]]; then
            output+=" ║   ╚═ $key\n"
        fi
    done

    # Print the rendered tree
    echo -e "$output"
}

# Example tree data (can be dynamically generated)
# declare -A tree_structure=(
#     ["Node 1"]="node"
#     ["Subnode 1.1"]="subnode"
#     ["Subnode 1.2"]="end"
#     ["Node 2"]="node"
#     ["Subnode 2.1"]="end"
# )
# Render the tree dynamically
# render_tree tree_structure


generate_state_identifiers() {
    local title="$1"               # Panel title
    local width=${2:-50}           # Total panel width (default: 50)
    shift 2                        # Shift off title and width
    local processes=("$@")         # Remaining arguments: process states

    # Usable content width inside the box
    local usable_width=$((width - 4))  # Subtract borders and padding

    # Calculate title padding
    local title_padding_length=$((usable_width - ${#title} - 2)) # -2 for "═ " after title
    local title_padding=$(printf "%-${title_padding_length}s" "" | tr ' ' "═")
    local title_line="╔═${title}${title_padding}═╗"

    # Generate bottom border
    local bottom_line="╚$(printf '═%.0s' $(seq 1 ${usable_width}))╝"

    # Map process states to symbols
    declare -A state_symbols=(
        ["active"]="●"
        ["queued"]="○"
        ["waiting"]="◐"
        ["error"]="✗"
        ["completed"]="✔"
    )

    # Generate content rows
    local content_rows=()
    for process in "${processes[@]}"; do
        # Parse process name and state using IFS
        IFS=":" read -r name state <<< "$process"

        # Ensure state is valid
        if [[ -z "${state_symbols[$state]}" ]]; then
            state="unknown"  # Fallback for unknown states
        fi
        local symbol=${state_symbols[$state]:-"?"}

        # Format content row
        local content=" $symbol $name"
        local padded_content=$(printf "%-${usable_width}s" "$content")
        content_rows+=("║${padded_content}  ║")
    done

    # Render the panel
    echo -e "${title_line}"
    for row in "${content_rows[@]}"; do
        echo -e "${row}"
    done
    echo -e "${bottom_line}"
}

# Example Usage
# generate_state_identifiers "Process States" 60 \
#     "Process 1:active" \
#     "Process 2:queued" \
#     "Process 3:waiting" \
#     "Process 4:error" \
#     "Process 5:completed"


generate_panel_message() {
    local type="$1"               # Panel type: warning, notification, error, info
    local title="$2"              # Panel title
    local width=${3:-50}          # Total panel width (default: 50)
    local message="$4"            # Panel message

    # Define color codes
    declare -A panel_colors=(
        ["warning"]="\033[1;33m"     # Yellow
        ["notification"]="\033[1;34m" # Blue
        ["error"]="\033[1;31m"       # Red
        ["info"]="\033[1;37m"        # White
    )

    # Get the appropriate color or fallback to white
    local panel_color=${panel_colors[$type]:-"${panel_colors["info"]}"}

    # Usable content width inside the box
    local usable_width=$((width - 4))  # Subtract borders and padding

    # Calculate title padding
    local title_padding_length=$((usable_width - ${#title} - 2)) # -2 for "═ " after title
    local title_padding=$(printf "%-${title_padding_length}s" "" | tr ' ' "═")
    local title_line="╔═${title}${title_padding}═╗"

    # Generate bottom border
    local bottom_line="╚$(printf '═%.0s' $(seq 1 ${usable_width}))╝"

    # Format the message, accounting for the 2-character discrepancy
    local padded_message=$(printf "%-$((usable_width - 2))s" "$message")
    local message_row="║ ${padded_message} ║"

    # Render the panel
    echo -e "${panel_color}${title_line}\033[0m"
    echo -e "${panel_color}${message_row}\033[0m"
    echo -e "${panel_color}${bottom_line}\033[0m"
}

# Example Usage
# generate_panel_message "warning" "Warning" 60 "Disk usage is over 90%!"
# generate_panel_message "notification" "Notification" 60 "System update available."
# generate_panel_message "error" "Error" 60 "Failed to connect to the database!"
# generate_panel_message "info" "Info" 60 "Backup completed successfully."


generate_progress_bar() {
    local current=$1          # Current progress
    local total=${2:-100}     # Total value (default: 100)
    local width=${3:-40}      # Bar width (default: 40)

    # Calculate filled and empty portions
    local percent=$((current * 100 / total))
    local filled=$((percent * width / 100))
    local empty=$((width - filled))

    # Build the bar
    local bar=$(printf "█%.0s" $(seq 1 $filled))
    bar+=$(printf "░%.0s" $(seq 1 $empty))

    # Render the bar with percentage
    echo "[$bar] $percent%"
}

# Example Usage
# generate_progress_bar 90 100 30


_run_prompttui_tests() {

    # test panel with content
    generate_panel_with_content "System Stats" 60 \
        "CPU Usage:    45%" \
        "Memory Usage: 72%" \
        "Disk Usage:   85%"


    # test tree
    declare -A tree_structure=(
        ["Node 1"]="node"
        ["Subnode 1.1"]="subnode"
        ["Subnode 1.2"]="end"
        ["Node 2"]="node"
        ["Subnode 2.1"]="end"
    )
    render_tree tree_structure


    # test state identifiers
    generate_state_identifiers "Process States" 60 \
        "Process 1:active" \
        "Process 2:queued" \
        "Process 3:waiting" \
        "Process 4:error" \
        "Process 5:completed"


    # test notification panel
    generate_panel_message "warning" "Warning" 60 "Disk usage is over 90%!"
    generate_panel_message "notification" "Notification" 60 "System update available."
    generate_panel_message "error" "Error" 60 "Failed to connect to the database!"
    generate_panel_message "info" "Info" 60 "Backup completed successfully."


    # test progress bar
    generate_progress_bar 90 100 30

    # Plain rule line
    generate_rule_line 60 ""

    # Rule line with text
    generate_rule_line 60 "Centered Text"

    # Rule line with custom character
    generate_rule_line 60 "Custom Character" "─"

}
_run_prompttui_tests


__update_ps1() {
    local components=()
    local git_info=""
    local venv_info=""
    local warnings=()
    local decorator="\[\033[0;38;5;82m\]⣿\[\033[0m\]"
    local base_prompt="$decorator\[\033[0;32m\]└─\[\033[0;94m\]\$ \[\033[0m\]"  # Base prompt

    # Git branch and status
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        git_info="$decorator[\[\033[0;36m\]git:(\[\033[0;37m\]$(__git_ps1 "%s")\[\033[0;36m\])\[\033[0;32m\]]"
        components+=("$git_info")
    fi

    # Virtual environment
    if [[ -n "$VIRTUAL_ENV" ]]; then
        venv_info="$decorator[\[\033[0;34m\](\[\033[0;37m\]$(basename $VIRTUAL_ENV)\[\033[0;34m\])\[\033[0;32m\]]"
        components+=("$venv_info")
    fi

    # Load average (15-minute)
    local load_15m
    if [[ "$OSTYPE" == "darwin"* ]]; then
        load_15m=$(sysctl -n vm.loadavg | awk '{print $4}')
    else
        load_15m=$(awk '{print $3}' /proc/loadavg)
    fi
    if (( $(echo "$load_15m > 6.0" | bc -l) )); then
        warnings+=("LOAD: $load_15m")
    fi

    # Memory usage
    local mem_usage=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        mem_usage=$(vm_stat | awk '/free/ {free=$3} /active/ {active=$3} /inactive/ {inactive=$3} /speculative/ {spec=$3} END {total=(free+active+inactive+spec)/256; used=(active+spec)/256; print int(used/total*100)}')
    else
        mem_usage=$(free | awk '/Mem:/ {print int($3/$2 * 100.0)}')
    fi
    if (( mem_usage > 75 )); then
        warnings+=("MEM: ${mem_usage}%")
    fi

    # Disk space
    local disk_usage
    if [[ "$OSTYPE" == "darwin"* ]]; then
        disk_usage=$(df / | awk 'NR==2 {print int($5)}')
    else
        disk_usage=$(df --output=pcent / | awk 'NR==2 {print $1}' | tr -d '%')
    fi
    if (( disk_usage > 90 )); then
        warnings+=("DISK: ${disk_usage}%")
    fi

    # Battery status
    if [[ "$OSTYPE" == "darwin"* ]]; then
        battery_info=$(pmset -g batt | grep -Eo '\d+%' | tr -d '%')
        charging=$(pmset -g batt | grep -q 'AC Power'; echo $?)
    elif [[ -d /sys/class/power_supply/BAT0 ]]; then
        battery_info=$(cat /sys/class/power_supply/BAT0/capacity)
        charging=$(cat /sys/class/power_supply/BAT0/status | grep -q 'Charging'; echo $?)
    fi
    if [[ -n "$battery_info" && "$battery_info" -lt 20 && "$charging" -ne 0 ]]; then
        warnings+=("BAT: ${battery_info}%")
    fi

    # Add warnings to components
    for warning in "${warnings[@]}"; do
        components+=("[\[\033[0;31m\]$warning\[\033[0;32m\]]")
    done

    # Build the prompt dynamically with proper tree alignment
    PS1="\n"
    local count=0
    for comp in "${components[@]}"; do
        if [[ $count -eq 0 ]]; then
            PS1+="\[\033[0;32m\]┌──$comp\n"
        else
            PS1+="\[\033[0;32m\]├──$comp\n"
        fi
        count=$((count + 1))
    done

    # Add the base prompt
    PS1+="\[\033[0;32m\]┌──(\[\033[0;33m\]\u@\h\[\033[0;32m\])-[\[\033[0;37m\]\w\[\033[0;32m\]]\n$base_prompt"
}

LAST_CMD_EXIT_CODE_SHOWN=0

trap '__update_last_exit_code' DEBUG

__update_last_exit_code() {
    LAST_CMD_EXIT_CODE_SHOWN=$?
}

# =====================
# Dynamic Prompt Integration (Optional)
# =====================
# Add these functions dynamically into your Bash prompt
# Example:
# PROMPT_COMMAND='__update_prompt'
# __update_prompt() {
#     local progress=$(generate_progress_bar 45 100 30)
#     PS1="\n$progress\n\[\033[0;32m\]└─\[\033[0;37m\]\$ \[\033[0m\]"
# }

# PROMPT_COMMAND='__update_ps1'

display_readme() {
    echo
    apply_gradient "╔═══════════════════════════════════════════════════════════════════════════╗" "sunset"
    apply_gradient "║                               README                                      ║" "sunset"
    apply_gradient "╚═══════════════════════════════════════════════════════════════════════════╝" "sunset"

    echo
    apply_gradient "**Project Description**" "forest"
    apply_gradient "This script provides a customizable Bash terminal user interface (TUI) that enhances user experience with dynamic prompts, color gradients, and custom panels for displaying system information, state identifiers, progress bars, and more." "ocean"
    echo

    apply_gradient "**Features**" "forest"
    apply_gradient "- Dynamic panels with custom content, warnings, notifications, and errors." "ocean"
    apply_gradient "- Gradient-themed text and ASCII graphics using predefined color palettes." "ocean"
    apply_gradient "- Stateful prompts that display system stats, Git information, and virtual environment details." "ocean"
    apply_gradient "- Rule lines with centered text for aesthetic separation of content." "ocean"
    apply_gradient "- Progress bars for visualizing task progress." "ocean"
    apply_gradient "- Modular design for future extensions and enhancements." "ocean"
    echo

    apply_gradient "**Usage**" "forest"
    apply_gradient "1. Run the script directly to test its features:" "ocean"
    apply_gradient "   ./bash_prompt_tui.sh" "ocean"
    apply_gradient "2. Add specific functions to your prompt dynamically:" "ocean"
    apply_gradient "   PROMPT_COMMAND='__update_ps1'" "ocean"
    apply_gradient "3. Customize gradients and themes by editing the gradient definitions." "ocean"
    echo

    apply_gradient "**Examples**" "forest"
    apply_gradient "- Display a custom panel:" "ocean"
    apply_gradient "  generate_panel_with_content \"System Stats\" 60 \\" "ocean"
    apply_gradient "      \"CPU Usage: 45%\" \\" "ocean"
    apply_gradient "      \"Memory Usage: 72%\" \\" "ocean"
    apply_gradient "      \"Disk Usage: 85%\"" "ocean"
    echo

    apply_gradient "**Credits**" "forest"
    apply_gradient "Author: Wadih Khairallah" "ocean"
    echo

    apply_gradient "**License**" "forest"
    apply_gradient "This script is distributed under the MIT License. Use it, modify it, and redistribute it freely while keeping the credits intact." "ocean"
    echo
}

# Check for '--readme' argument or no arguments and display README
if [[ "$1" == "--readme" || "$#" -eq 0 ]]; then
    display_readme
    exit 0
fi

# Your other script functions and features go here...
