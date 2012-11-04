#import "EJBindingLocalStorage.h"
#import <CoreData/CoreData.h>

#define STORAGE_FILE @"localStorage.sqlite"

@implementation EJBindingLocalStorage

- (id)initWithContext:(JSContextRef)ctxp object:(JSObjectRef)obj argc:(size_t)argc argv:(const JSValueRef [])argv
{
    if (self = [super initWithContext:ctxp object:obj argc:argc argv:argv]) {
        NSArray *documentDirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDir = [documentDirs objectAtIndex:0];
        NSString *path = [documentDir stringByAppendingPathComponent:STORAGE_FILE];
        
        storeUrl = [NSURL fileURLWithPath:path];
        NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:nil];
        psc = [[NSPersistentStoreCoordinator alloc]
               initWithManagedObjectModel:model];
        NSError *err;
        if (![psc addPersistentStoreWithType:NSSQLiteStoreType
                          configuration:nil
                                    URL:storeUrl
                                options:nil
                                       error:&err]) {
            NSLog(@"Failed to create localStorage store: %@",
                  [err localizedDescription]);
        }
        moc = [[NSManagedObjectContext alloc] init];
        [moc setPersistentStoreCoordinator:psc];
        [moc setUndoManager:nil];
    }
    return self;
}

- (void)dealloc
{
    [moc release];
    [psc release];
    [storeUrl release];
    [super dealloc];
}

- (NSArray*)getFromLocalStorage:(NSString *)key
{
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    [req setEntity:[NSEntityDescription entityForName:@"EJLocalStored"
                               inManagedObjectContext:moc]];
    [req setPredicate:[NSPredicate
                       predicateWithFormat:@"keyName == %@", key]];
    NSError *err;
    NSArray *results = [moc executeFetchRequest:req error:&err];
    [req release];
    assert(results.count == 1 || results.count == 0);
    return results;
}

- (void)setInLocalStorage:(NSString *)value forKey:(NSString *)key
{
    NSArray *existing = [self getFromLocalStorage:key];
    assert(existing.count == 1 || existing.count == 0);
    if (existing.count > 0) {
        for (NSManagedObject *old in existing) {
            [moc deleteObject:old];
        }
        NSError *err;
        if (![moc save:&err]) {
            NSLog(@"Failed to remove old records for %@: %@", key,
                  err.localizedDescription);
        }
    }
    NSManagedObject *obj = [NSEntityDescription
                            insertNewObjectForEntityForName:@"EJLocalStored"
                            inManagedObjectContext:moc];
    [obj setValue:key forKey:@"keyName"];
    [obj setValue:value forKey:@"value"];
    NSError *err;
    if (![moc save:&err]) {
        NSLog(@"Failed to set local storage %@ to %@: %@", key, value,
              err.localizedDescription);
    }
}

- (void)removeFromLocalStorage:(NSString *)key
{
    for (NSManagedObject *obj in [self getFromLocalStorage:key]) {
        [moc deleteObject:obj];
    }
    NSError *err;
    if (![moc save:&err]) {
        NSLog(@"Failed to remove key %@: %@", key, err.localizedDescription);
    }
}

- (void)clearLocalStorage
{
    NSError *err;
    if (![psc removePersistentStore:[psc persistentStoreForURL:storeUrl]
                              error:&err]) {
        NSLog(@"Failed to remove old persistant store: %@",
              err.localizedDescription);
        [psc unlock];
        return;
    }
	[psc release];
	[moc reset];
	[moc release];

    NSFileManager *fm = [[NSFileManager alloc] init];
    if (![fm removeItemAtURL:storeUrl error:&err]) {
        NSLog(@"Failed to delete old store file: %@", err.localizedDescription);
    }
    [fm release];

    NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:nil];
    psc = [[NSPersistentStoreCoordinator alloc]
           initWithManagedObjectModel:model];
    if (![psc addPersistentStoreWithType:NSSQLiteStoreType
                           configuration:nil
                                     URL:storeUrl
                                 options:nil
                                   error:&err]) {
        NSLog(@"Failed to create localStorage store: %@",
              [err localizedDescription]);
    }
	moc = [[NSManagedObjectContext alloc] init];
	[moc setPersistentStoreCoordinator:psc];
	[moc setUndoManager:nil];
}

EJ_BIND_FUNCTION(getItem, ctx, argc, argv ) {
	if( argc < 1 ) return NULL;
	
	NSString * key = JSValueToNSString( ctx, argv[0] );
	NSArray * vals = [self getFromLocalStorage:key];
    NSString * value = nil;
    if (vals.count > 0) {
        value = [NSString stringWithString:[[vals objectAtIndex:0]
                                            valueForKey:@"value"]];
    }
	return value ? NSStringToJSValue( ctx, value ) : NULL;
}

EJ_BIND_FUNCTION(setItem, ctx, argc, argv ) {
	if( argc < 2 ) return NULL;
	
	NSString * key = JSValueToNSString( ctx, argv[0] );
	NSString * value = JSValueToNSString( ctx, argv[1] );
	
	if( !key || !value ) return NULL;
	[self setInLocalStorage:value forKey:key];
	
	return NULL;
}

EJ_BIND_FUNCTION(removeItem, ctx, argc, argv ) {
	if( argc < 1 ) return NULL;
	
	NSString * key = JSValueToNSString( ctx, argv[0] );
	[self removeFromLocalStorage:key];
	
	return NULL;
}

EJ_BIND_FUNCTION(clear, ctx, argc, argv ) {
	[self clearLocalStorage];
	return NULL;
}


@end
