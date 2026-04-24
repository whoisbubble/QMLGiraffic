cmake_minimum_required(VERSION 3.16)

project(QMLGiraffic VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(APP_TARGET_NAME "appQMLGiraffic")
set(APP_PRODUCT_NAME "Giraffic")
set(APP_DISPLAY_NAME "Giraffic")
set(APP_EXECUTABLE_NAME "Giraffic")
set(APP_COMPANY_NAME "Giraffic")
set(APP_BUNDLE_ID "ru.coursework.giraffic")
set(APP_FILE_DESCRIPTION "Work schedule management")
set(APP_COPYRIGHT "Copyright (c) 2026 Giraffic")

include(GNUInstallDirs)

find_package(Qt6 REQUIRED COMPONENTS Quick Sql)

qt_standard_project_setup(REQUIRES 6.5)

if(APPLE AND NOT DEFINED CMAKE_OSX_DEPLOYMENT_TARGET)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "11.0" CACHE STRING "Minimum macOS deployment target" FORCE)
endif()

configure_file(cmake/Info.plist.in "${CMAKE_CURRENT_BINARY_DIR}/Info.plist" @ONLY)
configure_file(cmake/windows_version.rc.in "${CMAKE_CURRENT_BINARY_DIR}/windows_version.rc" @ONLY)

qt_add_executable(${APP_TARGET_NAME}
    main.cpp
)

qt_add_qml_module(${APP_TARGET_NAME}
    URI QMLGiraffic
    QML_FILES
        Main.qml
        AppButton.qml
        AppComboBox.qml
        AppField.qml
        AppPanel.qml
        AppTheme.qml
        GiraffePattern.qml
        NotifyWindow.qml
        ManageWindow.qml
        WorkersWindow.qml
        AddEventWindow.qml
        ClientsWindow.qml
        VenuesWindow.qml
        AdminWindow.qml
    SOURCES
        databasemanager.h
        databasemanager.cpp
)

qt_add_resources(${APP_TARGET_NAME} app_resources
    PREFIX "/"
    FILES
        assets/app_icon.png
)

if(WIN32)
    target_sources(${APP_TARGET_NAME} PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/windows_version.rc")
endif()

if(APPLE)
    set(APP_ICON_MACOSX "${CMAKE_CURRENT_SOURCE_DIR}/assets/app_icon.icns")
    set_source_files_properties(${APP_ICON_MACOSX} PROPERTIES
        MACOSX_PACKAGE_LOCATION "Resources"
    )
    target_sources(${APP_TARGET_NAME} PRIVATE ${APP_ICON_MACOSX})
endif()

set_target_properties(${APP_TARGET_NAME} PROPERTIES
    OUTPUT_NAME ${APP_EXECUTABLE_NAME}
    MACOSX_BUNDLE_BUNDLE_NAME ${APP_DISPLAY_NAME}
    MACOSX_BUNDLE_GUI_IDENTIFIER ${APP_BUNDLE_ID}
    MACOSX_BUNDLE_ICON_FILE "app_icon.icns"
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_BINARY_DIR}/Info.plist"
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(${APP_TARGET_NAME}
    PRIVATE
        Qt6::Quick
        Qt6::Sql
)

install(TARGETS ${APP_TARGET_NAME}
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

install(FILES config/giraffic.ini.example DESTINATION .)
