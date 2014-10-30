# gcc-mbed-build

Make scripts to be included as a submodule in MBED gcc-arm projects

### Add to a project

```bash
$ git submodule add https://github.com/rosterloh/gcc-mbed-build.git build
```

### Configuration
> Bold variables are required

| **Variable Name**  | **Description** |
| :----------------: | --------------- |
| **PROJECT** | Name to be given to the output binary for this project |
| **WORKSPACE_ROOT** | The root directory of this repository |
| DEVICES     | Used to specify a space delimited list of target device(s) that this application should be built for. |
|             | Allowed values include:
|             | _LPC1768_, _LPC11U24_, _KL25Z_, _NRF51822_, _STM32L053_ (default) |
| SRC         | The root directory for the sources of your project.  Defaults to '.' |
| BUILD_TYPE  | Type of build to produce.  Allowed values are: |
|             | _Debug_ - Build for debugging.  Disables optimizations.  Best debugging experience.|
|             | _Release_ - Build for release with no debug support. (default) |
|             | _Checked_ - Release build with debug support.  Due to optimizations, debug experience won't be as good as Debug but might be needed when bugs don't reproduce in Debug builds. |
| MBED_LIBS   | Specifies which additional official mbed libraries you would like to use with your application.  These include:
|             | _net/eth_, _rtos_, _fs_, _rpc_, _dsp_, _USBDevice_, _USBHost_ |
| DEFINES     | Project specific #defines to be set when compiling main application.  Each macro should start with "-D" as required by GCC. |
|INCDIRS      | Space delimited list of extra directories to use for #include searches. |
| LIBS_PREFIX | List of library/object files to prepend to mbed libs. |
| LIBS_SUFFIX | List of library/object files to append to mbed libs. |
| GPFLAGS     | Additional compiler flags used when building C++ sources. |
| GCFLAGS     | Additional compiler flags used when building C sources. |
| GAFLAGS     | Additional assembler flags used when building assembly language sources. |
| OPTIMIZATION| Optional variable that can be set to s, 0, 1, 2, or 3 for overriding the compiler's optimization level.  It defaults to 2 for Checked and Release buillds and is forced to be 0 for Debug builds. |
| VERBOSE     | When set to 1, all build commands will be displayed to console. It defaults to 0 which suppresses the output of the build tool command lines themselves. |

#### Example makefile:
```
PROJECT        := HelloWorld
SRC            := .
WORKSPACE_ROOT := ../..
INCDIRS        :=
LIBS_PREFIX    :=
LIBS_SUFFIX    :=

include $(WORKSPACE_ROOT)/build/mbed.mk
```
