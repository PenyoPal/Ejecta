//
//  EJBindingEpisodeCardsDownloader.h
//  Ejecta
//
//  Created by James Cash on 08-05-15.
//
//

#import "EJBindingBase.h"

@interface EJBindingEpisodeCardsDownloader : EJBindingBase
{
    BOOL downloadSuccess;
    JSObjectRef successCb;
    JSObjectRef errorCb;
}

@end
