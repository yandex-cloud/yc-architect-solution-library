#----------------------------------------------------------------
# Generated CMake target import file for configuration "Debug".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "parson::parson" for configuration "Debug"
set_property(TARGET parson::parson APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
set_target_properties(parson::parson PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_DEBUG "C"
  IMPORTED_LOCATION_DEBUG "${_IMPORT_PREFIX}/lib/libparson.a"
  )

list(APPEND _IMPORT_CHECK_TARGETS parson::parson )
list(APPEND _IMPORT_CHECK_FILES_FOR_parson::parson "${_IMPORT_PREFIX}/lib/libparson.a" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
