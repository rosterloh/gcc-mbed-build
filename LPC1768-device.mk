# Adapted from https://github.com/adamgreen/gcc4mbed

# Vendor/device for which the library should be built.
MBED_DEVICE        := LPC1768
MBED_TARGET        := NXP_LPC17XX
MBED_CLEAN         := $(MBED_DEVICE)-MBED-clean

# Compiler flags which are specifc to this device.
TARGETS_FOR_DEVICE := TARGET_LPC1768 TARGET_M3 TARGET_NXP TARGET_LPC176X TARGET_MBED_LPC1768 TARGET_CORTEX_M
GCC_DEFINES := $(patsubst %,-D%,$(TARGETS_FOR_DEVICE))
GCC_DEFINES += -D__CORTEX_M3 -DARM_MATH_CM3

C_FLAGS   := -mcpu=cortex-m3 -mthumb -mthumb-interwork
ASM_FLAGS := -mcpu=cortex-m3 -mthumb
LD_FLAGS  := -mcpu=cortex-m3 -mthumb

# Extra platform specific object files to link into file binary.
DEVICE_OBJECTS :=

# Linker script to be used.  Indicates what code should be placed where in memory.
LSCRIPT=$(MBED_CMSIS_ROOT)/TARGET_NXP/TARGET_LPC176X/TOOLCHAIN_GCC_ARM/LPC1768.ld

include $(WORKSPACE_ROOT)/build/device-common.mk
