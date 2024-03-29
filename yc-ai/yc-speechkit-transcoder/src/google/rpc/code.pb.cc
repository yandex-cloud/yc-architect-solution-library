// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: google/rpc/code.proto

#include "google/rpc/code.pb.h"

#include <algorithm>

#include <google/protobuf/io/coded_stream.h>
#include <google/protobuf/extension_set.h>
#include <google/protobuf/wire_format_lite.h>
#include <google/protobuf/descriptor.h>
#include <google/protobuf/generated_message_reflection.h>
#include <google/protobuf/reflection_ops.h>
#include <google/protobuf/wire_format.h>
// @@protoc_insertion_point(includes)
#include <google/protobuf/port_def.inc>

PROTOBUF_PRAGMA_INIT_SEG
namespace google {
namespace rpc {
}  // namespace rpc
}  // namespace google
static constexpr ::PROTOBUF_NAMESPACE_ID::Metadata* file_level_metadata_google_2frpc_2fcode_2eproto = nullptr;
static const ::PROTOBUF_NAMESPACE_ID::EnumDescriptor* file_level_enum_descriptors_google_2frpc_2fcode_2eproto[1];
static constexpr ::PROTOBUF_NAMESPACE_ID::ServiceDescriptor const** file_level_service_descriptors_google_2frpc_2fcode_2eproto = nullptr;
const ::PROTOBUF_NAMESPACE_ID::uint32 TableStruct_google_2frpc_2fcode_2eproto::offsets[1] = {};
static constexpr ::PROTOBUF_NAMESPACE_ID::internal::MigrationSchema* schemas = nullptr;
static constexpr ::PROTOBUF_NAMESPACE_ID::Message* const* file_default_instances = nullptr;

const char descriptor_table_protodef_google_2frpc_2fcode_2eproto[] PROTOBUF_SECTION_VARIABLE(protodesc_cold) =
  "\n\025google/rpc/code.proto\022\ngoogle.rpc*\267\002\n\004"
  "Code\022\006\n\002OK\020\000\022\r\n\tCANCELLED\020\001\022\013\n\007UNKNOWN\020\002"
  "\022\024\n\020INVALID_ARGUMENT\020\003\022\025\n\021DEADLINE_EXCEE"
  "DED\020\004\022\r\n\tNOT_FOUND\020\005\022\022\n\016ALREADY_EXISTS\020\006"
  "\022\025\n\021PERMISSION_DENIED\020\007\022\023\n\017UNAUTHENTICAT"
  "ED\020\020\022\026\n\022RESOURCE_EXHAUSTED\020\010\022\027\n\023FAILED_P"
  "RECONDITION\020\t\022\013\n\007ABORTED\020\n\022\020\n\014OUT_OF_RAN"
  "GE\020\013\022\021\n\rUNIMPLEMENTED\020\014\022\014\n\010INTERNAL\020\r\022\017\n"
  "\013UNAVAILABLE\020\016\022\r\n\tDATA_LOSS\020\017BX\n\016com.goo"
  "gle.rpcB\tCodeProtoP\001Z3google.golang.org/"
  "genproto/googleapis/rpc/code;code\242\002\003RPCb"
  "\006proto3"
  ;
static ::PROTOBUF_NAMESPACE_ID::internal::once_flag descriptor_table_google_2frpc_2fcode_2eproto_once;
const ::PROTOBUF_NAMESPACE_ID::internal::DescriptorTable descriptor_table_google_2frpc_2fcode_2eproto = {
  false, false, 447, descriptor_table_protodef_google_2frpc_2fcode_2eproto, "google/rpc/code.proto", 
  &descriptor_table_google_2frpc_2fcode_2eproto_once, nullptr, 0, 0,
  schemas, file_default_instances, TableStruct_google_2frpc_2fcode_2eproto::offsets,
  file_level_metadata_google_2frpc_2fcode_2eproto, file_level_enum_descriptors_google_2frpc_2fcode_2eproto, file_level_service_descriptors_google_2frpc_2fcode_2eproto,
};
PROTOBUF_ATTRIBUTE_WEAK ::PROTOBUF_NAMESPACE_ID::Metadata
descriptor_table_google_2frpc_2fcode_2eproto_metadata_getter(int index) {
  ::PROTOBUF_NAMESPACE_ID::internal::AssignDescriptors(&descriptor_table_google_2frpc_2fcode_2eproto);
  return descriptor_table_google_2frpc_2fcode_2eproto.file_level_metadata[index];
}

// Force running AddDescriptors() at dynamic initialization time.
PROTOBUF_ATTRIBUTE_INIT_PRIORITY static ::PROTOBUF_NAMESPACE_ID::internal::AddDescriptorsRunner dynamic_init_dummy_google_2frpc_2fcode_2eproto(&descriptor_table_google_2frpc_2fcode_2eproto);
namespace google {
namespace rpc {
const ::PROTOBUF_NAMESPACE_ID::EnumDescriptor* Code_descriptor() {
  ::PROTOBUF_NAMESPACE_ID::internal::AssignDescriptors(&descriptor_table_google_2frpc_2fcode_2eproto);
  return file_level_enum_descriptors_google_2frpc_2fcode_2eproto[0];
}
bool Code_IsValid(int value) {
  switch (value) {
    case 0:
    case 1:
    case 2:
    case 3:
    case 4:
    case 5:
    case 6:
    case 7:
    case 8:
    case 9:
    case 10:
    case 11:
    case 12:
    case 13:
    case 14:
    case 15:
    case 16:
      return true;
    default:
      return false;
  }
}


// @@protoc_insertion_point(namespace_scope)
}  // namespace rpc
}  // namespace google
PROTOBUF_NAMESPACE_OPEN
PROTOBUF_NAMESPACE_CLOSE

// @@protoc_insertion_point(global_scope)
#include <google/protobuf/port_undef.inc>
