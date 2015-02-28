# vim: ts=2 sw=2
# - Try to find the required libav components(default: AVFORMAT, AVUTIL, AVCODEC)
#
# Once done this will define
#  LIBAV_FOUND         - System has the all required components.
#  LIBAV_INCLUDE_DIRS  - Include directory necessary for using the required components headers.
#  LIBAV_LIBRARIES     - Link these to use the required libav components.
#  LIBAV_DEFINITIONS   - Compiler switches required for using the required libav components.
#
# For each of the components it will additionally set.
#   - AVCODEC
#   - AVDEVICE
#   - AVFILTER
#   - AVFORMAT
#   - AVRESAMPLE
#   - AVUTIL
#   - SWSCALE
# the following variables will be defined
#  <component>_FOUND        - System has <component>
#  <component>_INCLUDE_DIRS - Include directory necessary for using the <component> headers
#  <component>_LIBRARIES    - Link these to use <component>
#  <component>_DEFINITIONS  - Compiler switches required for using <component>
#  <component>_VERSION      - The components version
#
# Copyright (c) 2006, Matthias Kretz, <kretz@kde.org>
# Copyright (c) 2008, Alexander Neundorf, <neundorf@kde.org>
# Copyright (c) 2011, Michael Jansen, <kde@michael-jansen.biz>
# Copyright (c) 2013,2015 Stephen Baker <baker.stephen.e@gmail.com>
# Copyright (c) 2015, Alexander Bessman
#
# Redistribution and use is allowed according to the terms of the BSD license.
# For details see the accompanying COPYING-CMAKE-SCRIPTS file.

include(FindPackageHandleStandardArgs)

# The default components were taken from a survey over other FindLIBAV.cmake files
if (NOT LibAV_FIND_COMPONENTS)
  set(LibAV_FIND_COMPONENTS AVCODEC AVFORMAT AVUTIL)
endif ()

#
### Macro: set_component_found
#
# Marks the given component as found if both *_LIBRARIES AND *_INCLUDE_DIRS is present.
#
macro(set_component_found _component )
  if (${_component}_LIBRARIES AND ${_component}_INCLUDE_DIRS)
    # message(STATUS "  - ${_component} found.")
    set(${_component}_FOUND TRUE)
  else ()
    # message(STATUS "  - ${_component} not found.")
  endif ()
endmacro()

#
### Macro: find_component
#
macro(find_component _component _library _header _version)

  find_path(${_component}_INCLUDE_DIRS ${_header}
    HINTS
      ${PC_LIB${_component}_INCLUDEDIR}
      ${PC_LIB${_component}_INCLUDE_DIRS}
    PATH_SUFFIXES
      libav
      include
  )

  find_library(${_component}_LIBRARIES
      NAMES ${_library}
      HINTS
        ${PC_LIB${_component}_LIBDIR}
        ${PC_LIB${_component}_LIBRARY_DIRS}
      PATH_SUFFIXES
        lib
  )

  if (${_component}_INCLUDE_DIRS AND EXISTS "${${_component}_INCLUDE_DIRS}/${_version}")
    file(STRINGS "${${_component}_INCLUDE_DIRS}/${_version}" ${_component}_VERSION_MAJOR_LINE REGEX "^#define[ \t]+LIB${_component}_VERSION_MAJOR[ \t]+[0-9]+$")
    file(STRINGS "${${_component}_INCLUDE_DIRS}/${_version}" ${_component}_VERSION_MINOR_LINE REGEX "^#define[ \t]+LIB${_component}_VERSION_MINOR[ \t]+[0-9]+$")
    file(STRINGS "${${_component}_INCLUDE_DIRS}/${_version}" ${_component}_VERSION_MICRO_LINE REGEX "^#define[ \t]+LIB${_component}_VERSION_MICRO[ \t]+[0-9]+$")
    string(REGEX REPLACE "^#define[ \t]+LIB${_component}_VERSION_MAJOR[ \t]+([0-9]+)$" "\\1" ${_component}_VERSION_MAJOR "${${_component}_VERSION_MAJOR_LINE}")
    string(REGEX REPLACE "^#define[ \t]+LIB${_component}_VERSION_MINOR[ \t]+([0-9]+)$" "\\1" ${_component}_VERSION_MINOR "${${_component}_VERSION_MINOR_LINE}")
    string(REGEX REPLACE "^#define[ \t]+LIB${_component}_VERSION_MICRO[ \t]+([0-9]+)$" "\\1" ${_component}_VERSION_MICRO "${${_component}_VERSION_MICRO_LINE}")
    set(${_component}_VERSION_STRING ${${_component}_VERSION_MAJOR}.${${_component}_VERSION_MINOR}.${${_component}_VERSION_MICRO})
    unset(${_component}_VERSION_MAJOR_LINE)
    unset(${_component}_VERSION_MINOR_LINE)
    unset(${_component}_VERSION_MICRO_LINE)
    unset(${_component}_VERSION_MAJOR)
    unset(${_component}_VERSION_MINOR)
    unset(${_component}_VERSION_MICRO)
  endif ()
  find_package_handle_standard_args(${_component}
                                    REQUIRED_VARS ${_component}_LIBRARIES ${_component}_INCLUDE_DIRS
                                    VERSION_VAR ${_component}_VERSION_STRING)

  set(${_component}_DEFINITIONS  ${PC_${_component}_CFLAGS_OTHER} CACHE STRING "The ${_component} CFLAGS.")
  set(${_component}_VERSION      ${PC_${_component}_VERSION}      CACHE STRING "The ${_component} version number.")

  set_component_found(${_component})

endmacro()


# Check for cached results. If there are skip the costly part.
if (NOT LIBAV_LIBRARIES)

  # Check for all possible component.
  find_component(AVCODEC  avcodec  libavcodec/avcodec.h   libavcodec/version.h)
  find_component(AVFORMAT avformat libavformat/avformat.h libavformat/version.h)
  find_component(AVDEVICE avdevice libavdevice/avdevice.h libavdevice/version.h)
  find_component(AVFILTER avfilter libavfilter/avfilter.h libavfilter/version.h)
  find_component(AVRESAMPLE avresample libavresample/avresample.h libavresample/version.h)
  find_component(AVUTIL   avutil   libavutil/avutil.h     libavutil/version.h)
  find_component(SWSCALE  swscale  libswscale/swscale.h   libswscale/version.h)

  # Check if the required components were found and add their stuff to the LIBAV_* vars.
  foreach (_component ${LibAV_FIND_COMPONENTS})
    if (${_component}_FOUND)
      # message(STATUS "Required component ${_component} present.")
      set(LIBAV_LIBRARIES   ${LIBAV_LIBRARIES}   ${${_component}_LIBRARIES})
      set(LIBAV_DEFINITIONS ${LIBAV_DEFINITIONS} ${${_component}_DEFINITIONS})
      list(APPEND LIBAV_INCLUDE_DIRS ${${_component}_INCLUDE_DIRS})
    else ()
      # message(STATUS "Required component ${_component} missing.")
    endif ()
  endforeach ()

  # Build the include path with duplicates removed.
  if (LIBAV_INCLUDE_DIRS)
    list(REMOVE_DUPLICATES LIBAV_INCLUDE_DIRS)
  endif ()

  # cache the vars.
  set(LIBAV_INCLUDE_DIRS ${LIBAV_INCLUDE_DIRS} CACHE STRING "The LibAV include directories." FORCE)
  set(LIBAV_LIBRARIES    ${LIBAV_LIBRARIES}    CACHE STRING "The LibAV libraries." FORCE)
  set(LIBAV_DEFINITIONS  ${LIBAV_DEFINITIONS}  CACHE STRING "The LibAV cflags." FORCE)

  mark_as_advanced(LIBAV_INCLUDE_DIRS
                   LIBAV_LIBRARIES
                   LIBAV_DEFINITIONS)

endif ()

# Now set the noncached _FOUND vars for the components.
foreach (_component AVCODEC AVDEVICE AVFILTER AVFORMAT AVRESAMPLE AVUTIL SWSCALE)
  set_component_found(${_component})
endforeach ()

# Compile the list of required vars
set(_LibAV_REQUIRED_VARS LIBAV_LIBRARIES LIBAV_INCLUDE_DIRS)
foreach (_component ${LibAV_FIND_COMPONENTS})
  list(APPEND _LibAV_REQUIRED_VARS ${_component}_LIBRARIES ${_component}_INCLUDE_DIRS)
endforeach ()

# Give a nice error message if some of the required vars are missing.
find_package_handle_standard_args(LibAV DEFAULT_MSG ${_LibAV_REQUIRED_VARS})
