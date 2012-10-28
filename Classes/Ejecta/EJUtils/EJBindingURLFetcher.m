//
//  EJBindingURLFetcher.m
//  Ejecta
//
//  Created by James Cash on 24-10-12.
//
//

#import "EJBindingURLFetcher.h"

@implementation EJBindingURLFetcher

#pragma mark - Lifecycle
- (id)initWithContext:(JSContextRef)ctxp
               object:(JSObjectRef)obj
                 argc:(size_t)argc
                 argv:(const JSValueRef [])argv
{
    if (self =  [super initWithContext:ctxp object:obj argc:argc argv:argv]) {
        urlCallbacks = [[NSMutableDictionary alloc] initWithCapacity:1];
        requestData = [[NSMutableDictionary alloc] initWithCapacity:1];
    }
    return self;
}


#pragma mark - NSURLConnectionDataDelegate
- (void)connection:(NSURLConnection *)connection
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [connection cancel];
    NSURL *remoteUrl = connection.originalRequest.URL;
    NSArray *callbacks = [urlCallbacks objectForKey:remoteUrl];
    JSObjectRef callback;
    [(NSValue*)callbacks[1] getValue:&callback];


    if( callback ) {
        JSContextRef gctx = [EJApp instance].jsGlobalContext;
        JSValueRef params[] = { };
        [[EJApp instance] invokeCallback:callback thisObject:NULL argc:0 argv:params];
        JSValueUnprotect(gctx, callback);
    }
    [urlCallbacks removeObjectForKey:remoteUrl];
    [requestData removeObjectForKey:remoteUrl];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSURL *remoteUrl = connection.originalRequest.URL;
    [[requestData objectForKey:remoteUrl] appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSURL *remoteUrl = connection.originalRequest.URL;
    NSArray *callbacks = [urlCallbacks objectForKey:remoteUrl];
    JSObjectRef callback;
    [(NSValue*)callbacks[0] getValue:&callback];


    NSData *fetchedData = [requestData objectForKey:remoteUrl];
    NSString *data = [[NSString alloc] initWithBytes:[fetchedData bytes]
                                              length:[fetchedData length]
                                            encoding:NSUTF8StringEncoding];

    if( callback ) {
        JSContextRef gctx = [EJApp instance].jsGlobalContext;
        JSValueRef params[] = { NSStringToJSValue(gctx, data) };
        [[EJApp instance] invokeCallback:callback thisObject:NULL argc:1 argv:params];
        JSValueUnprotect(gctx, callback);
    }

    [urlCallbacks removeObjectForKey:remoteUrl];
    [requestData removeObjectForKey:remoteUrl];
}

#pragma mark - EJBinding
EJ_BIND_FUNCTION(fetchRemoteUrl, ctx, argc, argv) {
    if (argc < 1) return NULL;

    NSURL *remoteUrl = [NSURL URLWithString:JSValueToNSString(ctx, argv[0])];
    JSObjectRef successCallback = NULL;
	if( argc > 1 && JSValueIsObject(ctx, argv[1]) ) {
		successCallback = JSValueToObject(ctx, argv[1], NULL);
        JSValueProtect(ctx, successCallback);
    }
    JSObjectRef errorCallback = NULL;
	if( argc > 2 && JSValueIsObject(ctx, argv[2]) ) {
		errorCallback = JSValueToObject(ctx, argv[2], NULL);
        JSValueProtect(ctx, errorCallback);
	}
    
    NSURLRequest *req = [NSURLRequest requestWithURL:remoteUrl
                         cachePolicy:NSURLRequestUseProtocolCachePolicy
                                     timeoutInterval:60.0];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:req
                                                            delegate:self];
    NSArray *callbacks = [NSArray
                          arrayWithObjects:
                          [NSValue valueWithBytes:&successCallback objCType:@encode(JSObjectRef)],
                          [NSValue valueWithBytes:&errorCallback objCType:@encode(JSObjectRef)],
                          nil];
    [urlCallbacks setObject:callbacks forKey:remoteUrl];
    [requestData setObject:[NSMutableData data] forKey:remoteUrl];
    [conn start];
    return NULL;
}

@end
