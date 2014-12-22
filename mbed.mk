# Adapted from https://github.com/adamgreen/gcc4mbed

# Check for undefined variables.
ifndef PROJECT
$(error makefile must set PROJECT variable.)
endif

ifndef WORKSPACE_ROOT
$(error makefile must set WORKSPACE_ROOT.)
endif


# Set VERBOSE make variable to 1 to output all tool commands.
VERBOSE?=0
ifeq "$(VERBOSE)" "0"
Q := @
else
Q :=
endif


# Default variables.
SRC               ?= .
BUILD_TYPE        ?= Release
NO_FLOAT_SCANF    ?= 0
NO_FLOAT_PRINTF   ?= 0
DEVICES           ?= STM32L053
ifeq "$(BUILD_TYPE)" "Release"
OPTIMIZATION      ?= s
endif
ifeq "$(BUILD_TYPE)" "Debug"
OPTIMIZATION      ?= g
endif
ifeq "$(BUILD_TYPE)" "Checked"
OPTIMIZATION      ?= s
endif

#  Compiler/Assembler/Linker Paths
GCC     := arm-none-eabi-gcc
GPP     := arm-none-eabi-g++
AS      := arm-none-eabi-as
AR      := arm-none-eabi-ar
LD      := arm-none-eabi-g++
OBJCOPY := arm-none-eabi-objcopy
OBJDUMP := arm-none-eabi-objdump
SIZE    := arm-none-eabi-size

# Some tools are different on Windows in comparison to Unix.
ifeq "$(OS)" "Windows_NT"
REMOVE = del
SHELL = cmd.exe
REMOVE_DIR = rd /s /q
MKDIR = mkdir
QUIET = >nul 2>nul & exit 0
BLANK_LINE = echo -
else
REMOVE = rm
REMOVE_DIR = rm -r -f
MKDIR = mkdir -p
QUIET = > /dev/null 2>&1 ; exit 0
BLANK_LINE = echo
endif

# Create macro which will convert / to \ on Windows.
ifeq "$(OS)" "Windows_NT"
define convert-slash
$(subst /,\,$1)
endef
else
define convert-slash
$1
endef
endif


# Make sure that the mbed library always gets linked in.
MBED_LIBS += mbed


# Used on linker command line to pull all object files from mbed.a.  Unused modules will be garbage collected away.
WHOLE_ARCHIVE   := -Wl,-whole-archive
NOWHOLE_ARCHIVE := -Wl,-no-whole-archive
all_objs_from_mbed = $(patsubst %mbed.a,$(WHOLE_ARCHIVE) %mbed.a $(NOWHOLE_ARCHIVE),$1)

# Add in library dependencies.
MBED_LIBS := $(patsubst net/eth,net/lwip net/eth rtos,$(MBED_LIBS))
MBED_LIBS := $(patsubst USBHost,USBHost fs rtos,$(MBED_LIBS))


# Directories where mbed source files are found.
MBED_LIB_SRC_ROOT		:= $(WORKSPACE_ROOT)/mbed-src/libraries
MBED_SRC_ROOT       := $(MBED_LIB_SRC_ROOT)/mbed
MBED_CMSIS_ROOT     := $(MBED_SRC_ROOT)/targets/cmsis
MBED_HAL_ROOT       := $(MBED_SRC_ROOT)/targets/hal


# Root directories for official mbed library output.
LIB_RELEASE_DIR := $(WORKSPACE_ROOT)/mbed-src/Release
LIB_DEBUG_DIR   := $(WORKSPACE_ROOT)/mbed-src/Debug


# Toolchain sub-directories to be built with GCC.
TOOLCHAINS := TOOLCHAIN_GCC TOOLCHAIN_GCC_ARM
TOOLCHAIN_DEFINES := $(patsubst %,-D%,$(TOOLCHAINS))

# Macros for selecting sources/objects to be built for a project.
src_ext     := c cpp S
ifneq "$(OS)" "Windows_NT"
src_ext     += s
recurse_dir = $(patsubst %/,%,$(sort $1 $(shell find $1 -type d)))
else
win32_find = $(patsubst $(shell cmd /v:on /c "pushd $1 && echo !CD!&& popd")%,$1%,$(shell dir /s /ad /b $1))
recurse_dir = $(patsubst %/,%,$(sort $1 $(subst \,/,$(call win32_find,$(call convert-slash,$1)))))
endif
find_srcs   = $(subst //,/,$(foreach i,$(src_ext),$(foreach j,$1,$(wildcard $j/*.$i))))
srcs2objs   = $(patsubst $2/%,$3/%,$(addsuffix .o,$(basename $(call find_srcs,$1))))
all_targets = $(sort $(filter TARGET_%,$(notdir $1)))
unsupported_targets = $(filter-out $2,$(call all_targets,$1))
unsupported_target_dirs = $(filter $(addprefix %/,$(call unsupported_targets,$1,$2)),$1)
filter_targets = $(patsubst %/,%,$(filter-out $(addsuffix /%,$(call unsupported_target_dirs,$1,$2)),$(addsuffix /,$1)))
all_toolchains = $(sort $(filter TOOLCHAIN_%,$(notdir $1)))
unsupported_toolchains = $(filter-out $2,$(call all_toolchains,$1))
unsupported_toolchain_dirs = $(filter $(addprefix %/,$(call unsupported_toolchains,$1,$2)),$1)
filter_toolchains = $(patsubst %/,%,$(filter-out $(addsuffix /%,$(call unsupported_toolchain_dirs,$1,$(TOOLCHAINS))),$(addsuffix /,$1)))
filter_dirs = $(call filter_toolchains,$(call filter_targets,$1,$2))


# Utility macros to help build mbed SDK libraries.
define build_lib #,libname,source_dirs,include_dirs
    # Release and Debug target libraries for C and C++ portions of library.
    RELEASE_LIB  := $(RELEASE_DIR)/$1.a
    DEBUG_LIB    := $(DEBUG_DIR)/$1.a

    # Convert list of source files to corresponding list of object files to be generated.
    OBJECTS         := $(call srcs2objs,$2,$(MBED_LIB_SRC_ROOT),__Output__)
    DEBUG_OBJECTS   := $$(patsubst __Output__%,$(DEBUG_DIR)%,$$(OBJECTS))
    RELEASE_OBJECTS := $$(patsubst __Output__%,$(RELEASE_DIR)%,$$(OBJECTS))

    # List of the header dependency files, one per object file.
    DEPFILES += $$(patsubst %.o,%.d,$$(DEBUG_OBJECTS))
    DEPFILES += $$(patsubst %.o,%.d,$$(RELEASE_OBJECTS))

    # Append to main project's include path.
    MBED_INCLUDES += $3

    # Customize C/C++/ASM flags for Debug and Release builds.
    $$(DEBUG_LIB): C_FLAGS   := $(C_FLAGS) -O$(DEBUG_OPTIMIZATION)
    $$(DEBUG_LIB): CPP_FLAGS := $(CPP_FLAGS) -O$(DEBUG_OPTIMIZATION)
    $$(RELEASE_LIB): C_FLAGS   := $(C_FLAGS) -O$(RELEASE_OPTIMIZATION) -DNDEBUG
    $$(RELEASE_LIB): CPP_FLAGS := $(CPP_FLAGS) -O$(RELEASE_OPTIMIZATION) -DNDEBUG
    $$(RELEASE_LIB): ASM_FLAGS := $(ASM_FLAGS)
    $$(DEBUG_LIB):   ASM_FLAGS := $(ASM_FLAGS)

    #########################################################################
    # High level rules for building Debug and Release versions of library.
    #########################################################################
    $$(RELEASE_LIB): $$(RELEASE_OBJECTS)
				@echo Linking release library $@
				$(Q) $(MKDIR) $$(call convert-slash,$$(dir $$@)) $(QUIET)
				$(Q) $(AR) -rc $$@ $$+

    $$(DEBUG_LIB): $$(DEBUG_OBJECTS)
				@echo Linking debug library $@
				$(Q) $(MKDIR) $$(call convert-slash,$$(dir $$@)) $(QUIET)
				$(Q) $(AR) -rc $$@ $$+

endef


# Rules for building all of the desired device targets
all: $(DEVICES)
clean: $(addsuffix -clean,$(DEVICES))
clean-all: clean
		@echo Cleaning $(LIB_RELEASE_DIR)
		$(Q) $(REMOVE_DIR) $(call convert-slash,$(LIB_RELEASE_DIR)) $(QUIET)
		@echo Cleaning $(LIB_DEBUG_DIR)
		$(Q) $(REMOVE_DIR) $(call convert-slash,$(LIB_DEBUG_DIR)) $(QUIET)


# Determine supported devices by looking at *-device.mk makefiles.
ALL_DEVICE_MAKEFILES := $(wildcard $(WORKSPACE_ROOT)/build/*-device.mk)
ALL_DEVICES          := $(patsubst $(WORKSPACE_ROOT)/build/%-device.mk,%,$(ALL_DEVICE_MAKEFILES))


# Include makefiles that know how to build each of the supported device types.
include $(ALL_DEVICE_MAKEFILES)
