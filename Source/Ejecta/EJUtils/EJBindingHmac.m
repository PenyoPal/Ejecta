//
//  EJBindingHmac.m
//  Ejecta
//
//  Created by James Cash on 30-03-15.
//
//

#import "EJBindingHmac.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation EJBindingHmac

static NSString* hmac_key = @"utg28cAW%nq&my6M";

- (NSString *)hmacSha256:(NSString *)str
{
    NSData *key = [hmac_key dataUsingEncoding:NSUTF8StringEncoding];
    NSData *param = [str dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *hash = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, key.bytes, key.length, param.bytes, param.length, hash.mutableBytes);
    return [hash base64EncodedStringWithOptions:nil];
}

EJ_BIND_FUNCTION(hmacSha256, ctx, argc, argv) {
    if (argc < 1) return NULL;
    NSString *toHash = JSValueToNSString(ctx, argv[0]);
    return NSStringToJSValue(ctx, [self hmacSha256:toHash]);
}

@end
