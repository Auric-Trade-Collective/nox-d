module noxd;

import std;
import std.exception;
import std.string : toStringz;
import std.conv;
import core.stdc.config : c_long;
import nox;

alias HttpRequest = nox.HttpRequest;
alias HttpResponse = nox.HttpResponse;
alias NoxEndpointCollection = nox.NoxEndpointCollection;

extern(C) alias NoxCallback = void function(HttpResponse *, HttpRequest *);
alias NoxAuth = extern(C) int function(HttpRequest *);

extern(C) public void createGet(NoxEndpointCollection *endp, string path, NoxCallback cb) {
    CreateGet(endp, cast(char*)path.toStringz, cast(apiCallback)cb);
}

extern(C) public void createPost(NoxEndpointCollection *endp, string path, NoxCallback cb) {
    CreatePost(endp, cast(char*)path.toStringz, cast(apiCallback)cb);
}

extern(C) public void createPut(NoxEndpointCollection *endp, string path, NoxCallback cb) {
    CreatePut(endp, cast(char*)path.toStringz, cast(apiCallback)cb);
}

extern(C) public void createDelete(NoxEndpointCollection *endp, string path, NoxCallback cb) {
    CreateDelete(endp, cast(char*)path.toStringz, cast(apiCallback)cb);
}

extern(C) public void createAuth(NoxEndpointCollection *endp, NoxAuth cb) {
    nox.NoxEndpointCollection *coll = cast(nox.NoxEndpointCollection *)endp;
    authCallback *cbp = cast(authCallback *)malloc(authCallback.sizeof);
    *cbp = cast(authCallback)cb;
    coll.auth = cbp;
}

extern(C) public void writeText(HttpResponse *resp, string text) {
    char *ptr = cast(char *)text.toStringz;
    WriteText(cast(nox.HttpResponse *)resp, ptr, cast(int)text.length);
} 

extern(C) public void writeCopy(HttpResponse *resp, NoxObj obj) {
    WriteCopy(resp, obj.dat);
}

extern(C) public void writeFile(HttpResponse *resp, NoxObj *obj) {
    WriteFile(resp, obj.dat);
}

extern(C) public void writeMove(HttpResponse *resp, NoxObj *obj) {
    obj.canFree = false;
    WriteMove(resp, obj.dat); // this takes ownership of the buffer in NoxObj! 
}


// data
public class NoxObj {
    NoxData *dat;
    bool canFree = true;

    ~this() {
        if(canFree) FreeData(dat);
    }
}

public NoxObj noxBuffer(size_t buffSize, string contentType, out byte *ot) {
    byte *buff = cast(byte *)malloc(buffSize);
    ot = buff;

    NoxData *noxBuff = NoxBuffer(cast(ubyte*)buff, cast(size_t)buffSize, cast(char*)contentType.toStringz);
    NoxObj obj = new NoxObj();
    obj.dat = noxBuff;
    
    return obj;
}

public NoxObj noxFile(string filename) {
    NoxData *dat = NoxFile(cast(char *)filename.toStringz);
    NoxObj obj = new NoxObj();
    obj.dat = dat;

    return obj;
}


extern(C) public bool tryGetResponseHeader(HttpResponse *resp, string key, ulong index, out string ot) {
    char *ptr;
    int check = TryGetResponseHeader(resp, cast(char *)key.toStringz, index, &ptr);

    ot = fromStringz(ptr).idup;
    free(ptr);

    return (check == 1) ? true : false;
}

extern(C) public bool trySetResponseHeader(HttpResponse *resp, string key, string val, bool append = false) {
    int check = TrySetResponseHeader(resp, cast(char *)key.toStringz, cast(char *)val.toStringz, (append) ? 1 : 0);
    return (check == 1) ? true : false;
}

extern(C) public bool tryGetRequestHeader(HttpRequest *req, string key, ulong index, out string ot) {
    char *ptr;
    int check = TryGetRequestHeader(req, cast(char *)key.toStringz, index, &ptr);

    ot = fromStringz(ptr).idup;
    free(ptr);

    return (check == 1) ? true : false;
}

extern(C) public bool trySetRequestHeader(HttpRequest *req, string key, string val, bool append = false) {
    int check = TrySetRequestHeader(req, cast(char *)key.toStringz, cast(char *)val.toStringz, (append) ? 1 : 0); 
    return (check == 1) ? true : false;
}

extern(C) public ulong readBody(HttpRequest *req, out ubyte[] buff, ulong maxRead = 4096) {
    string lenStr; 
    if(tryGetRequestHeader(req, "Content-Length", 0, lenStr)) {
        ulong len = lenStr.to!ulong;
        ubyte *b = cast(ubyte *)malloc(ubyte.sizeof * len);
        ulong read = ReadBody(req, b, len);

        buff = b[0..read].dup;
        free(b);

        return read;
    }

    ubyte *b = cast(ubyte *)malloc(ubyte.sizeof * maxRead);
    ulong read = ReadBody(req, b, maxRead);

    buff = b[0..read].dup;
    free(b);

    return read;
}

extern(C) public string getUri(HttpRequest *req) {
    ulong len;
    char *ptr = GetUri(req, &len);
    scope(exit) free(ptr);

    string uri = ptr[0..len].idup;

    return uri;
}

extern(C) public bool tryGetUriParam(HttpRequest *req, string key, out string ot, ulong index = 0) {
    ulong len;
    char *ptr;
    scope(exit) free(ptr);

    int ret = TryGetUriParam(req, cast(char *)key.toStringz, index, &ptr, &len);

    ot = (len > 0) ? ptr[0..len].idup : "";
    return (ret == 1) ? true : false;
}

extern(C) ulong getUriParamCount(HttpRequest *req, string paramName) {
    ulong count = GetUriParamCount(req, cast(char *)paramName.toStringz);
    return count;
}

// char *TryGetCookie(HttpRequest *req, char *key);
// void TrySetCookie(HttpResponse *resp, char *key, char *value, char *path, long expires, bool secure, bool httponly);

extern(C) string tryGetCookie(HttpRequest *req, string key) {
    char *ptr = TryGetCookie(req, cast(char *)key.toStringz);
    scope(exit) free(ptr);

    return fromStringz(ptr).idup;
}

extern(C) bool trySetCookie(HttpResponse *resp, 
                             string key, string value, 
                             string path, long expires, 
                             bool secure, bool httponly) {
    int ret = TrySetCookie(resp, cast(char *)key.toStringz, cast(char *)value.toStringz,
                       cast(char *)path.toStringz, cast(c_long)expires,
                       secure, httponly);
    return (ret == 1) ? true : false;
}
