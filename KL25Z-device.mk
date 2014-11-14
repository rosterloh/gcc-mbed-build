# Adapted from https://github.com/adamgreen/gcc4mbed

# Vendor/device for which the library should be built.
MBED_DEVICE        := KL25Z
MBED_TARGET        := Freescale_KL25Z
MBED_CLEAN         := $(MBED_DEVICE)-MBED-clean

# Some libraries (mbed and rtos) have device specific source folders.
HAL_TARGET_SRC   := $(TARGETS_HAL)/TARGET_Freescale/TARGET_KLXX
HAL_TARGET_SRC   += $(TARGETS_HAL)/TARGET_Freescale/TARGET_KLXX/TARGET_KL25Z
CMSIS_TARGET_SRC := $(CMSIS_COMMON_HEADERS)/TARGET_Freescale/TARGET_KLXX/TARGET_KL25Z
CMSIS_TARGET_SRC += $(CMSIS_COMMON_HEADERS)/TARGET_Freescale/TARGET_KLXX/TARGET_KL25Z/TOOLCHAIN_GCC_ARM
RTX_TARGET_SRC   := $(MBED_LIB_SRC_ROOT)/rtos/rtx/TARGET_CORTEX_M/TARGET_M0P/TOOLCHAIN_GCC

# Compiler flags which are specifc to this device.
GCC_DEFINES := -DTARGET_KL25Z -DTARGET_M0P -DTARGET_Freescale -DTARGET_KLXX
GCC_DEFINES += -D__CORTEX_M0PLUS -DARM_MATH_CM0PLUS

C_FLAGS   := -mcpu=cortex-m0plus -mthumb -mthumb-interwork
ASM_FLAGS := -mcpu=cortex-m0plus -mthumb
LD_FLAGS  := -mcpu=cortex-m0plus -mthumb

# Extra platform specific object files to link into file binary.
DEVICE_OBJECTS :=

# Linker script to be used.  Indicates what code should be placed where in memory.
LSCRIPT=$(CMSIS_COMMON_HEADERS)/TARGET_Freescale/TARGET_KLXX/TARGET_KL25Z/TOOLCHAIN_GCC_ARM/MKL25Z4.ld


include $(WORKSPACE_ROOT)/build/device-common.mk
