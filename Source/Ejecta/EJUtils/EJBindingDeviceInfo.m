//
//  EJBindingDeviceInfo.m
//  Ejecta
//
//  Created by James Cash on 28-11-12.
//
//

#import "EJBindingDeviceInfo.h"

@implementation EJBindingDeviceInfo

EJ_BIND_GET(screenScale, ctx) {
	return JSValueMakeNumber(ctx, [UIScreen mainScreen].scale);
}

@end
