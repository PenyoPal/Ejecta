//
//  EJBindingURLFetcher.h
//  Ejecta
//
//  Created by James Cash on 24-10-12.
//
//

#import "EJBindingBase.h"

@interface EJBindingEpisodeDownloader : EJBindingBase
{
    NSString *saveToPath;
	JSObjectRef successCb;
	JSObjectRef errorCb;
}

@end
