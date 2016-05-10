# Adapted from Louis Dionne's hana CMake files.

# Copyright Louis Dionne 2015
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE.md or copy at http://boost.org/LICENSE_1_0.txt)

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
