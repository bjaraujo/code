cmake_minimum_required(VERSION 2.8)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules/")

# Create main project.
project(getm Fortran)

# Set version information.
set(getm_VERSION_MAJOR 2)
set(getm_VERSION_MINOR 5)
set(getm_VERSION_PATCH 0)
set(getm_VERSION "${getm_VERSION_MAJOR}.${getm_VERSION_MINOR}.${getm_VERSION_PATCH}")

if(GETM_FLAGS)
   add_definitions(${GETM_FLAGS})
endif(GETM_FLAGS)

set(GIT_COMMIT_ID ${getm_VERSION})
configure_file("${PROJECT_SOURCE_DIR}/futils/getm_version.F90.in" getm_version.F90)
option(GETM_EMBED_VERSION "Embed GETM version information" OFF)
if(GETM_EMBED_VERSION)
  add_custom_target(getm_version
    ${CMAKE_COMMAND} -DINFILE=${PROJECT_SOURCE_DIR}/futils/getm_version.F90.in -DOUTFILE=${CMAKE_BINARY_DIR}/getm_version.F90 -P "${PROJECT_SOURCE_DIR}/cmake/Modules/GetGitInfo.cmake"
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    COMMENT "Retrieving description of last GETM commit..."
    SOURCES ${PROJECT_SOURCE_DIR}/futils/getm_version.F90.in "${PROJECT_SOURCE_DIR}/cmake/Modules/GetGitInfo.cmake"
    VERBATIM
  )
endif()

# Generate include file with version information.
#configure_file(../include/version.h.in version.h)
#configure_file(../include/fortran_version.h.in fortran_version.h)
#configure_file(../include/git_revision.h.in git_revision.h)

# Use solution folders in IDEs
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

# various compilation switches

option(GETM_USE_STATIC "Static compilation (domain size is set at compile time)" OFF)
if(GETM_USE_STATIC)
   add_definitions(-DSTATIC)
endif(GETM_USE_STATIC)

# used for naming executable
set(par_str "")
option(GETM_USE_PARALLEL "Enable parallel computation" OFF)
if(GETM_USE_PARALLEL)
   find_package(MPI REQUIRED)
   if(MPI_Fortran_INCLUDE_PATH)
     include_directories("${MPI_Fortran_INCLUDE_PATH}")
   endif()
   add_definitions(-DGETM_PARALLEL)
   set(HALO_MPI futils/halo_mpi.F90 ${MPI_Fortran_EXTRA_SOURCES})
   set(par_str "_parallel")
endif(GETM_USE_PARALLEL)

option(GETM_USE_DEBUG "Enable debug output" OFF)
if(GETM_USE_DEBUG)
   add_definitions(-DDEBUG)
endif(GETM_USE_DEBUG)

option(GETM_USE_PROFILING "Profiling compilation" OFF)
if(GETM_USE_PROFILING)
   add_definitions(-DPROF)
endif(GETM_USE_PROFILING)

option(GETM_USE_STATIC "Static compilation (domain size specified at compile time)" OFF)
if(GETM_USE_STATIC)
   add_definitions(-DSTATIC)
endif(GETM_USE_STATIC)

option(GETM_USE_FABM "Include support for Framework for Aquatic Biogeochemical Models (fabm.net)" OFF)
if(GETM_USE_FABM)
   add_definitions(-D_FABM_)
   set (GETM_FABM 3d/getm_fabm.F90)
   set(FABM_EMBED_VERSION ${GETM_EMBED_VERSION} CACHE BOOL "Embed FABM version information" FORCE)

endif(GETM_USE_FABM)

option(GETM_USE_STRUCTURE_FRICTION "Include structure friction" OFF)
if(GETM_USE_STRUCTURE_FRICTION)
   add_definitions(-DSTRUCTURE_FRICTION)
   set (STRUCTURE_FRICTION 3d/structure_friction_3d.F90)
endif(GETM_USE_STRUCTURE_FRICTION)

add_definitions(-DFORTRAN95)

# Specify coordinate type
if(NOT GETM_COORDINATE_TYPE)
   set (GETM_COORDINATE_TYPE "Cartesian" CACHE STRING "Choose coordinate type." FORCE)
   set_property(CACHE GETM_COORDINATE_TYPE PROPERTY STRINGS Cartesian Spherical Curvilinear)
endif()
if(${GETM_COORDINATE_TYPE} STREQUAL "Cartesian")
  add_definitions(-DCARTESIAN)
  set(exe_id "_cartesian${par_str}")
elseif(${GETM_COORDINATE_TYPE} STREQUAL "Spherical")
  add_definitions(-DSPHERICAL)
  set(exe_id "_spherical${par_str}")
elseif(${GETM_COORDINATE_TYPE} STREQUAL "Curvilinear")
  add_definitions(-DCURVILINEAR)
  set(exe_id "_curvilinear${par_str}")
endif()
message(${GETM_COORDINATE_TYPE})

# Specify default build type for single-type systems (not VS)
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set (CMAKE_BUILD_TYPE "Release" CACHE STRING "Choose the type of build." FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

# Customize compiler flags
if(${CMAKE_Fortran_COMPILER_ID} STREQUAL "GNU")
  set (CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -ffree-line-length-none")
  add_definitions(-DGFORTRAN)
elseif(${CMAKE_Fortran_COMPILER_ID} STREQUAL "Intel")
  add_definitions(-DIFORT)
  if(WIN32)
    set(CMAKE_Fortran_FLAGS_DEBUG "${CMAKE_Fortran_FLAGS_DEBUG} /Od")
    set(CMAKE_Fortran_STACK_SIZE 128000000)
  endif()
elseif(${CMAKE_Fortran_COMPILER_ID} STREQUAL "Cray")
  set (CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -N 1023")
endif()

# Use use position-independent code (-fPIC) everywhere if building shared libraries
if(BUILD_SHARED_LIBS)
  set(CMAKE_POSITION_INDEPENDENT_CODE ON)
endif()

# Set default installation prefix.
if(WIN32)
  if(DEFINED ENV{LOCALAPPDATA})
    set(DEFAULT_PREFIX "$ENV{LOCALAPPDATA}/getm")
  else()
    set(DEFAULT_PREFIX "$ENV{APPDATA}/getm")
  endif()
else()
  set(DEFAULT_PREFIX "$ENV{HOME}/local/getm")
endif()
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  # Still on CMake default - override with our own default.
  set(CMAKE_INSTALL_PREFIX ${DEFAULT_PREFIX} CACHE PATH "Directory to install GETM in" FORCE)
else()
  # Just set the doc string for the variable.
  set(CMAKE_INSTALL_PREFIX ${DEFAULT_PREFIX} CACHE PATH "Directory to install GETM in")
endif()

# Find NetCDF and - on Windows - compile against static runtime if NetCDF was compiled as such.
find_package(NetCDF REQUIRED)
if (NetCDF_STATIC_MSVC_BUILD)
  add_compile_options("/libs:static")
endif()

# Global include directories
include_directories("${CMAKE_BINARY_DIR}"
                    "${PROJECT_SOURCE_DIR}/../include"
                   )
# Libraries added in alphabetic order - dependencies are dealt with below 
add_library(2d OBJECT
            2d/adv_arakawa_j7_2dh.F90
            2d/advection.F90
            2d/adv_fct_2dh.F90
            2d/adv_split_u.F90
            2d/adv_split_v.F90
            2d/adv_upstream_2dh.F90
            2d/bottom_friction.F90
            2d/cfl_check.F90
            2d/depth_update.F90
            2d/m2d.F90
            2d/momentum.F90
            2d/residual.F90
            2d/sealevel.F90
            2d/update_2d_bdy.F90
            2d/uv_advect.F90
            2d/uv_diff_2dh.F90
            2d/uv_diffusion.F90
            2d/variables_2d.F90
           )
set_property(TARGET 2d APPEND PROPERTY INCLUDE_DIRECTORIES "${PROJECT_SOURCE_DIR}/2d")

add_library(3d OBJECT
            3d/adaptive_coordinates.F90
            3d/advection_3d.F90
            3d/adv_split_w.F90
            3d/bdy_3d.F90
            3d/bottom_friction_3d.F90
            3d/check_h.F90
            3d/coordinates.F90
            3d/eqstate.F90
            3d/general_coordinates.F90
#            3d/getm_bio.F90
            ${GETM_FABM}
            3d/gotm.F90
            3d/hcc_check.F90
            3d/hybrid_coordinates.F90
            3d/internal_pressure.F90
            3d/ip_blumberg_mellor.F90
            3d/ip_blumberg_mellor_lin.F90
            3d/ip_chu_fan.F90
            3d/ip_shchepetkin_mcwilliams.F90
            3d/ip_song_wright.F90
            3d/ip_stelling_vankester.F90
            3d/ip_z_interpol.F90
            3d/m3d.F90
            3d/numerical_mixing.F90
            3d/physical_mixing.F90
            3d/preadapt_coordinates.F90
            3d/rivers.F90
            3d/salinity.F90
            3d/sigma_coordinates.F90
            3d/slow_bottom_friction.F90
            3d/slow_terms.F90
#            3d/spm.F90
            3d/ss_nn.F90
            3d/start_macro.F90
            3d/stop_macro.F90
            3d/stresses_3d.F90
            ${STRUCTURE_FRICTION}
            3d/temperature.F90
            3d/tke_eps_advect_3d.F90
            3d/uu_momentum_3d.F90
            3d/uv_advect_3d.F90
            3d/uv_diffusion_3d.F90
            3d/variables_3d.F90
            3d/vv_momentum_3d.F90
            3d/ww_momentum_3d.F90
           )
set_property(TARGET 3d APPEND PROPERTY INCLUDE_DIRECTORIES "${PROJECT_SOURCE_DIR}/3d")

add_library(domain OBJECT
            domain/bdy_spec.F90
            domain/domain.F90
            domain/have_bdy.F90
            domain/mirror_bdy_2d.F90
            domain/mirror_bdy_3d.F90
            domain/part_domain.F90
            domain/print_bdy.F90
            domain/uv_depths.F90
           )
set_property(TARGET domain APPEND PROPERTY INCLUDE_DIRECTORIES "${PROJECT_SOURCE_DIR}/domain")

add_library(futils OBJECT
#            git_revision.h
            futils/c2x.F90
            futils/check_3d_fields.F90
            futils/cnv_2d.F90
            futils/cnv_3d.F90
            futils/col_interpol.F90
            futils/eta_mask.F90
            futils/exceptions.F90
            futils/getm_error.F90
            futils/getm_timers.F90
            futils/grid_interpol.F90
            ${HALO_MPI}
            futils/halo_zones.F90
            futils/kbk_interpol.F90
            futils/parallel.F90
            futils/parameters.F90
            futils/pos.F90
            futils/read_par_setup.F90
            futils/strip_string.F90
            futils/time.F90
            futils/to_2d_u.F90
            futils/to_2d_vel.F90
            futils/to_2d_v.F90
            futils/to_3d_uu.F90
            futils/to_3d_vel.F90
            futils/to_3d_vv.F90
            futils/tow.F90
            futils/tridiagonal.F90
            futils/ver_interpol.F90
            ${CMAKE_BINARY_DIR}/getm_version.F90
           )
if(GETM_EMBED_VERSION)
  add_dependencies(futils getm_version)
endif()

add_library(getm OBJECT
            getm/cleanup.F90
            getm/initialise.F90
            getm/integration.F90
            getm/print_version.F90
           )

add_library(input OBJECT
            input/get_2d_bdy.F90
            input/get_2d_field.F90
            input/get_3d_bdy.F90
            input/get_3d_field.F90
            input/get_meteo_data.F90
            input/get_river_data.F90
            input/inquire_file.F90
            input/init_2d_bdy.F90
            input/init_3d_bdy.F90
            input/init_meteo_input.F90
            input/init_river_input.F90
            input/input.F90
            input/read_profile.F90
            input/read_topo_file.F90
           )

add_library(meteo OBJECT
            meteo/exchange_coefficients.F90
            meteo/fluxes.F90
            meteo/meteo.F90
            meteo/solar_zenith_angle.F90
            meteo/short_wave_radiation.F90
            meteo/albedo_water.F90
           )

add_library(ncdf OBJECT
            ncdf/create_restart_ncdf.F90
            ncdf/grid_ncdf.F90
            ncdf/init_2d_ncdf.F90
            ncdf/init_3d_ncdf.F90
            ncdf/init_grid_ncdf.F90
            ncdf/init_mean_ncdf.F90
            ncdf/ncdf_2d_bdy.F90
            ncdf/ncdf_2d.F90
            ncdf/ncdf_3d_bdy.F90
            ncdf/ncdf_3d_bio_bdy.F90
            ncdf/ncdf_3d.F90
            ncdf/ncdf_close.F90
            ncdf/ncdf_common.F90
            ncdf/ncdf_get_field.F90
            ncdf/get_2d_field_ncdf_by_id.F90
            ncdf/ncdf_in.F90
            ncdf/ncdf_mean.F90
            ncdf/ncdf_meteo.F90
            ncdf/ncdf_restart.F90
            ncdf/ncdf_rivers.F90
            ncdf/ncdf_topo.F90
            ncdf/open_restart_ncdf.F90
            ncdf/read_restart_ncdf.F90
            ncdf/save_2d_ncdf.F90
            ncdf/save_3d_ncdf.F90
            ncdf/save_grid_ncdf.F90
            ncdf/save_mean_ncdf.F90
            ncdf/set_attributes.F90
            ncdf/write_restart_ncdf.F90
           )
set_property(TARGET ncdf APPEND PROPERTY INCLUDE_DIRECTORIES "${PROJECT_SOURCE_DIR}/ncdf")

add_library(output OBJECT
            output/ascii_out.F90
            output/calc_mean_fields.F90
            output/diagnose.F90
            output/diagnostic_variables.F90
            output/ncdf_out.F90
            output/nesting.F90
            output/output.F90
           )

#option(DEFINE_ICE "Include ICE support" OFF)
#if(DEFINE_ICE)
#  add_library(ice OBJECT
#             )
#endif(DEFINE_ICE)

add_dependencies(domain futils)
add_dependencies(meteo futils domain)
add_dependencies(2d domain)
add_dependencies(3d meteo domain 2d)
add_dependencies(output futils domain 2d 3d meteo)
add_dependencies(ncdf futils domain output)
add_dependencies(input futils 2d 3d ncdf)
add_dependencies(getm input)

set_property(TARGET futils ncdf input APPEND PROPERTY INCLUDE_DIRECTORIES "${NetCDF_INCLUDE_DIRS}")
add_definitions(-DNETCDF_FMT -DREAL_4B=real\(4\))

# Use GOTM_PREFIX to locate include and lib directories
set(GOTM_EMBED_VERSION ${GETM_EMBED_VERSION} CACHE BOOL "Embed GOTM version information" FORCE)
find_path(GOTM_BASE src/gotm/gotm.F90 DOC "Path to GOTM source directory.")
if(GOTM_BASE)
  set(GOTM_BUILD_LIBRARIES_ONLY ON)
  set(GOTM_USE_FABM ${GETM_USE_FABM} CACHE BOOL "Include support for Framework for Aquatic Biogeochemical Models (fabm.net)" FORCE)
  add_subdirectory(${GOTM_BASE}/src gotm)
  set(GOTM_INCLUDE_DIRS ${CMAKE_BINARY_DIR}/gotm/modules)
  set(GOTM_LIBRARIES turbulence util)
  if(GETM_USE_FABM)
    set(GOTM_LIBRARIES ${GOTM_LIBRARIES} gotm_fabm)
    set_property(TARGET 3d getm APPEND PROPERTY INCLUDE_DIRECTORIES $<TARGET_PROPERTY:gotm_fabm,INTERFACE_INCLUDE_DIRECTORIES>)
  endif()
  mark_as_advanced(GOTM_PREFIX GOTM_USE_FABM)
  add_dependencies(3d ${GOTM_LIBRARIES})
else()
  find_package(GOTM REQUIRED)

  # Use FABM_PREFIX to locate include and lib directories
  if(GETM_USE_FABM)
    find_package(FABM REQUIRED)
    set_property(TARGET 3d getm APPEND PROPERTY INCLUDE_DIRECTORIES "${FABM_INCLUDE_DIRS}")
  endif()
endif()
set_property(TARGET 3d getm APPEND PROPERTY INCLUDE_DIRECTORIES "${GOTM_INCLUDE_DIRS}")

# Build GETM executable.
add_executable(getm_exe
               getm/main.F90
               $<TARGET_OBJECTS:getm>
               $<TARGET_OBJECTS:output>
               $<TARGET_OBJECTS:meteo>
               $<TARGET_OBJECTS:3d>
               $<TARGET_OBJECTS:2d>
               $<TARGET_OBJECTS:input>
               $<TARGET_OBJECTS:domain>
               $<TARGET_OBJECTS:ncdf>
               $<TARGET_OBJECTS:futils>
              )
set_property(TARGET getm_exe PROPERTY OUTPUT_NAME "getm${exe_id}")

target_link_libraries(getm_exe ${GOTM_LIBRARIES} ${NetCDF_LIBRARIES})
if (NetCDF_STATIC_MSVC_BUILD)
  set_property(TARGET getm_exe PROPERTY LINK_FLAGS_DEBUG "/NODEFAULTLIB:\"libcmt\"")
endif()
if(GETM_USE_PARALLEL AND MPI_Fortran_LIBRARIES)
  target_link_libraries(getm_exe ${MPI_Fortran_LIBRARIES})
endif()

if(GETM_USE_FABM AND NOT GOTM_BASE)
  target_link_libraries(getm_exe ${FABM_LIBRARIES})
endif()

# Install GETM executable
install(TARGETS getm_exe DESTINATION bin)

# Begin testing section

# add_custom_target(test_all COMMENT "building tests - nothing yet :-)")
add_executable(test_speed_adv_upstream_2dh EXCLUDE_FROM_ALL
               2d/test_speed_adv_upstream_2dh.F90
              )

add_executable(test_rotation EXCLUDE_FROM_ALL
               futils/test_rotation.F90
               $<TARGET_OBJECTS:futils>
              )
target_link_libraries(test_rotation ${NetCDF_LIBRARIES})
if (NetCDF_STATIC_MSVC_BUILD)
  set_property(TARGET test_rotation PROPERTY LINK_FLAGS_DEBUG "/NODEFAULTLIB:\"libcmt\"")
endif()
if(GETM_USE_PARALLEL AND MPI_Fortran_LIBRARIES)
  target_link_libraries(test_rotation ${MPI_Fortran_LIBRARIES})
endif()

add_custom_target(test_all WORKING_DIRECTORY tests COMMENT "building tests")
add_dependencies( test_all test_speed_adv_upstream_2dh test_rotation )

# End of testing section
