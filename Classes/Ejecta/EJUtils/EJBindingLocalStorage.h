#import <Foundation/Foundation.h>
#import "EJBindingBase.h"


@interface EJBindingLocalStorage : EJBindingBase {
    NSManagedObjectContext *moc;
    NSPersistentStoreCoordinator *psc;
    NSURL *storeUrl;
}

- (NSArray*)getFromLocalStorage:(NSString*)key;
- (void)setInLocalStorage:(NSString*)value forKey:(NSString*)key;
- (void)removeFromLocalStorage:(NSString*)key;
- (void)clearLocalStorage;

@end
