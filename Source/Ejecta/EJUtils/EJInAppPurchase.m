//
//  EJInAppPurchase.m
//  Ejecta
//
//  Created by James Cash on 19-01-13.
//
//

#import "EJInAppPurchase.h"

@implementation EJInAppPurchase

- (id)initWithContext:(JSContextRef)ctxp object:(JSObjectRef)obj argc:(size_t)argc argv:(const JSValueRef [])argv
{
	if (self = [super initWithContext:ctxp object:obj argc:argc argv:argv]) {
		[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
	}
	return self;
}

- (void)requestProductInfo:(NSSet *)productIdents withCallback:(void (^)(SKProduct* product))callback
{
	requestCallback = [callback retain];
	SKProductsRequest *req = [[SKProductsRequest alloc]
							  initWithProductIdentifiers:productIdents];
	[req setDelegate:self];
	[req start];
}

- (void)purchaseItem:(SKProduct *)product
		   onSuccess:(void (^)(SKPaymentTransaction *))successCb
			 onError:(void (^)(SKPaymentTransaction *))errorCb
{
	purchaseCallback = [successCb retain];
	purchaseFailedCallback = [errorCb retain];
	SKPayment *payment = [SKPayment paymentWithProduct:product];
	if ([SKPaymentQueue canMakePayments]) {
		[[SKPaymentQueue defaultQueue] addPayment:payment];
	}
}

#pragma mark - SKProductsRequestDelegate methods

- (void)productsRequest:(SKProductsRequest *)request
	 didReceiveResponse:(SKProductsResponse *)response
{
	// TODO: Cache the products so we don't need to request info seperately from
	// purchase?
	for (SKProduct *prod in response.products) {
		requestCallback(prod);
	}
	[requestCallback release];
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
	for (SKPaymentTransaction *transaction in transactions) {
		switch (transaction.transactionState) {
			case SKPaymentTransactionStatePurchased:
				// TODO: Can we have multiple things here?
				purchaseCallback(transaction);
				[purchaseCallback release];
				[purchaseFailedCallback release];
				break;
			case SKPaymentTransactionStateFailed:
				purchaseFailedCallback(transaction);
				[purchaseCallback release];
				[purchaseFailedCallback release];
				break;
			default:
				break;
		}
	}
}

EJ_BIND_FUNCTION(requestProductInfo, ctx, argc, argv) {
	if (argc < 2) {
		return NULL;
	}
	NSString *productIdent = JSValueToNSString(ctx, argv[0]);
	JSObjectRef successCb = JSValueToObject(ctx, argv[1], NULL);
	[self requestProductInfo:[NSSet setWithObject:productIdent]
				withCallback:^(SKProduct *product) {
					JSObjectRef infoObj = JSObjectMake(ctx, NULL, NULL);
					NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
					[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
					[numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
					[numberFormatter setLocale:product.priceLocale];
					JSValueRef priceStr = NSStringToJSValue(ctx, [numberFormatter stringFromNumber:product.price]);
					[numberFormatter release];
					JSObjectSetProperty(ctx, infoObj, JSStringCreateWithUTF8CString("price"),
										priceStr,
										kJSPropertyAttributeNone, NULL);
					JSObjectSetProperty(ctx, infoObj, JSStringCreateWithUTF8CString("title"),
										NSStringToJSValue(ctx, product.localizedTitle),
										kJSPropertyAttributeNone, NULL);
					JSObjectSetProperty(ctx, infoObj, JSStringCreateWithUTF8CString("description"),
										NSStringToJSValue(ctx, product.localizedDescription),
										kJSPropertyAttributeNone, NULL);
					JSObjectSetProperty(ctx, infoObj, JSStringCreateWithUTF8CString("productIdentifier"),
										NSStringToJSValue(ctx, product.productIdentifier),
										kJSPropertyAttributeNone, NULL);
					JSValueRef params[] = { infoObj };
					[[EJApp instance] invokeCallback:successCb
										  thisObject:NULL argc:1 argv:params];
				}];
	return NULL;
}

EJ_BIND_FUNCTION(purchaseItem, ctx, argc, argv) {
	if (argc < 3) {
		return NULL;
	}
	NSString *productIdent = JSValueToNSString(ctx, argv[0]);
	JSObjectRef successCb = JSValueToObject(ctx, argv[1], NULL);
	JSObjectRef errorCb = JSValueToObject(ctx, argv[2], NULL);
	[self requestProductInfo:[NSSet setWithObject:productIdent]
				withCallback:^(SKProduct *product) {
					[self purchaseItem:product onSuccess:^(SKPaymentTransaction *trans){
						[[EJApp instance] invokeCallback:successCb thisObject:NULL argc:0 argv:NULL];
					} onError:^(SKPaymentTransaction *trans) {
						[[EJApp instance] invokeCallback:errorCb thisObject:NULL argc:0 argv:NULL];
					}];
				}];
	return NULL;
}

@end
