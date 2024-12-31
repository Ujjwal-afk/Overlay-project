ifneq ($(KERNELRELEASE),)
# kbuild part of Makefile
	obj-$(CONFIG_OVERLAY)  := overlay.o
else
# normal Makefile
default:
	# Ensure KDIR is defined to point to the kernel source directory
	ifeq ($(KDIR),)
		$(error KDIR is not set. Please define KDIR to point to the kernel source directory.)
	endif
	$(MAKE) -C $(KDIR) M=$(PWD) modules
clean:
	rm -f *.ko *.o *.mod.o *.mod.c *.symvers .*.cmd
endif
