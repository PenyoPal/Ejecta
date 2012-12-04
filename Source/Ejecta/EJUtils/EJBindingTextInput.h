//
//  EJBindingTextInput.h
//  Ejecta
//
//  Created by James Cash on 14-11-12.
//
//

#import "EJBindingEventedBase.h"

@interface EJBindingTextInput : EJBindingEventedBase <UITextFieldDelegate> {
	UITextField * inputField;
	EJBindingTextInput * nextTextField;
	JSObjectRef enterCb;
}

@property (nonatomic,readonly) UITextField * inputField;

@end
