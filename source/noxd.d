module noxd;

import std;
import std.exception;
import std.string : toStringz;
import std.conv; import core.stdc.config : c_long; import nox;

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
        ubyte[] b = new ubyte[](len);
        ulong read = ReadBody(req, b.ptr, len);

        buff = b[0..read];
        return read;
    }

    ubyte[] b = new ubyte[](maxRead);
    ulong read = ReadBody(req, b.ptr, maxRead);
    buff = b[0..read];

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

extern(C) public ulong getUriParamCount(HttpRequest *req, string paramName) {
    ulong count = GetUriParamCount(req, cast(char *)paramName.toStringz);
    return count;
}

// char *TryGetCookie(HttpRequest *req, char *key);
// void TrySetCookie(HttpResponse *resp, char *key, char *value, char *path, long expires, bool secure, bool httponly);

extern(C) public string tryGetCookie(HttpRequest *req, string key) {
    char *ptr = TryGetCookie(req, cast(char *)key.toStringz);
    scope(exit) free(ptr);

    return fromStringz(ptr).idup;
}

extern(C) public void trySetCookie(HttpResponse *resp, 
                             string key, string value, 
                             string path, long expires, 
                             bool secure, bool httponly) {
    TrySetCookie(resp, cast(char *)key.toStringz, cast(char *)value.toStringz,
                 cast(char *)path.toStringz, cast(c_long)expires,
                 secure, httponly);
}

extern(C) public string registerName(NoxEndpointCollection *coll, string name) {
    char *ret = RegisterName(coll, cast(char *)name.toStringz);
    return fromStringz(ret).idup;
}

extern(C) public string getEnv(string secret, string key) {
    char *val = GetEnv(cast(char *)secret.toStringz, cast(char *)key.toStringz);
    if(val != null) {
        return fromStringz(val).idup;
    }

    return null;
}

class NoxLogger {
    private char *namespace;

    public this(string namespace) shared {
        this.namespace = cast(shared(char *))namespace.toStringz;
        LogDebug(cast(char *)this.namespace, cast(char *)"Nox-D logging initialized...".toStringz);
    }

    public void write(string message) shared {
        auto self = cast(NoxLogger)this;
        char *nmepsace = self.namespace;
        LogWrite(nmepsace, cast(char *)message.toStringz);
    }


    public void warn(string message) shared {
        auto self = cast(NoxLogger)this;
        char *nmepsace = self.namespace;
        LogWarn(nmepsace, cast(char *)message.toStringz);
    }

    public void error(string message) shared {
        auto self = cast(NoxLogger)this;
        char *nmepsace = self.namespace;
        LogError(nmepsace, cast(char *)message.toStringz);
    }

    public void panic(string message) shared {
        auto self = cast(NoxLogger)this;
        char *nmepsace = self.namespace;
        LogPanic(nmepsace, cast(char *)message.toStringz);
    }

    public void dbg(string message) shared {
        auto self = cast(NoxLogger)this;
        char *nmepsace = self.namespace;
        LogDebug(nmepsace, cast(char *)message.toStringz);
    }
}
