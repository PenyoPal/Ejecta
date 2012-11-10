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
		errorCb = successCb = NULL;
    }
    return self;
}

- (void)cancel
{
	if (connection) {
		[connection cancel];
		[connection release];
	}
	JSContextRef gctx = [EJApp instance].jsGlobalContext;
	if (errorCb) {
		JSValueUnprotect(gctx, errorCb);
		errorCb = NULL;
	}
	if (successCb) {
		JSValueUnprotect(gctx, successCb);
		successCb = NULL;
	}
	if (responseData) {
		[responseData release];
	}
	if (saveToPath) {
		[saveToPath release];
	}
}

#pragma mark - NSURLConnectionDataDelegate
- (void)connection:(NSURLConnection *)conn
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [connection cancel];
    [connection release];

    if( errorCb ) {
        JSContextRef gctx = [EJApp instance].jsGlobalContext;
        JSValueRef params[] = { };
        [[EJApp instance] invokeCallback:errorCb thisObject:NULL argc:0 argv:params];
        JSValueUnprotect(gctx, errorCb);
		JSValueUnprotect(gctx, successCb);
		errorCb = successCb = NULL;
    }
}

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data
{
	[responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
	NSURL *fileURL = [NSURL fileURLWithPathComponents:
					  [NSArray arrayWithObjects:NSHomeDirectory(),
					   @"Library", saveToPath, nil]];

	NSLog(@"Downloaded data, saving to %@", fileURL);
	NSError *err = nil;
	[responseData writeToURL:fileURL options:NSDataWritingAtomic error:&err];
	JSValueRef params[] = { };
	if (err) {
		NSLog(@"Error writing data out: %@", err.localizedDescription);
		[[EJApp instance] invokeCallback:errorCb thisObject:NULL argc:0 argv:params];
	} else {
		[[EJApp instance] invokeCallback:successCb thisObject:NULL argc:0 argv:params];
	}
	[connection release];
	[responseData release];
	JSContextRef gctx = [EJApp instance].jsGlobalContext;
	JSValueUnprotect(gctx, successCb);
	JSValueUnprotect(gctx, errorCb);
}

#pragma mark - EJBinding
EJ_BIND_FUNCTION(fetchRemoteUrl, ctx, argc, argv) {
    if (argc < 2) return NULL;

	[self cancel];
	
    NSURL *remoteUrl = [NSURL URLWithString:JSValueToNSString(ctx, argv[0])];
	saveToPath = [JSValueToNSString(ctx, argv[1]) retain];
	if( argc > 2 && JSValueIsObject(ctx, argv[2]) ) {
		successCb = JSValueToObject(ctx, argv[2], NULL);
        JSValueProtect(ctx, successCb);
    }
	if( argc > 3 && JSValueIsObject(ctx, argv[3]) ) {
		errorCb = JSValueToObject(ctx, argv[3], NULL);
        JSValueProtect(ctx, errorCb);
	}
    
    NSURLRequest *req = [NSURLRequest requestWithURL:remoteUrl
                         cachePolicy:NSURLRequestUseProtocolCachePolicy
                                     timeoutInterval:60.0];
    connection = [[NSURLConnection alloc] initWithRequest:req
												 delegate:self];

	responseData = [[NSMutableData alloc] initWithCapacity:1024 * 10];
    [connection start];
    return NULL;
}

@end
