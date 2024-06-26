# Set minimum required version of CMake
cmake_minimum_required(VERSION 3.12)

# ON when PICOOPTION=assembly
option(RF_ASSEMBLY "Use assembly code" OFF)

# For assembly code, prevent inline to preserve r4, r5, r6 
# (RP, SP, IP) during function prolog and before rf_start
add_compile_options("-O0" "-fno-inline")

# Include build functions from Pico SDK
include($ENV{PICO_SDK_PATH}/external/pico_sdk_import.cmake)

# Set name of project (as PROJECT_NAME) and C/C++ standards
project(orterforth C CXX ASM)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# Creates a pico-sdk subdirectory in our project for the libraries
pico_sdk_init()

# #define PICO and RF_ASSEMBLY as appropriate
add_compile_definitions(PICO)
if(RF_ASSEMBLY)
    add_compile_definitions(RF_ASSEMBLY)
endif(RF_ASSEMBLY)

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,-Map=orterforth.map")
# Install process
add_library(inst OBJECT ../../inst.c $<TARGET_OBJECTS:rf> $<TARGET_OBJECTS:persci>)
# I/O primitives
add_library(io OBJECT ../../io.c $<TARGET_OBJECTS:rf> $<TARGET_OBJECTS:system>)
# Multiplex console and disc over serial
add_library(mux OBJECT ../../mux.c $<TARGET_OBJECTS:rf>)
# Disc controller, for inst on startup
add_library(persci OBJECT ../../persci.c)
if(RF_ASSEMBLY)
    # Forth primitives in ARM Cortex M0+ assembly code
    add_library(rf OBJECT ../../rf_armm0.s)
else()
    # Forth primitives in C
    add_library(rf OBJECT ../../rf.c)
endif(RF_ASSEMBLY)
# Pico-specific operations
add_library(system OBJECT system.c $<TARGET_OBJECTS:mux> $<TARGET_OBJECTS:persci>)

# Tell CMake where to find the executable source file
add_executable(${PROJECT_NAME} 
    ../../main.c
    $<TARGET_OBJECTS:inst>
    $<TARGET_OBJECTS:io>
    $<TARGET_OBJECTS:mux>
    $<TARGET_OBJECTS:persci>
    $<TARGET_OBJECTS:rf>
    $<TARGET_OBJECTS:system>
)

# Create map/bin/hex/uf2 files
pico_add_extra_outputs(${PROJECT_NAME})

# Link to pico_stdlib (gpio, time, etc. functions)
target_link_libraries(${PROJECT_NAME} pico_stdlib)

# Enable usb output, disable uart output
pico_enable_stdio_usb(${PROJECT_NAME} 1)
pico_enable_stdio_uart(${PROJECT_NAME} 0)
