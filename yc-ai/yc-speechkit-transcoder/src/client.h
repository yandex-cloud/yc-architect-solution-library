//
// Created by makhlu on 18.09.2021.
//
#include "yandex/cloud/operation/operation_service.grpc.pb.h"
#include "yandex/cloud/ai/stt/v2/stt_service.grpc.pb.h"
#include "yandex/cloud/ai/stt/v2/stt_service.pb.h"
#include <grpcpp/channel.h>
#include <grpcpp/client_context.h>
#include <grpcpp/security/credentials.h>
#include <grpcpp/create_channel.h>

#include <map>
#include <sstream>
#include <stdexcept>
#include <string>

std::map<std::string, std::string> options;

#ifndef YC_SPEECHKIT_TRANSCODER_CLIENT_H
#define YC_SPEECHKIT_TRANSCODER_CLIENT_H

using yandex::cloud::ai::stt::v2::RecognitionSpec;
using yandex::cloud::ai::stt::v2::RecognitionSpec_AudioEncoding;

std::string str_pipeline_template;
std::string source_uri;

/*  RecognitionSpec */
std::string language_code;
RecognitionSpec_AudioEncoding audio_encoding = RecognitionSpec_AudioEncoding::RecognitionSpec_AudioEncoding_OGG_OPUS;
int sample_rate_hertz = 48000;
std::string model = "general";
std::string auth_model = "Bearer";
std::string auth_token;


/* Config param const*/

const char* CFG_PARAM_CONFIG = "config"; // config file path
const char* CFG_PARAM_AUDIO_SOURCE = "audio-source"; // audio source uri (file:// or http://)


const char* ws = " \t\n\r\f\v";

// trim from end of string (right)
inline std::string& rtrim(std::string& s, const char* t = ws)
{
    s.erase(s.find_last_not_of(t) + 1);
    return s;
}

// trim from beginning of string (left)
inline std::string& ltrim(std::string& s, const char* t = ws)
{
    s.erase(0, s.find_first_not_of(t));
    return s;
}

// trim from both ends of string (right then left)
inline std::string& trim(std::string& s, const char* t = ws)
{
    return ltrim(rtrim(s, t), t);
}
#endif //YC_SPEECHKIT_TRANSCODER_CLIENT_H
