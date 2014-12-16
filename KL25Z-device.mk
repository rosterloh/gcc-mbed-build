# Adapted from https://github.com/adamgreen/gcc4mbed

# Vendor/device for which the library should be built.
MBED_DEVICE        := KL25Z
MBED_TARGET        := Freescale_KL25Z
MBED_CLEAN         := $(MBED_DEVICE)-MBED-clean

# Compiler flags which are specifc to this device.
TARGETS_FOR_DEVICE := TARGET_KL25Z TARGET_M0P TARGET_Freescale TARGET_KLXX TARGET_CORTEX_M
GCC_DEFINES := $(patsubst %,-D%,$(TARGETS_FOR_DEVICE))
GCC_DEFINES += -D__CORTEX_M0PLUS -DARM_MATH_CM0PLUS

C_FLAGS   := -mcpu=cortex-m0plus -mthumb -mthumb-interwork
ASM_FLAGS := -mcpu=cortex-m0plus -mthumb
LD_FLAGS  := -mcpu=cortex-m0plus -mthumb

# Extra platform specific object files to link into file binary.
DEVICE_OBJECTS :=

# Linker script to be used.  Indicates what code should be placed where in memory.
LSCRIPT=$(MBED_CMSIS_ROOT)/TARGET_Freescale/TARGET_KLXX/TARGET_KL25Z/TOOLCHAIN_GCC_ARM/MKL25Z4.ld


include $(WORKSPACE_ROOT)/build/device-common.mk
