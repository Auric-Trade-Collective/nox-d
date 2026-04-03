module noxd;

import std;
import std.string : toStringz;
// import core.stdc.stdlib;
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
