#!/usr/bin/env bash
# shellcheck disable=SC2154
#|---/ /+--------------------------+---/ /|#
#|--/ /-| Main installation script |--/ /-|#
#|-/ /--| Prasanth Rangan          |-/ /--|#
#|/ /---+--------------------------+/ /---|#

cat <<"EOF"

-------------------------------------------------
        .
       / \		_       _  _      ___  ___
      /^  \	    _| |_    | || |_  _|   \| __|
     /  _  \	  |_   _|   | __ | || | |) | _|
    /  | | ~\	    |_|     |_||_|\_, |___/|___|
   /.-'   '-.\			  |__/

-------------------------------------------------

EOF

#--------------------------------#
# import variables and functions #
#--------------------------------#
scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
if ! source "${scrDir}/Scripts/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

#------------------#
# evaluate options #
#------------------#
flg_Install=0
flg_Service=0
flg_DryRun=0

while getopts isth RunStep; do
    case $RunStep in
    i) flg_Install=1 ;;
    s) flg_Service=1 ;;
    t) flg_DryRun=1 ;;
    h) 
        cat <<EOF
Usage: $0 [options]
            i : [i]nstall hyprland and core packages
            s : enable system [s]ervices
            t : [t]est run without executing

NOTE:
        running without args is equivalent to -is

EOF
        exit 1
        ;; 
    esac
done

# Only export that are used outside this script
HYDE_LOG="$(date +'%y%m%d_%Hh%Mm%Ss')"
export flg_DryRun flg_Install HYDE_LOG

if [ "${flg_DryRun}" -eq 1 ]; then
    print_log -n "[test-run] " -b "enabled :: " "Testing without executing"
elif [ $OPTIND -eq 1 ]; then
    flg_Install=1
    flg_Service=1
fi

#------------#
# installing #
#------------#
if [ ${flg_Install} -eq 1 ]; then
    cat <<"EOF"

 _         _       _ _ _
|_|___ ___| |_ ___| | |_|___ ___
| |   |_ -|  _| .'| | | |   | . |
|_|_|_|___|_| |__,|_|_|_|_|_|_  |
                            |___|

EOF

    #----------------------#
    # prepare package list #
    #----------------------#
    custom_pkg=$1
    cp "${scrDir}/Scripts/pkg_core.lst" "${scrDir}/install_pkg.lst"
    trap 'rm "${scrDir}/install_pkg.lst"' EXIT

    if [ -f "${custom_pkg}" ] && [ -n "${custom_pkg}" ]; then
        echo -e "\n#user packages" >>"${scrDir}/install_pkg.lst"
        cat "${custom_pkg}" >>"${scrDir}/install_pkg.lst"
    fi

    #----------------#
    # get user prefs #
    #----------------#
    echo ""
    # Simplified: Assuming AUR helper is handled or user installs manually
    # Simplified: Assuming shell is handled or user installs manually

    #--------------------------------#
    # install packages from the list #
    #--------------------------------#
    "${scrDir}/Scripts/install_pkg.sh" "${scrDir}/install_pkg.lst"
fi

#------------------------#
# enable system services #
#------------------------#
if [ ${flg_Service} -eq 1 ]; then
    cat <<"EOF"

                 _
 ___ ___ ___ _ _|_|___ ___ ___
|_ -| -_|  _| | | |  _| -_|_ -|
|___|___|_|  \_/|_|___|___|___|

EOF

    "${scrDir}/Scripts/restore_svc.sh"
fi

if [ $flg_Install -eq 1 ]; then
    echo ""
    print_log -g "Installation" " :: " "COMPLETED!"
fi

print_log -b "Log" " :: " -y "View logs at ${cacheDir}/logs/${HYDE_LOG}"

if [ $flg_Install -eq 1 ] || [ $flg_Service -eq 1 ] && [ $flg_DryRun -ne 1 ]; then
    print_log -stat "HyDE" "It is recommended to reboot the system to apply new changes. Do you want to reboot the system? (y/N)"
    read -r answer

    if [[ "$answer" == [Yy] ]]; then
        echo "Rebooting system"
        systemctl reboot
    else
        echo "The system will not reboot"
    fi
fi