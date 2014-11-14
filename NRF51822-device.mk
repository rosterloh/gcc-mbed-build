# Vendor/device for which the library should be built.
MBED_DEVICE        := NRF51822
MBED_TARGET        := NRF51822_MKIT
MBED_CLEAN         := $(MBED_DEVICE)-MBED-clean

# Some libraries (mbed and rtos) have device specific source folders.
HAL_TARGET_SRC   := $(TARGETS_HAL)/TARGET_NORDIC/TARGET_MCU_NRF51822
HAL_TARGET_SRC   += $(TARGETS_HAL)/TARGET_NORDIC/TARGET_MCU_NRF51822/TARGET_NRF51822_MKIT
HAL_TARGET_SRC   += $(TARGETS_HAL)/TARGET_NORDIC/TARGET_MCU_NRF51822/Lib/app_common
HAL_TARGET_SRC   += $(TARGETS_HAL)/TARGET_NORDIC/TARGET_MCU_NRF51822/Lib/nrf-sdk
HAL_TARGET_SRC   += $(TARGETS_HAL)/TARGET_NORDIC/TARGET_MCU_NRF51822/Lib/nrf-sdk/app_common
HAL_TARGET_SRC   += $(TARGETS_HAL)/TARGET_NORDIC/TARGET_MCU_NRF51822/Lib/nrf-sdk/sd_common
HAL_TARGET_SRC   += $(TARGETS_HAL)/TARGET_NORDIC/TARGET_MCU_NRF51822/Lib/s110_nrf51822_7_1_0/s110_nrf51822_7.1.0_API/include
CMSIS_TARGET_SRC := $(CMSIS_COMMON_HEADERS)/TARGET_NORDIC/TARGET_MCU_NRF51822/
CMSIS_TARGET_SRC += $(CMSIS_COMMON_HEADERS)/TARGET_NORDIC/TARGET_MCU_NRF51822/TOOLCHAIN_GCC_ARM
RTX_TARGET_SRC   := $(MBED_LIB_SRC_ROOT)/rtos/rtx/TARGET_CORTEX_M/TARGET_M0/TOOLCHAIN_GCC

# Compiler flags which are specifc to this device.
GCC_DEFINES := -DTARGET_NRF51822 -DTARGET_M0 -DTARGET_NORDIC -DTAGET_NRF51822_MKIT -DTARGET_MCU_NRF51822 -DTARGET_MCU_NORDIC_16K
GCC_DEFINES += -D__CORTEX_M0 -DARM_MATH_CM0

C_FLAGS   := -mcpu=cortex-m0 -mthumb -mthumb-interwork
ASM_FLAGS := -mcpu=cortex-m0 -mthumb
LD_FLAGS  := -mcpu=cortex-m0 -mthumb

# Extra platform specific object files to link into file binary.
# For NRF51 parts, we add in the softdevice.
DEVICE_OBJECTS := $(MBED_DEVICE)/s110_nrf51822_7.1.0_softdevice.o

# Linker script to be used.  Indicates what code should be placed where in memory.
#LSCRIPT=$(WORKSPACE_ROOT)/build/NRF51822.ld
LSCRIPT=$(CMSIS_COMMON_HEADERS)/TARGET_NORDIC/TARGET_MCU_NRF51822/TOOLCHAIN_GCC_ARM/TARGET_MCU_NORDIC_16K/NRF51822.ld

include $(WORKSPACE_ROOT)/build/device-common.mk

# Rules to build the SoftDevice object file.
$(MBED_DEVICE)/s110_nrf51822_7.1.0_softdevice.bin : $(MBED_SRC_ROOT)/targets/hal/TARGET_NORDIC/TARGET_MCU_NRF51822/Lib/s110_nrf51822_7_1_0/s110_nrf51822_7.1.0_softdevice.hex
	$(Q) $(OBJCOPY) -I ihex -O binary --gap-fill 0xFF $< $@

$(MBED_DEVICE)/s110_nrf51822_7.1.0_softdevice.o : $(MBED_DEVICE)/s110_nrf51822_7.1.0_softdevice.bin
	$(Q) $(OBJCOPY) -I binary -O elf32-littlearm -B arm --rename-section .data=.SoftDevice $< $@
