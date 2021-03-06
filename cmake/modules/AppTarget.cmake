# before including this module, BasicConfig must be included

# check whether project type is set correctly
if(NOT "${META_PROJECT_TYPE}" STREQUAL "application")
    message(FATAL_ERROR "The AppTarget CMake module is intended to be used for building application projects only (and not for libraries).")
endif()

# set the windows extension to "exe", this is required by the Windows specific WindowsResources module
if(WIN32)
    set(WINDOWS_EXT "exe")
endif(WIN32)

# set compile definitions
if(NOT META_PUBLIC_SHARED_LIB_COMPILE_DEFINITIONS)
    set(META_PUBLIC_SHARED_LIB_COMPILE_DEFINITIONS ${META_PUBLIC_COMPILE_DEFINITIONS} ${META_ADDITIONAL_PUBLIC_SHARED_COMPILE_DEFINITIONS})
endif()
if(NOT META_PRIVATE_SHARED_LIB_COMPILE_DEFINITIONS)
    set(META_PRIVATE_SHARED_LIB_COMPILE_DEFINITIONS ${META_PRIVATE_COMPILE_DEFINITIONS} ${META_ADDITIONAL_PRIVATE_SHARED_COMPILE_DEFINITIONS})
endif()

# set linker flags
if(STATIC_LINKAGE)
    set(ACTUAL_ADDITIONAL_LINK_FLAGS ${META_ADDITIONAL_STATIC_LINK_FLAGS})
else()
    set(ACTUAL_ADDITIONAL_LINK_FLAGS ${META_ADDITIONAL_LINK_FLAGS})
endif()

# add target for building the application
add_executable(${TARGET_PREFIX}${META_PROJECT_NAME}${TARGET_SUFFIX} ${GUI_TYPE} ${HEADER_FILES} ${SRC_FILES} ${WIDGETS_FILES} ${QML_FILES} ${RES_FILES} ${QM_FILES} ${WINDOWS_ICON_PATH})
target_link_libraries(${TARGET_PREFIX}${META_PROJECT_NAME}${TARGET_SUFFIX}
    PUBLIC ${ACTUAL_ADDITIONAL_LINK_FLAGS} "${PUBLIC_LIBRARIES}"
    PRIVATE "${PRIVATE_LIBRARIES}"
)
target_compile_definitions(${TARGET_PREFIX}${META_PROJECT_NAME}${TARGET_SUFFIX}
    PUBLIC "${META_PUBLIC_SHARED_LIB_COMPILE_DEFINITIONS}"
    PRIVATE "${META_PRIVATE_SHARED_LIB_COMPILE_DEFINITIONS}"
)
set_target_properties(${TARGET_PREFIX}${META_PROJECT_NAME}${TARGET_SUFFIX} PROPERTIES
    CXX_STANDARD 11
    LINK_SEARCH_START_STATIC ${STATIC_LINKAGE}
    LINK_SEARCH_END_STATIC ${STATIC_LINKAGE}
)

if(MAKE_APP_TARGET_LINKABLE OR LINK_TESTS_AGAINST_APP_TARGET)
    set_target_properties(${TARGET_PREFIX}${META_PROJECT_NAME}${TARGET_SUFFIX} PROPERTIES
        ENABLE_EXPORTS ON
    )
endif()

# add install target for binary
install(TARGETS ${TARGET_PREFIX}${META_PROJECT_NAME}${TARGET_SUFFIX}
    RUNTIME DESTINATION bin
    COMPONENT binary
)
if(NOT TARGET install-binary)
    add_custom_target(install-binary
        COMMAND "${CMAKE_COMMAND}" -DCMAKE_INSTALL_COMPONENT=binary -P "${CMAKE_BINARY_DIR}/cmake_install.cmake"
    )
endif()
add_dependencies(install-binary ${TARGET_PREFIX}${META_PROJECT_NAME}${TARGET_SUFFIX})

# add install target for localization
if(NOT TARGET install-mingw-w64)
    add_custom_target(install-mingw-w64)
    add_dependencies(install-mingw-w64 install-binary ${TARGET_PREFIX}${META_PROJECT_NAME}${TARGET_SUFFIX})
endif()

# add install target for desktop entries and icons
foreach(DESKTOP_FILE ${DESKTOP_FILES})
    install(
        FILES "${DESKTOP_FILE}"
        DESTINATION "share/applications"
        COMPONENT desktop
    )
endforeach()

foreach(ICON_FILE ${ICON_FILES})
    install(
        FILES "${ICON_FILE}"
        DESTINATION "share/icons/hicolor/scalable/apps"
        COMPONENT desktop
    )
endforeach()
if(NOT TARGET install-desktop)
    add_custom_target(install-desktop
        COMMAND "${CMAKE_COMMAND}" -DCMAKE_INSTALL_COMPONENT=desktop -P "${CMAKE_BINARY_DIR}/cmake_install.cmake"
    )
endif()
add_dependencies(install-desktop ${TARGET_PREFIX}${META_PROJECT_NAME}${TARGET_SUFFIX})

# add install target for stripped binaries
if(NOT TARGET install-binary-strip)
    add_custom_target(install-binary-strip
        COMMAND "${CMAKE_COMMAND}" -DCMAKE_INSTALL_DO_STRIP=1 -DCMAKE_INSTALL_COMPONENT=binary -P "${CMAKE_BINARY_DIR}/cmake_install.cmake"
    )
endif()
add_dependencies(install-binary-strip ${TARGET_PREFIX}${META_PROJECT_NAME}${TARGET_SUFFIX})

# add mingw-w64 specific install target
if(NOT TARGET install-mingw-w64-strip)
    add_custom_target(install-mingw-w64-strip)
    add_dependencies(install-mingw-w64-strip install-binary-strip ${LOCALIZATION_TARGET})
endif()

# add target for launching application with wine ensuring the WINEPATH is set correctly so wine is able to find all required *.dll files
# requires script from c++utilities, hence the sources of c++utilities must be present
if(MINGW AND CMAKE_CROSSCOMPILING AND CPP_UTILITIES_SOURCE_DIR)
    if(NOT TARGET ${META_PROJECT_NAME}_run)
        if(CMAKE_FIND_ROOT_PATH)
            list(APPEND RUNTIME_LIBRARY_PATH "${CMAKE_FIND_ROOT_PATH}/bin")
        endif()
        add_custom_target(${META_PROJECT_NAME}_run COMMAND "${CPP_UTILITIES_SOURCE_DIR}/scripts/wine.sh" "${CMAKE_CURRENT_BINARY_DIR}/${META_PROJECT_NAME}.${WINDOWS_EXT}" ${RUNTIME_LIBRARY_PATH})
        add_dependencies(${META_PROJECT_NAME}_run ${META_PROJECT_NAME})
    endif()
endif()

# find template for *.desktop files
include(TemplateFinder)
find_template_file("desktop" CPP_UTILITIES APP_DESKTOP_TEMPLATE_FILE)

# function to add *.desktop files with additional entries
function(add_custom_desktop_file_with_additional_entries
        FILE_NAME
        DESKTOP_FILE_APP_NAME
        DESKTOP_FILE_GENERIC_NAME
        DESKTOP_FILE_DESCRIPTION
        DESKTOP_FILE_CATEGORIES
        DESKTOP_FILE_CMD
        DESKTOP_FILE_ICON
        DESKTOP_FILE_ADDITIONAL_ENTRIES)
    # create desktop file from template
    configure_file(
        "${APP_DESKTOP_TEMPLATE_FILE}"
        "${CMAKE_CURRENT_BINARY_DIR}/resources/${FILE_NAME}.desktop"
    )
    # add install for the desktop file
    install(
        FILES "${CMAKE_CURRENT_BINARY_DIR}/resources/${FILE_NAME}.desktop"
        DESTINATION "share/applications"
        COMPONENT desktop
    )
endfunction()

# function to add *.desktop files
function(add_custom_desktop_file
        FILE_NAME
        DESKTOP_FILE_APP_NAME
        DESKTOP_FILE_GENERIC_NAME
        DESKTOP_FILE_DESCRIPTION
        DESKTOP_FILE_CATEGORIES
        DESKTOP_FILE_CMD
        DESKTOP_FILE_ICON)
    add_custom_desktop_file_with_additional_entries(
        "${FILE_NAME}"
        "${DESKTOP_FILE_APP_NAME}"
        "${DESKTOP_FILE_GENERIC_NAME}"
        "${DESKTOP_FILE_DESCRIPTION}"
        "${DESKTOP_FILE_CATEGORIES}"
        "${DESKTOP_FILE_CMD}"
        "${DESKTOP_FILE_ICON}"
        ""
    )
endfunction()

# convenience function to add *.desktop file from project meta data
function(add_desktop_file)
    # compose actions
    set(DESKTOP_FILE_ADDITIONAL_ENTRIES "")
    foreach(ACTION_VAR ${META_APP_ACTIONS})
        list(GET META_APP_ACTION_${ACTION_VAR} 0 ACTION_ID)
        list(GET META_APP_ACTION_${ACTION_VAR} 1 ACTION_NAME)
        list(GET META_APP_ACTION_${ACTION_VAR} 2 ACTION_ARGS)
        set(DESKTOP_FILE_ADDITIONAL_ENTRIES "${DESKTOP_FILE_ADDITIONAL_ENTRIES}\n[Desktop Action ${ACTION_ID}]\nName=${ACTION_NAME}\nExec=${TARGET_PREFIX}${META_PROJECT_NAME}${TARGET_SUFFIX} ${ACTION_ARGS}")
    endforeach()

    # create desktop file
    add_custom_desktop_file_with_additional_entries(
        "${TARGET_PREFIX}${META_PROJECT_NAME}${TARGET_SUFFIX}"
        "${META_APP_NAME}"
        "${META_GENERIC_NAME}"
        "${META_APP_DESCRIPTION}"
        "${META_APP_CATEGORIES}"
        "${TARGET_PREFIX}${META_PROJECT_NAME}${TARGET_SUFFIX}"
        "${META_PROJECT_NAME}"
        "${DESKTOP_FILE_ADDITIONAL_ENTRIES}"
    )
endfunction()
