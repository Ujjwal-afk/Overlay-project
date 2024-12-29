#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <stdint.h>

// Include the same definitions as the kernel module
#define OVERLAY_IOC_MAGIC 'O'
#define OVERLAY_SET_PARAMS _IOW(OVERLAY_IOC_MAGIC, 1, struct overlay_params)
#define OVERLAY_ENABLE     _IO(OVERLAY_IOC_MAGIC, 2)
#define OVERLAY_DISABLE    _IO(OVERLAY_IOC_MAGIC, 3)

struct overlay_params {
    int x, y;
    int width, height;
    uint32_t color;
};

int main() {
    int fd = open("/dev/overlay", O_RDWR);
    if (fd < 0) {
        perror("Failed to open /dev/overlay");
        return 1;
    }

    // Set overlay parameters
    struct overlay_params params = {
        .x = 100,
        .y = 100,
        .width = 200,
        .height = 200,
        .color = 0xFF0000FF // Red
    };
    ioctl(fd, OVERLAY_SET_PARAMS, &params);

    // Enable the overlay
    ioctl(fd, OVERLAY_ENABLE);

    // Wait for 5 seconds
    sleep(5);

    // Disable the overlay
    ioctl(fd, OVERLAY_DISABLE);

    close(fd);
    return 0;
}
