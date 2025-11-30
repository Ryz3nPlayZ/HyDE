#!/usr/bin/env bash
#|---/ /+------------------------------+---/ /|#
#|--/ /-| Script to patch custom theme |--/ /-|#
#|-/ /--| kRHYME7                      |-/ /--|#
#|/ /---+------------------------------+/ /---|#

print_prompt() {
    [[ "${verbose}" == "false" ]] && return 0
    while (("$#")); do
        case "$1" in
        -r)
            echo -ne "\e[31m$2\e[0m"
            shift 2
            ;; # Red
        -g)
            echo -ne "\e[32m$2\e[0m"
            shift 2
            ;; # Green
        -y)
            echo -ne "\e[33m$2\e[0m"
            shift 2
            ;; # Yellow
        -b)
            echo -ne "\e[34m$2\e[0m"
            shift 2
            ;; # Blue
        -m)
            echo -ne "\e[35m$2\e[0m"
            shift 2
            ;; # Magenta
        -c)
            echo -ne "\e[36m$2\e[0m"
            shift 2
            ;; # Cyan
        -w)
            echo -ne "\e[37m$2\e[0m"
            shift 2
            ;; # White
        -n)
            echo -ne "\e[96m$2\e[0m"
            shift 2
            ;; # Neon
        *)
            echo -ne "$1"
            shift
            ;;
        esac
    done
    echo ""
}

scrDir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
# if [ $? -ne 0 ]; then
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

verbose="${4}"
set +e

# error function
ask_help() {
    cat <<HELP
Usage:
    $(print_prompt "$0 " -y "Theme-Name " -c "/Path/to/Configs")
    $(print_prompt "$0 " -y "Theme-Name " -c "https://github.com/User/Repository")
    $(print_prompt "$0 " -y "Theme-Name " -c "https://github.com/User/Repository/tree/branch")

Options:
    'export FULL_THEME_UPDATE=true'       Overwrites the archived files (useful for updates and changes in archives)

Supported Archive Format:
    | File prfx          | Hyprland variable | Target dir                      |
    | ---------------    | ----------------- | --------------------------------|
    | Gtk_               | \$GTK_THEME        | \$HOME/.local/share/themes     |
    | Icon_              | \$ICON_THEME       | \$HOME/.local/share/icons      |
    | Cursor_            | \$CURSOR_THEME     | \$HOME/.local/share/icons      |
    | Sddm_              | \$SDDM_THEME       | /usr/share/sddm/themes         |
    | Font_              | \$FONT             | \$HOME/.local/share/fonts      |
    | Document-Font_     | \$DOCUMENT_FONT    | \$HOME/.local/share/fonts      |
    | Monospace-Font_    | \$MONOSPACE_FONT   | \$HOME/.local/share/fonts      |
    | Notification-Font_ | \$NOTIFICATION_FONT | \$HOME/.local/share/fonts  |
    | Bar-Font_          | \$BAR_FONT         | \$HOME/.local/share/fonts      |
    | Menu-Font_         | \$MENU_FONT        | \$HOME/.local/share/fonts      |

Note:
    Target directories without enough permissions will be skipped.
        run 'sudo chmod -R 777 <target directory>'
            example: 'sudo chmod -R 777 /usr/share/sddm/themes'
HELP
}

if [[ -z $1 || -z $2 ]]; then
    ask_help
    exit 1
fi

# set parameters
Fav_Theme="$1"

if [ -d "$2" ]; then
    Theme_Dir="$2"
else
    Git_Repo=${2%/}
    if echo "$Git_Repo" | grep -q "/tree/"; then
        branch=${Git_Repo#*tree/}
        Git_Repo=${Git_Repo%/tree/*}
    else
        branches=$(curl -s "https://api.github.com/repos/${Git_Repo#*://*/}/branches" | jq -r '.[].name')
        # shellcheck disable=SC2206
        branches=($branches)
        if [[ ${#branches[@]} -le 1 ]]; then
            branch=${branches[0]}
        else
            echo "Select a Branch"
            select branch in "${branches[@]}"; do
                [[ -n $branch ]] && break || echo "Invalid selection. Please try again."
            done
        fi
    fi

    Git_Path=${Git_Repo#*://*/}
    Git_Owner=${Git_Path%/*}
    branch_dir=${branch//\//_}
    cacheDir=${cacheDir:-"$HOME/.cache/hyde"}
    Theme_Dir="${cacheDir}/themepatcher/${branch_dir}-${Git_Owner}"

    if [ -d "$Theme_Dir" ]; then
        print_prompt "Directory $Theme_Dir already exists. Using existing directory."
        if cd "$Theme_Dir"; then
            git fetch --all &>/dev/null
            git reset --hard "@{upstream}" &>/dev/null
            cd - &>/dev/null || exit
        else
            print_prompt -y "Could not navigate to $Theme_Dir. Skipping git pull."
        fi
    else
        print_prompt "Directory $Theme_Dir does not exist. Cloning repository into new directory."
        if ! git clone -b "$branch" --depth 1 "$Git_Repo" "$Theme_Dir" &>/dev/null; then
            print_prompt "Git clone failed"
            exit 1
        fi
    fi
fi

print_prompt "Patching" -g " --// ${Fav_Theme} //-- " "from " -b "${Theme_Dir}\n"

Fav_Theme_Dir="${HOME}/.config/hypr/themes/${Fav_Theme}"
[ ! -d "${Fav_Theme_Dir}" ] && print_prompt -r "[ERROR] " "'${Fav_Theme_Dir}'" -y " Do not Exist" && exit 1

# config=$(find "${dcolDir}" -type f -name "*.dcol" | awk -v favTheme="${Fav_Theme}" -F 'theme/' '{gsub(/\.dcol$/, ".theme"); print ".config/hyde/themes/" favTheme "/" $2}')
config=$(find "${confDir}/hyde/wallbash" -type f -path "*/theme*" -name "*.dcol" 2>/dev/null | awk '!seen[substr($0, match($0, /[^/]+$/))]++' | awk -v favTheme="${Fav_Theme}" -F 'theme/' '{gsub(/\.dcol$/, ".theme"); print ".config/hyde/themes/" favTheme "/" $2}')
restore_list=""

while IFS= read -r fileCheck; do
    if [[ -e "${Theme_Dir}/Configs/${fileCheck}" ]]; then
        print_prompt -g "[found] " "${fileCheck}"
        fileBase=$(basename "${fileCheck}")
        fileDir=$(dirname "${fileCheck}")
        restore_list+="Y|Y|\${HOME}/${fileDir}|${fileBase}|hyprland\n"
    else
        print_prompt -y "[warn] " "${fileCheck} --> do not exist in ${Theme_Dir}/Configs/"
    fi
done <<<"$config"
if [ -f "${Fav_Theme_Dir}/theme.dcol" ]; then
    print_prompt -n "[note] " "found theme.dcol to override wallpaper dominant colors"
    restore_list+="Y|Y|\${HOME}/.config/hyde/themes/${Fav_Theme}|theme.dcol|hyprland\n"
fi
readonly restore_list

# Get Wallpapers
wallpapers=$(
    find "${Fav_Theme_Dir}" -type f \( -iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) ! -path "*/logo/*"
)
wpCount="$(wc -l <<<"${wallpapers}")"
{ [ -z "${wallpapers}" ] && print_prompt -r "[ERROR] " "No wallpapers found" && exit_flag=true; } || { readonly wallpapers && print_prompt -g "\n[OK] " "wallpapers :: [count] ${wpCount} (.gif+.jpg+.jpeg+.png)"; }

# Get logos
if [ -d "${Fav_Theme_Dir}/logo" ]; then
    logos=$(find "${Fav_Theme_Dir}/logo" -type f \( -iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \))
    logosCount="$(wc -l <<<"${logos}")"
    { [ -z "${logos}" ] && print_prompt -y "[warn] " "No logos found"; } || { readonly logos && print_prompt -g "[OK] " "logos :: [count] ${logosCount}\n"; }
fi

# parse thoroughly 😁

confDir=${XDG_CONFIG_HOME:-"$HOME/.config"}

# populate wallpaper
Fav_Theme_Walls="${confDir}/hyde/themes/${Fav_Theme}/wallpapers"
[ ! -d "${Fav_Theme_Walls}" ] && mkdir -p "${Fav_Theme_Walls}"
while IFS= read -r walls; do
    cp -f "${walls}" "${Fav_Theme_Walls}"
done <<<"${wallpapers}"

# populate logos
Fav_Theme_Logos="${confDir}/hyde/themes/${Fav_Theme}/logo"
if [ -n "${logos}" ]; then
    [ ! -d "${Fav_Theme_Logos}" ] && mkdir -p "${Fav_Theme_Logos}"
    while IFS= read -r logo; do
        if [ -f "${logo}" ]; then
            cp -f "${logo}" "${Fav_Theme_Logos}"
        else
            print_prompt -y "[warn] " "${logo} --> do not exist"
        fi
    done <<<"${logos}"
fi

# restore configs with theme override
echo -en "${restore_list}" >"${Theme_Dir}/restore_cfg.lst"
print_prompt -g "\n[exec] " "restore_cfg.sh \"${Theme_Dir}/restore_cfg.lst\" \"${Theme_Dir}/Configs\" \"${Fav_Theme}\"\n"
"${scrDir}/restore_cfg.sh" "${Theme_Dir}/restore_cfg.lst" "${Theme_Dir}/Configs" "${Fav_Theme}" &>/dev/null
if [ "${3}" != "--skipcaching" ]; then
    "$HOME/.local/lib/hyde/theme.switch.sh"
fi

print_prompt -y "\nNote: Warnings are not errors. Review the output to check if it concerns you."

exit 0
