# Adapted from https://github.com/adamgreen/gcc4mbed

# Can skip parsing of this makefile if user hasn't requested this device.
ifeq "$(findstring $(MBED_DEVICE),$(DEVICES))" "$(MBED_DEVICE)"

###############################################################################
# Setup flags that are common across the different pieces of code to be built.
###############################################################################
# Optimization levels to be used for Debug and Release versions of libraries.
DEBUG_OPTIMIZATION   := g
RELEASE_OPTIMIZATION := s

# Compiler flags used to enable creation of header dependency files.
DEP_FLAGS := -MMD -MP

# Preprocessor defines to use when compiling/assembling code with GCC.
GCC_DEFINES += -DTOOLCHAIN_GCC_ARM -DTOOLCHAIN_GCC -D__MBED__=1

# Flags to be used with C/C++ compiler that are shared between Debug and Release builds.
#C_FLAGS += -g3 -ffunction-sections -fdata-sections -fno-exceptions -fno-delete-null-pointer-checks -fomit-frame-pointer
#C_FLAGS += -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers -Wno-missing-braces
C_FLAGS += -c -g -fno-common -fmessage-length=0 -Wall -fno-exceptions -ffunction-sections -fdata-sections -fomit-frame-pointer
C_FLAGS += $(GCC_DEFINES)
C_FLAGS += $(DEP_FLAGS)

# MBED uses -std=gnu++98 not -std=gnu++11
CPP_FLAGS := $(C_FLAGS) -std=gnu++98 -fno-rtti
C_FLAGS   += -std=gnu99

# Flags used to assemble assembly languages sources.
ASM_FLAGS += -g3 -x assembler-with-cpp $(GCC_DEFINES)

# Clear out the include path for the mbed libraries required to build this project.
MBED_INCLUDES :=

# Directories where mbed library output files should be placed.
RELEASE_DIR :=$(LIB_RELEASE_DIR)/$(MBED_TARGET)
DEBUG_DIR   :=$(LIB_DEBUG_DIR)/$(MBED_TARGET)

###############################################################################
# Build Main Application
###############################################################################
# Output Object Directory.
OUTDIR := build/$(MBED_DEVICE)

# Final target binary.  Used for variable target scoping.
TARGET_BIN := $(OUTDIR)/$(PROJECT).bin

# List of the objects files to be compiled/assembled based on source files in SRC.
OBJECTS := $(call srcs2objs,$(call recurse_dir,$(SRC)),$(SRC),$(OUTDIR))

# Initialize list of the header dependency files, one per object file. Each mbed SDK library will append to this list.
DEPFILES := $(patsubst %.o,%.d,$(OBJECTS))

# Include path which points to subdirectories of this project and user specified directory.
INCLUDE_DIRS := $(patsubst %,-I%,$(INCDIRS) $(SRC) $(call recurse_dir,$(SRC)))

# DEFINEs to be used when building C/C++ code
MAIN_DEFINES := $(DEFINES)

# Libraries to be linked into final binary
SYS_LIBS  := -lstdc++ -lsupc++ -lm -lc -lgcc -lnosys
LIBS      := $(LIBS_PREFIX)

# Some choices like mbed SDK library locations and enabling of asserts depend on build type.
ifeq "$(GCC4MBED_TYPE)" "Debug"
MBED_LIBRARIES := $(patsubst %,$(DEBUG_DIR)/%.a,$(MBED_LIBS))
else
MBED_LIBRARIES := $(patsubst %,$(RELEASE_DIR)/%.a,$(MBED_LIBS))
MAIN_DEFINES   += -DNDEBUG
endif

LIBS      += $(MBED_LIBRARIES)
LIBS      += $(LIBS_SUFFIX)

# Compiler/Assembler options to use when building application for this device.
$(MBED_DEVICE): C_FLAGS   := -O$(OPTIMIZATION) $(C_FLAGS) $(MAIN_DEFINES) $(INCLUDE_DIRS) $(GCFLAGS)
$(MBED_DEVICE): CPP_FLAGS := -O$(OPTIMIZATION) $(CPP_FLAGS) $(MAIN_DEFINES) $(INCLUDE_DIRS) $(GPFLAGS)
$(MBED_DEVICE): ASM_FLAGS := $(ASM_FLAGS) $(GAFLAGS) $(INCLUDE_DIRS)

# Linker Options.
#$(MBED_DEVICE): LD_FLAGS := $(LD_FLAGS) -Wl,--gc-sections -Wl,--wrap=main --specs=nano.specs
$(MBED_DEVICE): LD_FLAGS := $(LD_FLAGS) -Wl,--gc-sections --specs=nano.specs
#$(MBED_DEVICE): LD_FLAGS +=	-u _printf_float -u _scanf_float
$(MBED_DEVICE): LD_FLAGS += -Wl,-Map=$(OUTDIR)/$(PROJECT).map,--cref
#	-mfloat-abi=soft

.PHONY: $(MBED_DEVICE) $(MBED_DEVICE)-clean $(MBED_DEVICE)-deploy $(MBED_DEVICE)-size

$(MBED_DEVICE): $(TARGET_BIN) $(OUTDIR)/$(PROJECT).hex $(OUTDIR)/$(PROJECT).disasm $(MBED_DEVICE)-size

$(TARGET_BIN): $(OUTDIR)/$(PROJECT).elf
	@echo Extracting $@
	$(Q) $(OBJCOPY) -O binary $< $@

$(OUTDIR)/$(PROJECT).hex: $(OUTDIR)/$(PROJECT).elf
	@echo Extracting $@
	$(Q) $(OBJCOPY) -R .stack -O ihex $< $@

$(OUTDIR)/$(PROJECT).disasm: $(OUTDIR)/$(PROJECT).elf
	@echo Extracting disassembly to $@
	$(Q) $(OBJDUMP) -d -f -M reg-names-std --demangle $< >$@

$(OUTDIR)/$(PROJECT).elf: $(LSCRIPT) $(OBJECTS) $(LIBS)
	@echo Linking $@
	$(Q) $(LD) $(LD_FLAGS) -T$+ $(SYS_LIBS) -o $@

$(MBED_DEVICE)-size: $(OUTDIR)/$(PROJECT).elf
	$(Q) $(SIZE) $<
	@$(BLANK_LINE)

$(MBED_DEVICE)-clean: CLEAN_TARGET := $(OUTDIR)
$(MBED_DEVICE)-clean: PROJECT      := $(PROJECT)
$(MBED_DEVICE)-clean:
	@echo Cleaning $(PROJECT)/$(CLEAN_TARGET)
	$(Q) $(REMOVE_DIR) $(CLEAN_TARGET) $(QUIET)
	$(Q) $(REMOVE) $(PROJECT).bin $(QUIET)
	$(Q) $(REMOVE) $(PROJECT).hex $(QUIET)
	$(Q) $(REMOVE) $(PROJECT).elf $(QUIET)

$(OUTDIR)/%.o : $(SRC)/%.cpp makefile
	@echo Compiling $<
	$(Q) $(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(Q) $(GPP) $(CPP_FLAGS) $(MBED_INCLUDES) -c $< -o $@

$(OUTDIR)/%.o : $(SRC)/%.c makefile
	@echo Compiling $<
	$(Q) $(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(Q) $(GCC) $(C_FLAGS) $(MBED_INCLUDES) -c $< -o $@

$(OUTDIR)/%.o : $(SRC)/%.S makefile
	@echo Assembling $<
	$(Q) $(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(Q) $(GCC) $(ASM_FLAGS) $(MBED_INCLUDES) -c $< -o $@

$(OUTDIR)/%.o : $(SRC)/%.S makefile
	@echo Assembling $<
	$(Q) $(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(Q) $(GCC) $(ASM_FLAGS) $(MBED_INCLUDES) -c $< -o $@


###############################################################################
# Library mbed.a
###############################################################################
$(eval $(call build_lib,mbed,\
                       $(HAL_TARGET_SRC) $(CMSIS_TARGET_SRC) $(COMMON_SRC),\
                       $(API_HEADERS) $(HAL_HEADERS) $(CMSIS_COMMON_HEADERS) $(HAL_TARGET_SRC) $(CMSIS_TARGET_SRC)))

###############################################################################
# Library rtos.a
###############################################################################
$(eval $(call build_lib,rtos,\
                       $(RTOS_DIRS) $(RTX_TARGET_SRC),\
                       $(RTOS_DIRS)))

###############################################################################
# Library net/lwip.a
###############################################################################
$(eval $(call build_lib,net/lwip,$(LWIP_DIRS),$(LWIP_DIRS)))

###############################################################################
# Library net/eth.a
###############################################################################
$(eval $(call build_lib,net/eth,$(ETH_DIRS) $(ETH_TARGET_SRC),$(ETH_DIRS) $(ETH_TARGET_SRC)))

###############################################################################
# Library fs.a
###############################################################################
$(eval $(call build_lib,fs,$(FS_DIRS),$(FS_DIRS)))

###############################################################################
# Library USBDevice.a
###############################################################################
$(eval $(call build_lib,USBDevice,$(USB_DEVICE_DIRS),$(USB_DEVICE_DIRS)))

###############################################################################
# Library USBHost.a
###############################################################################
$(eval $(call build_lib,USBHost,$(USB_HOST_DIRS),$(USB_HOST_DIRS)))

###############################################################################
# Library rpc.a
###############################################################################
$(eval $(call build_lib,rpc,$(RPC_DIRS),$(RPC_DIRS)))

###############################################################################
# Library dsp.a
###############################################################################
$(eval $(call build_lib,dsp,$(DSP_DIRS),$(DSP_DIRS)))


#########################################################################
#  Default rules to compile c/c++/assembly language sources to objects.
#########################################################################
$(DEBUG_DIR)/%.o : $(MBED_LIB_SRC_ROOT)/%.c
	@echo Compiling $<
	$(Q) $(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(Q) $(GCC) $(C_FLAGS) $(MBED_INCLUDES) -c $< -o $@

$(RELEASE_DIR)/%.o : $(MBED_LIB_SRC_ROOT)/%.c
	@echo Compiling $<
	$(Q) $(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(Q) $(GCC) $(C_FLAGS) $(MBED_INCLUDES) -c $< -o $@

$(DEBUG_DIR)/%.o : $(MBED_LIB_SRC_ROOT)/%.cpp
	@echo Compiling $<
	$(Q) $(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(Q) $(GPP) $(CPP_FLAGS) $(MBED_INCLUDES) -c $< -o $@

$(RELEASE_DIR)/%.o : $(MBED_LIB_SRC_ROOT)/%.cpp
	@echo Compiling $<
	$(Q) $(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(Q) $(GPP) $(CPP_FLAGS) $(MBED_INCLUDES) -c $< -o $@

$(DEBUG_DIR)/%.o : $(MBED_LIB_SRC_ROOT)/%.s
	@echo Assembling $<
	$(Q) $(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(Q) $(GCC) $(ASM_FLAGS) $(MBED_INCLUDES) -c $< -o $@

$(RELEASE_DIR)/%.o : $(MBED_LIB_SRC_ROOT)/%.s
	@echo Assembling $<
	$(Q) $(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(Q) $(GCC) $(ASM_FLAGS) $(MBED_INCLUDES) -c $< -o $@

$(DEBUG_DIR)/%.o : $(MBED_LIB_SRC_ROOT)/%.S
	@echo Assembling $<
	$(Q) $(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(Q) $(GCC) $(ASM_FLAGS) $(MBED_INCLUDES) -c $< -o $@

$(RELEASE_DIR)/%.o : $(MBED_LIB_SRC_ROOT)/%.S
	@echo Assembling $<
	$(Q) $(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(Q) $(GCC) $(ASM_FLAGS) $(MBED_INCLUDES) -c $< -o $@


#########################################################################
# High level rule for cleaning out all official mbed libraries.
#########################################################################
.PHONY: $(MBED_CLEAN)

$(MBED_CLEAN): CLEAN_TARGETS:=$(DEBUG_DIR) $(RELEASE_DIR)
$(MBED_CLEAN):
	@echo Cleaning $(CLEAN_TARGETS)
	$(Q) $(REMOVE_DIR) $(call convert-slash,$(CLEAN_TARGETS)) $(QUIET)


# Pull in all library header dependencies.
-include $(DEPFILES)


# When building the project for this device, use this scoped include path for
# the mbed components used.
$(MBED_DEVICE): MBED_INCLUDES := $(patsubst %,-I%,$(MBED_INCLUDES))


else
# Have an empty rule for this device since it isn't supported.
.PHONY: $(MBED_DEVICE)

$(MBED_DEVICE):
	@#

endif # ifeq "$(findstring $(MBED_DEVICE),$(DEVICES))"...
