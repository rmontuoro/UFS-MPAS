cmake_minimum_required(VERSION 3.19)

project(ufs-mpas
        VERSION 1.0
        LANGUAGES C CXX Fortran)

if (NOT ESMF_FOUND)
  find_package(ESMF REQUIRED)
endif ()

# UFS interface
list(APPEND ufs_mpas_files src/drv/ufs_mpas_cap.F90)

add_library(ufs-mpas STATIC ${ufs_mpas_files})
set_target_properties(ufs-mpas PROPERTIES Fortran_MODULE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/mod)
target_include_directories(ufs-mpas INTERFACE $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/mod>
                                              $<INSTALL_INTERFACE:mod>)
target_include_directories(ufs-mpas PRIVATE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
target_link_libraries(ufs-mpas PRIVATE ESMF::ESMF)
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

