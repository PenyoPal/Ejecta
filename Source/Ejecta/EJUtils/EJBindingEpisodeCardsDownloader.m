//
//  EJBindingEpisodeCardsDownloader.m
//  Ejecta
//
//  Created by James Cash on 08-05-15.
//
//

#import "EJBindingEpisodeCardsDownloader.h"

#pragma mark - Javascript array helpers

// To check if a javascript value is an array, create an array object so we can call Array.isArray(obj)
BOOL JSValueIsArray(JSContextRef ctx, JSValueRef value) {
    if (!JSValueIsObject(ctx, value)) {
        return false;
    }
    JSStringRef name = JSStringCreateWithUTF8CString("Array");
    JSObjectRef array = (JSObjectRef)JSObjectGetProperty(ctx, JSContextGetGlobalObject(ctx), name, NULL);
    JSStringRelease(name);
    name = JSStringCreateWithUTF8CString("isArray");
    JSObjectRef isArray = (JSObjectRef)JSObjectGetProperty(ctx, array, name, NULL);
    JSStringRelease(name);
    return JSValueToBoolean(ctx, JSObjectCallAsFunction(ctx, isArray, NULL, 1, &value, NULL));
}

NSUInteger JSArrayGetCount(JSContextRef ctx, JSObjectRef arr) {
    JSStringRef lenPropName = JSStringCreateWithUTF8CString("length");
    JSValueRef jsLen = JSObjectGetProperty(ctx, arr, lenPropName, NULL);
    JSStringRelease(lenPropName);
    return (NSUInteger)JSValueToNumberFast(ctx, jsLen);
}

JSValueRef JSArrayValueAtIndex(JSContextRef ctx, JSObjectRef arr, NSUInteger idx) {
    return JSObjectGetPropertyAtIndex(ctx, arr, idx, NULL);
}

@implementation EJBindingEpisodeCardsDownloader

#pragma mark - Lifecycle
- (instancetype)initWithContext:(JSContextRef)ctxp argc:(size_t)argc argv:(const JSValueRef [])argv
{
    if (self = [super initWithContext:ctxp argc:argc argv:argv]) {
        errorCb = successCb = NULL;
        downloadSuccess = YES;
    }
    return self;
}

- (void)cleanUp
{
    JSContextRef gctx = scriptView.jsGlobalContext;
    if (errorCb) {
        JSValueUnprotect(gctx, errorCb);
        errorCb = NULL;
    }
    if (successCb) {
        JSValueUnprotect(gctx, successCb);
        successCb = NULL;
    }
}

#pragma mark - saving content
- (void)saveEpisodeCard:(NSData *)cardData forEpisode:(NSString *)episode andAssetSize:(long)assetSize
{
    NSLog(@"Saving...");
    NSURL *fileUrl = [NSURL
                     fileURLWithPathComponents:@[NSHomeDirectory(), @"Library", @"assets",
                                                 [NSString stringWithFormat:@"%@_card_%ld.png", episode, assetSize]]];
    BOOL isDir = NO;
    if (![[NSFileManager defaultManager]
          fileExistsAtPath:[fileUrl URLByDeletingLastPathComponent].path
          isDirectory:&isDir]) {
        NSLog(@"Need to create directory to save to");
        NSError *err = nil;
        [[NSFileManager defaultManager]
         createDirectoryAtURL:[fileUrl URLByDeletingLastPathComponent]
         withIntermediateDirectories:YES attributes:nil error:&err];
        if (err) {
            NSLog(@"Failed to create directory! %@", err.localizedDescription);
            return;
        }
    }
    NSError *err = nil;
    [cardData writeToURL:fileUrl options:NSDataWritingAtomic error:&err];
    if (err) {
        NSLog(@"Failed to write episode card for %@: %@", episode, err.localizedDescription);
    }
    NSLog(@"Saved content to %@", fileUrl);
}

EJ_BIND_FUNCTION(downloadEpisodeCards, ctx, argc, argv) {
    NSLog(@"downloadEpisodeCards... %zu", argc);
    if (argc < 3) {
        return NULL;
    }
    NSURL *remoteUrl = [NSURL URLWithString:JSValueToNSString(ctx, argv[0])];
    NSLog(@"Remote url = %@", remoteUrl);
    long assetSize = (long)JSValueToNumberFast(ctx, argv[1]);
    NSLog(@"asset size = %ld", assetSize);
    JSObjectRef arr = (JSObjectRef)argv[2];
    if (!JSValueIsArray(ctx, arr)) {
        return NULL;
    }
    if( argc > 3 && JSValueIsObject(ctx, argv[3]) ) {
        successCb = JSValueToObject(ctx, argv[3], NULL);
        JSValueProtect(ctx, successCb);
    }
    if( argc > 4 && JSValueIsObject(ctx, argv[4]) ) {
        errorCb = JSValueToObject(ctx, argv[4], NULL);
        JSValueProtect(ctx, errorCb);
    }
    NSUInteger nItems = JSArrayGetCount(ctx, arr);
    NSLog(@"Downloading %d items", nItems);
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
    for (NSUInteger i = 0; i < nItems; i++) {
        __block NSString *cardName = [JSValueToNSString(ctx, JSArrayValueAtIndex(ctx, arr, i)) retain];
        NSLog(@"Dispatching block to dl %@", cardName);
        dispatch_group_async(group, queue, ^{
            NSLog(@"Downloading %@", cardName);
            NSURL *cardURL = [NSURL URLWithString:[NSString stringWithFormat:@"/images/%ld/%@_card_%ld.png", assetSize, cardName, assetSize]
                                    relativeToURL:remoteUrl];
            NSURLRequest *req = [NSURLRequest requestWithURL:cardURL];
            NSURLResponse *resp; NSError *err = nil;
            NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
            if (err) {
                NSLog(@"Downloading episode card %@ failed: %@", cardName, err.localizedDescription);
                downloadSuccess = NO;
            } else {
                [self saveEpisodeCard:data forEpisode:cardName andAssetSize:assetSize];
            }
            [cardName release];
        });
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (downloadSuccess) {
            if (successCb) {
                JSValueRef params[] = {};
                [scriptView invokeCallback:successCb thisObject:NULL argc:0 argv:params];
            }
        } else {
            if (errorCb) {
                // TODO: cb should indicate which failed?
                JSValueRef params[] = {};
                [scriptView invokeCallback:errorCb thisObject:NULL argc:0 argv:params];
            }
        }
        [self cleanUp];
    });
    return NULL;
}

@end
