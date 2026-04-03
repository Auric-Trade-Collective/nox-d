import core.stdc.config;
import core.stdc.stdint;

extern (C):

// APIS

struct HttpRequest
{
    // uintptr_t headers;
    // uintptr_t body;
    // uintptr_t url;

    //0 GET, 1 POST, 2 PUT, 3 DELETE

    alias uintptr_t = c_ulong;
    uintptr_t gohandle;
    char* endpoint;
    char* method;
    char* remoteAddr;
}

struct HttpResponse
{
    uintptr_t gohandle;
}

alias apiCallback = void function (HttpResponse*, HttpRequest*);

struct NoxEndpoint
{
    char* endpoint;
    apiCallback callback;
    int method;
}

alias authCallback = int function (HttpRequest*);

struct NoxEndpointCollection
{
    void* dll;
    int endpointCount;
    authCallback* auth;
    NoxEndpoint* endpoints;
}

alias createEndpoint = void function (NoxEndpointCollection*, char*, apiCallback, int);
alias createNox = void function (NoxEndpointCollection*);
char* SanitizePath (char* buff);
void CreateNoxEndpoint (
    NoxEndpointCollection* coll,
    char* endpoint,
    apiCallback callback,
    int method);

void CreateAuth (NoxEndpointCollection* coll, authCallback cb);

void InvokeApiCallback (apiCallback cb, HttpResponse* resp, HttpRequest* req);

int InvokeAuth (authCallback cb, HttpRequest* req);

//Here is where the JSON and Stream helpers will exist
//This includes exported function defs, some types, and C logic

enum NoxDataType
{
    PLAINTEXT = 0,
    STREAM = 2,
    STREAMFILE = 3, //whilst you can use BYTES/STREAM to stream a file, this will tell
    //nox what file you want to send, and nox will handle the reading,
    //writing, parsing, and data types for you
    BYTES = 4
}

alias PLAINTEXT = NoxDataType.PLAINTEXT;
alias STREAM = NoxDataType.STREAM;
alias STREAMFILE = NoxDataType.STREAMFILE;
alias BYTES = NoxDataType.BYTES;

enum NoxStreamSection
{
    BEGIN = 1,
    PART = 2,
    END = 3
}

alias BEGIN = NoxStreamSection.BEGIN;
alias PART = NoxStreamSection.PART;
alias END = NoxStreamSection.END;

struct NoxData
{
    NoxDataType type;
    ubyte* buff; //Does not have to be a Cstring
    alias size_t = c_ulong;
    size_t length;
    char* filename; // CSTRING, can be NULL
    NoxStreamSection section;
    char* contentType;
}

NoxData* NoxBuffer (ubyte* buff, size_t len, char* contentType);

NoxData* NoxText (char* buff, size_t len);

//Cstring, can be read without a len
NoxData* NoxFile (char* filename);

void FreeData (NoxData* dat);

//Copies the pointer given
void WriteCopy (HttpResponse* resp, NoxData* dat);
//The pointer given should not be freed by the programmer, but is freed by nox, no copy streaming!
void WriteMove (HttpResponse* resp, NoxData* dat);

void WriteText (HttpResponse* resp, char* buff, int len);
void WriteFile (HttpResponse* resp, NoxData* dat);

void CreateGet (NoxEndpointCollection* collection, char* path, apiCallback callback);
void CreatePost (NoxEndpointCollection* collection, char* path, apiCallback callback);
void CreatePut (NoxEndpointCollection* collection, char* path, apiCallback callback);
void CreateDelete (NoxEndpointCollection* collection, char* path, apiCallback callback);

int TryGetResponseHeader (HttpResponse* resp, char* key, size_t index, char** ot);
int TrySetResponseHeader (HttpResponse* resp, char* key, char* val, int add);

int TryGetRequestHeader (HttpRequest* resp, char* key, size_t index, char** ot);
int TrySetRequestHeader (HttpRequest* resp, char* key, char* val, int add);

// the returned value is how many bytes are read
size_t ReadBody (HttpRequest* req, ubyte* buff, size_t bytesToRead);

char* GetUri (HttpRequest* req, size_t* otLength);
int TryGetUriParam (HttpRequest* req, char* key, size_t index, char** ot, size_t* otLen);
size_t GetUriParamCount (HttpRequest* req, char* paramName);

char* TryGetCookie (HttpRequest* req, char* key);
void TrySetCookie (HttpResponse* resp, char* key, char* value, char* path, c_long expires, bool secure, bool httponly);

void LogWrite (char* name_space, char* msg);
void LogWarn (char* name_space, char* msg);
void LogError (char* name_space, char* msg);
void LogPanic (char* name_space, char* msg);

//PLUGINS

struct PluginCtx
{
    void* handle;
}

struct EventCtx
{
    int type;
    char* error;
    HttpRequest* httpRequest;
    HttpResponse* httpResponse;
}

alias pluginMain = void function (PluginCtx*);
alias eventCallback = void function (EventCtx*);

void InvokePluginMain (PluginCtx* ctx, pluginMain cb);

enum EventType
{
    OnLog = 0,
    OnError = 1,
    OnRequest = 2,
    OnResponse = 3,
    OnAny = 4
}

alias OnLog = EventType.OnLog;
alias OnError = EventType.OnError;
alias OnRequest = EventType.OnRequest;
alias OnResponse = EventType.OnResponse;
alias OnAny = EventType.OnAny;

void RegisterEvent (PluginCtx* plugin, int eventType, eventCallback cb);

