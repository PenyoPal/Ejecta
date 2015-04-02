//
//  EJBindingOpenedUrlHandler.m
//  Ejecta
//
//  Created by James Cash on 02-04-15.
//
//

#import "EJBindingOpenedUrlHandler.h"

@implementation EJBindingOpenedUrlHandler

- (id)initWithContext:(JSContextRef)ctxp argc:(size_t)argc argv:(const JSValueRef [])argv
{
    NSLog(@"Creating url handler");
    if (self = [super initWithContext:ctxp argc:argc argv:argv]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationHandler:) name:@"recievedMigrateUrl" object:nil];
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"Destroying url handler");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)notificationHandler:(NSNotification *)notification
{
    NSLog(@"Got notification in binding");
    NSURL *url = notification.object;
    [self sendRecievedUrlEvent:url];
}

- (void)sendRecievedUrlEvent:(NSURL *)url
{
    JSContextRef ctx = scriptView.jsGlobalContext;
    JSObjectRef urlObj = JSObjectMake(ctx, NULL, NULL);
    JSObjectSetProperty(ctx, urlObj, JSStringCreateWithUTF8CString("url"),
                        NSStringToJSValue(ctx, [url absoluteString]), kJSPropertyAttributeNone, NULL);
    JSObjectSetProperty(ctx, urlObj, JSStringCreateWithUTF8CString("path"),
                        NSStringToJSValue(ctx, [url path]), kJSPropertyAttributeNone, NULL);
    NSArray *queryParams = [[url query] componentsSeparatedByString:@"&"];
    JSObjectRef paramsObj = JSObjectMake(ctx, NULL, NULL);
    [queryParams enumerateObjectsUsingBlock:^(NSString *param, NSUInteger idx, BOOL* stop) {
        NSArray *keyValue = [param componentsSeparatedByString:@"="];
        assert([keyValue count] == 2);
        NSString *key = keyValue[0], *value = keyValue[1];
        JSObjectSetProperty(ctx, paramsObj, JSStringCreateWithCFString((CFStringRef)key),
                            NSStringToJSValue(ctx, value), kJSPropertyAttributeNone, NULL);

    }];
    JSObjectSetProperty(ctx, urlObj, JSStringCreateWithUTF8CString("params"), paramsObj,
                        kJSPropertyAttributeNone, NULL);
    JSValueRef args[] = { urlObj };
    [self triggerEvent:@"RecievedUrl" argc:1 argv:args];
}


EJ_BIND_FUNCTION(flush, ctx, argc, argv) {
    NSURL *stored = [[NSUserDefaults standardUserDefaults] URLForKey:@"_migrateUrl"];
    if (stored) {
        [self sendRecievedUrlEvent:stored];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"_migrateUrl"];
    }
    return NULL;
}

EJ_BIND_EVENT(RecievedUrl);

@end
