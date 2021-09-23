//
// Created by makhlu on 22.09.2021.
//

#ifndef YC_SPEECHKIT_TRANSCODER_SPEECHKIT_ASR_SVC_H
#define YC_SPEECHKIT_TRANSCODER_SPEECHKIT_ASR_SVC_H
#include <string>
#include <map>
#include <grpcpp/client_context.h>
#include "parson/parson.h"
#include "yandex/cloud/ai/stt/v2/stt_service.grpc.pb.h"
#include "yandex/cloud/operation/operation_service.grpc.pb.h"

// services
using yandex::cloud::ai::stt::v2::SttService;
using yandex::cloud::operation::OperationService;

using yandex::cloud::ai::stt::v2::LongRunningRecognitionResponse;

class asr_svc_callback {
public:
    virtual void asr_result(std::string asr_result_json) = 0;
};

class speechkit_asr_svc {

    public:
        speechkit_asr_svc(std::map<std::string, std::string> config);
        void start_asr_task(std::shared_ptr<asr_svc_callback>, std::string asr_s3_src_uri);

    private:
        grpc::ClientContext* _context;
        std::map<std::string, std::string> _config;
        std::shared_ptr<asr_svc_callback> _callback;
        grpc::ClientContext* init_asr_client_context(std::map<std::string, std::string> config);
        const char* make_asr_task(std::unique_ptr<SttService::Stub> speech);
        int collect_asr_task_result(std::unique_ptr<OperationService::Stub> asr_task_processing, const char* asr_task_id, LongRunningRecognitionResponse* asr_task_response);
};

#endif //YC_SPEECHKIT_TRANSCODER_SPEECHKIT_ASR_SVC_H
