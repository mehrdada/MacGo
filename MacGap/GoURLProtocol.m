#import "GoURLProtocol.h"
#import "ServerProcess.h"


@implementation GoURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return [@"go" isEqualToString: request.URL.scheme];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)startLoading {
    NSData *urlData = [[self.request.URL description] dataUsingEncoding:NSUTF8StringEncoding];
    [[ServerProcess process] write:urlData];
    NSData * data = [[ServerProcess process] read];
    
    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:self.request.URL MIMEType:@"text/html" expectedContentLength:data.length textEncodingName:@"utf8"];
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];

        [[self client] URLProtocol:self didLoadData:data];
        [[self client] URLProtocolDidFinishLoading:self];


    //self.connection = [NSURLConnection connectionWithRequest:self.request delegate:self];
}

- (void)stopLoading {
//    [self.connection cancel];
  //  self.connection = nil;
}

@end