# Set minimum required version of CMake
cmake_minimum_required(VERSION 3.12)

# Include build functions from Pico SDK
include($ENV{PICO_SDK_PATH}/external/pico_sdk_import.cmake)

# Set name of project (as PROJECT_NAME) and C/C++ standards
project(orterforth C CXX ASM)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# Creates a pico-sdk subdirectory in our project for the libraries
pico_sdk_init()

add_compile_definitions(PICO)
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,-Map=orterforth.map")
add_library(rf OBJECT ../../rf.c)
add_library(rf_persci OBJECT ../../rf_persci.c)
add_library(rf_system OBJECT ../../rf_system.c $<TARGET_OBJECTS:rf> $<TARGET_OBJECTS:rf_persci>)
add_library(rf_inst OBJECT ../../rf_inst.c $<TARGET_OBJECTS:rf> $<TARGET_OBJECTS:rf_persci>)

# Tell CMake where to find the executable source file
add_executable(${PROJECT_NAME} 
    ../../orterforth.c
    $<TARGET_OBJECTS:rf>
    $<TARGET_OBJECTS:rf_persci>
    $<TARGET_OBJECTS:rf_system>
    $<TARGET_OBJECTS:rf_inst>
)

# Create map/bin/hex/uf2 files
pico_add_extra_outputs(${PROJECT_NAME})

# Link to pico_stdlib (gpio, time, etc. functions)
target_link_libraries(${PROJECT_NAME} pico_stdlib)

# Enable usb output, disable uart output
pico_enable_stdio_usb(${PROJECT_NAME} 1)
pico_enable_stdio_uart(${PROJECT_NAME} 0)