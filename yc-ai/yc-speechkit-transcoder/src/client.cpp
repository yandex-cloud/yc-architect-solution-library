#include <iostream>
#include "client.h"


int main(int argc, char** argv)
{

	if (argc != 4) {
		std::cout << "Usage asr-client -config <path_to_cfg_file> -audio-source <uri_to_audio>" << std::endl;
		return -1;
	}

}

void parse_config(char** argv){

}