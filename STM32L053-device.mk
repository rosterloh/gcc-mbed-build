# Vendor/device for which the library should be built.
MBED_DEVICE        := STM32L053
MBED_TARGET        := DISCO_L053C8
MBED_CLEAN         := $(MBED_DEVICE)-MBED-clean

# Some libraries (mbed and rtos) have device specific source folders.
HAL_TARGET_SRC   := $(TARGETS_HAL)/TARGET_STM/TARGET_DISCO_L053C8
CMSIS_TARGET_SRC := $(CMSIS_COMMON_HEADERS)/TARGET_STM/TARGET_STM32L0
CMSIS_TARGET_SRC += $(CMSIS_COMMON_HEADERS)/TARGET_STM/TARGET_STM32L0/TARGET_DISCO_L053C8
CMSIS_TARGET_SRC += $(CMSIS_COMMON_HEADERS)/TARGET_STM/TARGET_STM32L0/TARGET_DISCO_L053C8/TOOLCHAIN_GCC_ARM
RTX_TARGET_SRC   := $(MBED_LIB_SRC_ROOT)/rtos/rtx/TARGET_CORTEX_M/TARGET_M0P/TOOLCHAIN_GCC

# Compiler flags which are specifc to this device.
GCC_DEFINES := -DTARGET_STM -DTARGET_M0P -DTARGET_STM32L0 -DTARGET_STM32L053C8
GCC_DEFINES += -D__CORTEX_M0PLUS -DARM_MATH_CM0PLUS

#C_FLAGS   := -mcpu=cortex-m0plus -mthumb -mthumb-interwork
C_FLAGS   := -mcpu=cortex-m0plus -mthumb
ASM_FLAGS := -mcpu=cortex-m0plus -mthumb
LD_FLAGS  := -mcpu=cortex-m0plus -mthumb

# Extra platform specific object files to link into file binary.
+DEVICE_OBJECTS :=

# Linker script to be used.  Indicates what code should be placed where in memory.
#LSCRIPT=$(CMSIS_COMMON_HEADERS)/TARGET_STM/TARGET_STM32L0/TARGET_DISCO_L053C8/TOOLCHAIN_GCC_ARM/STM32L053C8_FLASH.ld
LSCRIPT=$(CMSIS_COMMON_HEADERS)/TARGET_STM/TARGET_STM32L0/TARGET_DISCO_L053C8/TOOLCHAIN_GCC_ARM/STM32L0xx.ld

include $(WORKSPACE_ROOT)/build/device-common.mk
