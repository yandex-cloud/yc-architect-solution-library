# CMakeList.txt : CMake project for sk-transcoder, include source and define
# project specific logic here.
#
cmake_minimum_required (VERSION 3.8)

project ("yc-speechkit-transcoder")

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

# gRPC C++ plugin
get_target_property(gRPC_CPP_PLUGIN_EXECUTABLE gRPC::grpc_cpp_plugin LOCATION)

#######################################################################################################################
# Generate protobuf files
######################################################################################################################
file(GLOB protobuf_files 
			${CMAKE_SOURCE_DIR}/yandex-cloud-api/yandex/cloud/ai/stt/v2/*.proto
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

#######################################################################################################################
# Generate grpc services
######################################################################################################################
file(GLOB grpc_files
		${CMAKE_SOURCE_DIR}/yandex-cloud-api/yandex/cloud/ai/stt/v2/stt_service.proto
		${CMAKE_SOURCE_DIR}/yandex-cloud-api/yandex/cloud/operation/operation_service.proto
)

FOREACH(grpc ${grpc_files})

	FILE(TO_NATIVE_PATH ${grpc} grpc_native)
	message("Generate grpc  file for service -> ${grpc_native}")
	GET_FILENAME_COMPONENT(grpc_file_name ${grpc_native} NAME_WE)

	string(REGEX REPLACE "(.+)\\${grpc_file_name}.*" "\\1" grpc_file_path ${grpc})
	string(REGEX MATCH "(/yandex/cloud/.*)" grpc_file_out_path ${grpc_file_path})
	MESSAGE("grpc_file_name -> ${grpc_native} grpc_file_out_path -> ${grpc_file_out_path}")

	EXECUTE_PROCESS(
			COMMAND ${PROTOBUF_PROTOC_EXECUTABLE} -I "${CMAKE_SOURCE_DIR}/yandex-cloud-api/third_party/googleapis/" -I "${CMAKE_SOURCE_DIR}/yandex-cloud-api/" --grpc_out=${CMAKE_CURRENT_SOURCE_DIR} --plugin=protoc-gen-grpc=${gRPC_CPP_PLUGIN_EXECUTABLE} "${grpc_native}"
			RESULT_VARIABLE rv)

	set(GRPC_SRCS "${CMAKE_CURRENT_SOURCE_DIR}${grpc_file_out_path}${grpc_file_name}.grpc.pb.cc")
	set(GRPC_HDRS "${CMAKE_CURRENT_SOURCE_DIR}${grpc_file_out_path}${grpc_file_name}.grpc.pb.h")
	list(APPEND grpc_cc_src ${GRPC_SRCS})
	list(APPEND grpc_h_src ${GRPC_HDRS}) 

	MESSAGE("grpc_cc_src-> ${grpc_cc_src} \nGRPC_SRCS -> ${GRPC_SRCS} \nGRPC_HDRS -> ${GRPC_HDRS} \nSRC_DIR->${CMAKE_CURRENT_SOURCE_DIR}")

	IF(${rv})
		MESSAGE("Generation of grpc service model returned ${rv} for proto ${grpc_svc_native}")
	ENDIF()


ENDFOREACH()
# add_subdirectory("transcoder")

# Add source to this project's executable.
add_executable (asr-client "client.cpp"  ${grpc_cc_src} ${grpc_h_src} ${protobuf_cc_src} ${protobuf_h_src})

target_link_libraries(asr-client PUBLIC  gRPC::grpc++ gRPC::grpc  protobuf::libprotobuf)