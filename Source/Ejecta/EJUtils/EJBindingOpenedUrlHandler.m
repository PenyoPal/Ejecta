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
    JSValueRef args[] = { NSStringToJSValue(scriptView.jsGlobalContext, [url absoluteString]) };
    [self triggerEvent:@"RecievedUrl" argc:1 argv:args];
}

EJ_BIND_FUNCTION(flush, ctx, argc, argv) {
    NSURL *stored = [[NSUserDefaults standardUserDefaults] URLForKey:@"_migrateUrl"];
    if (stored) {
        JSValueRef args[] = { NSStringToJSValue(ctx, [stored absoluteString]) };
        [self triggerEvent:@"RecievedUrl" argc:1 argv:args];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"_migrateUrl"];
    }
    return NULL;
}

EJ_BIND_EVENT(RecievedUrl);

@end
