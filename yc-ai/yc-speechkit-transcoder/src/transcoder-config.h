//
// Created by makhlu on 21.09.2021.
//
#ifndef YC_SPEECHKIT_TRANSCODER_CONFIG_H
#define YC_SPEECHKIT_TRANSCODER_CONFIG_H

#include <string>

/* Config param const*/
static const char* CFG_PARAM_SOURCE_URI = "source_uri";
static const char* CFG_PARAM_LANG_CODE = "language_code";
static const char* CFG_PARAM_AUDIO_ENCODING = "audio_encoding";
static const char* CFG_PARAM_SAMPLE_RATE = "sample_rate_hertz";
static const char* CFG_PARAM_MODEL = "model";
static const char* CFG_PARAM_AUTH_MODEL = "auth_model";
static const char* CFG_PARAM_AUTH_TOKEN = "auth_token";
static const char* CFG_PARAM_BUCKET = "bucket";
static const char* CFG_PARAM_CONFIG = "config"; // config file path
static const char* CFG_PARAM_AUDIO_SOURCE = "audio-source"; // audio source uri (file:// or http://)
static const char* CFG_PIPELINE_TEMPLATE = "str_pipeline_template";

static const char* CFG_PARAMS[8] = { CFG_PARAM_AUDIO_SOURCE, CFG_PARAM_LANG_CODE , CFG_PARAM_AUDIO_ENCODING , 
        CFG_PARAM_SAMPLE_RATE, CFG_PARAM_MODEL, CFG_PARAM_AUTH_MODEL, CFG_PARAM_AUTH_TOKEN, CFG_PARAM_BUCKET };


static const char* ws = " \t\n\r\f\v";

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
#endif //YC_SPEECHKIT_TRANSCODER_CONFIG_H
