#import "ServerProcess.h"

#include <sys/types.h>
#include <sys/socket.h>
#include <stdio.h>
#include <stdarg.h>

extern ServerProcess* serverProcess;

@implementation ServerProcess

- (ServerProcess *)init {
    if (self = [super init]) {
        [self initializeProcess];
    }
    return self;
}

- (void)initializeProcess {
    int sockets[2];
    
    if (socketpair(PF_LOCAL, SOCK_DGRAM, 0, sockets) < 0) {
        perror("opening stream socket pair");
        exit(1);
    }
    _fd = sockets[1];

    int channelSockets[ServerProcessChannelCount][2];
    for (int i = 0; i < ServerProcessChannelCount; ++i) {
        socketpair(PF_LOCAL, SOCK_STREAM, 0, channelSockets[i]);
        channels[i] = channelSockets[i][1];
    }
    
    int p[2];
    pipe(p);

    pid_t child = fork();
    if (child == 0) {
        close(p[1]); // close write end of pipe
        setpgid(0, 0); // prevent ^C in parent from stopping this process

        child = fork();
        if (child == 0) { //child
            close(p[0]); // close read end of pipe (don't need it here)
            close(_fd); // close other end of socket
            for (int i = 0; i < ServerProcessChannelCount; ++i) {
                close(channels[i]);
            }
            char a[ServerProcessChannelCount + 1][50];
            snprintf(*a, sizeof(*a), "%x", *sockets);
            char *argv[ServerProcessChannelCount+2];
            argv[0] = *a;
            for (int i = 0; i < ServerProcessChannelCount; ++i) {
                snprintf(a[i+1], sizeof(*a), "%x", *channelSockets[i]);
                argv[i+1] = a[i+1];
            }
            argv[ServerProcessChannelCount+1] = 0;
            execvp("gomac", argv);
            exit(1);
        }
        
        // middle:
        close(sockets[0]);
        close(_fd);
        for (int i = 0; i < ServerProcessChannelCount; ++i) {
            close(channelSockets[i][0]);
            close(channelSockets[i][1]);
        }
        char buf;
        read(p[0], &buf, 1); // returns when parent exits for any reason
        kill(child, 9);
        exit(0);
    }
    
    // parent:
    for (int i = 0; i < ServerProcessChannelCount; ++i) {
        close(channelSockets[i][0]);
    }
    close(sockets[0]);
}
/*
- (int)connect {
    int sockets[2];
    socketpair(PF_LOCAL, SOCK_STREAM, 0, sockets);
    
    struct msghdr parent_msg;
    size_t length;
    
    memset(&parent_msg, 0, sizeof(parent_msg));
    struct cmsghdr *cmsg;
    char cmsgbuf[CMSG_SPACE(sizeof(*sockets))];
    parent_msg.msg_control = cmsgbuf;
    parent_msg.msg_controllen = sizeof(cmsgbuf); // necessary for CMSG_FIRSTHDR to return the correct value
    cmsg = CMSG_FIRSTHDR(&parent_msg);
    cmsg->cmsg_level = SOL_SOCKET;
    cmsg->cmsg_type = SCM_RIGHTS;
    cmsg->cmsg_len = CMSG_LEN(sizeof(*sockets));
    memcpy(CMSG_DATA(cmsg), sockets, sizeof(*sockets));
    parent_msg.msg_controllen = cmsg->cmsg_len; // total size of all control blocks
    
    if((sendmsg(_fd, &parent_msg, 0)) < 0)
    {
        perror("sendmsg()");
        exit(EXIT_FAILURE);
    }
    close(sockets[0]);
    return sockets[1];
}
*/
- (void)write:(NSData *)data {
    if (write(_fd, data.bytes, data.length) < 0)
        perror("writing stream message");
}

- (NSData *)read {
    char buf[100000];
    ssize_t len;
    if ((len = read(_fd, buf, sizeof(buf)))) {
        return [NSData dataWithBytes:buf length:len];
    }
    return nil;
}

- (void)dealloc {
    close(_fd);
}

+ (ServerProcess *)process {
    return serverProcess;
}

@end

