//
//  EJBindingLoadingScreen.m
//  Ejecta
//
//  Created by James Cash on 27-11-12.
//
//

#import "EJBindingLoadingScreen.h"
#import "EJApp.h"

@implementation EJBindingLoadingScreen

EJ_BIND_FUNCTION(hide, ctx, argc, argv) {
	[[EJApp instance] hideLoadingScreen];
	return NULL;
}

@end
