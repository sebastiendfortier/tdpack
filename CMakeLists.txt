cmake_minimum_required(VERSION 3.16)

message(STATUS "(EC) Generating tdpack Makefile")

#----- Append EC specific module path
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake_rpn/modules $ENV{EC_CMAKE_MODULE_PATH})

include(ec_init)           # Initialise compilers and ec specific functions
ec_git_version()           # Get version from git state
ec_parse_manifest()        # Parse MANIFEST file

project(${NAME} DESCRIPTION "${DESCRIPTION}" LANGUAGES C Fortran)
set(PROJECT_VERSION ${VERSION}${STATE})
set(tdpack_VERSION ${PROJECT_VERSION} CACHE INTERNAL "libtdpack version" FORCE) # Needed for cascaded version identification
message(STATUS "(EC) ${PROJECT_NAME} version = ${PROJECT_VERSION}")

ec_build_info()            # Generate build include file (optional)

include(ec_doxygen)
include(ec_compiler_presets)

file(GLOB PROJECT_C_FILES src/*.c)
file(GLOB PROJECT_F_FILES src/*.F90)
file(GLOB PROJECT_INCLUDE_FILES src/*.h* src/*.inc)
set(MODULE_DIR ${CMAKE_CURRENT_BINARY_DIR}/include)
set(PROJECT_MODULE_FILES ${MODULE_DIR}/tdpack_const.mod ${MODULE_DIR}/tdpack.mod)

add_library(${PROJECT_NAME}-static STATIC ${PROJECT_C_FILES} ${PROJECT_F_FILES})
add_dependencies(${PROJECT_NAME}-static tdpack_build_info)

add_library(${PROJECT_NAME}-shared SHARED  $<TARGET_OBJECTS:${PROJECT_NAME}-static>)
add_dependencies(${PROJECT_NAME}-shared ${PROJECT_NAME}-static ${PROJECT_NAME}_build_info)
set_target_properties(${PROJECT_NAME}-static ${PROJECT_NAME}-shared PROPERTIES
    VERSION ${PROJECT_VERSION}
    PUBLIC_HEADER "${PROJECT_INCLUDE_FILES}"
    Fortran_MODULE_DIRECTORY ${MODULE_DIR}
    INTERFACE_COMPILE_DEFINITIONS HAVE_TDPACK="${PROJECT_VERSION}"
    INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${MODULE_DIR}>
    POSITION_INDEPENDENT_CODE ON
    OUTPUT_NAME tdpack)
   
install(TARGETS ${PROJECT_NAME}-static
    EXPORT ${PROJECT_NAME}-static-targets
    INCLUDES      DESTINATION include
    PUBLIC_HEADER DESTINATION include
    LIBRARY       DESTINATION lib
    ARCHIVE       DESTINATION lib)
install(TARGETS ${PROJECT_NAME}-shared
    EXPORT ${PROJECT_NAME}-shared-targets
    INCLUDES      DESTINATION include
    PUBLIC_HEADER DESTINATION include
    LIBRARY       DESTINATION lib
    ARCHIVE       DESTINATION lib)
install(FILES ${PROJECT_MODULE_FILES} DESTINATION include)

if(BUILD_SHARED_LIBS)
    add_library(${PROJECT_NAME}::${PROJECT_NAME} ALIAS ${PROJECT_NAME}-shared)
else()
    add_library(${PROJECT_NAME}::${PROJECT_NAME} ALIAS ${PROJECT_NAME}-static)
endif()

# Symbolic link for archive numbered version
add_custom_command(TARGET ${PROJECT_NAME}-static POST_BUILD
    COMMAND ln -sfv lib${PROJECT_NAME}.a lib${PROJECT_NAME}_${PROJECT_VERSION}.a)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/lib${PROJECT_NAME}_${PROJECT_VERSION}.a DESTINATION lib)

#----- Generate the config file for the project to be usable via cmake's find_package command
set(INCLUDE_INSTALL_DIR include)
set(LIB_INSTALL_DIR     lib)
set(CONFIG_INSTALL_DIR  "${LIB_INSTALL_DIR}/cmake/${PROJECT_NAME}-${PROJECT_VERSION}")

install(EXPORT ${PROJECT_NAME}-shared-targets
    NAMESPACE ${PROJECT_NAME}::
    DESTINATION ${CONFIG_INSTALL_DIR})
install(EXPORT ${PROJECT_NAME}-static-targets
    NAMESPACE ${PROJECT_NAME}::
    DESTINATION ${CONFIG_INSTALL_DIR})

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
ec_package_name()                # Define package prefix  
ec_build_config()                # Create build configuration script
ec_prepare_ssm()                 # Prepare ssm packaging files

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
