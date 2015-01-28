macro(SSVCMake_cleanCache)
#{
	set(CMAKE_BUILD_TYPE "" CACHE STRING "" FORCE)
	set(CMAKE_CXX_FLAGS "" CACHE STRING "" FORCE)
	set(CMAKE_CXX_FLAGS_RELEASE "" CACHE STRING "" FORCE)
	set(CMAKE_CXX_FLAGS_DEBUG "" CACHE STRING "" FORCE)
	set(SSVCMAKE_CXX_FLAGS_DEBUG "" CACHE STRING "" FORCE)
	unset(SSVCMAKE_CLEAN_CACHE CACHE)
	unset(SSVCMAKE_CLEAN_CACHE)
#}
endmacro()



macro(SSVCMake_setForceCacheIfNull mVar mX)
#{
	if("${${mVar}}" STREQUAL "")	
	#{
		message("SSVCMake: ${mVar} was null, setting it to ${mX}")
		set("${mVar}" "${mX}" CACHE STRING "" FORCE)
	#}
	else()
	#{
		message("SSVCMake: ${mVar} was already set to: ${${mVar}}")
	#}
	endif()

	if("${SSVCMAKE_FORCE_ALWAYS}")
	#{
		message("SSVCMake: ${mVar} forced to ${mX}")
		set("${mVar}" "${mX}" CACHE STRING "" FORCE)
	#}
	endif()
#}
endmacro()



macro(SSVCMake_setForceCache mVar mX)
#{
	message("SSVCMake: force-setting ${mVar} to ${mX}")
	set("${mVar}" "${mX}" CACHE STRING "" FORCE)
#}
endmacro()



macro(SSVCMake_setDefaultSettings)
#{
	message("SSVCMake: setting default settings")

	SSVCMake_setForceCacheIfNull(CMAKE_BUILD_TYPE Release)

	set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/modules/;${CMAKE_MODULE_PATH}")
	
	set(INC_DIR "include" CACHE STRING "")
	set(SRC_DIR "src" CACHE STRING "")

	include_directories("./")
	include_directories("./${INC_DIR}")
#}
endmacro()



macro(SSVCMake_setDefaultFlags)
#{
	message("SSVCMake: setting default flags")

	if("${CMAKE_BUILD_TYPE}" STREQUAL "WIP")
	#{
		SSVCMake_setForceCache(CMAKE_CXX_FLAGS "-std=c++1y -O0 -Wall -Wextra -Wpedantic -Wundef -Wshadow -pthread -Wno-missing-field-initializers")		
	#}
	else()
	#{
		SSVCMake_setForceCache(CMAKE_CXX_FLAGS "-std=c++1y -Wall -Wextra -Wpedantic -pthread -Wundef -Wshadow -Wpointer-arith -Wcast-align -Wwrite-strings -Wno-unreachable-code -Wno-missing-field-initializers")
		SSVCMake_setForceCache(CMAKE_CXX_FLAGS_RELEASE "-DNDEBUG -O3")
		SSVCMake_setForceCache(SSVCMAKE_CXX_FLAGS_DEBUG "-fno-omit-frame-pointer -g3")
	#}
	endif()

	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${SSVCMAKE_EXTRA_FLAGS}")

	if("${SSVCMAKE_PROFILE_COMPILATION}")
	#{
		message("SSVCMake: profiling compilation")
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -v -ftime-report")
	#}
	endif()
#}
endmacro()



macro(SSVCMake_setDefaultGlobs)
#{
	message("SSVCMake: setting default globs")	
	file(GLOB_RECURSE SRC_LIST "${INC_DIR}/*" "${SRC_DIR}/*")
#}
endmacro(SSVCMake_setDefaultGlobs)



macro(SSVCMake_findExtlib mExtlib)
#{
	message("SSVCMake: finding ${mExtlib}")

	set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/../${mExtlib}/cmake/modules/;${CMAKE_SOURCE_DIR}/extlibs/${mExtlib}/cmake/modules/;${CMAKE_MODULE_PATH}")
	find_package("${mExtlib}" REQUIRED)
	string(TOUPPER "${mExtlib}" ${mExtlib}_UPPER)	
	include_directories("${${${mExtlib}_UPPER}_INCLUDE_DIR}")
#}
endmacro()



macro(SSVCMake_setDefaults)
#{
	if("${SSVCMAKE_CLEAN_CACHE}")
	#{
		message("SSVCMake: cleaning cache")

		SSVCMake_cleanCache()		
	#}
	else()
	#{
		message("SSVCMake: setting all defaults")

		SSVCMake_setDefaultSettings()
		SSVCMake_setDefaultFlags()
		SSVCMake_setDefaultGlobs()
	#}
	endif()
#}
endmacro()



macro(SSVCMake_findSFML)
#{
	message("SSVCMake: finding SFML")

	set(SFML_STATIC_LIBRARIES FALSE CACHE BOOL "Look for static SFML libraries.")
	find_package(SFML COMPONENTS audio graphics window system network)

	if(NOT SFML_FOUND)
	#{
		set(SFML_INCLUDE_DIR "" CACHE STRING "SFML2 include directory")
		set(SFML_SYSTEM_LIBRARY "" CACHE STRING "SFML2 System library file")
		set(SFML_WINDOW_LIBRARY "" CACHE STRING "SFML2 Window library file")
		set(SFML_GRAPHICS_LIBRARY "" CACHE STRING "SFML2 Graphics library file")
		set(SFML_NETWORK_LIBRARY "" CACHE STRING "SFML2 Network library file")
		set(SFML_AUDIO_LIBRARY "" CACHE STRING "SFML2 Audio library file")
		message("\n-> SFML directory not found. Set include and libraries manually.")
	#}
	endif()

	include_directories("${SFML_INCLUDE_DIR}")
#}
endmacro()



macro(SSVCMake_linkSFML)
#{
	message("SSVCMake: linking SFML")

	target_link_libraries(${PROJECT_NAME} ${SFML_AUDIO_LIBRARY})
	target_link_libraries(${PROJECT_NAME} ${SFML_GRAPHICS_LIBRARY})
	target_link_libraries(${PROJECT_NAME} ${SFML_WINDOW_LIBRARY})
	target_link_libraries(${PROJECT_NAME} ${SFML_SYSTEM_LIBRARY})
	target_link_libraries(${PROJECT_NAME} ${SFML_NETWORK_LIBRARY})
#}
endmacro()



macro(SSVCMake_setAndInstallHeaderOnly)
#{
	message("SSVCMake: setting up and installing as header-only library")

	set_source_files_properties(${SRC_LIST} PROPERTIES HEADER_FILE_ONLY 1)
	add_library(HEADER_ONLY_TARGET STATIC ${SRC_LIST})
	set_target_properties(HEADER_ONLY_TARGET PROPERTIES LINKER_LANGUAGE CXX)
	install(DIRECTORY ${INC_DIR} DESTINATION .)
#}
endmacro()