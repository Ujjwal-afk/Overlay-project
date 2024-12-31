#!/bin/sh

set -eu

GKI_ROOT=$(pwd)

display_usage() {
    echo "Usage: $0 [--cleanup | <integration-options>]"
    echo "  --cleanup:              Cleans up previous modifications made by the script."
    echo "  <integration-options>:  Tells how the driver should be integrated into the kernel source (Y, M)."
    echo "  <driver-name>:          Optional driver name. If not provided, a random name will be used."
    echo "  -h, --help:             Displays this usage information."
    echo "  (no args):              Sets up or updates the driver environment to the latest state (integration as Y)."
}

initialize_variables() {
    if [ -d "$GKI_ROOT/common/drivers" ]; then
        DRIVER_DIR="$GKI_ROOT/common/drivers"
    elif [ -d "$GKI_ROOT/drivers" ]; then
        DRIVER_DIR="$GKI_ROOT/drivers"
    else
        DRIVER_DIR=""
    fi

    DRIVER_MAKEFILE="$DRIVER_DIR/Makefile"
    DRIVER_KCONFIG="$DRIVER_DIR/Kconfig"
}

perform_cleanup() {
    echo "[+] Cleaning up..."
    if [ -n "$DRIVER_DIR" ]; then
        [ -L "$DRIVER_DIR/overlay" ] && rm "$DRIVER_DIR/overlay" && echo "[-] Symlink removed."
        grep -q "overlay" "$DRIVER_MAKEFILE" && sed -i '/overlay/d' "$DRIVER_MAKEFILE" && echo "[-] Makefile reverted."
        grep -q "drivers/overlay/Kconfig" "$DRIVER_KCONFIG" && sed -i '/drivers\/overlay\/Kconfig/d' "$DRIVER_KCONFIG" && echo "[-] Kconfig reverted."
    fi
    [ -d "$GKI_ROOT/OverlayDriver" ] && rm -rf "$GKI_ROOT/OverlayDriver" && echo "[-] OverlayDriver directory deleted."
}

randomize_driver_and_module() {
    local random_name
    if [ -n "${1:-}" ]; then
        random_name="$1"
    else
        random_name=$(tr -dc 'a-z' </dev/urandom | head -c 6)
    fi

    sed -i "s/#define DEVICE_NAME \".*\"/#define DEVICE_NAME \"$random_name\"/" "$GKI_ROOT/OverlayDriver/kernel.c"
    if [ "$2" = "M" ]; then
        sed -i "s/overlay.o/${random_name}_overlay.o/" "$GKI_ROOT/OverlayDriver/Makefile"
        echo -e "\e[36mModule Name: ${random_name}_overlay.ko\e[0m"
    fi

    echo -e "\e[36mDevice Name: $random_name\e[0m"
}

setup_driver() {
    if [ -z "$DRIVER_DIR" ]; then
        echo '[ERROR] "drivers/" directory not found.'
        exit 127
    fi

    echo "[+] Setting up OverlayDriver..."
    [ -d "$GKI_ROOT/OverlayDriver" ] || git clone https://github.com/Ujjwal-afk/Overlay-project OverlayDriver && echo "[+] Repository cloned."
    cd "$GKI_ROOT/OverlayDriver"
    git stash && echo "[-] Stashed current changes."
    git pull && echo "[+] Repository updated."

    if [ "$1" = "M" ]; then
        sed -i 's/default y/default m/' Kconfig
    elif [ "$1" != "Y" ]; then
        echo "[ERROR] First argument not valid. Should be one of: Y, M"
        exit 128
    fi

    cd "$DRIVER_DIR"
    ln -sf "$(realpath --relative-to="$DRIVER_DIR" "$GKI_ROOT/OverlayDriver")" "overlay" && echo "[+] Symlink created."

    # Add entries in Makefile and Kconfig if not already present
    grep -q "overlay" "$DRIVER_MAKEFILE" || printf "\nobj-\$(CONFIG_OVERLAY) += overlay/\n" >> "$DRIVER_MAKEFILE" && echo "[+] Modified Makefile."
    grep -q "source \"drivers/overlay/Kconfig\"" "$DRIVER_KCONFIG" || sed -i "/endmenu/i\source \"drivers/overlay/Kconfig\"" "$DRIVER_KCONFIG" && echo "[+] Modified Kconfig."

    if [ "$#" -ge 2 ]; then
        randomize_driver_and_module "$2" "$1"
    else
        randomize_driver_and_module "" "$1"
    fi
    echo '[+] Done.'
}

# Process command-line arguments
if [ "$#" -eq 0 ]; then
    set -- Y
fi

case "$1" in
    -h|--help)
        display_usage
        ;;
    --cleanup)
        initialize_variables
        perform_cleanup
        ;;
    *)
        initialize_variables
        setup_driver "$@"
        ;;
esac
