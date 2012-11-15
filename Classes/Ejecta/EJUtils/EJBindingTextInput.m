//
//  EJBindingTextInput.m
//  Ejecta
//
//  Created by James Cash on 14-11-12.
//
//

#import "EJBindingTextInput.h"

@implementation EJBindingTextInput

@synthesize inputField;

- (id)initWithContext:(JSContextRef)ctxp object:(JSObjectRef)obj argc:(size_t)argc argv:(const JSValueRef [])argv
{
	if (self = [super initWithContext:ctxp object:obj argc:argc argv:argv]) {
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
		[[EJApp instance].view addSubview:inputField];
	}
	return self;
}

- (void)dealloc
{
	[inputField release];
	[super dealloc];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (nextTextField) {
		NSLog(@"Going to next text field instead %@", nextTextField);
		[nextTextField.inputField becomeFirstResponder];
	} else {
		[inputField resignFirstResponder];
	}
	return NO;
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

EJ_BIND_FUNCTION(show, ctx, argc, argv) {
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
		JSClassRef kls = [[EJApp instance] getJSClassForClass:[EJBindingTextInput class]];
		JSObjectRef obj = JSObjectMake(ctx, kls, NULL);
		JSObjectSetPrivate(obj, nextTextField);
		return obj;
	}
	return NULL;
}

EJ_BIND_SET(nextField, ctx, nextTextInput) {
	nextTextField = (EJBindingTextInput *)JSObjectGetPrivate((JSObjectRef)nextTextInput);
}

@end
