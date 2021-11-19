// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: yandex/cloud/operation/operation.proto

#ifndef GOOGLE_PROTOBUF_INCLUDED_yandex_2fcloud_2foperation_2foperation_2eproto
#define GOOGLE_PROTOBUF_INCLUDED_yandex_2fcloud_2foperation_2foperation_2eproto

#include <limits>
#include <string>

#include <google/protobuf/port_def.inc>
#if PROTOBUF_VERSION < 3015000
#error This file was generated by a newer version of protoc which is
#error incompatible with your Protocol Buffer headers. Please update
#error your headers.
#endif
#if 3015008 < PROTOBUF_MIN_PROTOC_VERSION
#error This file was generated by an older version of protoc which is
#error incompatible with your Protocol Buffer headers. Please
#error regenerate this file with a newer version of protoc.
#endif

#include <google/protobuf/port_undef.inc>
#include <google/protobuf/io/coded_stream.h>
#include <google/protobuf/arena.h>
#include <google/protobuf/arenastring.h>
#include <google/protobuf/generated_message_table_driven.h>
#include <google/protobuf/generated_message_util.h>
#include <google/protobuf/metadata_lite.h>
#include <google/protobuf/generated_message_reflection.h>
#include <google/protobuf/message.h>
#include <google/protobuf/repeated_field.h>  // IWYU pragma: export
#include <google/protobuf/extension_set.h>  // IWYU pragma: export
#include <google/protobuf/unknown_field_set.h>
#include <google/protobuf/any.pb.h>
#include "google/rpc/status.pb.h"
#include <google/protobuf/timestamp.pb.h>
// @@protoc_insertion_point(includes)
#include <google/protobuf/port_def.inc>
#define PROTOBUF_INTERNAL_EXPORT_yandex_2fcloud_2foperation_2foperation_2eproto
PROTOBUF_NAMESPACE_OPEN
namespace internal {
class AnyMetadata;
}  // namespace internal
PROTOBUF_NAMESPACE_CLOSE

// Internal implementation detail -- do not use these members.
struct TableStruct_yandex_2fcloud_2foperation_2foperation_2eproto {
  static const ::PROTOBUF_NAMESPACE_ID::internal::ParseTableField entries[]
    PROTOBUF_SECTION_VARIABLE(protodesc_cold);
  static const ::PROTOBUF_NAMESPACE_ID::internal::AuxiliaryParseTableField aux[]
    PROTOBUF_SECTION_VARIABLE(protodesc_cold);
  static const ::PROTOBUF_NAMESPACE_ID::internal::ParseTable schema[1]
    PROTOBUF_SECTION_VARIABLE(protodesc_cold);
  static const ::PROTOBUF_NAMESPACE_ID::internal::FieldMetadata field_metadata[];
  static const ::PROTOBUF_NAMESPACE_ID::internal::SerializationTable serialization_table[];
  static const ::PROTOBUF_NAMESPACE_ID::uint32 offsets[];
};
extern const ::PROTOBUF_NAMESPACE_ID::internal::DescriptorTable descriptor_table_yandex_2fcloud_2foperation_2foperation_2eproto;
::PROTOBUF_NAMESPACE_ID::Metadata descriptor_table_yandex_2fcloud_2foperation_2foperation_2eproto_metadata_getter(int index);
namespace yandex {
namespace cloud {
namespace operation {
class Operation;
struct OperationDefaultTypeInternal;
extern OperationDefaultTypeInternal _Operation_default_instance_;
}  // namespace operation
}  // namespace cloud
}  // namespace yandex
PROTOBUF_NAMESPACE_OPEN
template<> ::yandex::cloud::operation::Operation* Arena::CreateMaybeMessage<::yandex::cloud::operation::Operation>(Arena*);
PROTOBUF_NAMESPACE_CLOSE
namespace yandex {
namespace cloud {
namespace operation {

// ===================================================================

class Operation PROTOBUF_FINAL :
    public ::PROTOBUF_NAMESPACE_ID::Message /* @@protoc_insertion_point(class_definition:yandex.cloud.operation.Operation) */ {
 public:
  inline Operation() : Operation(nullptr) {}
  virtual ~Operation();
  explicit constexpr Operation(::PROTOBUF_NAMESPACE_ID::internal::ConstantInitialized);

  Operation(const Operation& from);
  Operation(Operation&& from) noexcept
    : Operation() {
    *this = ::std::move(from);
  }

  inline Operation& operator=(const Operation& from) {
    CopyFrom(from);
    return *this;
  }
  inline Operation& operator=(Operation&& from) noexcept {
    if (GetArena() == from.GetArena()) {
      if (this != &from) InternalSwap(&from);
    } else {
      CopyFrom(from);
    }
    return *this;
  }

  static const ::PROTOBUF_NAMESPACE_ID::Descriptor* descriptor() {
    return GetDescriptor();
  }
  static const ::PROTOBUF_NAMESPACE_ID::Descriptor* GetDescriptor() {
    return GetMetadataStatic().descriptor;
  }
  static const ::PROTOBUF_NAMESPACE_ID::Reflection* GetReflection() {
    return GetMetadataStatic().reflection;
  }
  static const Operation& default_instance() {
    return *internal_default_instance();
  }
  enum ResultCase {
    kError = 8,
    kResponse = 9,
    RESULT_NOT_SET = 0,
  };

  static inline const Operation* internal_default_instance() {
    return reinterpret_cast<const Operation*>(
               &_Operation_default_instance_);
  }
  static constexpr int kIndexInFileMessages =
    0;

  friend void swap(Operation& a, Operation& b) {
    a.Swap(&b);
  }
  inline void Swap(Operation* other) {
    if (other == this) return;
    if (GetArena() == other->GetArena()) {
      InternalSwap(other);
    } else {
      ::PROTOBUF_NAMESPACE_ID::internal::GenericSwap(this, other);
    }
  }
  void UnsafeArenaSwap(Operation* other) {
    if (other == this) return;
    GOOGLE_DCHECK(GetArena() == other->GetArena());
    InternalSwap(other);
  }

  // implements Message ----------------------------------------------

  inline Operation* New() const final {
    return CreateMaybeMessage<Operation>(nullptr);
  }

  Operation* New(::PROTOBUF_NAMESPACE_ID::Arena* arena) const final {
    return CreateMaybeMessage<Operation>(arena);
  }
  void CopyFrom(const ::PROTOBUF_NAMESPACE_ID::Message& from) final;
  void MergeFrom(const ::PROTOBUF_NAMESPACE_ID::Message& from) final;
  void CopyFrom(const Operation& from);
  void MergeFrom(const Operation& from);
  PROTOBUF_ATTRIBUTE_REINITIALIZES void Clear() final;
  bool IsInitialized() const final;

  size_t ByteSizeLong() const final;
  const char* _InternalParse(const char* ptr, ::PROTOBUF_NAMESPACE_ID::internal::ParseContext* ctx) final;
  ::PROTOBUF_NAMESPACE_ID::uint8* _InternalSerialize(
      ::PROTOBUF_NAMESPACE_ID::uint8* target, ::PROTOBUF_NAMESPACE_ID::io::EpsCopyOutputStream* stream) const final;
  int GetCachedSize() const final { return _cached_size_.Get(); }

  private:
  inline void SharedCtor();
  inline void SharedDtor();
  void SetCachedSize(int size) const final;
  void InternalSwap(Operation* other);
  friend class ::PROTOBUF_NAMESPACE_ID::internal::AnyMetadata;
  static ::PROTOBUF_NAMESPACE_ID::StringPiece FullMessageName() {
    return "yandex.cloud.operation.Operation";
  }
  protected:
  explicit Operation(::PROTOBUF_NAMESPACE_ID::Arena* arena);
  private:
  static void ArenaDtor(void* object);
  inline void RegisterArenaDtor(::PROTOBUF_NAMESPACE_ID::Arena* arena);
  public:

  ::PROTOBUF_NAMESPACE_ID::Metadata GetMetadata() const final;
  private:
  static ::PROTOBUF_NAMESPACE_ID::Metadata GetMetadataStatic() {
    return ::descriptor_table_yandex_2fcloud_2foperation_2foperation_2eproto_metadata_getter(kIndexInFileMessages);
  }

  public:

  // nested types ----------------------------------------------------

  // accessors -------------------------------------------------------

  enum : int {
    kIdFieldNumber = 1,
    kDescriptionFieldNumber = 2,
    kCreatedByFieldNumber = 4,
    kCreatedAtFieldNumber = 3,
    kModifiedAtFieldNumber = 5,
    kMetadataFieldNumber = 7,
    kDoneFieldNumber = 6,
    kErrorFieldNumber = 8,
    kResponseFieldNumber = 9,
  };
  // string id = 1;
  void clear_id();
  const std::string& id() const;
  void set_id(const std::string& value);
  void set_id(std::string&& value);
  void set_id(const char* value);
  void set_id(const char* value, size_t size);
  std::string* mutable_id();
  std::string* release_id();
  void set_allocated_id(std::string* id);
  private:
  const std::string& _internal_id() const;
  void _internal_set_id(const std::string& value);
  std::string* _internal_mutable_id();
  public:

  // string description = 2;
  void clear_description();
  const std::string& description() const;
  void set_description(const std::string& value);
  void set_description(std::string&& value);
  void set_description(const char* value);
  void set_description(const char* value, size_t size);
  std::string* mutable_description();
  std::string* release_description();
  void set_allocated_description(std::string* description);
  private:
  const std::string& _internal_description() const;
  void _internal_set_description(const std::string& value);
  std::string* _internal_mutable_description();
  public:

  // string created_by = 4;
  void clear_created_by();
  const std::string& created_by() const;
  void set_created_by(const std::string& value);
  void set_created_by(std::string&& value);
  void set_created_by(const char* value);
  void set_created_by(const char* value, size_t size);
  std::string* mutable_created_by();
  std::string* release_created_by();
  void set_allocated_created_by(std::string* created_by);
  private:
  const std::string& _internal_created_by() const;
  void _internal_set_created_by(const std::string& value);
  std::string* _internal_mutable_created_by();
  public:

  // .google.protobuf.Timestamp created_at = 3;
  bool has_created_at() const;
  private:
  bool _internal_has_created_at() const;
  public:
  void clear_created_at();
  const PROTOBUF_NAMESPACE_ID::Timestamp& created_at() const;
  PROTOBUF_NAMESPACE_ID::Timestamp* release_created_at();
  PROTOBUF_NAMESPACE_ID::Timestamp* mutable_created_at();
  void set_allocated_created_at(PROTOBUF_NAMESPACE_ID::Timestamp* created_at);
  private:
  const PROTOBUF_NAMESPACE_ID::Timestamp& _internal_created_at() const;
  PROTOBUF_NAMESPACE_ID::Timestamp* _internal_mutable_created_at();
  public:
  void unsafe_arena_set_allocated_created_at(
      PROTOBUF_NAMESPACE_ID::Timestamp* created_at);
  PROTOBUF_NAMESPACE_ID::Timestamp* unsafe_arena_release_created_at();

  // .google.protobuf.Timestamp modified_at = 5;
  bool has_modified_at() const;
  private:
  bool _internal_has_modified_at() const;
  public:
  void clear_modified_at();
  const PROTOBUF_NAMESPACE_ID::Timestamp& modified_at() const;
  PROTOBUF_NAMESPACE_ID::Timestamp* release_modified_at();
  PROTOBUF_NAMESPACE_ID::Timestamp* mutable_modified_at();
  void set_allocated_modified_at(PROTOBUF_NAMESPACE_ID::Timestamp* modified_at);
  private:
  const PROTOBUF_NAMESPACE_ID::Timestamp& _internal_modified_at() const;
  PROTOBUF_NAMESPACE_ID::Timestamp* _internal_mutable_modified_at();
  public:
  void unsafe_arena_set_allocated_modified_at(
      PROTOBUF_NAMESPACE_ID::Timestamp* modified_at);
  PROTOBUF_NAMESPACE_ID::Timestamp* unsafe_arena_release_modified_at();

  // .google.protobuf.Any metadata = 7;
  bool has_metadata() const;
  private:
  bool _internal_has_metadata() const;
  public:
  void clear_metadata();
  const PROTOBUF_NAMESPACE_ID::Any& metadata() const;
  PROTOBUF_NAMESPACE_ID::Any* release_metadata();
  PROTOBUF_NAMESPACE_ID::Any* mutable_metadata();
  void set_allocated_metadata(PROTOBUF_NAMESPACE_ID::Any* metadata);
  private:
  const PROTOBUF_NAMESPACE_ID::Any& _internal_metadata() const;
  PROTOBUF_NAMESPACE_ID::Any* _internal_mutable_metadata();
  public:
  void unsafe_arena_set_allocated_metadata(
      PROTOBUF_NAMESPACE_ID::Any* metadata);
  PROTOBUF_NAMESPACE_ID::Any* unsafe_arena_release_metadata();

  // bool done = 6;
  void clear_done();
  bool done() const;
  void set_done(bool value);
  private:
  bool _internal_done() const;
  void _internal_set_done(bool value);
  public:

  // .google.rpc.Status error = 8;
  bool has_error() const;
  private:
  bool _internal_has_error() const;
  public:
  void clear_error();
  const ::google::rpc::Status& error() const;
  ::google::rpc::Status* release_error();
  ::google::rpc::Status* mutable_error();
  void set_allocated_error(::google::rpc::Status* error);
  private:
  const ::google::rpc::Status& _internal_error() const;
  ::google::rpc::Status* _internal_mutable_error();
  public:
  void unsafe_arena_set_allocated_error(
      ::google::rpc::Status* error);
  ::google::rpc::Status* unsafe_arena_release_error();

  // .google.protobuf.Any response = 9;
  bool has_response() const;
  private:
  bool _internal_has_response() const;
  public:
  void clear_response();
  const PROTOBUF_NAMESPACE_ID::Any& response() const;
  PROTOBUF_NAMESPACE_ID::Any* release_response();
  PROTOBUF_NAMESPACE_ID::Any* mutable_response();
  void set_allocated_response(PROTOBUF_NAMESPACE_ID::Any* response);
  private:
  const PROTOBUF_NAMESPACE_ID::Any& _internal_response() const;
  PROTOBUF_NAMESPACE_ID::Any* _internal_mutable_response();
  public:
  void unsafe_arena_set_allocated_response(
      PROTOBUF_NAMESPACE_ID::Any* response);
  PROTOBUF_NAMESPACE_ID::Any* unsafe_arena_release_response();

  void clear_result();
  ResultCase result_case() const;
  // @@protoc_insertion_point(class_scope:yandex.cloud.operation.Operation)
 private:
  class _Internal;
  void set_has_error();
  void set_has_response();

  inline bool has_result() const;
  inline void clear_has_result();

  template <typename T> friend class ::PROTOBUF_NAMESPACE_ID::Arena::InternalHelper;
  typedef void InternalArenaConstructable_;
  typedef void DestructorSkippable_;
  ::PROTOBUF_NAMESPACE_ID::internal::ArenaStringPtr id_;
  ::PROTOBUF_NAMESPACE_ID::internal::ArenaStringPtr description_;
  ::PROTOBUF_NAMESPACE_ID::internal::ArenaStringPtr created_by_;
  PROTOBUF_NAMESPACE_ID::Timestamp* created_at_;
  PROTOBUF_NAMESPACE_ID::Timestamp* modified_at_;
  PROTOBUF_NAMESPACE_ID::Any* metadata_;
  bool done_;
  union ResultUnion {
    constexpr ResultUnion() : _constinit_{} {}
      ::PROTOBUF_NAMESPACE_ID::internal::ConstantInitialized _constinit_;
    ::google::rpc::Status* error_;
    PROTOBUF_NAMESPACE_ID::Any* response_;
  } result_;
  mutable ::PROTOBUF_NAMESPACE_ID::internal::CachedSize _cached_size_;
  ::PROTOBUF_NAMESPACE_ID::uint32 _oneof_case_[1];

  friend struct ::TableStruct_yandex_2fcloud_2foperation_2foperation_2eproto;
};
// ===================================================================


// ===================================================================

#ifdef __GNUC__
  #pragma GCC diagnostic push
  #pragma GCC diagnostic ignored "-Wstrict-aliasing"
#endif  // __GNUC__
// Operation

// string id = 1;
inline void Operation::clear_id() {
  id_.ClearToEmpty();
}
inline const std::string& Operation::id() const {
  // @@protoc_insertion_point(field_get:yandex.cloud.operation.Operation.id)
  return _internal_id();
}
inline void Operation::set_id(const std::string& value) {
  _internal_set_id(value);
  // @@protoc_insertion_point(field_set:yandex.cloud.operation.Operation.id)
}
inline std::string* Operation::mutable_id() {
  // @@protoc_insertion_point(field_mutable:yandex.cloud.operation.Operation.id)
  return _internal_mutable_id();
}
inline const std::string& Operation::_internal_id() const {
  return id_.Get();
}
inline void Operation::_internal_set_id(const std::string& value) {
  
  id_.Set(::PROTOBUF_NAMESPACE_ID::internal::ArenaStringPtr::EmptyDefault{}, value, GetArena());
}
inline void Operation::set_id(std::string&& value) {
  
  id_.Set(
    ::PROTOBUF_NAMESPACE_ID::internal::ArenaStringPtr::EmptyDefault{}, ::std::move(value), GetArena());
  // @@protoc_insertion_point(field_set_rvalue:yandex.cloud.operation.Operation.id)
}
inline void Operation::set_id(const char* value) {
  GOOGLE_DCHECK(value != nullptr);
  
  id_.Set(::PROTOBUF_NAMESPACE_ID::internal::ArenaStringPtr::EmptyDefault{}, ::std::string(value), GetArena());
  // @@protoc_insertion_point(field_set_char:yandex.cloud.operation.Operation.id)
}
inline void Operation::set_id(const char* value,
    size_t size) {
  
  id_.Set(::PROTOBUF_NAMESPACE_ID::internal::ArenaStringPtr::EmptyDefault{}, ::std::string(
      reinterpret_cast<const char*>(value), size), GetArena());
  // @@protoc_insertion_point(field_set_pointer:yandex.cloud.operation.Operation.id)
}
inline std::string* Operation::_internal_mutable_id() {
  
  return id_.Mutable(::PROTOBUF_NAMESPACE_ID::internal::ArenaStringPtr::EmptyDefault{}, GetArena());
}
inline std::string* Operation::release_id() {
  // @@protoc_insertion_point(field_release:yandex.cloud.operation.Operation.id)
  return id_.Release(&::PROTOBUF_NAMESPACE_ID::internal::GetEmptyStringAlreadyInited(), GetArena());
}
inline void Operation::set_allocated_id(std::string* id) {
  if (id != nullptr) {
    
  } else {
    
  }
  id_.SetAllocated(&::PROTOBUF_NAMESPACE_ID::internal::GetEmptyStringAlreadyInited(), id,
      GetArena());
  // @@protoc_insertion_point(field_set_allocated:yandex.cloud.operation.Operation.id)
}

// string description = 2;
inline void Operation::clear_description() {
  description_.ClearToEmpty();
}
inline const std::string& Operation::description() const {
  // @@protoc_insertion_point(field_get:yandex.cloud.operation.Operation.description)
  return _internal_description();
}
inline void Operation::set_description(const std::string& value) {
  _internal_set_description(value);
  // @@protoc_insertion_point(field_set:yandex.cloud.operation.Operation.description)
}
inline std::string* Operation::mutable_description() {
  // @@protoc_insertion_point(field_mutable:yandex.cloud.operation.Operation.description)
  return _internal_mutable_description();
}
inline const std::string& Operation::_internal_description() const {
  return description_.Get();
}
inline void Operation::_internal_set_description(const std::string& value) {
  
  description_.Set(::PROTOBUF_NAMESPACE_ID::internal::ArenaStringPtr::EmptyDefault{}, value, GetArena());
}
inline void Operation::set_description(std::string&& value) {
  
  description_.Set(
    ::PROTOBUF_NAMESPACE_ID::internal::ArenaStringPtr::EmptyDefault{}, ::std::move(value), GetArena());
  // @@protoc_insertion_point(field_set_rvalue:yandex.cloud.operation.Operation.description)
}
inline void Operation::set_description(const char* value) {
  GOOGLE_DCHECK(value != nullptr);
  
  description_.Set(::PROTOBUF_NAMESPACE_ID::internal::ArenaStringPtr::EmptyDefault{}, ::std::string(value), GetArena());
  // @@protoc_insertion_point(field_set_char:yandex.cloud.operation.Operation.description)
}
inline void Operation::set_description(const char* value,
    size_t size) {
  
  description_.Set(::PROTOBUF_NAMESPACE_ID::internal::ArenaStringPtr::EmptyDefault{}, ::std::string(
      reinterpret_cast<const char*>(value), size), GetArena());
  // @@protoc_insertion_point(field_set_pointer:yandex.cloud.operation.Operation.description)
}
inline std::string* Operation::_internal_mutable_description() {
  
  return description_.Mutable(::PROTOBUF_NAMESPACE_ID::internal::ArenaStringPtr::EmptyDefault{}, GetArena());
}
inline std::string* Operation::release_description() {
  // @@protoc_insertion_point(field_release:yandex.cloud.operation.Operation.description)
  return description_.Release(&::PROTOBUF_NAMESPACE_ID::internal::GetEmptyStringAlreadyInited(), GetArena());
}
inline void Operation::set_allocated_description(std::string* description) {
  if (description != nullptr) {
    
  } else {
    
  }
  description_.SetAllocated(&::PROTOBUF_NAMESPACE_ID::internal::GetEmptyStringAlreadyInited(), description,
      GetArena());
  // @@protoc_insertion_point(field_set_allocated:yandex.cloud.operation.Operation.description)
}

// .google.protobuf.Timestamp created_at = 3;
inline bool Operation::_internal_has_created_at() const {
  return this != internal_default_instance() && created_at_ != nullptr;
}
inline bool Operation::has_created_at() const {
  return _internal_has_created_at();
}
inline const PROTOBUF_NAMESPACE_ID::Timestamp& Operation::_internal_created_at() const {
  const PROTOBUF_NAMESPACE_ID::Timestamp* p = created_at_;
  return p != nullptr ? *p : reinterpret_cast<const PROTOBUF_NAMESPACE_ID::Timestamp&>(
      PROTOBUF_NAMESPACE_ID::_Timestamp_default_instance_);
}
inline const PROTOBUF_NAMESPACE_ID::Timestamp& Operation::created_at() const {
  // @@protoc_insertion_point(field_get:yandex.cloud.operation.Operation.created_at)
  return _internal_created_at();
}
inline void Operation::unsafe_arena_set_allocated_created_at(
    PROTOBUF_NAMESPACE_ID::Timestamp* created_at) {
  if (GetArena() == nullptr) {
    delete reinterpret_cast<::PROTOBUF_NAMESPACE_ID::MessageLite*>(created_at_);
  }
  created_at_ = created_at;
  if (created_at) {
    
  } else {
    
  }
  // @@protoc_insertion_point(field_unsafe_arena_set_allocated:yandex.cloud.operation.Operation.created_at)
}
inline PROTOBUF_NAMESPACE_ID::Timestamp* Operation::release_created_at() {
  
  PROTOBUF_NAMESPACE_ID::Timestamp* temp = created_at_;
  created_at_ = nullptr;
  if (GetArena() != nullptr) {
    temp = ::PROTOBUF_NAMESPACE_ID::internal::DuplicateIfNonNull(temp);
  }
  return temp;
}
inline PROTOBUF_NAMESPACE_ID::Timestamp* Operation::unsafe_arena_release_created_at() {
  // @@protoc_insertion_point(field_release:yandex.cloud.operation.Operation.created_at)
  
  PROTOBUF_NAMESPACE_ID::Timestamp* temp = created_at_;
  created_at_ = nullptr;
  return temp;
}
inline PROTOBUF_NAMESPACE_ID::Timestamp* Operation::_internal_mutable_created_at() {
  
  if (created_at_ == nullptr) {
    auto* p = CreateMaybeMessage<PROTOBUF_NAMESPACE_ID::Timestamp>(GetArena());
    created_at_ = p;
  }
  return created_at_;
}
inline PROTOBUF_NAMESPACE_ID::Timestamp* Operation::mutable_created_at() {
  // @@protoc_insertion_point(field_mutable:yandex.cloud.operation.Operation.created_at)
  return _internal_mutable_created_at();
}
inline void Operation::set_allocated_created_at(PROTOBUF_NAMESPACE_ID::Timestamp* created_at) {
  ::PROTOBUF_NAMESPACE_ID::Arena* message_arena = GetArena();
  if (message_arena == nullptr) {
    delete reinterpret_cast< ::PROTOBUF_NAMESPACE_ID::MessageLite*>(created_at_);
  }
  if (created_at) {
    ::PROTOBUF_NAMESPACE_ID::Arena* submessage_arena =
      reinterpret_cast<::PROTOBUF_NAMESPACE_ID::MessageLite*>(created_at)->GetArena();
    if (message_arena != submessage_arena) {
      created_at = ::PROTOBUF_NAMESPACE_ID::internal::GetOwnedMessage(
          message_arena, created_at, submessage_arena);
    }
    
  } else {
    
  }
  created_at_ = created_at;
  // @@protoc_insertion_point(field_set_allocated:yandex.cloud.operation.Operation.created_at)
}

// string created_by = 4;
inline void Operation::clear_created_by() {
  created_by_.ClearToEmpty();
}
inline const std::string& Operation::created_by() const {
  // @@protoc_insertion_point(field_get:yandex.cloud.operation.Operation.created_by)
  return _internal_created_by();
}
inline void Operation::set_created_by(const std::string& value) {
  _internal_set_created_by(value);
  // @@protoc_insertion_point(field_set:yandex.cloud.operation.Operation.created_by)
}
inline std::string* Operation::mutable_created_by() {
  // @@protoc_insertion_point(field_mutable:yandex.cloud.operation.Operation.created_by)
  return _internal_mutable_created_by();
}
inline const std::string& Operation::_internal_created_by() const {
  return created_by_.Get();
}
inline void Operation::_internal_set_created_by(const std::string& value) {
  
  created_by_.Set(::PROTOBUF_NAMESPACE_ID::internal::ArenaStringPtr::EmptyDefault{}, value, GetArena());
}
inline void Operation::set_created_by(std::string&& value) {
  
  created_by_.Set(
    ::PROTOBUF_NAMESPACE_ID::internal::ArenaStringPtr::EmptyDefault{}, ::std::move(value), GetArena());
  // @@protoc_insertion_point(field_set_rvalue:yandex.cloud.operation.Operation.created_by)
}
inline void Operation::set_created_by(const char* value) {
  GOOGLE_DCHECK(value != nullptr);
  
  created_by_.Set(::PROTOBUF_NAMESPACE_ID::internal::ArenaStringPtr::EmptyDefault{}, ::std::string(value), GetArena());
  // @@protoc_insertion_point(field_set_char:yandex.cloud.operation.Operation.created_by)
}
inline void Operation::set_created_by(const char* value,
    size_t size) {
  
  created_by_.Set(::PROTOBUF_NAMESPACE_ID::internal::ArenaStringPtr::EmptyDefault{}, ::std::string(
      reinterpret_cast<const char*>(value), size), GetArena());
  // @@protoc_insertion_point(field_set_pointer:yandex.cloud.operation.Operation.created_by)
}
inline std::string* Operation::_internal_mutable_created_by() {
  
  return created_by_.Mutable(::PROTOBUF_NAMESPACE_ID::internal::ArenaStringPtr::EmptyDefault{}, GetArena());
}
inline std::string* Operation::release_created_by() {
  // @@protoc_insertion_point(field_release:yandex.cloud.operation.Operation.created_by)
  return created_by_.Release(&::PROTOBUF_NAMESPACE_ID::internal::GetEmptyStringAlreadyInited(), GetArena());
}
inline void Operation::set_allocated_created_by(std::string* created_by) {
  if (created_by != nullptr) {
    
  } else {
    
  }
  created_by_.SetAllocated(&::PROTOBUF_NAMESPACE_ID::internal::GetEmptyStringAlreadyInited(), created_by,
      GetArena());
  // @@protoc_insertion_point(field_set_allocated:yandex.cloud.operation.Operation.created_by)
}

// .google.protobuf.Timestamp modified_at = 5;
inline bool Operation::_internal_has_modified_at() const {
  return this != internal_default_instance() && modified_at_ != nullptr;
}
inline bool Operation::has_modified_at() const {
  return _internal_has_modified_at();
}
inline const PROTOBUF_NAMESPACE_ID::Timestamp& Operation::_internal_modified_at() const {
  const PROTOBUF_NAMESPACE_ID::Timestamp* p = modified_at_;
  return p != nullptr ? *p : reinterpret_cast<const PROTOBUF_NAMESPACE_ID::Timestamp&>(
      PROTOBUF_NAMESPACE_ID::_Timestamp_default_instance_);
}
inline const PROTOBUF_NAMESPACE_ID::Timestamp& Operation::modified_at() const {
  // @@protoc_insertion_point(field_get:yandex.cloud.operation.Operation.modified_at)
  return _internal_modified_at();
}
inline void Operation::unsafe_arena_set_allocated_modified_at(
    PROTOBUF_NAMESPACE_ID::Timestamp* modified_at) {
  if (GetArena() == nullptr) {
    delete reinterpret_cast<::PROTOBUF_NAMESPACE_ID::MessageLite*>(modified_at_);
  }
  modified_at_ = modified_at;
  if (modified_at) {
    
  } else {
    
  }
  // @@protoc_insertion_point(field_unsafe_arena_set_allocated:yandex.cloud.operation.Operation.modified_at)
}
inline PROTOBUF_NAMESPACE_ID::Timestamp* Operation::release_modified_at() {
  
  PROTOBUF_NAMESPACE_ID::Timestamp* temp = modified_at_;
  modified_at_ = nullptr;
  if (GetArena() != nullptr) {
    temp = ::PROTOBUF_NAMESPACE_ID::internal::DuplicateIfNonNull(temp);
  }
  return temp;
}
inline PROTOBUF_NAMESPACE_ID::Timestamp* Operation::unsafe_arena_release_modified_at() {
  // @@protoc_insertion_point(field_release:yandex.cloud.operation.Operation.modified_at)
  
  PROTOBUF_NAMESPACE_ID::Timestamp* temp = modified_at_;
  modified_at_ = nullptr;
  return temp;
}
inline PROTOBUF_NAMESPACE_ID::Timestamp* Operation::_internal_mutable_modified_at() {
  
  if (modified_at_ == nullptr) {
    auto* p = CreateMaybeMessage<PROTOBUF_NAMESPACE_ID::Timestamp>(GetArena());
    modified_at_ = p;
  }
  return modified_at_;
}
inline PROTOBUF_NAMESPACE_ID::Timestamp* Operation::mutable_modified_at() {
  // @@protoc_insertion_point(field_mutable:yandex.cloud.operation.Operation.modified_at)
  return _internal_mutable_modified_at();
}
inline void Operation::set_allocated_modified_at(PROTOBUF_NAMESPACE_ID::Timestamp* modified_at) {
  ::PROTOBUF_NAMESPACE_ID::Arena* message_arena = GetArena();
  if (message_arena == nullptr) {
    delete reinterpret_cast< ::PROTOBUF_NAMESPACE_ID::MessageLite*>(modified_at_);
  }
  if (modified_at) {
    ::PROTOBUF_NAMESPACE_ID::Arena* submessage_arena =
      reinterpret_cast<::PROTOBUF_NAMESPACE_ID::MessageLite*>(modified_at)->GetArena();
    if (message_arena != submessage_arena) {
      modified_at = ::PROTOBUF_NAMESPACE_ID::internal::GetOwnedMessage(
          message_arena, modified_at, submessage_arena);
    }
    
  } else {
    
  }
  modified_at_ = modified_at;
  // @@protoc_insertion_point(field_set_allocated:yandex.cloud.operation.Operation.modified_at)
}

// bool done = 6;
inline void Operation::clear_done() {
  done_ = false;
}
inline bool Operation::_internal_done() const {
  return done_;
}
inline bool Operation::done() const {
  // @@protoc_insertion_point(field_get:yandex.cloud.operation.Operation.done)
  return _internal_done();
}
inline void Operation::_internal_set_done(bool value) {
  
  done_ = value;
}
inline void Operation::set_done(bool value) {
  _internal_set_done(value);
  // @@protoc_insertion_point(field_set:yandex.cloud.operation.Operation.done)
}

// .google.protobuf.Any metadata = 7;
inline bool Operation::_internal_has_metadata() const {
  return this != internal_default_instance() && metadata_ != nullptr;
}
inline bool Operation::has_metadata() const {
  return _internal_has_metadata();
}
inline const PROTOBUF_NAMESPACE_ID::Any& Operation::_internal_metadata() const {
  const PROTOBUF_NAMESPACE_ID::Any* p = metadata_;
  return p != nullptr ? *p : reinterpret_cast<const PROTOBUF_NAMESPACE_ID::Any&>(
      PROTOBUF_NAMESPACE_ID::_Any_default_instance_);
}
inline const PROTOBUF_NAMESPACE_ID::Any& Operation::metadata() const {
  // @@protoc_insertion_point(field_get:yandex.cloud.operation.Operation.metadata)
  return _internal_metadata();
}
inline void Operation::unsafe_arena_set_allocated_metadata(
    PROTOBUF_NAMESPACE_ID::Any* metadata) {
  if (GetArena() == nullptr) {
    delete reinterpret_cast<::PROTOBUF_NAMESPACE_ID::MessageLite*>(metadata_);
  }
  metadata_ = metadata;
  if (metadata) {
    
  } else {
    
  }
  // @@protoc_insertion_point(field_unsafe_arena_set_allocated:yandex.cloud.operation.Operation.metadata)
}
inline PROTOBUF_NAMESPACE_ID::Any* Operation::release_metadata() {
  
  PROTOBUF_NAMESPACE_ID::Any* temp = metadata_;
  metadata_ = nullptr;
  if (GetArena() != nullptr) {
    temp = ::PROTOBUF_NAMESPACE_ID::internal::DuplicateIfNonNull(temp);
  }
  return temp;
}
inline PROTOBUF_NAMESPACE_ID::Any* Operation::unsafe_arena_release_metadata() {
  // @@protoc_insertion_point(field_release:yandex.cloud.operation.Operation.metadata)
  
  PROTOBUF_NAMESPACE_ID::Any* temp = metadata_;
  metadata_ = nullptr;
  return temp;
}
inline PROTOBUF_NAMESPACE_ID::Any* Operation::_internal_mutable_metadata() {
  
  if (metadata_ == nullptr) {
    auto* p = CreateMaybeMessage<PROTOBUF_NAMESPACE_ID::Any>(GetArena());
    metadata_ = p;
  }
  return metadata_;
}
inline PROTOBUF_NAMESPACE_ID::Any* Operation::mutable_metadata() {
  // @@protoc_insertion_point(field_mutable:yandex.cloud.operation.Operation.metadata)
  return _internal_mutable_metadata();
}
inline void Operation::set_allocated_metadata(PROTOBUF_NAMESPACE_ID::Any* metadata) {
  ::PROTOBUF_NAMESPACE_ID::Arena* message_arena = GetArena();
  if (message_arena == nullptr) {
    delete reinterpret_cast< ::PROTOBUF_NAMESPACE_ID::MessageLite*>(metadata_);
  }
  if (metadata) {
    ::PROTOBUF_NAMESPACE_ID::Arena* submessage_arena =
      reinterpret_cast<::PROTOBUF_NAMESPACE_ID::MessageLite*>(metadata)->GetArena();
    if (message_arena != submessage_arena) {
      metadata = ::PROTOBUF_NAMESPACE_ID::internal::GetOwnedMessage(
          message_arena, metadata, submessage_arena);
    }
    
  } else {
    
  }
  metadata_ = metadata;
  // @@protoc_insertion_point(field_set_allocated:yandex.cloud.operation.Operation.metadata)
}

// .google.rpc.Status error = 8;
inline bool Operation::_internal_has_error() const {
  return result_case() == kError;
}
inline bool Operation::has_error() const {
  return _internal_has_error();
}
inline void Operation::set_has_error() {
  _oneof_case_[0] = kError;
}
inline ::google::rpc::Status* Operation::release_error() {
  // @@protoc_insertion_point(field_release:yandex.cloud.operation.Operation.error)
  if (_internal_has_error()) {
    clear_has_result();
      ::google::rpc::Status* temp = result_.error_;
    if (GetArena() != nullptr) {
      temp = ::PROTOBUF_NAMESPACE_ID::internal::DuplicateIfNonNull(temp);
    }
    result_.error_ = nullptr;
    return temp;
  } else {
    return nullptr;
  }
}
inline const ::google::rpc::Status& Operation::_internal_error() const {
  return _internal_has_error()
      ? *result_.error_
      : reinterpret_cast< ::google::rpc::Status&>(::google::rpc::_Status_default_instance_);
}
inline const ::google::rpc::Status& Operation::error() const {
  // @@protoc_insertion_point(field_get:yandex.cloud.operation.Operation.error)
  return _internal_error();
}
inline ::google::rpc::Status* Operation::unsafe_arena_release_error() {
  // @@protoc_insertion_point(field_unsafe_arena_release:yandex.cloud.operation.Operation.error)
  if (_internal_has_error()) {
    clear_has_result();
    ::google::rpc::Status* temp = result_.error_;
    result_.error_ = nullptr;
    return temp;
  } else {
    return nullptr;
  }
}
inline void Operation::unsafe_arena_set_allocated_error(::google::rpc::Status* error) {
  clear_result();
  if (error) {
    set_has_error();
    result_.error_ = error;
  }
  // @@protoc_insertion_point(field_unsafe_arena_set_allocated:yandex.cloud.operation.Operation.error)
}
inline ::google::rpc::Status* Operation::_internal_mutable_error() {
  if (!_internal_has_error()) {
    clear_result();
    set_has_error();
    result_.error_ = CreateMaybeMessage< ::google::rpc::Status >(GetArena());
  }
  return result_.error_;
}
inline ::google::rpc::Status* Operation::mutable_error() {
  // @@protoc_insertion_point(field_mutable:yandex.cloud.operation.Operation.error)
  return _internal_mutable_error();
}

// .google.protobuf.Any response = 9;
inline bool Operation::_internal_has_response() const {
  return result_case() == kResponse;
}
inline bool Operation::has_response() const {
  return _internal_has_response();
}
inline void Operation::set_has_response() {
  _oneof_case_[0] = kResponse;
}
inline PROTOBUF_NAMESPACE_ID::Any* Operation::release_response() {
  // @@protoc_insertion_point(field_release:yandex.cloud.operation.Operation.response)
  if (_internal_has_response()) {
    clear_has_result();
      PROTOBUF_NAMESPACE_ID::Any* temp = result_.response_;
    if (GetArena() != nullptr) {
      temp = ::PROTOBUF_NAMESPACE_ID::internal::DuplicateIfNonNull(temp);
    }
    result_.response_ = nullptr;
    return temp;
  } else {
    return nullptr;
  }
}
inline const PROTOBUF_NAMESPACE_ID::Any& Operation::_internal_response() const {
  return _internal_has_response()
      ? *result_.response_
      : reinterpret_cast< PROTOBUF_NAMESPACE_ID::Any&>(PROTOBUF_NAMESPACE_ID::_Any_default_instance_);
}
inline const PROTOBUF_NAMESPACE_ID::Any& Operation::response() const {
  // @@protoc_insertion_point(field_get:yandex.cloud.operation.Operation.response)
  return _internal_response();
}
inline PROTOBUF_NAMESPACE_ID::Any* Operation::unsafe_arena_release_response() {
  // @@protoc_insertion_point(field_unsafe_arena_release:yandex.cloud.operation.Operation.response)
  if (_internal_has_response()) {
    clear_has_result();
    PROTOBUF_NAMESPACE_ID::Any* temp = result_.response_;
    result_.response_ = nullptr;
    return temp;
  } else {
    return nullptr;
  }
}
inline void Operation::unsafe_arena_set_allocated_response(PROTOBUF_NAMESPACE_ID::Any* response) {
  clear_result();
  if (response) {
    set_has_response();
    result_.response_ = response;
  }
  // @@protoc_insertion_point(field_unsafe_arena_set_allocated:yandex.cloud.operation.Operation.response)
}
inline PROTOBUF_NAMESPACE_ID::Any* Operation::_internal_mutable_response() {
  if (!_internal_has_response()) {
    clear_result();
    set_has_response();
    result_.response_ = CreateMaybeMessage< PROTOBUF_NAMESPACE_ID::Any >(GetArena());
  }
  return result_.response_;
}
inline PROTOBUF_NAMESPACE_ID::Any* Operation::mutable_response() {
  // @@protoc_insertion_point(field_mutable:yandex.cloud.operation.Operation.response)
  return _internal_mutable_response();
}

inline bool Operation::has_result() const {
  return result_case() != RESULT_NOT_SET;
}
inline void Operation::clear_has_result() {
  _oneof_case_[0] = RESULT_NOT_SET;
}
inline Operation::ResultCase Operation::result_case() const {
  return Operation::ResultCase(_oneof_case_[0]);
}
#ifdef __GNUC__
  #pragma GCC diagnostic pop
#endif  // __GNUC__

// @@protoc_insertion_point(namespace_scope)

}  // namespace operation
}  // namespace cloud
}  // namespace yandex

// @@protoc_insertion_point(global_scope)

#include <google/protobuf/port_undef.inc>
#endif  // GOOGLE_PROTOBUF_INCLUDED_GOOGLE_PROTOBUF_INCLUDED_yandex_2fcloud_2foperation_2foperation_2eproto