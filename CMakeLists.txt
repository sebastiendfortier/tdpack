# This must be repeated in each CMake file; having it in an included file is not
# sufficient
cmake_minimum_required(VERSION 3.16)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake_rpn)
include(ec_init)           # Initialise compilers and ec specific functions
ec_git_version()           # Get version from git state
ec_parse_manifest()        # Parse MANIFEST file

# Given our wacky compiler setups, languages must be activated after the
# compieler has been configured
project(${NAME} DESCRIPTION "${DESCRIPTION}")
set(PROJECT_VERSION ${VERSION}${STATE})
set(TDPACK_VERSION ${PROJECT_VERSION} CACHE INTERNAL "libtdpack version" FORCE) # Needed for cascaded version identification

option(BUILD_SHARED_LIBS "Build shared libraries instead of static ones." FALSE)

enable_language(C Fortran)
include(ec_compiler_presets)
include(ec_doxygen)
ec_build_info()            # Generate build include file (optional)

file(GLOB PROJECT_C_FILES src/*.c)
file(GLOB PROJECT_F_FILES src/*.F90)
file(GLOB PROJECT_INCLUDE_FILES src/*.h*)
set(PROJECT_MODULE_FILES ${CMAKE_CURRENT_BINARY_DIR}/tdpack_const.mod ${CMAKE_CURRENT_BINARY_DIR}/tdpack.mod)

add_library(tdpack ${PROJECT_C_FILES} ${PROJECT_F_FILES})
add_dependencies(tdpack tdpack_build_info)
set_target_properties(tdpack PROPERTIES
    VERSION ${PROJECT_VERSION}
    PUBLIC_HEADER "${PROJECT_INCLUDE_FILES}"
    POSITION_INDEPENDENT_CODE ON)
   
install(TARGETS tdpack
        PUBLIC_HEADER DESTINATION include/$ENV{EC_ARCH}
        LIBRARY       DESTINATION lib/$ENV{EC_ARCH}
        ARCHIVE       DESTINATION lib/$ENV{EC_ARCH})
install(FILES ${PROJECT_MODULE_FILES} DESTINATION include/$ENV{EC_ARCH})

#----- Generate the config file for the project to be usable via cmake's find_package command
set(INCLUDE_INSTALL_DIR include)
set(LIB_INSTALL_DIR     lib)
set(CONFIG_INSTALL_DIR  "${LIB_INSTALL_DIR}/cmake/${PROJECT_NAME}-${PROJECT_VERSION}")

include(CMakePackageConfigHelpers)
configure_package_config_file(
    "Config.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
    INSTALL_DESTINATION "${CONFIG_INSTALL_DIR}"
    PATH_VARS           INCLUDE_INSTALL_DIR LIB_INSTALL_DIR
)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
    COMPATIBILITY SameMajorVersion
)
install(FILES   "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
                "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
    DESTINATION "${CONFIG_INSTALL_DIR}"
)

#----- Packaging
ec_package_name()    # Define package prefix  
ec_build_config()    # Create build configuration script
ec_prepare_ssm(lib)  # Prepare ssm packaging files

set(CPACK_GENERATOR "TGZ")
set(CPACK_PACKAGE_VENDOR "ECCC")
set(CPACK_PACKAGE_CONTACT "${MAINTAINER}")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
set(CPACK_RESOURCE_FILE_README "${CMAKE_CURRENT_SOURCE_DIR}/README.org")
set(CPACK_OUTPUT_FILE_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/package")
set(CPACK_PACKAGE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
set(CPACK_PACKAGE_FILE_NAME "${PACKAGE_NAME}")
set(CPACK_SOURCE_PACKAGE_FILE_NAME "${NAME}_${PROJECT_VERSION}")
include(CPack)