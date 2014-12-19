# Vendor/device for which the library should be built.
MBED_DEVICE        := NRF51822
MBED_TARGET        := NRF51822_MKIT
MBED_CLEAN         := $(MBED_DEVICE)-MBED-clean

# Compiler flags which are specifc to this device.
TARGETS_FOR_DEVICE := TARGET_NRF51822 TARGET_M0 TARGET_NORDIC TARGET_NRF51822_MKIT TARGET_MCU_NRF51822
TARGETS_FOR_DEVICE += TARGET_MCU_NORDIC_16K TARGET_CORTEX_M
GCC_DEFINES := $(patsubst %,-D%,$(TARGETS_FOR_DEVICE))
GCC_DEFINES += -D__CORTEX_M0 -DARM_MATH_CM0

C_FLAGS   := -mcpu=cortex-m0 -mthumb -mthumb-interwork
ASM_FLAGS := -mcpu=cortex-m0 -mthumb
LD_FLAGS  := -mcpu=cortex-m0 -mthumb -Wl,--no-warn-mismatch

# Extra platform specific object files to link into file binary.
# For NRF51 parts, we add in the softdevice.
DEVICE_OBJECTS := $(MBED_DEVICE)/s110_nrf51822_7.1.0_softdevice.o

# Linker script to be used.  Indicates what code should be placed where in memory.
#LSCRIPT=$(WORKSPACE_ROOT)/build/NRF51822.ld
LSCRIPT=$(MBED_CMSIS_ROOT)/TARGET_NORDIC/TARGET_MCU_NRF51822/TOOLCHAIN_GCC_ARM/TARGET_MCU_NORDIC_16K/NRF51822.ld

include $(WORKSPACE_ROOT)/build/device-common.mk

# Rules to build the SoftDevice object file.
$(MBED_DEVICE)/s110_nrf51822_7.1.0_softdevice.bin : $(MBED_HAL_ROOT)/TARGET_NORDIC/TARGET_MCU_NRF51822/Lib/s110_nrf51822_7_1_0/s110_nrf51822_7.1.0_softdevice.hex
	$(Q) $(OBJCOPY) -I ihex -O binary --gap-fill 0xFF $< $@

$(MBED_DEVICE)/s110_nrf51822_7.1.0_softdevice.o : $(MBED_DEVICE)/s110_nrf51822_7.1.0_softdevice.bin
	$(Q) $(OBJCOPY) -I binary -O elf32-littlearm -B arm --rename-section .data=.SoftDevice $< $@
