//
//  EJBindingAlertView.h
//  Ejecta
//
//  Created by James Cash on 17-02-13.
//
//

#import "EJBindingEventedBase.h"

@interface EJBindingAlertView : EJBindingEventedBase <UIAlertViewDelegate> {
	UIAlertView *alertView;
	NSURL *okUrl;
}

@end
