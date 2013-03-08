//
//  EJBindingAlertView.m
//  Ejecta
//
//  Created by James Cash on 17-02-13.
//
//

#import "EJBindingAlertView.h"

@implementation EJBindingAlertView

- (void)dealloc
{
	[okUrl release];
	[super dealloc];
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	JSContextRef ctx = [[EJApp instance] jsGlobalContext];
	NSString *btn;
	switch (buttonIndex) {
		case 0:
			btn = @"cancel";
			break;
		case 1:
			btn = @"okay";
			[[UIApplication sharedApplication] openURL:okUrl];
			break;
		default:
			break;
	}
	JSValueRef params[] = { NSStringToJSValue(ctx, btn) };
	[self triggerEvent:@"ButtonClicked" argc:1 argv:params];
}

#pragma mark - Bindings

EJ_BIND_FUNCTION(createPopup, ctx, argc, argv) {
	if (argc < 1) {
		return NULL;
	}
	JSObjectRef args = (JSObjectRef)argv[0];
	NSString *title = JSValueToNSString(ctx, JSObjectGetProperty(ctx, args, JSStringCreateWithUTF8CString("title"), NULL));
	NSString *message = JSValueToNSString(ctx, JSObjectGetProperty(ctx, args, JSStringCreateWithUTF8CString("message"), NULL));
	NSString *okTitle = JSValueToNSString(ctx, JSObjectGetProperty(ctx, args, JSStringCreateWithUTF8CString("okTitle"), NULL));
	okUrl = [[NSURL URLWithString:JSValueToNSString(ctx, JSObjectGetProperty(ctx, args, JSStringCreateWithUTF8CString("okUrl"), NULL))] retain];
	NSString *cancelTitle = JSValueToNSString(ctx, JSObjectGetProperty(ctx, args, JSStringCreateWithUTF8CString("cancelTitle"), NULL));
	alertView = [[UIAlertView alloc] initWithTitle:title
										   message:message
										  delegate:self
								 cancelButtonTitle:cancelTitle
								 otherButtonTitles:okTitle, nil];
	[alertView show];
	return NULL;
}

EJ_BIND_EVENT(ButtonClicked);

@end