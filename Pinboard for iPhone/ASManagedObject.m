//
//  ASManagedObject.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 8/28/12.
//
//

#import "ASManagedObject.h"

static NSManagedObjectContext *__managedObjectContext = nil;
static NSManagedObjectModel *__managedObjectModel = nil;
static NSURL *__persistentStoreURL = nil;
static NSPersistentStoreCoordinator *__persistentStoreCoordinator = nil;
static NSString *const kURIRepresentationKey = @"URIRepresentation";

@implementation ASManagedObject

+ (NSManagedObjectContext *)sharedContext {
    if (!__managedObjectContext) {
        __managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        __managedObjectContext.persistentStoreCoordinator = [self sharedCoordinator];
    }
    return __managedObjectContext;
}

+ (void)resetPersistentStore:(NSPersistentStore *)store withURL:(NSURL *)url {
    NSError *error = nil;
    [[self sharedCoordinator] removePersistentStore:store error:&error];
    [[NSFileManager defaultManager] removeItemAtPath:url.path error:&error];
}

+ (NSPersistentStoreCoordinator *)sharedCoordinator {
    if (!__persistentStoreCoordinator) {
        __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self sharedModel]];
        
        NSURL *storeUrl = [self persistentStoreURL];
        
        NSError *error = nil;
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];


        if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
            // Handle error
            NSLog(@"%@", error);
        }

        /*
        [self resetPersistentStore:[__persistentStoreCoordinator.persistentStores lastObject] withURL:storeUrl];
        [__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error];
         */
    }

    return __persistentStoreCoordinator;
}

+ (NSURL *)persistentStoreURL {
	if (!__persistentStoreURL) {
		NSDictionary *applicationInfo = [[NSBundle mainBundle] infoDictionary];
#if TARGET_OS_IPHONE
		NSString *applicationName = [applicationInfo objectForKey:@"CFBundleDisplayName"];
		NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
		__persistentStoreURL = [documentsURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", applicationName]];
#else
		NSString *applicationName = [applicationInfo objectForKey:@"CFBundleName"];
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSURL *applicationSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
		applicationSupportURL = [applicationSupportURL URLByAppendingPathComponent:applicationName];

		NSDictionary *properties = [applicationSupportURL resourceValuesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] error:nil];
		if (!properties) {
			[fileManager createDirectoryAtPath:[applicationSupportURL path] withIntermediateDirectories:YES attributes:nil error:nil];
		}

		__persistentStoreURL = [applicationSupportURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", applicationName]];
#endif
	}
	return __persistentStoreURL;
}

+ (NSManagedObjectModel *)sharedModel {
    if (!__managedObjectModel) {
        __managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    }
    return __managedObjectModel;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder {
	NSManagedObjectContext *context = [[self class] sharedContext];
	NSPersistentStoreCoordinator *psc = [[self class] sharedCoordinator];
	self = (ASManagedObject *)[context objectWithID:[psc managedObjectIDForURIRepresentation:(NSURL *)[decoder decodeObjectForKey:kURIRepresentationKey]]];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:[[self objectID] URIRepresentation] forKey:kURIRepresentationKey];
}

@end
