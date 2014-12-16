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
GCC_DEFINES += $(TOOLCHAIN_DEFINES) -DTOOLCHAIN_GCC -D__MBED__=1

# Flags to be used with C/C++ compiler that are shared between Debug and Release builds.
C_FLAGS += -g3 -ffunction-sections -fdata-sections -fno-exceptions -fno-delete-null-pointer-checks -fomit-frame-pointer
C_FLAGS += -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers -Wno-missing-braces -fno-builtin -fmessage-length=0
#C_FLAGS += -Wredundant-decls -Wundef -Wshadow
#C_FLAGS += -c -g -fno-common
C_FLAGS += $(GCC_DEFINES)
C_FLAGS += $(DEP_FLAGS)

# MBED uses -std=gnu++98 not -std=gnu++11
CPP_FLAGS := $(C_FLAGS) -fno-rtti -std=gnu++11
C_FLAGS   += -std=gnu99
# C only but enabled by default -Wimplicit-function-declaration -Wmissing-prototypes -Wstrict-prototypes

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
OBJECTS := $(call srcs2objs,$(call filter_dirs,$(call recurse_dir,$(SRC)),$(TARGETS_FOR_DEVICE)),$(SRC),$(OUTDIR))

# Add in device specific object file(s).
OBJECTS += $(DEVICE_OBJECTS)

# Initialize list of the header dependency files, one per object file. Each mbed SDK library will append to this list.
DEPFILES := $(patsubst %.o,%.d,$(OBJECTS))

# Include path which points to subdirectories of this project and user specified directory.
INCLUDE_DIRS := $(patsubst %,-I%,$(INCDIRS) $(SRC) $(call filter_dirs,$(call recurse_dir,$(SRC)),$(TARGETS_FOR_DEVICE)))

# DEFINEs to be used when building C/C++ code
MAIN_DEFINES := $(DEFINES)

# Libraries to be linked into final binary
SYS_LIBS  := -lstdc++ -lsupc++ -lm -lgcc -lc -lgcc -lc -lnosys
LIBS      := $(LIBS_PREFIX)

# Some choices like mbed SDK library locations and enabling of asserts depend on build type.
ifeq "$(BUILD_TYPE)" "Debug"
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
$(MBED_DEVICE): LD_FLAGS := $(LD_FLAGS) --specs=nano.specs -u mbed_sdk_init -u mbed_main
$(MBED_DEVICE): LD_FLAGS += -Wl,-Map=$(OUTDIR)/$(PROJECT).map,--cref,--gc-sections,--wrap=main
ifneq "$(NO_FLOAT_SCANF)" "1"
$(MBED_DEVICE): LD_FLAGS += -u _scanf_float
endif
ifneq "$(NO_FLOAT_PRINTF)" "1"
$(MBED_DEVICE): LD_FLAGS += -u _printf_float
endif
#	--wrap=_isatty,--wrap=malloc,--wrap=realloc,--wrap=free,--wrap=_read,--wrap=_write,--wrap=semihost_connected

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
MBED_DIRS := $(call filter_dirs,$(call recurse_dir,$(MBED_SRC_ROOT)),$(TARGETS_FOR_DEVICE))
$(eval $(call build_lib,mbed,\
												$(MBED_DIRS),\
												$(MBED_DIRS)))

###############################################################################
# Library rtos.a
###############################################################################
ifeq "$(findstring rtos,$(MBED_LIBS))" "rtos"
	RTOS_DIRS := $(call filter_dirs,$(call recurse_dir,$(MBED_LIB_SRC_ROOT)/rtos),$(TARGETS_FOR_DEVICE))
	$(eval $(call build_lib,rtos,$(RTOS_DIRS),$(RTOS_DIRS)))
endif

###############################################################################
# Library net/lwip.a
###############################################################################
ifeq "$(findstring net/lwip,$(MBED_LIBS))" "net/lwip"
	LWIP_DIRS := $(call filter_dirs,$(call recurse_dir,$(MBED_LIB_SRC_ROOT)/net/lwip),$(TARGETS_FOR_DEVICE))
	$(eval $(call build_lib,net/lwip,$(LWIP_DIRS),$(LWIP_DIRS)))
endif

###############################################################################
# Library net/eth.a
###############################################################################
ifeq "$(findstring net/eth,$(MBED_LIBS))" "net/eth"
	ETH_DIRS := $(call filter_dirs,$(call recurse_dir,$(MBED_LIB_SRC_ROOT)/net/eth),$(TARGETS_FOR_DEVICE))
	$(eval $(call build_lib,net/eth,$(ETH_DIRS),$(ETH_DIRS)))
endif

###############################################################################
# Library fs.a
###############################################################################
ifeq "$(findstring fs,$(MBED_LIBS))" "fs"
FS_DIRS := $(call filter_dirs,$(call recurse_dir,$(MBED_LIB_SRC_ROOT)/fs),$(TARGETS_FOR_DEVICE))
$(eval $(call build_lib,fs,$(FS_DIRS),$(FS_DIRS)))
endif

###############################################################################
# Library USBDevice.a
###############################################################################
ifeq "$(findstring USBDevice,$(MBED_LIBS))" "USBDevice"
USB_DEVICE_DIRS := $(call filter_dirs,$(call recurse_dir,$(MBED_LIB_SRC_ROOT)/USBDevice),$(TARGETS_FOR_DEVICE))
$(eval $(call build_lib,USBDevice,$(USB_DEVICE_DIRS),$(USB_DEVICE_DIRS)))
endif

###############################################################################
# Library USBHost.a
###############################################################################
ifeq "$(findstring USBHost,$(MBED_LIBS))" "USBHost"
USB_HOST_DIRS := $(call filter_dirs,$(call recurse_dir,$(MBED_LIB_SRC_ROOT)/USBHost),$(TARGETS_FOR_DEVICE))
$(eval $(call build_lib,USBHost,$(USB_HOST_DIRS),$(USB_HOST_DIRS)))
endif

###############################################################################
# Library rpc.a
###############################################################################
ifeq "$(findstring rpc,$(MBED_LIBS))" "rpc"
RPC_DIRS := $(call filter_dirs,$(call recurse_dir,$(MBED_LIB_SRC_ROOT)/rpc),$(TARGETS_FOR_DEVICE))
$(eval $(call build_lib,rpc,$(RPC_DIRS),$(RPC_DIRS)))
endif

###############################################################################
# Library dsp.a
###############################################################################
ifeq "$(findstring dsp,$(MBED_LIBS))" "dsp"
DSP_DIRS := $(call filter_dirs,$(call recurse_dir,$(MBED_LIB_SRC_ROOT)/dsp),$(TARGETS_FOR_DEVICE))
$(eval $(call build_lib,dsp,$(DSP_DIRS),$(DSP_DIRS)))
endif

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
