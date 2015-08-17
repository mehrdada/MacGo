#import <Foundation/Foundation.h>

@class ServerProcess;

static const int ServerProcessChannelCount = 10;

@interface ServerProcess : NSObject {
    int _fd;
    int channels[ServerProcessChannelCount];
}

- (void) write:(NSData *)data;
- (NSData *) read;

+ (ServerProcess *)process;

@end