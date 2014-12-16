# Adapted from https://github.com/adamgreen/gcc4mbed

# Vendor/device for which the library should be built.
MBED_DEVICE        := LPC11U24
MBED_TARGET        := NXP_LPC11U24
MBED_CLEAN         := $(MBED_DEVICE)-MBED-clean

# Compiler flags which are specifc to this device.
TARGETS_FOR_DEVICE := TARGET_LPC11U24 TARGET_M0 TARGET_NXP TARGET_LPC11UXX TARGET_LPC11U24_401 TARGET_CORTEX_M
GCC_DEFINES := $(patsubst %,-D%,$(TARGETS_FOR_DEVICE))
GCC_DEFINES += -D__CORTEX_M0 -DARM_MATH_CM0

C_FLAGS   := -mcpu=cortex-m0 -mthumb -mthumb-interwork
ASM_FLAGS := -mcpu=cortex-m0 -mthumb
LD_FLAGS  := -mcpu=cortex-m0 -mthumb

# Extra platform specific object files to link into file binary.
DEVICE_OBJECTS :=

# Linker script to be used.  Indicates what code should be placed where in memory.
LSCRIPT=$(MBED_CMSIS_ROOT)/TARGET_NXP/TARGET_LPC11UXX/TOOLCHAIN_GCC_ARM/TARGET_LPC11U24_401/LPC11U24.ld


include $(WORKSPACE_ROOT)/build/device-common.mk
