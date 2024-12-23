cmake_minimum_required(VERSION 3.15)
project(justlists LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Define the normalized output directory
set(NORMALIZED_OUTPUT_DIR ${CMAKE_BINARY_DIR}/bin)

# Set global output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${NORMALIZED_OUTPUT_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${NORMALIZED_OUTPUT_DIR})
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${NORMALIZED_OUTPUT_DIR})

# Override configuration-specific output directories (Debug, Release, etc.)
foreach(OUTPUTCONFIG Debug Release RelWithDebInfo MinSizeRel)
    string(TOUPPER ${OUTPUTCONFIG} OUTPUTCONFIG_UPPER)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG_UPPER} ${NORMALIZED_OUTPUT_DIR})
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${OUTPUTCONFIG_UPPER} ${NORMALIZED_OUTPUT_DIR})
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${OUTPUTCONFIG_UPPER} ${NORMALIZED_OUTPUT_DIR})
endforeach()

# Detect platform and print debug information
if(WIN32)
    set(RUN_COMMAND "${NORMALIZED_OUTPUT_DIR}/justlists.exe")
    message(STATUS "Building for Windows")
    message(STATUS "Compiler: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
    message(STATUS "Run the executable with: ./build/bin/justlists.exe")
elseif(UNIX AND NOT APPLE)
    set(RUN_COMMAND "${NORMALIZED_OUTPUT_DIR}/justlists")
    message(STATUS "Building for Linux")
    message(STATUS "Compiler: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
    message(STATUS "Run the executable with: ./build/bin/justlists")
else()
    set(RUN_COMMAND "Unknown platform. Cannot determine run command.")
    message(WARNING "Unknown platform. The build may not be fully supported.")
endif()

# Add GLFW as a subdirectory
add_subdirectory(external/glfw)

# Define IMGUI sources
set(IMGUI_SOURCES
    ${CMAKE_SOURCE_DIR}/external/imgui/imgui.cpp
    ${CMAKE_SOURCE_DIR}/external/imgui/imgui_draw.cpp
    ${CMAKE_SOURCE_DIR}/external/imgui/imgui_widgets.cpp
    ${CMAKE_SOURCE_DIR}/external/imgui/imgui_tables.cpp
    ${CMAKE_SOURCE_DIR}/external/imgui/backends/imgui_impl_glfw.cpp
    ${CMAKE_SOURCE_DIR}/external/imgui/backends/imgui_impl_opengl3.cpp
)

# Define main sources
set(SOURCES
    ${CMAKE_SOURCE_DIR}/sources/main.cpp
)

# Add executable
add_executable(${PROJECT_NAME} ${SOURCES} ${IMGUI_SOURCES})

# Ensure target-specific output directories are set
set_target_properties(${PROJECT_NAME} PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${NORMALIZED_OUTPUT_DIR}
    RUNTIME_OUTPUT_DIRECTORY_DEBUG ${NORMALIZED_OUTPUT_DIR}
    RUNTIME_OUTPUT_DIRECTORY_RELEASE ${NORMALIZED_OUTPUT_DIR}
    RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO ${NORMALIZED_OUTPUT_DIR}
    RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL ${NORMALIZED_OUTPUT_DIR}
)

# Include directories
target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_SOURCE_DIR}/external/glfw/include
    ${CMAKE_SOURCE_DIR}/external/imgui
    ${CMAKE_SOURCE_DIR}/external/imgui/backends
)

# Link libraries based on platform
if(WIN32)
    target_link_libraries(${PROJECT_NAME} PRIVATE glfw opengl32)
elseif(UNIX AND NOT APPLE)
    target_link_libraries(${PROJECT_NAME} PRIVATE glfw dl GL X11 Xrandr Xi Xcursor Xinerama)
endif()

# Set compiler options
if(MSVC)
    target_compile_options(${PROJECT_NAME} PRIVATE /W4)  # Enable warnings for MSVC
    message(STATUS "MSVC-specific warning level set to /W4")
else()
    target_compile_options(${PROJECT_NAME} PRIVATE -Wall -Wextra -Wpedantic)
    message(STATUS "GCC/Clang-specific warning flags: -Wall -Wextra -Wpedantic")
endif()

# Add post-build message about running the executable
add_custom_command(
    TARGET ${PROJECT_NAME}
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E echo
    "To run the executable, use: ${RUN_COMMAND}"
)

# Final instructions for debugging
message(STATUS "Build output directory: ${NORMALIZED_OUTPUT_DIR}")
message(STATUS "Source directory: ${CMAKE_SOURCE_DIR}")
