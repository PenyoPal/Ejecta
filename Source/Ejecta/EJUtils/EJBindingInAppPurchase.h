//
//  EJBindingInAppPurchase.h
//  Ejecta
//
//  Created by James Cash on 19-01-13.
//
//

#import "EJBindingEventedBase.h"
#import <StoreKit/StoreKit.h>

@interface EJBindingInAppPurchase : EJBindingEventedBase <SKProductsRequestDelegate,SKPaymentTransactionObserver>
{
	BOOL requestingForPurchase;
}

@end
