# Adapted from https://github.com/adamgreen/gcc4mbed

# Variables that must be defined in including makefile.
#   PROJECT: Name to be given to the output binary for this project.
#   WORKSPACE_ROOT: The root directory of this repository.
#
# Variables that may be optionally set in makefile.
#   DEVICES: Used to specify a space delimited list of target device(s) that
#             this application should be built for.  Allowed values include:
#              LPC1768
#              LPC11U24
#              KL25Z
#              STM32L058
#              NRF51822
#              default: STM32L058
#   SRC: The root directory for the sources of your project.  Defaults to '.'.
#   BUILD_TYPE: Type of build to produce.  Allowed values are:
#                  Debug - Build for debugging.  Disables optimizations and
#                          links in debug MRI runtime.  Best debugging
#                          experience.
#                  Release - Build for release with no debug support.
#                  Checked - Release build with debug support.  Due to
#                            optimizations, debug experience won't be as good
#                            as Debug but might be needed when bugs don't
#                            reproduce in Debug builds.
#                  default: Release
#   MBED_LIBS: Specifies which additional official mbed libraries you would
#              like to use with your application.  These include:
#               net/eth
#               rtos
#               fs
#               rpc
#               dsp
#               USBDevice
#               USBHost
#   DEFINES: Project specific #defines to be set when compiling main
#            application.  Each macro should start with "-D" as required by
#            GCC.
#   INCDIRS: Space delimited list of extra directories to use for #include
#            searches.
#   LIBS_PREFIX: List of library/object files to prepend to mbed libs.
#   LIBS_SUFFIX: List of library/object files to append to mbed libs.
#   GPFLAGS: Additional compiler flags used when building C++ sources.
#   GCFLAGS: Additional compiler flags used when building C sources.
#   GAFLAGS: Additional assembler flags used when building assembly language
#             sources.
#   OPTIMIZATION: Optional variable that can be set to s, 0, 1, 2, or 3 for
#                 overriding the compiler's optimization level.  It defaults
#                 to 2 for Checked and Release buillds and is forced to be 0
#                 for Debug builds.
#   VERBOSE: When set to 1, all build commands will be displayed to console.
#            It defaults to 0 which suppresses the output of the build tool
#            command lines themselves.
#
# Example makefile:
#       PROJECT        := HelloWorld
#       SRC            := .
#       WORKSPACE_ROOT := ../..
#       INCDIRS        :=
#       LIBS_PREFIX    :=
#       LIBS_SUFFIX    :=
#
#       include $(WORKSPACE_ROOT)/build/mbed.mk
#
###############################################################################

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
DEVICES           ?= STM320L058
ifeq "$(BUILD_TYPE)" "Release"
OPTIMIZATION      ?= 2
endif
ifeq "$(BUILD_TYPE)" "Debug"
OPTIMIZATION      ?= 0
endif
ifeq "$(BUILD_TYPE)" "Checked"
OPTIMIZATION      ?= 2
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


# Add in library dependencies.
MBED_LIBS := $(patsubst net/eth,net/lwip net/eth rtos,$(MBED_LIBS))
MBED_LIBS := $(patsubst USBHost,USBHost fs rtos,$(MBED_LIBS))


# Directories where non-device specific mbed source files are found.
MBED_LIB_SRC_ROOT    := $(WORKSPACE_ROOT)/mbed-src/libraries
MBED_SRC_ROOT        := $(MBED_LIB_SRC_ROOT)/mbed
COMMON_SRC           := $(MBED_SRC_ROOT)/common
API_HEADERS          := $(MBED_SRC_ROOT)/api
HAL_HEADERS          := $(MBED_SRC_ROOT)/hal
CMSIS_COMMON_HEADERS := $(MBED_SRC_ROOT)/targets/cmsis
TARGETS_HAL          := $(MBED_SRC_ROOT)/targets/hal

# Root directories for official mbed library output.
LIB_RELEASE_DIR := $(WORKSPACE_ROOT)/mbed-src/Release
LIB_DEBUG_DIR   := $(WORKSPACE_ROOT)/mbed-src/Debug


# Macros for selecting sources/objects to be built for a project.
src_ext     := c cpp S
ifneq "$(OS)" "Windows_NT"
src_ext     +=  s
endif
recurse_dir = $(patsubst %/,%,$(sort $(dir $(wildcard $1/* $1/*/* $1/*/*/* $1/*/*/*/* $1/*/*/*/*/* $1/*/*/*/*/*/*))))
find_srcs   = $(subst //,/,$(foreach i,$(src_ext),$(foreach j,$1,$(wildcard $j/*.$i))))
srcs2objs   = $(patsubst $2/%,$3/%,$(addsuffix .o,$(basename $(call find_srcs,$1))))

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


# Directories where library sources files common to all devices are found. Only perform expansion for libraries that
# are actually required since this isn't a fast operation.
ifeq "$(findstring rtos,$(MBED_LIBS))" "rtos"
    RTOS_DIRS := $(MBED_LIB_SRC_ROOT)/rtos/rtos $(MBED_LIB_SRC_ROOT)/rtos/rtx
else
    RTOS_DIRS :=
endif

ifeq "$(findstring net/lwip,$(MBED_LIBS))" "net/lwip"
    LWIP_DIRS := $(call recurse_dir,$(MBED_LIB_SRC_ROOT)/net/lwip)
else
    LWIP_DIRS :=
endif

ifeq "$(findstring net/eth,$(MBED_LIBS))" "net/eth"
    ETH_DIRS := $(MBED_LIB_SRC_ROOT)/net/eth/EthernetInterface
else
    ETH_DIRS :=
endif

ifeq "$(findstring fs,$(MBED_LIBS))" "fs"
    FS_DIRS := $(call recurse_dir,$(MBED_LIB_SRC_ROOT)/fs)
else
    FS_DIRS :=
endif

ifeq "$(findstring USBDevice,$(MBED_LIBS))" "USBDevice"
    USB_DEVICE_DIRS := $(call recurse_dir,$(MBED_LIB_SRC_ROOT)/USBDevice)
else
    USB_DEVICE_DIRS :=
endif

ifeq "$(findstring USBHost,$(MBED_LIBS))" "USBHost"
    USB_HOST_DIRS := $(call recurse_dir,$(MBED_LIB_SRC_ROOT)/USBHost)
else
    USB_HOST_DIRS :=
endif

ifeq "$(findstring rpc,$(MBED_LIBS))" "rpc"
    RPC_DIRS := $(call recurse_dir,$(MBED_LIB_SRC_ROOT)/rpc)
else
    RPC_DIRS :=
endif

ifeq "$(findstring dsp,$(MBED_LIBS))" "dsp"
    DSP_DIRS := $(call recurse_dir,$(MBED_LIB_SRC_ROOT)/dsp)
else
    DSP_DIRS :=
endif


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
