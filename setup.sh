#!/bin/sh

set -eu

# Root directory of the kernel source
KERNEL_ROOT=$(pwd)

display_usage() {
    echo "Usage: $0 [--cleanup | Y | M]"
    echo "  --cleanup: Removes overlay driver integration."
    echo "  Y: Integrates the overlay driver as built-in."
    echo "  M: Integrates the overlay driver as a loadable module."
    echo "  -h, --help: Displays this usage information."
}

initialize_variables() {
    if [ -d "$KERNEL_ROOT/common/drivers" ]; then
        DRIVER_DIR="$KERNEL_ROOT/common/drivers"
    elif [ -d "$KERNEL_ROOT/drivers" ]; then
        DRIVER_DIR="$KERNEL_ROOT/drivers"
    else
        echo "Drivers directory not found."
        exit 1
    fi

    DRIVER_MAKEFILE="$DRIVER_DIR/Makefile"
    DRIVER_KCONFIG="$DRIVER_DIR/Kconfig"
    OVERLAY_DIR="$KERNEL_ROOT/overlay_driver"
}

perform_cleanup() {
    echo "Cleaning up..."
    [ -d "$OVERLAY_DIR" ] && rm -rf "$OVERLAY_DIR" && echo "Removed overlay_driver directory."
    [ -L "$DRIVER_DIR/overlay_driver" ] && rm "$DRIVER_DIR/overlay_driver" && echo "Removed overlay_driver symlink."
    sed -i '/overlay_driver/d' "$DRIVER_MAKEFILE" && echo "Reverted Makefile."
    sed -i '/overlay_driver\\/Kconfig/d' "$DRIVER_KCONFIG" && echo "Reverted Kconfig."
    echo "Cleanup complete."
}

setup_driver() {
    mkdir -p "$OVERLAY_DIR"
    cp -r "$(dirname "$0")/overlay" "$OVERLAY_DIR"

    ln -sf "$OVERLAY_DIR" "$DRIVER_DIR/overlay_driver"
    echo "obj-\$(CONFIG_OVERLAY_DRIVER) += overlay_driver/" >> "$DRIVER_MAKEFILE"
    echo "source \"drivers/overlay_driver/Kconfig\"" >> "$DRIVER_KCONFIG"

    echo "Driver setup complete."
}

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
    Y|M)
        initialize_variables
        setup_driver
        ;;
    *)
        echo "Invalid argument."
        display_usage
        ;;
esac
