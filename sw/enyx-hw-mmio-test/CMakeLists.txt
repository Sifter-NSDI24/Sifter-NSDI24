cmake_minimum_required(VERSION 3.3)

set (CMAKE_CXX_STANDARD 11)
set (CMAKE_C_STANDARD 11)

project(enyx-hw-mmio-test
    VERSION
        1.0.0
    LANGUAGES
        C
        CXX
)

find_package(enyx-hw REQUIRED)
find_package(Threads REQUIRED)

include(GNUInstallDirs)

add_executable(
    enyx-hw-mmio-test
    main.cpp)

target_link_libraries(
    enyx-hw-mmio-test

    PRIVATE
        enyx-hw-c
        Threads::Threads)

install(
    TARGETS
        enyx-hw-mmio-test
    DESTINATION
        ${CMAKE_INSTALL_BINDIR})
