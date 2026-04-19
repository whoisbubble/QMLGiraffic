cmake_minimum_required(VERSION 3.16)

project(QMLGiraffic VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(GNUInstallDirs)

find_package(Qt6 REQUIRED COMPONENTS Quick Sql)

qt_standard_project_setup(REQUIRES 6.10)

qt_add_executable(appQMLGiraffic
    main.cpp
)

qt_add_qml_module(appQMLGiraffic
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

qt_add_resources(appQMLGiraffic app_resources
    PREFIX "/"
    FILES
        assets/app_icon.png
)

if(WIN32)
    target_sources(appQMLGiraffic PRIVATE app_icon.rc)
endif()

if(APPLE)
    set(APP_ICON_MACOSX "${CMAKE_CURRENT_SOURCE_DIR}/assets/app_icon.icns")
    set_source_files_properties(${APP_ICON_MACOSX} PROPERTIES
        MACOSX_PACKAGE_LOCATION "Resources"
    )
    target_sources(appQMLGiraffic PRIVATE ${APP_ICON_MACOSX})
endif()

set_target_properties(appQMLGiraffic PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER ru.coursework.giraffic
    MACOSX_BUNDLE_ICON_FILE app_icon.icns
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appQMLGiraffic
    PRIVATE
        Qt6::Quick
        Qt6::Sql
)

install(TARGETS appQMLGiraffic
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

install(FILES config/giraffic.ini.example DESTINATION .)
