//
// Created by makhlu on 22.09.2021.
//

#include <memory>
#include "speechkit_asr_svc.h"
#include "yandex/cloud/operation/operation_service.grpc.pb.h"

#include <grpcpp/channel.h>
#include <grpcpp/client_context.h>
#include <grpcpp/security/credentials.h>
#include <grpcpp/create_channel.h>
#include <thread>


using yandex::cloud::ai::stt::v2::LongRunningRecognitionRequest;

using yandex::cloud::ai::stt::v2::RecognitionSpec;
using yandex::cloud::ai::stt::v2::RecognitionSpec_AudioEncoding;
using yandex::cloud::ai::stt::v2::RecognitionConfig;
using yandex::cloud::ai::stt::v2::RecognitionAudio;
using yandex::cloud::operation::Operation;

using grpc::CreateChannel;
using grpc::SslCredentials;


speechkit_asr_svc::speechkit_asr_svc(std::map<std::string, std::string> config)
    :  _config(config), _context(init_asr_client_context(config)){
 ;
}

void speechkit_asr_svc::start_asr_task(std::shared_ptr<asr_svc_callback> callback, std::string asr_s3_src_uri){
    if (!callback){

    }
    _callback = callback;
}

grpc::ClientContext* speechkit_asr_svc::init_asr_client_context(std::map<std::string, std::string> config){

    grpc::ClientContext* context = new grpc::ClientContext();
    std::string str_bearer;// = config[CFG_PARAM_AUTH_MODEL] + ' ' + config[CFG_PARAM_AUTH_TOKEN];
    context->AddMetadata("authorization", str_bearer.c_str());
    context->AddMetadata("x-data-logging-enabled", "true");
    return context;
}

const char* speechkit_asr_svc::make_asr_task(std::unique_ptr<SttService::Stub> speech) {

    const char* language_code = "ru-RU";
    const char* model = "general";

    RecognitionSpec* asr_spec = new RecognitionSpec();
    asr_spec->set_language_code(language_code);
    asr_spec->set_audio_encoding(RecognitionSpec_AudioEncoding::RecognitionSpec_AudioEncoding_OGG_OPUS);
    asr_spec->set_sample_rate_hertz(48000);
    asr_spec->set_model(model);
    asr_spec->set_partial_results(false);

    // init recognition config
    RecognitionConfig* asr_config = new RecognitionConfig();
    asr_config->set_allocated_specification(asr_spec);

    // init audio config
    std::string uri = "https://storage.yandexcloud.net/vera/filipp.wav";
    RecognitionAudio* asr_audio = new RecognitionAudio();
    asr_audio->set_allocated_uri(&uri);

    LongRunningRecognitionRequest request{};
    request.set_allocated_audio(asr_audio);
    request.set_allocated_config(asr_config);

    Operation* op = new Operation();

    if(!_context){
        std::cout <<  "Context is not initialized. Re init"   << std::endl;
        _context = init_asr_client_context(_config);
    }

    grpc::Status rpc_status = speech->LongRunningRecognize (_context, request, op);//(context, request, op);
    const char* asr_task_id;
    if (!rpc_status.ok()) {
        std::cout <<  "RPC status " << rpc_status.error_code() << std::endl;
        std::cout <<  "RPC error message: " <<  rpc_status.error_message()  << std::endl;

    }else{
        asr_task_id = op->id().c_str();
        std::cout <<  "RPC call completed successfully. asr_task_id" << op->id() << std::endl;
    }

    request.release_config();
    request.release_audio();

    // release resources
    if (asr_audio != NULL){
        asr_audio->release_uri();
    }

    if (asr_config != NULL){
        asr_config->release_folder_id();
        asr_config->release_specification();
    }
    return asr_task_id;

}

int speechkit_asr_svc::collect_asr_task_result(std::unique_ptr<OperationService::Stub> asr_task_processing, const char* asr_task_id, LongRunningRecognitionResponse* asr_task_response){

    yandex::cloud::operation::GetOperationRequest asr_task_result_request{};
    asr_task_result_request.set_operation_id(asr_task_id);


    Operation* op = new Operation();
    while(!op->done()){

        std::cout <<  "Waiting for asr task '%s' to complete."  <<  asr_task_id << std::endl;
        std::this_thread::sleep_for(std::chrono::seconds(1));

        if(!_context){
            std::cout <<  "Context is not initialized. Re init"   << std::endl;
            _context = init_asr_client_context(_config);
        }
        grpc::Status  rpc_status = asr_task_processing->Get(_context,asr_task_result_request, op);

        if (!rpc_status.ok()){
            std::cout <<  "RPC failure " << rpc_status.error_message() << std::endl;
            return -1; // error code
        }
    }

    // Extract the response payload.

    if (!op->response().Is<LongRunningRecognitionResponse>()){
        std::cout <<  "RPC call for asr task '%s' completed successfully, but didn't return LongRunningRecognitionResponse in payload" << asr_task_id << std::endl;

    }else {
        op->response().UnpackTo(asr_task_response);
        std::cout <<  "RPC call for asr task " << asr_task_id << " completed successfully. " << asr_task_response->ByteSizeLong() << " bytes received." << std::endl;
        _callback->asr_result(asr_task_response->DebugString());
    }

        return 0;
}
