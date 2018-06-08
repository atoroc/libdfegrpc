#ifndef _LIB_DIALOGFLOW_H_
#define _LIB_DIALOGFLOW_H_

#ifdef __cplusplus
extern "C" {
#endif

#if BUILDING_LIBDIALOGFLOW
#define LIBDIALOGFLOW_DLL_EXPORTED __attribute__((__visibility__("default")))
#else
#define LIBDIALOGFLOW_DLL_EXPORTED
#endif

struct dialogflow_session;

enum dialogflow_session_state {
    DF_STATE_READY,
    DF_STATE_STARTED,
    DF_STATE_FINISHED,
    DF_STATE_ERROR,
    DF_STATE_COUNT
};

enum dialogflow_log_level {
    DF_LOG_LEVEL_DEBUG,
    DF_LOG_LEVEL_INFO,
    DF_LOG_LEVEL_WARNING,
    DF_LOG_LEVEL_ERROR
};

struct dialogflow_result {
    const char *slot;
    size_t valueLen;
    const char *value;
    int score;
};

typedef void (*DF_LOG_FUNC)(enum dialogflow_log_level level, const char *file, int line, const char *function, const char *fmt, va_list args);

extern LIBDIALOGFLOW_DLL_EXPORTED int df_init(DF_LOG_FUNC log_function);
extern LIBDIALOGFLOW_DLL_EXPORTED struct dialogflow_session *df_create_session(const char *endpoint, const char *auth_key);
extern LIBDIALOGFLOW_DLL_EXPORTED int df_close_session(struct dialogflow_session *session);
extern LIBDIALOGFLOW_DLL_EXPORTED int df_set_session_id(struct dialogflow_session *session, const char *session_id);
extern LIBDIALOGFLOW_DLL_EXPORTED const char *df_get_session_id(struct dialogflow_session *session);
extern LIBDIALOGFLOW_DLL_EXPORTED int df_set_project_id(struct dialogflow_session *session, const char *project_id);
extern LIBDIALOGFLOW_DLL_EXPORTED const char *df_get_project_id(struct dialogflow_session *session);
extern LIBDIALOGFLOW_DLL_EXPORTED int df_recognize_event(struct dialogflow_session *session, const char *event, const char *language);
extern LIBDIALOGFLOW_DLL_EXPORTED int df_start_recognition(struct dialogflow_session *session, const char *language);
extern LIBDIALOGFLOW_DLL_EXPORTED int df_stop_recognition(struct dialogflow_session *session);
extern LIBDIALOGFLOW_DLL_EXPORTED enum dialogflow_session_state df_write_audio(struct dialogflow_session *session, const char *samples, size_t sample_count);
extern LIBDIALOGFLOW_DLL_EXPORTED enum dialogflow_session_state df_get_state(struct dialogflow_session *session);
extern LIBDIALOGFLOW_DLL_EXPORTED int df_get_rpc_state(struct dialogflow_session *session);
extern LIBDIALOGFLOW_DLL_EXPORTED int df_get_result_count(struct dialogflow_session *session);
/* structure is valid until session is destroyed or recognition re-started */
extern LIBDIALOGFLOW_DLL_EXPORTED struct dialogflow_result *df_get_result(struct dialogflow_session *session, int number);
extern LIBDIALOGFLOW_DLL_EXPORTED int df_get_response_count(struct dialogflow_session *session);
extern LIBDIALOGFLOW_DLL_EXPORTED void df_set_debug(struct dialogflow_session *session, int debug);

extern LIBDIALOGFLOW_DLL_EXPORTED int google_synth_speech(const char *endpoint, const char *svc_key, const char *text, 
    const char *language, const char *voice_name, const char *destination_filename);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* _LIB_DIALOGFLOW_H_ */