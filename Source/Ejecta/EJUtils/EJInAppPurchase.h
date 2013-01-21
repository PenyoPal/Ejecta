//
//  EJInAppPurchase.h
//  Ejecta
//
//  Created by James Cash on 19-01-13.
//
//

#import "EJBindingBase.h"
#import <StoreKit/StoreKit.h>

@interface EJInAppPurchase : EJBindingBase <SKProductsRequestDelegate,SKPaymentTransactionObserver>
{
	void (^requestCallback)(SKProduct *product);
	void (^purchaseCallback)(SKPaymentTransaction *transaction);
	void (^purchaseFailedCallback)(SKPaymentTransaction *transaction);

}

@end
