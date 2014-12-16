# Adapted from https://github.com/adamgreen/gcc4mbed

# Vendor/device for which the library should be built.
MBED_DEVICE        := NUCLEO_F401RE
MBED_TARGET        := STM_NUCLEO_F401RE
MBED_CLEAN         := $(MBED_DEVICE)-MBED-clean

# Compiler flags which are specifc to this device.
TARGETS_FOR_DEVICE := TARGET_NUCLEO_F401RE TARGET_M4 TARGET_CORTEX_M TARGET_STM TARGET_STM32F4 TARGET_STM32F401RE
TARGETS_FOR_DEVICE += TARGET_FF_ARDUINO TARGET_FF_MORPHO
GCC_DEFINES := $(patsubst %,-D%,$(TARGETS_FOR_DEVICE))
GCC_DEFINES += -D__CORTEX_M4 -DARM_MATH_CM4 -D__FPU_PRESENT=1

C_FLAGS   := -mcpu=cortex-m4 -mthumb -mthumb-interwork -mfpu=fpv4-sp-d16 -mfloat-abi=softfp
ASM_FLAGS := -mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16
LD_FLAGS  := -mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16

# Extra platform specific object files to link into file binary.
DEVICE_OBJECTS :=

# Linker script to be used.  Indicates what code should be placed where in memory.
LSCRIPT=$(MBED_CMSIS_ROOT)/TARGET_STM/TARGET_NUCLEO_F401RE/TOOLCHAIN_GCC_ARM/NUCLEO_F401RE.ld

include $(WORKSPACE_ROOT)/build/device-common.mk
