cmake_minimum_required(VERSION 3.16)

project(DewaruciCpp VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Sql)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appDewaruciCpp
    main.cpp
    src/database/DatabaseConnection.cpp
    src/database/DatabaseShipConnection.cpp
    src/database/models/LinearIsotropicMaterials.cpp
    src/database/models/StructureProfileTable.cpp
    src/database/models/FrameArrangementXZ.cpp
    src/database/models/FrameArrangementYZ.cpp
    src/controllers/StructureProfileTableController.cpp
    src/controllers/FrameArrangementXZController.cpp
)

qt_add_qml_module(appDewaruciCpp
    URI DewaruciCpp
    VERSION 1.0
    QML_FILES
        ./qml/Main.qml
        ./qml/components/section0/LinearIsotropicMaterials/LinearIsotropicMaterials.qml
        ./qml/components/section0/ProfileTable/ProfileTable.qml
        ./qml/pages/FrameArrangement.qml
        ./qml/components/section0/FrameArrangement/InputSection/XZInput/XZInput.qml
        ./qml/components/section0/FrameArrangement/InputSection/YZInput/YZInput.qml
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appDewaruciCpp PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appDewaruciCpp
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appDewaruciCpp
    PRIVATE Qt6::Quick Qt6::Sql
)

include(GNUInstallDirs)
install(TARGETS appDewaruciCpp
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
