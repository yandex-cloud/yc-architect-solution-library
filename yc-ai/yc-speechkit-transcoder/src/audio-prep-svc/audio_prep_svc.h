//
// Created by makhlu on 21.09.2021.
//

#ifndef YC_SPEECHKIT_TRANSCODER_AUDIO_PREP_SVC_H
#define YC_SPEECHKIT_TRANSCODER_AUDIO_PREP_SVC_H


#include <gst/gst.h>
#include <gst/pbutils/pbutils.h>
#include <map>
#include <string>
#include <memory>
#include "parson/parson.h"



class audio_prep_svc_callback {
public:
    virtual void format_detection_result(std::string detection_result_json) = 0;
    virtual void preparation_pipeline_compleated(std::string pipeline_result_json) = 0;
};



class audio_preparation_svc{



/* Structure to contain all our information, so we can pass it around */
typedef struct _DiscovererData {
    GstDiscoverer* discoverer;
    GMainLoop* loop;
    std::map<std::string, std::string> config;
    std::shared_ptr<audio_prep_svc_callback> callback;
} DiscovererData;

public:
    const char* CFG_PIPELINE_TEMPLATE = "str_pipeline_template";
    audio_preparation_svc(std::map<std::string, std::string> config, std::shared_ptr<audio_prep_svc_callback> callback);
    void discover_audio_format(std::string audio_source_uri);
    void start_preparation_pipeline(std::string audio_source_uri);
    static gboolean   bus_call(GstBus* bus, GstMessage* msg, gpointer    data);
    static void on_finished_cb(GstDiscoverer* discoverer, DiscovererData* data);
    static void on_discovered_cb(GstDiscoverer* discoverer, GstDiscovererInfo* info, GError* err, DiscovererData* data);

private:


    JSON_Object* serialize_discoverer_data(DiscovererData* data);
    /* This function is called when the discoverer has finished examining
* all the URIs we provided.*/

    static void print_topology(GstDiscovererStreamInfo* info, gint depth);
    static void print_stream_info(GstDiscovererStreamInfo* info, gint depth);
    static void print_tag_foreach(const GstTagList* tags, const gchar* tag, gpointer user_data);

    static bool replace(std::string& str, const std::string& from, const std::string& to);
    bool make_pipeline_string(const std::string& audio_source_uri, std::string& str_pipeline);
    static bool make_storage_audio_file_name(const  std::string& audio_source_uri, std::string& audio_bucket_path);
    DiscovererData _discovery{};
protected:
};

#endif //YC_SPEECHKIT_TRANSCODER_AUDIO_PREP_SVC_H
