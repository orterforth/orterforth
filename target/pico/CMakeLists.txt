# == DO NOT EDIT THE FOLLOWING LINES for the Raspberry Pi Pico VS Code Extension to work ==
if(WIN32)
    set(USERHOME $ENV{USERPROFILE})
else()
    set(USERHOME $ENV{HOME})
endif()
set(sdkVersion 2.1.0)
if(PICO_PLATFORM STREQUAL "rp2350-riscv")
    set(toolchainVersion RISCV_RPI_2_0_0_5)
else()
    set(toolchainVersion 13_3_Rel1)
endif()
set(picotoolVersion 2.1.0)
set(picoVscode ${USERHOME}/.pico-sdk/cmake/pico-vscode.cmake)
if (EXISTS ${picoVscode})
    include(${picoVscode})
endif()
# ====================================================================================
#set(PICO_BOARD pico2 CACHE STRING "Board type")

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

add_executable(${PROJECT_NAME} ../../main.c)

# Install process
add_library(inst STATIC ../../inst.c)
# I/O primitives
add_library(io STATIC ../../io.c)
# Multiplex console and disc over serial
add_library(mux STATIC ../../mux.c ../../mux.h)
target_link_libraries(mux pico_stdlib)
# Disc controller, for inst on startup
add_library(persci STATIC ../../persci.c ../../persci.h)
if(RF_ASSEMBLY)
    # Forth primitives in assembly code
    if(PICO_PLATFORM STREQUAL "rp2350-riscv")
        add_library(rf STATIC ../../rf_riscv.s ../../rf.h)
    else()
        add_library(rf STATIC ../../rf_armm0.s ../../rf.h)
    endif()
else()
    # Forth primitives in C
    add_library(rf STATIC ../../rf.c ../../rf.h)
endif(RF_ASSEMBLY)
# Pico-specific operations
add_library(system STATIC system.c)
target_link_libraries(system pico_stdlib)
# link executable
target_link_libraries(${PROJECT_NAME}
    PUBLIC inst io mux persci rf system pico_stdlib)

# Create map/bin/hex/uf2 files
pico_add_extra_outputs(${PROJECT_NAME})

# Enable usb output, disable uart output
pico_enable_stdio_usb(${PROJECT_NAME} 1)
pico_enable_stdio_uart(${PROJECT_NAME} 0)
