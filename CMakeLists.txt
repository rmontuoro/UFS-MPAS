cmake_minimum_required(VERSION 3.19)

project(ufs-mpas
        VERSION 1.0
        LANGUAGES C Fortran)

if (NOT ESMF_FOUND)
    list(APPEND CMAKE_MODULE_PATH $ENV{ESMF_ROOT}/cmake)
    list(APPEND CMAKE_MODULE_PATH $ENV{esmf_ROOT}/cmake)
    find_package(ESMF REQUIRED)
endif ()

# MPAS model
add_subdirectory(src/model/MPAS-Model)

# UFS interface
set(ufs_mpas_files
    ufs_mpas_cap.F90
    ufs_mpas_geom.F90
    ufs_mpas_methods.F90
    ufs_mpas_types.F90
)
list(TRANSFORM ufs_mpas_files PREPEND src/drv/)

target_compile_options(framework PRIVATE $<$<COMPILE_LANG_AND_ID:Fortran,Intel>:-falias>)

add_library(ufs-mpas ${ufs_mpas_files})
set_target_properties(ufs-mpas PROPERTIES Fortran_MODULE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/mod)
target_include_directories(ufs-mpas PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/mod>
                                           $<INSTALL_INTERFACE:mod>)
target_include_directories(ufs-mpas PRIVATE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
target_link_libraries(ufs-mpas PUBLIC MPAS::core::atmosphere ESMF::ESMF)
list(APPEND LIB_TARGETS ufs-mpas)

add_library(ufs-mpas::ufs-mpas ALIAS ufs-mpas)

###############################################################################
### Install
###############################################################################

install(
  TARGETS   ${LIB_TARGETS}
  EXPORT    UFS-MPASExports
  LIBRARY   DESTINATION lib
  ARCHIVE   DESTINATION lib
  COMPONENT Library)

export(EXPORT    UFS-MPASExports
       NAMESPACE ufs-mpas::
       FILE      ufs-mpas-targets.cmake)

install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/mod DESTINATION ${CMAKE_INSTALL_PREFIX}/UFS-MPAS)

install(EXPORT      UFS-MPASExports
        NAMESPACE   ufs-mpas::
        FILE        ufs-mpas-targets.cmake
        DESTINATION lib/cmake)
