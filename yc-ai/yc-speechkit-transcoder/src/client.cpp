#include <iostream>
#include <fstream>

#include "client.h"
#include "audio-prep-svc/audio_prep_svc.h"


using namespace std;

class audio_transformer_callback : public  audio_prep_svc_callback{
    public:
    virtual void format_detection_result(std::string detection_result_json)  override
    {

    }
    virtual void preparation_pipeline_compleated(std::string pipeline_result_json)  override
    {

    }
    private:
};


bool add_option(std::string option_name, std::string option_value){
        options[option_name] = option_value;
        return !options[option_name].empty();
}

bool parse_config_option(char* config_option_line){
    std::string config_option_name;
    std::istringstream is_option(config_option_line);
    if (std::getline(is_option, config_option_name, '=')) {
        std::string config_option_value;
        if (std::getline(is_option, config_option_value)) {
            return add_option(config_option_name, config_option_value);
        }
    }
    return false;
}

bool parse_config(){
    const char * config_file = options[CFG_PARAM_CONFIG].c_str();
    if (!config_file){
        std::cout << "Config file option required: config=<path_to_cfg_file> " << std::endl;
        return false;
    }
    std::ifstream cfg_file_in(config_file);

    if (cfg_file_in){
        for (std::string line; std::getline(cfg_file_in, line); ) {
            if (!parse_config_option((char *)line.c_str())){
                std::cout << "Error parsing config line: " << line << std::endl;
            }
        }
        return true;
    }else{
        std::cout << "Config file " << config_file << " not found." << std::endl;
        return false;
    }
}

int main(int argc, char** argv)
{
    bool error = false;
	if (argc < 3) {
        error = true;
	}else {
        // Parse command line options
        for (int i = 1; i < argc; i++){
                if (!parse_config_option(argv[i])) {
                    error = true;
                    break;
                }
        }
        if (options.size() < 2 ){
            error = true;
        }else{
            if (!parse_config()) {
                error = true;
            }else{
                auto prepare_audio_callback = std::make_shared<audio_transformer_callback>();
                audio_preparation_svc prepare_svc(options,prepare_audio_callback);
                prepare_svc.discover_audio_format(options[CFG_PARAM_AUDIO_SOURCE]);
                prepare_svc.start_preparation_pipeline(options[CFG_PARAM_AUDIO_SOURCE]);
            }
        }
    }
    if (error) {
        std::cout << "Usage asr-client config=<path_to_cfg_file> audio-source=<uri_to_audio>" << std::endl;
        return -1;
    }else{
        std::cout << "Completed." << std::endl;
        return 0;
    }

}



/* bool parse_config(std::istream& cfgfile)
{
   for (std::string line; std::getline(cfgfile, line); )
    {
        std::istringstream iss(line);
        std::string id, eq, val;

        bool error = false;

        if (!(iss >> id))
        {
            error = true;
        }
        else if (id[0] == '#')
        {
            continue;
        }
        else if (!(iss >> eq >> val >> std::ws) || eq != "=" || iss.get() != EOF)
        {
            error = true;
        }

        if (error)
        {
            // do something appropriate: throw, skip, warn, etc.
        }
        else
        {
            options[id] = val;
        }
    }
}*/