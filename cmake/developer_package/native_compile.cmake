# Copyright (C) 2018-2023  Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

include(ExternalProject)

#
# ov_native_compile_external_project(
#      TARGET_NAME <name>
#      NATIVE_INSTALL_DIR <source dir>
#      NATIVE_TARGETS <target1 target2 ..>
#      [NATIVE_SOURCE_SUBDIR <subdir>]
#      [CMAKE_ARGS <option1 option2 ...>]
#   )
#
function(ov_native_compile_external_project)
    set(oneValueRequiredArgs NATIVE_INSTALL_DIR TARGET_NAME NATIVE_SOURCE_SUBDIR)
    set(multiValueArgs CMAKE_ARGS NATIVE_TARGETS)
    cmake_parse_arguments(ARG "" "${oneValueRequiredArgs};${oneValueOptionalArgs}" "${multiValueArgs}" ${ARGN})

    if(YOCTO_AARCH64)
        # need to unset several variables which can set env to cross-environment
        foreach(var SDKTARGETSYSROOT CONFIG_SITE OECORE_NATIVE_SYSROOT OECORE_TARGET_SYSROOT
                    OECORE_ACLOCAL_OPTS OECORE_BASELIB OECORE_TARGET_ARCH OECORE_TARGET_OS CC CXX
                    CPP AS LD GDB STRIP RANLIB OBJCOPY OBJDUMP READELF AR NM M4 TARGET_PREFIX
                    CONFIGURE_FLAGS CFLAGS CXXFLAGS LDFLAGS CPPFLAGS KCFLAGS OECORE_DISTRO_VERSION
                    OECORE_SDK_VERSION ARCH CROSS_COMPILE OE_CMAKE_TOOLCHAIN_FILE OPENSSL_CONF
                    OE_CMAKE_FIND_LIBRARY_CUSTOM_LIB_SUFFIX PKG_CONFIG_SYSROOT_DIR PKG_CONFIG_PATH)
            if(DEFINED ENV{${var}})
                list(APPEND cmake_env --unset=${var})
            endif()
        endforeach()

        # filter out PATH from yocto locations
        string(REPLACE ":" ";" custom_path "$ENV{PATH}")
        foreach(path IN LISTS custom_path)
            if(NOT path MATCHES "^$ENV{OECORE_NATIVE_SYSROOT}")
                list(APPEND clean_path "${path}")
            endif()
        endforeach()

        find_host_program(NATIVE_CMAKE_COMMAND
                          NAMES cmake
                          PATHS ${clean_path}
                          DOC "Host cmake"
                          REQUIRED
                          NO_DEFAULT_PATH)
    else()
        set(NATIVE_CMAKE_COMMAND "${CMAKE_COMMAND}")
    endif()

    # if env has CMAKE_TOOLCHAIN_FILE, we need to skip it
    if(DEFINED ENV{CMAKE_TOOLCHAIN_FILE})
        list(APPEND cmake_env --unset=CMAKE_TOOLCHAIN_FILE)
    endif()

    # compile flags
    if(CMAKE_COMPILER_IS_GNUCXX)
        set(compile_flags "-Wno-undef -Wno-error -Wno-deprecated-declarations")
    endif()

    if(ARG_NATIVE_SOURCE_SUBDIR)
        set(ARG_NATIVE_SOURCE_SUBDIR SOURCE_SUBDIR ${ARG_NATIVE_SOURCE_SUBDIR})
    endif()

    ExternalProject_Add(${ARG_TARGET_NAME}
        # Directory Options
        SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}"
        PREFIX "${CMAKE_CURRENT_BINARY_DIR}"
        BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/build"
        INSTALL_DIR "${ARG_NATIVE_INSTALL_DIR}"
        # Configure Step Options:
        CMAKE_COMMAND
            ${NATIVE_CMAKE_COMMAND}
        CMAKE_ARGS
            "-DCMAKE_CXX_COMPILER_LAUNCHER=${CMAKE_CXX_COMPILER_LAUNCHER}"
            "-DCMAKE_C_COMPILER_LAUNCHER=${CMAKE_C_COMPILER_LAUNCHER}"
            "-DCMAKE_CXX_LINKER_LAUNCHER=${CMAKE_CXX_LINKER_LAUNCHER}"
            "-DCMAKE_C_LINKER_LAUNCHER=${CMAKE_C_LINKER_LAUNCHER}"
            "-DCMAKE_CXX_FLAGS=${compile_flags}"
            "-DCMAKE_C_FLAGS=${compile_flags}"
            "-DCMAKE_POLICY_DEFAULT_CMP0069=NEW"
            "-DCMAKE_INSTALL_PREFIX=${ARG_NATIVE_INSTALL_DIR}"
            "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
            ${ARG_CMAKE_ARGS}
        CMAKE_GENERATOR "${CMAKE_GENERATOR}"
        ${ARG_NATIVE_SOURCE_SUBDIR}
        # Build Step Options:
        BUILD_COMMAND
            ${NATIVE_CMAKE_COMMAND}
                --build "${CMAKE_CURRENT_BINARY_DIR}/build"
                --config Release
                --parallel
                -- ${ARG_NATIVE_TARGETS}
        # Test Step Options:
        TEST_EXCLUDE_FROM_MAIN ON
        # Target Options:
        EXCLUDE_FROM_ALL ON
    )
endfunction()
