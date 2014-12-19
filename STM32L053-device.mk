# Vendor/device for which the library should be built.
MBED_DEVICE        := STM32L053
MBED_TARGET        := DISCO_L053C8
MBED_CLEAN         := $(MBED_DEVICE)-MBED-clean

# Compiler flags which are specifc to this device.
TARGETS_FOR_DEVICE := TARGET_DISCO_L053C8 TARGET_M0P TARGET_STM TARGET_STM32L0 TARGET_STM32L053C8 TARGET_CORTEX_M
GCC_DEFINES := $(patsubst %,-D%,$(TARGETS_FOR_DEVICE))
GCC_DEFINES += -D__CORTEX_M0PLUS -DARM_MATH_CM0PLUS

C_FLAGS   := -mcpu=cortex-m0plus -mthumb -mthumb-interwork -msoft-float
ASM_FLAGS := -mcpu=cortex-m0plus -mthumb -mthumb-interwork -msoft-float
LD_FLAGS  := -mcpu=cortex-m0plus -mthumb -msoft-float

# Extra platform specific object files to link into file binary.
DEVICE_OBJECTS :=

# Linker script to be used.  Indicates what code should be placed where in memory.
LSCRIPT=$(MBED_CMSIS_ROOT)/TARGET_STM/TARGET_STM32L0/TARGET_DISCO_L053C8/TOOLCHAIN_GCC_ARM/STM32L053X8.ld

include $(WORKSPACE_ROOT)/build/device-common.mk
