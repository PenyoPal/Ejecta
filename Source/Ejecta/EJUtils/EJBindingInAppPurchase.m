//
//  EJBindingInAppPurchase.m
//  Ejecta
//
//  Created by James Cash on 19-01-13.
//
//

#import "EJBindingInAppPurchase.h"

@implementation EJBindingInAppPurchase

- (id)initWithContext:(JSContextRef)ctxp object:(JSObjectRef)obj argc:(size_t)argc argv:(const JSValueRef [])argv
{
	if (self = [super initWithContext:ctxp object:obj argc:argc argv:argv]) {
		[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
		requestingForPurchase = NO;
	}
	return self;
}

- (void)dealloc
{
	[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
	[super dealloc];
}

- (void)requestProductInfo:(NSSet *)productIdents
{
	NSLog(@"Requesting info for %@", productIdents);
	SKProductsRequest *req = [[SKProductsRequest alloc]
							  initWithProductIdentifiers:productIdents];
	[req setDelegate:self];
	[req start];
}

- (void)purchaseItem:(SKProduct *)product
{
 	SKPayment *payment = [SKPayment paymentWithProduct:product];
	if ([SKPaymentQueue canMakePayments]) {
		[[SKPaymentQueue defaultQueue] addPayment:payment];
	} else {
		// TODO: Indicate cause of failure
		[self triggerEvent:@"PurchaseFailure" argc:0 argv:NULL];
	}
}

#pragma mark - SKProductsRequestDelegate methods

- (void)productsRequest:(SKProductsRequest *)request
	 didReceiveResponse:(SKProductsResponse *)response
{
	NSLog(@"Recieved response for product request: %@", response);
	for (SKProduct *product in response.products) {
		if (requestingForPurchase) {
			[self purchaseItem:product];
			requestingForPurchase = NO;
		} else {
			// Create JS object with info to trigger callback with
			JSContextRef ctx = [[EJApp instance] jsGlobalContext];
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
			[self triggerEvent:@"ProductInfoRecieved" argc:1 argv:params];
		}
	}
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
	NSLog(@"Payment queue updated: %@", transactions);
	for (SKPaymentTransaction *transaction in transactions) {
		// TODO: Put more useful info in the callback
		NSLog(@"Transaction state: %d", transaction.transactionState);
		switch (transaction.transactionState) {
			case SKPaymentTransactionStatePurchased:
				NSLog(@"Transaction purchansed");
				[self triggerEvent:@"PurchaseSuccess" argc:0 argv:NULL];
				break;
			case SKPaymentTransactionStateFailed:
				NSLog(@"Transaction failed: %@", transaction.error.localizedDescription);
				[self triggerEvent:@"PurchaseFailure" argc:0 argv:NULL];
				break;
			case SKPaymentTransactionStateRestored:
				NSLog(@"Transaction restored");
				[self triggerEvent:@"RestoredPurchase" argc:0 argv:NULL];
				break;
			default:
				break;
		}
		if (transaction.transactionState != SKPaymentTransactionStatePurchasing) {
			[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
		}
	}
}

EJ_BIND_FUNCTION(requestProductInfo, ctx, argc, argv) {
	// TODO: Allow sending an array/variadaic number of items
	if (argc < 1) {
		return NULL;
	}
	NSString *productIdent = JSValueToNSString(ctx, argv[0]);
	[self requestProductInfo:[NSSet setWithObject:productIdent]];
	return NULL;
}

EJ_BIND_FUNCTION(purchaseItem, ctx, argc, argv) {
	NSLog(@"Purchasing items");
	if (argc < 1) {
		return NULL;
	}
	NSString *productIdent = JSValueToNSString(ctx, argv[0]);
	NSLog(@"Attempting to purchase %@", productIdent);
	requestingForPurchase = YES;
	[self requestProductInfo:[NSSet setWithObject:productIdent]];
	return NULL;
}

EJ_BIND_FUNCTION(restorePurchases, ctx, argc, argv) {
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
	return NULL;
}

EJ_BIND_EVENT(ProductInfoRecieved)
EJ_BIND_EVENT(PurchaseSuccess)
EJ_BIND_EVENT(PurchaseFailure)
EJ_BIND_EVENT(RestoredPurchase)

@end
