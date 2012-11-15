//
//  EJBindingTextInput.h
//  Ejecta
//
//  Created by James Cash on 14-11-12.
//
//

#import "EJBindingBase.h"

@interface EJBindingTextInput : EJBindingBase <UITextFieldDelegate> {
	UITextField * inputField;
	EJBindingTextInput * nextTextField;
}

@property (nonatomic,readonly) UITextField * inputField;

@end
