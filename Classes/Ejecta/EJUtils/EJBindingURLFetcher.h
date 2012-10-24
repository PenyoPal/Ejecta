//
//  EJBindingURLFetcher.h
//  Ejecta
//
//  Created by James Cash on 24-10-12.
//
//

#import "EJBindingBase.h"

@interface EJBindingURLFetcher : EJBindingBase <NSURLConnectionDataDelegate>
{
    NSMutableDictionary *urlCallbacks;
    NSMutableDictionary *requestData;
}

@end
