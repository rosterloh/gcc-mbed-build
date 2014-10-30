# Adapted from https://github.com/adamgreen/gcc4mbed

# Vendor/device for which the library should be built.
MBED_DEVICE        := LPC1768
MBED_TARGET        := NXP_LPC17XX
MBED_CLEAN         := $(MBED_DEVICE)-MBED-clean

# Some libraries (mbed and rtos) have device specific source folders.
HAL_TARGET_SRC   := $(TARGETS_HAL)/TARGET_NXP/TARGET_LPC176X
HAL_TARGET_SRC   += $(TARGETS_HAL)/TARGET_NXP/TARGET_LPC176X/TARGET_MBED_LPC1768
CMSIS_TARGET_SRC := $(CMSIS_COMMON_HEADERS)/TARGET_NXP/TARGET_LPC176X
CMSIS_TARGET_SRC += $(CMSIS_COMMON_HEADERS)/TARGET_NXP/TARGET_LPC176X/TOOLCHAIN_GCC_ARM
RTX_TARGET_SRC   := $(MBED_LIB_SRC_ROOT)/rtos/rtx/TARGET_M3/TOOLCHAIN_GCC
ETH_TARGET_SRC   := $(MBED_LIB_SRC_ROOT)/net/eth/lwip-eth/arch/TARGET_NXP


# Compiler flags which are specifc to this device.
GCC_DEFINES := -DTARGET_LPC1768 -DTARGET_M3 -DTARGET_NXP -DTARGET_LPC176X -DTARGET_MBED_LPC1768
GCC_DEFINES += -D__CORTEX_M3 -DARM_MATH_CM3

C_FLAGS   := -mcpu=cortex-m3 -mthumb -mthumb-interwork
ASM_FLAGS := -mcpu=cortex-m3 -mthumb
LD_FLAGS  := -mcpu=cortex-m3 -mthumb


# Linker script to be used.  Indicates what code should be placed where in memory.
LSCRIPT=$(CMSIS_COMMON_HEADERS)/TARGET_NXP/TARGET_LPC176X/TOOLCHAIN_GCC_ARM/LPC1768.ld


include $(WORKSPACE_ROOT)/build/device-common.mk
