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
#include "discoverer.h"

class audio_prep_svc_callback {
public:
    virtual void format_detection_result(std::string detection_result_json) = 0;
    virtual void preparation_pipeline_compleated(std::string pipeline_result_json) = 0;
};

class audio_preparation_svc{
public:
    audio_preparation_svc(std::map<std::string, std::string> config, std::shared_ptr<audio_prep_svc_callback> callback);
    void discover_audio_format(std::string audio_source_uri);
    void start_preparation_pipeline(std::string audio_source_uri);
private:

    /* This function is called when the discoverer has finished examining
   * all the URIs we provided.*/
    void on_finished_cb(GstDiscoverer* discoverer, DiscovererData* data);
    JSON_Object* serialize_discoverer_data(DiscovererData* data);

    std::map<std::string, std::string> _config;
    std::shared_ptr<audio_prep_svc_callback> _callback;
protected:
};

#endif //YC_SPEECHKIT_TRANSCODER_AUDIO_PREP_SVC_H
