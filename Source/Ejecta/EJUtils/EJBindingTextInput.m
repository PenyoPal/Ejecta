//
//  EJBindingTextInput.m
//  Ejecta
//
//  Created by James Cash on 14-11-12.
//
//

#import "EJBindingTextInput.h"
#import "EJClassLoader.h"

@implementation EJBindingTextInput

@synthesize inputField;

- (id)initWithContext:(JSContextRef)ctxp argc:(size_t)argc argv:(const JSValueRef [])argv
{
	if (self = [super initWithContext:ctxp argc:argc argv:argv]) {
		CGRect textFieldFrame = CGRectZero;
		if (argc >= 4) {
			NSInteger x = JSValueToNumberFast(ctxp, argv[0]);
			NSInteger y = JSValueToNumberFast(ctxp, argv[1]);
			NSInteger width = JSValueToNumberFast(ctxp, argv[2]);
			NSInteger height = JSValueToNumberFast(ctxp, argv[3]);
			textFieldFrame = CGRectMake(x, y, width, height);
		}
		inputField = [[UITextField alloc] initWithFrame:textFieldFrame];
		inputField.borderStyle = UITextBorderStyleRoundedRect;
		if (argc >= 5) {
			NSString *type = JSValueToNSString(ctxp, argv[4]);
			if ([type isEqualToString:@"password"]) {
				inputField.secureTextEntry = YES;
			} else if ([type isEqualToString:@"email"]) {
				inputField.autocorrectionType = UITextAutocorrectionTypeNo;
				inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
				inputField.keyboardType = UIKeyboardTypeEmailAddress;
				inputField.adjustsFontSizeToFitWidth = YES;
				inputField.minimumFontSize = 9;
			}
		}
		inputField.hidden = YES;
		inputField.delegate = self;
        // scriptView isn't around yet, or something, so wait until we try to show the view to add it
		enterCb = NULL;
	}
	return self;
}

- (void)dealloc
{
    [inputField removeFromSuperview];
	if (enterCb) {
		JSValueUnprotect(scriptView.jsGlobalContext, enterCb);
	}
	[inputField release];
	[super dealloc];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	NSLog(@"Enter pressed");
	if (enterCb) {
		NSLog(@"Enter key pressed, invoking cb");
		[scriptView invokeCallback:enterCb thisObject:NULL argc:0 argv:NULL];
	}
	if (nextTextField) {
		NSLog(@"Going to next text field instead %@", nextTextField);
		[nextTextField.inputField becomeFirstResponder];
	} else {
		[inputField resignFirstResponder];
	}
	return YES;
}

- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string
{
	[self triggerEvent:@"keyup" argc:0 argv:NULL];
	return YES;
}

EJ_BIND_FUNCTION(setFrame, ctx, argc, argv) {
	if (argc < 4) { return NULL; }
	NSInteger x = JSValueToNumberFast(ctx, argv[0]);
	NSInteger y = JSValueToNumberFast(ctx, argv[1]);
	NSInteger width = JSValueToNumberFast(ctx, argv[2]);
	NSInteger height = JSValueToNumberFast(ctx, argv[3]);
	CGRect textFieldFrame = CGRectMake(x, y, width, height);
	inputField.frame = textFieldFrame;
	[inputField setNeedsDisplay];
	return NULL;
}

EJ_BIND_FUNCTION(dismissKeyboard, ctx, argc, argv) {
	if (inputField.isFirstResponder) {
		[inputField resignFirstResponder];
	}
	return NULL;
}

EJ_BIND_FUNCTION(hide, ctx, argc, argv) {
	inputField.hidden = YES;
	return NULL;
}

EJ_BIND_GET(hidden, ctx) {
	return JSValueMakeBoolean(ctx, inputField.hidden);
}

EJ_BIND_GET(onEnter, ctx) {
	return enterCb;
}

EJ_BIND_SET(onEnter, ctx, newEnterCb) {
	NSLog(@"Setting enter callback");
	if (enterCb) {
		JSValueUnprotect(ctx, enterCb);
	}
	enterCb = JSValueToObject(ctx, newEnterCb, NULL);
	JSValueProtect(ctx, enterCb);
}

EJ_BIND_FUNCTION(show, ctx, argc, argv) {
    if (!inputField.superview) {
        [scriptView addSubview:inputField];
    }
	inputField.hidden = NO;
	return NULL;
}

EJ_BIND_GET(value, ctx) {
	return NSStringToJSValue(ctx, inputField.text ? inputField.text : @"");
}

EJ_BIND_SET(value, ctx, newValue) {
	inputField.text = JSValueToNSString(ctx, newValue);
}

EJ_BIND_GET(nextField, ctx) {
	if (nextTextField) {
        JSClassRef kls = [scriptView.classLoader getJSClass:[EJBindingTextInput class]].jsClass;
		JSObjectRef obj = JSObjectMake(ctx, kls, NULL);
		JSObjectSetPrivate(obj, nextTextField);
		return obj;
	}
	return NULL;
}

EJ_BIND_SET(nextField, ctx, nextTextInput) {
	nextTextField = (EJBindingTextInput *)JSObjectGetPrivate((JSObjectRef)nextTextInput);
}

EJ_BIND_EVENT(keyup);

@end
