// <auto-generated>
//     Generated by the protocol buffer compiler.  DO NOT EDIT!
//     source: yandex/cloud/ai/vision/v2/image.proto
// </auto-generated>
#pragma warning disable 1591, 0612, 3021
#region Designer generated code

using pb = global::Google.Protobuf;
using pbc = global::Google.Protobuf.Collections;
using pbr = global::Google.Protobuf.Reflection;
using scg = global::System.Collections.Generic;
namespace Yandex.Cloud.Ai.Vision.V2 {

  /// <summary>Holder for reflection information generated from yandex/cloud/ai/vision/v2/image.proto</summary>
  public static partial class ImageReflection {

    #region Descriptor
    /// <summary>File descriptor for yandex/cloud/ai/vision/v2/image.proto</summary>
    public static pbr::FileDescriptor Descriptor {
      get { return descriptor; }
    }
    private static pbr::FileDescriptor descriptor;

    static ImageReflection() {
      byte[] descriptorData = global::System.Convert.FromBase64String(
          string.Concat(
            "CiV5YW5kZXgvY2xvdWQvYWkvdmlzaW9uL3YyL2ltYWdlLnByb3RvEhl5YW5k",
            "ZXguY2xvdWQuYWkudmlzaW9uLnYyIqUBCgVJbWFnZRIRCgdjb250ZW50GAEg",
            "ASgMSAASPgoKaW1hZ2VfdHlwZRgCIAEoDjIqLnlhbmRleC5jbG91ZC5haS52",
            "aXNpb24udjIuSW1hZ2UuSW1hZ2VUeXBlIjoKCUltYWdlVHlwZRIaChZJTUFH",
            "RV9UWVBFX1VOU1BFQ0lGSUVEEAASCAoESlBFRxABEgcKA1BORxACQg0KC0lt",
            "YWdlU291cmNlQicKHXlhbmRleC5jbG91ZC5hcGkuYWkudmlzaW9uLnYyWgZ2",
            "aXNpb25iBnByb3RvMw=="));
      descriptor = pbr::FileDescriptor.FromGeneratedCode(descriptorData,
          new pbr::FileDescriptor[] { },
          new pbr::GeneratedClrTypeInfo(null, null, new pbr::GeneratedClrTypeInfo[] {
            new pbr::GeneratedClrTypeInfo(typeof(global::Yandex.Cloud.Ai.Vision.V2.Image), global::Yandex.Cloud.Ai.Vision.V2.Image.Parser, new[]{ "Content", "ImageType" }, new[]{ "ImageSource" }, new[]{ typeof(global::Yandex.Cloud.Ai.Vision.V2.Image.Types.ImageType) }, null, null)
          }));
    }
    #endregion

  }
  #region Messages
  public sealed partial class Image : pb::IMessage<Image>
  #if !GOOGLE_PROTOBUF_REFSTRUCT_COMPATIBILITY_MODE
      , pb::IBufferMessage
  #endif
  {
    private static readonly pb::MessageParser<Image> _parser = new pb::MessageParser<Image>(() => new Image());
    private pb::UnknownFieldSet _unknownFields;
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    [global::System.CodeDom.Compiler.GeneratedCode("protoc", null)]
    public static pb::MessageParser<Image> Parser { get { return _parser; } }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    [global::System.CodeDom.Compiler.GeneratedCode("protoc", null)]
    public static pbr::MessageDescriptor Descriptor {
      get { return global::Yandex.Cloud.Ai.Vision.V2.ImageReflection.Descriptor.MessageTypes[0]; }
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    [global::System.CodeDom.Compiler.GeneratedCode("protoc", null)]
    pbr::MessageDescriptor pb::IMessage.Descriptor {
      get { return Descriptor; }
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    [global::System.CodeDom.Compiler.GeneratedCode("protoc", null)]
    public Image() {
      OnConstruction();
    }

    partial void OnConstruction();

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    [global::System.CodeDom.Compiler.GeneratedCode("protoc", null)]
    public Image(Image other) : this() {
      imageType_ = other.imageType_;
      switch (other.ImageSourceCase) {
        case ImageSourceOneofCase.Content:
          Content = other.Content;
          break;
      }

      _unknownFields = pb::UnknownFieldSet.Clone(other._unknownFields);
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    [global::System.CodeDom.Compiler.GeneratedCode("protoc", null)]
    public Image Clone() {
      return new Image(this);
    }

    /// <summary>Field number for the "content" field.</summary>
    public const int ContentFieldNumber = 1;
    /// <summary>
    ///        bytes with data
    /// </summary>
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    [global::System.CodeDom.Compiler.GeneratedCode("protoc", null)]
    public pb::ByteString Content {
      get { return imageSourceCase_ == ImageSourceOneofCase.Content ? (pb::ByteString) imageSource_ : pb::ByteString.Empty; }
      set {
        imageSource_ = pb::ProtoPreconditions.CheckNotNull(value, "value");
        imageSourceCase_ = ImageSourceOneofCase.Content;
      }
    }

    /// <summary>Field number for the "image_type" field.</summary>
    public const int ImageTypeFieldNumber = 2;
    private global::Yandex.Cloud.Ai.Vision.V2.Image.Types.ImageType imageType_ = global::Yandex.Cloud.Ai.Vision.V2.Image.Types.ImageType.Unspecified;
    /// <summary>
    ///    type of data
    /// </summary>
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    [global::System.CodeDom.Compiler.GeneratedCode("protoc", null)]
    public global::Yandex.Cloud.Ai.Vision.V2.Image.Types.ImageType ImageType {
      get { return imageType_; }
      set {
        imageType_ = value;
      }
    }

    private object imageSource_;
    /// <summary>Enum of possible cases for the "ImageSource" oneof.</summary>
    public enum ImageSourceOneofCase {
      None = 0,
      Content = 1,
    }
    private ImageSourceOneofCase imageSourceCase_ = ImageSourceOneofCase.None;
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    [global::System.CodeDom.Compiler.GeneratedCode("protoc", null)]
    public ImageSourceOneofCase ImageSourceCase {
      get { return imageSourceCase_; }
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    [global::System.CodeDom.Compiler.GeneratedCode("protoc", null)]
    public void ClearImageSource() {
      imageSourceCase_ = ImageSourceOneofCase.None;
      imageSource_ = null;
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    [global::System.CodeDom.Compiler.GeneratedCode("protoc", null)]
    public override bool Equals(object other) {
      return Equals(other as Image);
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    [global::System.CodeDom.Compiler.GeneratedCode("protoc", null)]
    public bool Equals(Image other) {
      if (ReferenceEquals(other, null)) {
        return false;
      }
      if (ReferenceEquals(other, this)) {
        return true;
      }
      if (Content != other.Content) return false;
      if (ImageType != other.ImageType) return false;
      if (ImageSourceCase != other.ImageSourceCase) return false;
      return Equals(_unknownFields, other._unknownFields);
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    [global::System.CodeDom.Compiler.GeneratedCode("protoc", null)]
    public override int GetHashCode() {
      int hash = 1;
      if (imageSourceCase_ == ImageSourceOneofCase.Content) hash ^= Content.GetHashCode();
      if (ImageType != global::Yandex.Cloud.Ai.Vision.V2.Image.Types.ImageType.Unspecified) hash ^= ImageType.GetHashCode();
      hash ^= (int) imageSourceCase_;
      if (_unknownFields != null) {
        hash ^= _unknownFields.GetHashCode();
      }
      return hash;
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    [global::System.CodeDom.Compiler.GeneratedCode("protoc", null)]
    public override string ToString() {
      return pb::JsonFormatter.ToDiagnosticString(this);
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    [global::System.CodeDom.Compiler.GeneratedCode("protoc", null)]
    public void WriteTo(pb::CodedOutputStream output) {
    #if !GOOGLE_PROTOBUF_REFSTRUCT_COMPATIBILITY_MODE
      output.WriteRawMessage(this);
    #else
      if (imageSourceCase_ == ImageSourceOneofCase.Content) {
        output.WriteRawTag(10);
        output.WriteBytes(Content);
      }
      if (ImageType != global::Yandex.Cloud.Ai.Vision.V2.Image.Types.ImageType.Unspecified) {
        output.WriteRawTag(16);
        output.WriteEnum((int) ImageType);
      }
      if (_unknownFields != null) {
        _unknownFields.WriteTo(output);
      }
    #endif
    }

    #if !GOOGLE_PROTOBUF_REFSTRUCT_COMPATIBILITY_MODE
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    [global::System.CodeDom.Compiler.GeneratedCode("protoc", null)]
    void pb::IBufferMessage.InternalWriteTo(ref pb::WriteContext output) {
      if (imageSourceCase_ == ImageSourceOneofCase.Content) {
        output.WriteRawTag(10);
        output.WriteBytes(Content);
      }
      if (ImageType != global::Yandex.Cloud.Ai.Vision.V2.Image.Types.ImageType.Unspecified) {
        output.WriteRawTag(16);
        output.WriteEnum((int) ImageType);
      }
      if (_unknownFields != null) {
        _unknownFields.WriteTo(ref output);
      }
    }
    #endif

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    [global::System.CodeDom.Compiler.GeneratedCode("protoc", null)]
    public int CalculateSize() {
      int size = 0;
      if (imageSourceCase_ == ImageSourceOneofCase.Content) {
        size += 1 + pb::CodedOutputStream.ComputeBytesSize(Content);
      }
      if (ImageType != global::Yandex.Cloud.Ai.Vision.V2.Image.Types.ImageType.Unspecified) {
        size += 1 + pb::CodedOutputStream.ComputeEnumSize((int) ImageType);
      }
      if (_unknownFields != null) {
        size += _unknownFields.CalculateSize();
      }
      return size;
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    [global::System.CodeDom.Compiler.GeneratedCode("protoc", null)]
    public void MergeFrom(Image other) {
      if (other == null) {
        return;
      }
      if (other.ImageType != global::Yandex.Cloud.Ai.Vision.V2.Image.Types.ImageType.Unspecified) {
        ImageType = other.ImageType;
      }
      switch (other.ImageSourceCase) {
        case ImageSourceOneofCase.Content:
          Content = other.Content;
          break;
      }

      _unknownFields = pb::UnknownFieldSet.MergeFrom(_unknownFields, other._unknownFields);
    }

    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    [global::System.CodeDom.Compiler.GeneratedCode("protoc", null)]
    public void MergeFrom(pb::CodedInputStream input) {
    #if !GOOGLE_PROTOBUF_REFSTRUCT_COMPATIBILITY_MODE
      input.ReadRawMessage(this);
    #else
      uint tag;
      while ((tag = input.ReadTag()) != 0) {
        switch(tag) {
          default:
            _unknownFields = pb::UnknownFieldSet.MergeFieldFrom(_unknownFields, input);
            break;
          case 10: {
            Content = input.ReadBytes();
            break;
          }
          case 16: {
            ImageType = (global::Yandex.Cloud.Ai.Vision.V2.Image.Types.ImageType) input.ReadEnum();
            break;
          }
        }
      }
    #endif
    }

    #if !GOOGLE_PROTOBUF_REFSTRUCT_COMPATIBILITY_MODE
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    [global::System.CodeDom.Compiler.GeneratedCode("protoc", null)]
    void pb::IBufferMessage.InternalMergeFrom(ref pb::ParseContext input) {
      uint tag;
      while ((tag = input.ReadTag()) != 0) {
        switch(tag) {
          default:
            _unknownFields = pb::UnknownFieldSet.MergeFieldFrom(_unknownFields, ref input);
            break;
          case 10: {
            Content = input.ReadBytes();
            break;
          }
          case 16: {
            ImageType = (global::Yandex.Cloud.Ai.Vision.V2.Image.Types.ImageType) input.ReadEnum();
            break;
          }
        }
      }
    }
    #endif

    #region Nested types
    /// <summary>Container for nested types declared in the Image message type.</summary>
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute]
    [global::System.CodeDom.Compiler.GeneratedCode("protoc", null)]
    public static partial class Types {
      /// <summary>
      ///    type of image
      /// </summary>
      public enum ImageType {
        [pbr::OriginalName("IMAGE_TYPE_UNSPECIFIED")] Unspecified = 0,
        [pbr::OriginalName("JPEG")] Jpeg = 1,
        [pbr::OriginalName("PNG")] Png = 2,
      }

    }
    #endregion

  }

  #endregion

}

#endregion Designer generated code
