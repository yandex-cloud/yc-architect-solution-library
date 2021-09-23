//
// Created by makhlu on 22.09.2021.
//

#include "audio_prep_svc.h"


    audio_preparation_svc::audio_preparation_svc(std::map<std::string, std::string> config, std::shared_ptr<audio_prep_svc_callback> callback)
    : _config(config), _callback(callback) {
        ;
    }

    void audio_preparation_svc::discover_audio_format(std::string audio_source_uri){

    }
    void audio_preparation_svc::start_preparation_pipeline(std::string audio_source_uri){

    }

    void audio_preparation_svc::on_finished_cb(GstDiscoverer* discoverer, DiscovererData* data) {
        g_print("Finished discovering\n");

        g_main_loop_quit(data->loop);

        if (!_callback) {
            g_print("Error. Callback do not set");
        }else{

            JSON_Value *root_value = json_value_init_object();
            JSON_Object *root_object = json_value_get_object(root_value);


            char* serialized_string = json_serialize_to_string_pretty(root_value );

            _callback->format_detection_result(std::string(serialized_string));
            json_value_free(root_value);
        }
    }








