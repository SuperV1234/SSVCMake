# Adapted from Louis Dionne's hana CMake files.

# Copyright Louis Dionne 2015
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE.md or copy at http://boost.org/LICENSE_1_0.txt)

# Message with vrm_cmake prefix.
macro(vrm_cmake_message str)
#{
    message("[vrm_cmake] ${str}")
#}
endmacro()

# Initializes the `PROJECT_NAME_UPPER` variable.
# It contains the project name, uppercase.
macro(vrm_cmake_init_project_name_upper)
#{
    set(PROJECT_NAME_UPPER "")
    string(TOUPPER ${PROJECT_NAME} PROJECT_NAME_UPPER)
#}
endmacro()

# Initializes the `${PROJECT_NAME_UPPER}_SOURCE_DIR` variable.
macro(vrm_cmake_init_project_source_dir)
#{
    set("${PROJECT_NAME_UPPER}_SOURCE_DIR" "${CMAKE_CURRENT_SOURCE_DIR}")
#}
endmacro()

# Initializes common data for a C++ CMake project.
# * Project name and uppercase project name.
# * Appends common module paths.
# * Enables testing.
macro(vrm_cmake_init_project project_name)
#{
    project(${project_name} CXX)
    enable_testing()

    vrm_cmake_init_project_name_upper()
    vrm_cmake_init_project_source_dir()

    list(APPEND CMAKE_MODULE_PATH
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake"
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")

    vrm_cmake_message("initialized project ${project_name}")
#}
endmacro()

# Initializes an option `${PROJECT_NAME_UPPER}_${name}`.
# Description `desc` and default value `default`.
macro(vrm_cmake_project_option name desc default)
#{
    option("${PROJECT_NAME_UPPER}_${name}" desc default)
#}
endmacro()

# Includes a CMake module only once.
macro(vrm_cmake_include_once module flag)
#{
    if(NOT ${flag})
    #{
        include(${module})
        set(${flag} true)
    #}
    endif()
#}
endmacro()

# Includes `CheckCXXCompilerFlag` if required.
macro(vrm_cmake_init_compiler_flag_check)
#{
    vrm_cmake_include_once(CheckCXXCompilerFlag
        VRM_CMAKE_COMPILER_FLAG_CHECK_INCLUDED)
#}
endmacro()

# Creates `testname` variable that checks for compiler flag `flag`.
# The flag is enabled, if possible.
macro(vrm_cmake_add_compiler_flag flag)
#{
    # Compute flag testname
    string(SUBSTRING ${flag} 1 -1 flag_0)
    string(TOUPPER ${flag_0} flag_1)
    string(REPLACE "-" "_" flag_2 ${flag_1})
    string(REPLACE "+" "X" flag_3 ${flag_2})
    string(REPLACE "=" "" flag_4 ${flag_3})

    set(PROJECT_TESTNAME "${PROJECT_NAME_UPPER}_HAS_${flag_4}")

    vrm_cmake_init_compiler_flag_check()
    check_cxx_compiler_flag(${flag} ${PROJECT_TESTNAME})

    if(${PROJECT_TESTNAME})
    #{
        add_compile_options(${flag})
    #}
    endif()
#}
endmacro()

# Creates an install target that installs the project as an header-only library.
# Library files are in the list `file_list`.
# The `src_dir` is copied to `dest_dir`.
macro(vrm_cmake_header_only_install file_list src_dir dest_dir)
#{
    vrm_cmake_message("added header-only install target")

    set_source_files_properties(${file_list} PROPERTIES HEADER_FILE_ONLY 1)
    add_library(HEADER_ONLY_TARGET STATIC ${file_list})
    set_target_properties(HEADER_ONLY_TARGET PROPERTIES LINKER_LANGUAGE CXX)
    install(DIRECTORY ${src_dir} DESTINATION ${dest_dir})
#}
endmacro()

# Creates an install target that installs the project as an header-only library.
# Automatically globs `src_dir`.
macro(vrm_cmake_header_only_install_glob src_dir dest_dir)
#{
    vrm_cmake_message("globbing ${src_dir} for header-only install")

    # Glob library header files.
    file(GLOB_RECURSE INSTALL_FILES_LIST "${src_dir}/*")

    # Create header-only install target.
    vrm_cmake_header_only_install("${INSTALL_FILES_LIST}" "${src_dir}" "${dest_dir}")
#}
endmacro()

# Creates a `check` target, intended for tests and examples.
# Uses CTest.
macro(vrm_check_target)
#{
    vrm_cmake_message("created check target")

    add_custom_target(check
        COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        COMMENT "Build and then run all the tests.")
#}
endmacro()

# Return an unique name for a file target.
# Replaces slashes with `.`, assumes `.cpp` if the extension is not specified.
function(vrm_cmake_target_name_for out file)
#{
    if(NOT ARGV2)
        set(_extension ".cpp")
    else()
        set(_extension "${ARGV2}")
    endif()

    file(RELATIVE_PATH _relative "${${PROJECT_NAME_UPPER}_SOURCE_DIR}" ${file})
    string(REPLACE "${_extension}" "" _name ${_relative})
    string(REGEX REPLACE "/" "." _name ${_name})
    set(${out} "${_name}" PARENT_SCOPE)
#}
endfunction()

# Look for valgrind, if memcheck is enabled.
macro(vrm_cmake_add_option_memcheck)
#{
    vrm_cmake_project_option(ENABLE_MEMCHECK "Run the unit tests and examples under Valgrind if it is found." OFF)

    if("${${PROJECT_NAME_UPPER}_ENABLE_MEMCHECK}")
    #{
        vrm_cmake_message("memcheck enabled")

        find_package(Valgrind REQUIRED)
    #}
    endif()
#}
endmacro()

# Disable exceptions if the user wants to.
macro(vrm_cmake_add_option_no_exceptions)
#{
    vrm_cmake_project_option(DISABLE_EXCEPTIONS "Build with exceptions disabled." OFF)

    if("${${PROJECT_NAME_UPPER}_DISABLE_EXCEPTIONS}")
    #{
        vrm_cmake_message("exceptions disabled")

        vrm_cmake_add_compiler_flag("-fno-exceptions")
    #}
    endif()
#}
endmacro()

# Enable `-Werror` if the user wants to.
macro(vrm_cmake_add_option_werror)
#{
    vrm_cmake_project_option(ENABLE_WERROR "Fail and stop if a warning is triggered." OFF)

    if("${${PROJECT_NAME_UPPER}_ENABLE_WERROR}")
    #{
        vrm_cmake_message("werror enabled")

        vrm_cmake_add_compiler_flag("-Werror")
        vrm_cmake_add_compiler_flag("-WX")
    #}
    endif()
#}
endmacro()

# Creates a test called `name` which runs the given `command` with the given arguments.
# Uses Valgrind if memcheck is enabled.
function(vrm_cmake_add_test name)
#{
    if("${${PROJECT_NAME_UPPER}_ENABLE_MEMCHECK}")
    #{
        add_test(${name} ${Valgrind_EXECUTABLE} --leak-check=full --error-exitcode=1 ${ARGN})
    #}
    else()
    #{
        add_test(${name} ${ARGN})
    #}
    endif()
#}
endfunction()

# Adds a test, also as part of the `tests` target.
function(vrm_cmake_add_unit_test name)
#{
    vrm_cmake_add_test(${ARGV})
    add_dependencies(tests ${name})
#}
endfunction()

# Adds a test for a public header, making sure including it works properly.
# Adds them to the `tests` target.
macro(vrm_cmake_add_public_header_test header)
#{
    string(REGEX REPLACE "/" "." _target "${header}")

    if(NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/header/${header}.cpp")
    #{
        file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/header/${header}.cpp" "
#include <${header}>
int __attribute__((const)) main() { return 0; }
        ")
    #}
    endif()

    add_executable(test.header.${_target} EXCLUDE_FROM_ALL
                        "${CMAKE_CURRENT_BINARY_DIR}/header/${header}.cpp")

    vrm_cmake_add_test(test.header.${_target}
                            ${CMAKE_CURRENT_BINARY_DIR}/test.header.${_target})

    add_dependencies(tests test.header.${_target})

    # Append generated targets
    list(APPEND vrm_cmake_out "test.header.${_target}")
#}
endmacro()

# Generate tests that include each public header.
macro(vrm_cmake_generate_public_header_tests header_list inc_dir)
#{
    vrm_cmake_message("generating public header tests")

    # Clear result list.
    set(vrm_cmake_out "")

    foreach(_header IN LISTS ${header_list})
    #{
        file(RELATIVE_PATH _relative "${inc_dir}" "${_header}")
        vrm_cmake_add_public_header_test("${_relative}")
    #}
    endforeach()
#}
endmacro()

# Generate unit tests.
macro(vrm_cmake_generate_unit_tests test_srcs)
#{
    vrm_cmake_message("generating unit tests")

    # Clear result list.
    set(vrm_cmake_out "")

    foreach(_file IN LISTS ${test_srcs})
    #{
        file(READ "${_file}" _contents)
        vrm_cmake_target_name_for(_target "${_file}")

        add_executable(${_target} EXCLUDE_FROM_ALL "${_file}")
        vrm_cmake_add_unit_test(${_target} ${CMAKE_CURRENT_BINARY_DIR}/${_target})
        # target_link_libraries(${_target} linked_libraries)

        # Append generated targets
        list(APPEND vrm_cmake_out ${_target})
    #}
    endforeach()
#}
endmacro()

# Generate unit tests.
macro(vrm_cmake_generate_unit_tests_glob glob_pattern)
#{
    vrm_cmake_message("globbing unit tests")

    # Glob all tests.
    file(GLOB_RECURSE _srcs ${glob_pattern})

    # Add all the unit tests.
    vrm_cmake_generate_unit_tests(_srcs)
#}
endmacro()

# Generate unit tests.
macro(vrm_cmake_generate_public_header_tests_glob glob_pattern inc_dir)
#{
    vrm_cmake_message("globbing public headers")

    # Glob all public headers. (Detail headers can be removed here.)
    file(GLOB_RECURSE _pub_headers "${inc_dir}/${glob_pattern}")
    vrm_cmake_list_remove_glob(_pub_headers GLOB_RECURSE "dummy")

    # Generate tests that include each public header.
    vrm_cmake_generate_public_header_tests(_pub_headers "${inc_dir}")
#}
endmacro()

# TODO
macro(vrm_cmake_add_compiler_flag_pthread)
#{
    vrm_cmake_message("added common pthread flags")

    vrm_cmake_add_compiler_flag("-pthread")
#}
endmacro()

# TODO
macro(vrm_cmake_link_pthread)
#{
    vrm_cmake_message("linking pthread")

    target_link_libraries(${PROJECT_NAME} -lpthread)
#}
endmacro()

# Adds common compiler safety/warning flags/definitions to the project.
macro(vrm_cmake_add_common_compiler_flags_safety)
#{
    vrm_cmake_message("added common safety flags")

    # Enable common flags
    vrm_cmake_add_compiler_flag("-pedantic")
    vrm_cmake_add_compiler_flag("-std=c++14")

    # Enable warnings
    vrm_cmake_add_compiler_flag("-W")
    vrm_cmake_add_compiler_flag("-Wall")
    vrm_cmake_add_compiler_flag("-Wextra")
    vrm_cmake_add_compiler_flag("-Wno-unused-local-typedefs")
    vrm_cmake_add_compiler_flag("-Wwrite-strings")
    vrm_cmake_add_compiler_flag("-Wshadow")
    vrm_cmake_add_compiler_flag("-Wundef")
    vrm_cmake_add_compiler_flag("-Wno-missing-field-initializers")
    vrm_cmake_add_compiler_flag("-Wpointer-arith")
    vrm_cmake_add_compiler_flag("-Wcast-align")
    vrm_cmake_add_compiler_flag("-Wno-unreachable-code")
    vrm_cmake_add_compiler_flag("-Wnon-virtual-dtor")
    vrm_cmake_add_compiler_flag("-Woverloaded-virtual")
    vrm_cmake_add_compiler_flag("-Wmisleading-indentation")
    vrm_cmake_add_compiler_flag("-Wduplicated-cond")
    vrm_cmake_add_compiler_flag("-Weverything")
    vrm_cmake_add_compiler_flag("-Wsuggest-final-types")
    vrm_cmake_add_compiler_flag("-Wsuggest-final-methods")
    vrm_cmake_add_compiler_flag("-Wsuggest-override")
    vrm_cmake_add_compiler_flag("-Wsuggest-attribute=pure")
    vrm_cmake_add_compiler_flag("-Wsuggest-attribute=const")
    vrm_cmake_add_compiler_flag("-Wsuggest-attribute=noreturn")
    vrm_cmake_add_compiler_flag("-Wsuggest-attribute=format")
    vrm_cmake_add_compiler_flag("-Wsequence-point")
    vrm_cmake_add_compiler_flag("-Wlogical-op")
    vrm_cmake_add_compiler_flag("-Wduplicated-cond")
    vrm_cmake_add_compiler_flag("-Wtautological-compare")
    vrm_cmake_add_compiler_flag("-Wnull-dereference")
    # vrm_cmake_add_compiler_flag("-Winline")

    # Disable warnings
    vrm_cmake_add_compiler_flag("-Wno-c++98-compat")
    vrm_cmake_add_compiler_flag("-Wno-c++98-compat-pedantic")
    vrm_cmake_add_compiler_flag("-Wno-missing-prototypes")
    vrm_cmake_add_compiler_flag("-Wno-newline-eof")
    vrm_cmake_add_compiler_flag("-Wno-reserved-id-macro")
    vrm_cmake_add_compiler_flag("-Wno-exit-time-destructors")
    vrm_cmake_add_compiler_flag("-Wno-global-constructors")
    vrm_cmake_add_compiler_flag("-Wno-missing-variable-declarations")
    vrm_cmake_add_compiler_flag("-Wno-header-hygiene")
    vrm_cmake_add_compiler_flag("-Wno-conversion")
    vrm_cmake_add_compiler_flag("-Wno-float-equal")
    vrm_cmake_add_compiler_flag("-Wno-old-style-cast")
    vrm_cmake_add_compiler_flag("-Wno-unused-macros")
    vrm_cmake_add_compiler_flag("-Wno-class-varargs")
    vrm_cmake_add_compiler_flag("-Wno-padded")
    vrm_cmake_add_compiler_flag("-Wno-weak-vtables")
    vrm_cmake_add_compiler_flag("-Wno-date-time")
    vrm_cmake_add_compiler_flag("-Wno-unneeded-member-function")
    vrm_cmake_add_compiler_flag("-Wno-covered-switch-default")
    vrm_cmake_add_compiler_flag("-Wno-range-loop-analysis")
    vrm_cmake_add_compiler_flag("-Wno-unused-member-function")
    vrm_cmake_add_compiler_flag("-Wno-switch-enum")
#}
endmacro()

# Adds common compiler release flags/definitions to the project.
macro(vrm_cmake_add_common_compiler_flags_release)
#{
    vrm_cmake_message("added common release flags")

    vrm_cmake_add_compiler_flag("-Ofast")
    vrm_cmake_add_compiler_flag("-ffast-math")

    add_definitions(-DNDEBUG -DSSVU_ASSERT_FORCE_OFF=1)
#}
endmacro()

# Adds common compiler debug flags/definitions to the project.
macro(vrm_cmake_add_common_compiler_flags_debug)
#{
    vrm_cmake_message("added common debug flags")

    vrm_cmake_add_compiler_flag("-fno-omit-frame-pointer")
    vrm_cmake_add_compiler_flag("-g3")
#}
endmacro()

# Adds common compiler flags/definitions, depending on the build type.
macro(vrm_cmake_add_common_compiler_flags)
#{
    vrm_cmake_add_common_compiler_flags_safety()

    if("${CMAKE_BUILD_TYPE}" STREQUAL "RELEASE")
    #{
        vrm_cmake_message("RELEASE mode")
        vrm_cmake_add_common_compiler_flags_release()
    #}
    elseif("${CMAKE_BUILD_TYPE}" STREQUAL "DEBUG")
    #{
        vrm_cmake_message("DEBUG mode")
        vrm_cmake_add_common_compiler_flags_debug()
    #}
    else()
    #{
        vrm_cmake_message("WIP mode")
    #}
    endif()
#}
endmacro()

# Returns a list of globbed objects except the listed ones.
macro(vrm_cmake_list_remove_glob list glob)
#{
    list(REMOVE_ITEM ${list} ${ARGN})
#}
endmacro()

# TODO:
macro(vrm_cmake_find_extlib_in extlib dir)
#{
    vrm_cmake_message("finding ${extlib}")

    list(APPEND CMAKE_MODULE_PATH
        "${CMAKE_SOURCE_DIR}/${dir}/${extlib}/cmake/modules/"
        "${CMAKE_SOURCE_DIR}/${dir}/${extlib}/cmake/"
        "${CMAKE_SOURCE_DIR}/extlibs/${extlib}/cmake/modules/"
        "${CMAKE_SOURCE_DIR}/extlibs/${extlib}/cmake/")

    find_package("${extlib}" REQUIRED)
    string(TOUPPER "${extlib}" ${extlib}_UPPER)
#}
endmacro()

# TODO:
macro(vrm_cmake_find_extlib_in_and_default_include extlib dir)
#{
    vrm_cmake_find_extlib_in(${extlib} ${dir})
    include_directories("${${${extlib}_UPPER}_INCLUDE_DIR}")
#}
endmacro()

# TODO:
macro(vrm_cmake_find_extlib extlib)
#{
    vrm_cmake_message("finding ${extlib} in ./..")
    vrm_cmake_find_extlib_in_and_default_include(${extlib} "..")
#}
endmacro()

# TODO: add sanitization options
