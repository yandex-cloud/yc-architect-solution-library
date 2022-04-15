//
// Created by makhlu on 22.09.2021.
//

#include  <../transcoder-config.h>
#include "audio_prep_svc.h"



    audio_preparation_svc::audio_preparation_svc(std::map<std::string, std::string> config, std::shared_ptr<audio_prep_svc_callback> callback)
    {
        /* Initialize cumstom data structure */
        memset(&_discovery, 0, sizeof(DiscovererData));
        _discovery.config = config;
        _discovery.callback = callback;

      
        if (!gst_is_initialized()) {
            g_print("Initializing GStreamer\n");
            gst_init(nullptr, nullptr);
        }
    }


    audio_preparation_svc::~audio_preparation_svc() {
        if (_discovery.discoverer)
            g_object_unref(_discovery.discoverer);

        if (_discovery.loop)
            g_main_loop_unref(_discovery.loop);
    }

    void audio_preparation_svc::discover_audio_format(std::string audio_source_uri){

        GError* err = NULL;

        g_print("Discovering '%s'\n", audio_source_uri.c_str());
        /* Instantiate the Discoverer */
        _discovery.discoverer = gst_discoverer_new(5 * GST_SECOND, &err);
        if (!_discovery.discoverer) {
            g_print("Error creating discoverer instance: %s\n", err->message);
            g_clear_error(&err);
            return;
        }

        /* Connect to the interesting signals */
        g_signal_connect(_discovery.discoverer, "discovered", G_CALLBACK(on_discovered_cb), &_discovery);
        g_signal_connect(_discovery.discoverer, "finished", G_CALLBACK(on_finished_cb), &_discovery);

        /* Start the discoverer process (nothing to do yet) */
        gst_discoverer_start(_discovery.discoverer);

        /* Add a request to process asynchronously the URI passed through the command line */
        if (!gst_discoverer_discover_uri_async(_discovery.discoverer, audio_source_uri.c_str())) {
            g_print("Failed to start discovering URI '%s'\n", audio_source_uri.c_str());
            g_object_unref(_discovery.discoverer);
            return;
        }

        /*   Create a GLib Main Loop and set it to run, so we can wait for the signals */
        _discovery.loop = g_main_loop_new(NULL, FALSE);
        g_main_loop_run(_discovery.loop);

        /* Stop the discoverer process */
        gst_discoverer_stop(_discovery.discoverer);

        /* Free discoverer resources */
        g_object_unref(_discovery.discoverer);
        g_main_loop_unref(_discovery.loop);
    }

    void audio_preparation_svc::start_preparation_pipeline(std::string audio_source_uri){
        GstBus* bus;
        GstMessage* msg;
        GError* err = NULL;
        GMainLoop* loop;
        loop = g_main_loop_new(NULL, FALSE);

        std::string str_pipeline =  make_pipeline_string(audio_source_uri);

        printf("Starting pipeline: %s\n", str_pipeline.c_str());

        GstElement* pipeline =  gst_parse_launch(str_pipeline.c_str(), NULL);

        guint watch_id;
        bus = gst_pipeline_get_bus(GST_PIPELINE(pipeline));


        //watch_id = gst_bus_add_watch(bus, (gpointer) on_finished_cb , loop);
        g_signal_connect(_discovery.discoverer, "finished", G_CALLBACK(on_finished_cb), &_discovery);
        gst_object_unref(bus);

        /* run */
        GstStateChangeReturn ret;
        ret = gst_element_set_state(pipeline, GST_STATE_PLAYING);

        if (ret == GST_STATE_CHANGE_FAILURE) {
            GstMessage* msg;

            g_print("Failed to start up pipeline!\n");

            /* check if there is an error message with details on the bus */
            msg = gst_bus_poll(bus, GST_MESSAGE_ERROR, 0);
            if (msg) {
                GError* err = NULL;

                gst_message_parse_error(msg, &err, NULL);
                g_print("ERROR: %s\n", err->message);
                g_error_free(err);
                gst_message_unref(msg);
            }
            return;
        }

        /* Iterate */
        g_print("Running...\n");
        g_main_loop_run(loop);


        /* Out of the main loop, clean up nicely */
        g_print("Returned, stopping...\n");

        /* Free resources */
        gst_element_set_state(pipeline, GST_STATE_NULL);
        g_print("Deleting pipeline\n");
        gst_object_unref(pipeline);
        g_source_remove(watch_id);
        g_main_loop_unref(loop);
    }

    /* Substitute template params*/
    std::string  audio_preparation_svc::make_pipeline_string(std::string audio_source_uri) {

        // CFG_PARAM_SOURCE_URI is not in app config - add them from call param
        _discovery.config[CFG_PARAM_SOURCE_URI] = audio_source_uri;

        std::string  pipeline_string = _discovery.config[CFG_PIPELINE_TEMPLATE];

       for (auto const& map_token : _discovery.config)
       {
           size_t index = 0;
           std::string pattern = "{" + map_token.first + "}";
           index = pipeline_string.find(pattern, index);
           if (index != std::string::npos) {
               int replace_len = pattern.length(); //pattern.length() > map_token.second.length() ? pattern.length() : map_token.second.length();
               pipeline_string.replace(index, replace_len , map_token.second);
               index += replace_len;
           }
       }

       g_print("Pipeline is: %s\n", pipeline_string.c_str());

       return pipeline_string;
      
    }

    void audio_preparation_svc::on_finished_cb(GstDiscoverer* discoverer, DiscovererData* data) {
        g_print("Finished discovering\n");

        g_main_loop_quit(data->loop);

        if (!data->callback) {
            g_print("Error. Callback do not set");
        }
    }

    /* This function is called every time the discoverer has information regarding
    * one of the URIs we provided.*/
    void audio_preparation_svc::on_discovered_cb(GstDiscoverer* discoverer, GstDiscovererInfo* info, GError* err, DiscovererData* data) {
        GstDiscovererResult result;
        const gchar* uri;
        const GstTagList* tags;
        GstDiscovererStreamInfo* sinfo;

        JSON_Value* root_value = json_value_init_object();
        JSON_Object* root_object = json_value_get_object(root_value);
        char buff[2048];

        uri = gst_discoverer_info_get_uri(info);
        result = gst_discoverer_info_get_result(info);
        switch (result) {
            case GST_DISCOVERER_URI_INVALID:
                g_print("Invalid URI '%s'\n", uri);
                std::snprintf(buff, sizeof(buff), "Invalid URI '%s'\n", uri);
                break;
            case GST_DISCOVERER_ERROR:
                g_print("Discoverer error: %s\n", err->message);
                std::snprintf(buff, sizeof(buff), "Discoverer error: %s\n", err->message);
                break;
            case GST_DISCOVERER_TIMEOUT:
                g_print("Timeout\n");
                std::snprintf(buff, sizeof(buff), "Timeout\n");
                break;
            case GST_DISCOVERER_BUSY:
                g_print("Busy\n");
                std::snprintf(buff, sizeof(buff), "Busy\n");
                break;
            case GST_DISCOVERER_MISSING_PLUGINS: {
                const GstStructure* s;
                gchar* str;

                s = gst_discoverer_info_get_misc(info);
                str = gst_structure_to_string(s);

                g_print("Missing plugins: %s\n", str);
                std::snprintf(buff, sizeof(buff), "Missing plugins: %s\n", str);
                g_free(str);
                break;
            }
            case GST_DISCOVERER_OK:
                g_print("Discovered '%s'\n", uri);
                std::snprintf(buff, sizeof(buff), "Discovered '%s'\n", uri);
                break;
        }

        if (result != GST_DISCOVERER_OK) {
            g_printerr("This URI cannot be played\n");
            std::snprintf(buff, sizeof(buff), "This URI cannot be played\n");
            return;
        }

        std::string tmp_value = std::string(buff);
        json_object_set_string(root_object, "status", rtrim(tmp_value).c_str());

        /*Construct output json with media deiscovered  information */
        g_print("\nDuration: %" GST_TIME_FORMAT "\n", GST_TIME_ARGS(gst_discoverer_info_get_duration(info)));       
        std::snprintf(buff, sizeof(buff), "%" GST_TIME_FORMAT "\n", GST_TIME_ARGS(gst_discoverer_info_get_duration(info)));        
        tmp_value = std::string(buff);
        json_object_set_string(root_object, "duration", rtrim(tmp_value).c_str());

        /* Tags*/
        tags = gst_discoverer_info_get_tags(info);       
        JSON_Value* tags_value = json_value_init_object();
        if (tags) {
            g_print("Tags:\n");
            gst_tag_list_foreach(tags, print_tag_foreach, tags_value);
        }
        
        json_object_dotset_value(root_object, "tags", tags_value);

        g_print("Seekable: %s\n", (gst_discoverer_info_get_seekable(info) ? "yes" : "no"));
        json_object_set_string(root_object, "seekable", (gst_discoverer_info_get_seekable(info) ? "yes" : "no"));

        g_print("\n");

        sinfo = gst_discoverer_info_get_stream_info(info);
        if (!sinfo)
            return;

        g_print("Stream information:\n");
        
        JSON_Value* streams_array = json_value_init_array();
        print_topology(sinfo, 1, streams_array);

        gst_discoverer_stream_info_unref(sinfo);

        json_object_set_value(root_object, "streams", streams_array);
        g_print("\n");

        char* serialized_string = json_serialize_to_string_pretty(root_value);
        data->callback->format_detection_result(std::string(serialized_string));

        json_value_free(root_value);
    }

/* Print a tag in a human-readable format (name: value) */
void audio_preparation_svc::print_tag_foreach(const GstTagList* tags, const gchar* tag, gpointer user_data) {
    GValue val = { 0, };
    gchar* str;
   // gint depth = GPOINTER_TO_INT(user_data);
    JSON_Value* tags_value = reinterpret_cast<JSON_Value*>(user_data);

    gst_tag_list_copy_value(&val, tags, tag);

    if (G_VALUE_HOLDS_STRING(&val))
        str = g_value_dup_string(&val);
    else
        str = gst_value_serialize(&val);

    g_print("%*s%s: %s\n", 2 , " ", gst_tag_get_nick(tag), str);
 
    json_object_set_string(json_value_get_object(tags_value), gst_tag_get_nick(tag), str);

    g_free(str);

    g_value_unset(&val);
}

/* Print information regarding a stream */
void audio_preparation_svc::print_stream_info(GstDiscovererStreamInfo* info, gint depth, JSON_Value* streams_array) {
    gchar* desc = NULL;
    GstCaps* caps;
    const GstTagList* tags;

    caps = gst_discoverer_stream_info_get_caps(info);

    if (caps) {
        if (gst_caps_is_fixed(caps))
            desc = gst_pb_utils_get_codec_description(caps);
        else
            desc = gst_caps_to_string(caps);
        gst_caps_unref(caps);
    }
   
    JSON_Value* stream_value =  json_value_init_object();
        g_print("%*s%s: %s\n", 2 * depth, " ", gst_discoverer_stream_info_get_stream_type_nick(info), (desc ? desc : ""));
       json_object_set_string(json_value_get_object(stream_value), gst_discoverer_stream_info_get_stream_type_nick(info), (desc ? desc : ""));

    if (desc) {
        g_free(desc);
        desc = NULL;
    }

    tags = gst_discoverer_stream_info_get_tags(info);
    if (tags) {
        g_print("%*sTags:\n", 2 * (depth + 1), " ");
       // gst_tag_list_foreach(tags, print_tag_foreach, stream_value);
    }
    
    json_array_append_value(json_value_get_array(streams_array), stream_value);
}

/* Print information regarding a stream and its substreams, if any */
void audio_preparation_svc::print_topology(GstDiscovererStreamInfo* info, gint depth, JSON_Value* streams_array) {
    GstDiscovererStreamInfo* next;

    if (!info)
        return;

    print_stream_info(info, depth, streams_array);

    next = gst_discoverer_stream_info_get_next(info);
    if (next) {
        print_topology(next, depth + 1, streams_array);
        gst_discoverer_stream_info_unref(next);
    }
    else if (GST_IS_DISCOVERER_CONTAINER_INFO(info)) {
        GList* tmp, * streams;

        streams = gst_discoverer_container_info_get_streams(GST_DISCOVERER_CONTAINER_INFO(info));
        for (tmp = streams; tmp; tmp = tmp->next) {
            GstDiscovererStreamInfo* tmpinf = (GstDiscovererStreamInfo*)tmp->data;
            print_topology(tmpinf, depth + 1, streams_array);
        }
        gst_discoverer_stream_info_list_free(streams);
    }
}










