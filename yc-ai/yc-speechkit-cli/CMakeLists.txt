# CMakeList.txt : CMake project for yc-speechkit-cli, include source and define
# project specific logic here.
#
cmake_minimum_required (VERSION 3.8)

project ("yc-speechkit-cli")


set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/)

include_directories(${CMAKE_CURRENT_SOURCE_DIR})


find_package(PkgConfig REQUIRED)
########################################################################
#   Protobuf
########################################################################
find_package(Protobuf REQUIRED)
# gRPC
find_package(gRPC CONFIG REQUIRED)
message(STATUS "Using gRPC ${gRPC_VERSION}")

include_directories(${Protobuf_INCLUDE_DIRS})
# include_directories(${CMAKE_CURRENT_SOURCE_DIR})
# include_directories(${CMAKE_CURRENT_SOURCE_DIR}/audio-prep-svc)
#######################################################################################################################
# Generate protobuf files
######################################################################################################################
file(GLOB protobuf_files 
			${CMAKE_SOURCE_DIR}/yandex-cloud-api/yandex/cloud/ai/stt/v3/*.proto
			${CMAKE_SOURCE_DIR}/yandex-cloud-api/yandex/cloud/operation/*.proto
			${CMAKE_SOURCE_DIR}/yandex-cloud-api/yandex/cloud/api/*.proto
			${CMAKE_SOURCE_DIR}/yandex-cloud-api/yandex/cloud/*.proto
			${CMAKE_SOURCE_DIR}/yandex-cloud-api/third_party/googleapis/google/api/*.proto
			${CMAKE_SOURCE_DIR}/yandex-cloud-api/third_party/googleapis/google/rpc/*.proto
			${CMAKE_SOURCE_DIR}/yandex-cloud-api/third_party/googleapis/google/type/*.proto
			)


# compile each file in turn, and then generate the pb.cc And. pb.h move back to the original directory
FOREACH(proto ${protobuf_files})
		
		FILE(TO_NATIVE_PATH ${proto} proto_native)

		GET_FILENAME_COMPONENT(proto_file_name ${proto_native} NAME_WE)

		string(REGEX REPLACE "(.+)\\${proto_file_name}.*" "\\1" proto_file_path ${proto})
		string(REGEX MATCH "(/google/.*|/yandex/cloud/.*)" proto_file_out_path ${proto_file_path})
		MESSAGE("proto_file_name -> ${proto_file_name} proto_file_out_path -> ${proto_file_out_path}")

		EXECUTE_PROCESS(
				COMMAND ${PROTOBUF_PROTOC_EXECUTABLE} -I "${CMAKE_SOURCE_DIR}/yandex-cloud-api/third_party/googleapis/" -I "${CMAKE_SOURCE_DIR}/yandex-cloud-api/" --cpp_out=${CMAKE_CURRENT_SOURCE_DIR} "${proto_native}"
				RESULT_VARIABLE rv)

				#string(CONCAT PROTO_SRCS ${PROTO_SRCS} " " ${CMAKE_SOURCE_DIR} ${proto_file_out_path} ${proto_file_name} ".pb.cc")
				set(PROTO_SRCS "${CMAKE_CURRENT_SOURCE_DIR}${proto_file_out_path}${proto_file_name}.pb.cc")
				set(PROTO_HDRS "${CMAKE_CURRENT_SOURCE_DIR}${proto_file_out_path}${proto_file_name}.pb.h")
				list(APPEND protobuf_cc_src ${PROTO_SRCS})
				list(APPEND protobuf_h_src ${PROTO_HDRS})

				MESSAGE("protobuf_cc_src-> ${protobuf_cc_src} \nPROTO_SRCS -> ${PROTO_SRCS} \nPROTO_HDRS -> ${PROTO_HDRS} \nSRC_DIR->${CMAKE_CURRENT_SOURCE_DIR}")
				
		 IF(${rv})
			MESSAGE("Generation of data model returned ${rv} for proto ${proto_native}")
		 ENDIF()
		 # 
ENDFOREACH()

# Add source to this project's executable.
add_executable (yc-speechkit-cli "yc-speechkit-cli.cpp" "yc-speechkit-cli.h")

# TODO: Add tests and install targets if needed.
