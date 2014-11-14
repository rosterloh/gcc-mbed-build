# Adapted from https://github.com/adamgreen/gcc4mbed

# Vendor/device for which the library should be built.
MBED_DEVICE        := LPC11U24
MBED_TARGET        := NXP_LPC11U24
MBED_CLEAN         := $(MBED_DEVICE)-MBED-clean

# Some libraries (mbed and rtos) have device specific source folders.
HAL_TARGET_SRC   := $(TARGETS_HAL)/TARGET_NXP/TARGET_LPC11UXX
HAL_TARGET_SRC   += $(TARGETS_HAL)/TARGET_NXP/TARGET_LPC11UXX/TARGET_LPC11U24_401
CMSIS_TARGET_SRC := $(CMSIS_COMMON_HEADERS)/TARGET_NXP/TARGET_LPC11UXX
CMSIS_TARGET_SRC += $(CMSIS_COMMON_HEADERS)/TARGET_NXP/TARGET_LPC11UXX/TOOLCHAIN_GCC_ARM
RTX_TARGET_SRC   := $(MBED_LIB_SRC_ROOT)/rtos/rtx/TARGET_CORTEX_M/TARGET_M0/TOOLCHAIN_GCC


# Compiler flags which are specifc to this device.
GCC_DEFINES := -DTARGET_LPC11U24 -DTARGET_M0 -DTARGET_NXP -DTARGET_LPC11UXX -DTARGET_LPC11U24_401
GCC_DEFINES += -D__CORTEX_M0 -DARM_MATH_CM0

C_FLAGS   := -mcpu=cortex-m0 -mthumb -mthumb-interwork
ASM_FLAGS := -mcpu=cortex-m0 -mthumb
LD_FLAGS  := -mcpu=cortex-m0 -mthumb

# Extra platform specific object files to link into file binary.
DEVICE_OBJECTS :=

# Linker script to be used.  Indicates what code should be placed where in memory.
LSCRIPT=$(CMSIS_COMMON_HEADERS)/TARGET_NXP/TARGET_LPC11UXX/TOOLCHAIN_GCC_ARM/TARGET_LPC11U24_401/LPC11U24.ld


include $(WORKSPACE_ROOT)/build/device-common.mk
