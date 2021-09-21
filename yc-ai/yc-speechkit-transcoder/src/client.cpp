#include <iostream>
#include "client.h"

using namespace std;

void add_option(std::string option_name, std::string option_value){
        options[option_name] = option_value;
}

int main(int argc, char** argv)
{
    bool error = false;
	if (argc < 3) {
        error = true;
	}else {
        // Parse command line options
        for (int i = 1; i < argc; i++) {
            std::string config_option_name;
            std::istringstream is_option(argv[i]);
            if (std::getline(is_option, config_option_name, '=')) {
                std::string config_option_value;
                if (std::getline(is_option, config_option_value)) {
                    add_option(config_option_name, config_option_value);
                }
            }
        }
    }
    if (error) {
        std::cout << "Usage asr-client config=<path_to_cfg_file> audio-source=<uri_to_audio>" << std::endl;
        return -1;
    }else{
        return 0;
    }

}



void parse_config(std::istream& cfgfile)
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
}