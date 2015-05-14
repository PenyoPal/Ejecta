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

// Currently assumes that values are strings
JSObjectRef NSArrayToJSArray(JSContextRef ctx, NSArray *arr) {
    JSStringRef name = JSStringCreateWithUTF8CString("Array");
    JSObjectRef arrayProto = (JSObjectRef)JSObjectGetProperty(ctx, JSContextGetGlobalObject(ctx), name, NULL);
    JSStringRelease(name);

    JSObjectRef jsArr = JSObjectCallAsConstructor(ctx, arrayProto, 0, NULL, NULL);
    JSStringRef pushName = JSStringCreateWithUTF8CString("push");
    JSObjectRef push = (JSObjectRef)JSObjectGetProperty(ctx, jsArr, pushName, NULL);
    JSStringRelease(pushName);
    [arr enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        JSValueRef args[] = { NSStringToJSValue(ctx, obj) };
        JSObjectCallAsFunction(ctx, push, jsArr, 1, args, NULL);
    }];
    return jsArr;
}

@implementation EJBindingEpisodeCardsDownloader

#pragma mark - Lifecycle
- (instancetype)initWithContext:(JSContextRef)ctxp argc:(size_t)argc argv:(const JSValueRef [])argv
{
    if (self = [super initWithContext:ctxp argc:argc argv:argv]) {
        successCb = NULL;
    }
    return self;
}

- (void)cleanUp
{
    JSContextRef gctx = scriptView.jsGlobalContext;
    if (successCb) {
        JSValueUnprotect(gctx, successCb);
        successCb = NULL;
    }
}

#pragma mark - saving content
- (BOOL)saveEpisodeCard:(NSData *)cardData forEpisode:(NSString *)episode andAssetSize:(long)assetSize
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
            return NO;
        }
    }
    NSError *err = nil;
    [cardData writeToURL:fileUrl options:NSDataWritingAtomic error:&err];
    if (err) {
        NSLog(@"Failed to write episode card for %@: %@", episode, err.localizedDescription);
        return NO;
    }
    NSLog(@"Saved content to %@", fileUrl);
    return YES;
}

EJ_BIND_FUNCTION(downloadEpisodeCards, ctx, argc, argv) {
    // For testing purposes, clear cache
//    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    if (argc < 3) {
        return NULL;
    }
    NSURL *remoteUrl = [NSURL URLWithString:JSValueToNSString(ctx, argv[0])];
    long assetSize = (long)JSValueToNumberFast(ctx, argv[1]);
    JSObjectRef arr = (JSObjectRef)argv[2];
    if (!JSValueIsArray(ctx, arr)) {
        return NULL;
    }
    if( argc > 3 && JSValueIsObject(ctx, argv[3]) ) {
        successCb = JSValueToObject(ctx, argv[3], NULL);
        JSValueProtect(ctx, successCb);
    }
    NSUInteger nItems = JSArrayGetCount(ctx, arr);
    NSLog(@"Downloading %d items", nItems);
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
    __block NSMutableArray *got = [[NSMutableArray alloc] init],
                           *failed = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < nItems; i++) {
        __block NSString *cardName = [JSValueToNSString(ctx, JSArrayValueAtIndex(ctx, arr, i)) retain];
        dispatch_group_async(group, queue, ^{
            NSLog(@"Downloading %@", cardName);
            NSURL *cardURL = [NSURL URLWithString:[NSString stringWithFormat:@"/images/%ld/%@_card_%ld.png", assetSize, cardName, assetSize]
                                    relativeToURL:remoteUrl];
            NSURLRequest *req = [NSURLRequest requestWithURL:cardURL];
            NSURLResponse *resp; NSError *err = nil;
            NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
            if (err) {
                NSLog(@"Downloading episode card %@ failed: %@", cardName, err.localizedDescription);
                [failed addObject:cardName];
            } else if (![self saveEpisodeCard:data forEpisode:cardName andAssetSize:assetSize]) {
                [failed addObject:cardName];
            } else {
                [got addObject:cardName];
            }
            [cardName release];
        });
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        JSContextRef ctx = scriptView.jsGlobalContext;
        if (successCb) {
            JSValueRef params[] = { NSArrayToJSArray(ctx, got), NSArrayToJSArray(ctx, failed) };
            [scriptView invokeCallback:successCb thisObject:NULL argc:2 argv:params];
        }
        [self cleanUp];
        [got release];
        [failed release];
    });
    return NULL;
}

@end
