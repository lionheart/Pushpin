//
//  ASManagedObject.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 8/28/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface ASManagedObject : NSManagedObject <NSCoding>

+ (NSManagedObjectContext *)sharedContext;
+ (NSPersistentStoreCoordinator *)sharedCoordinator;
+ (NSManagedObjectModel* )sharedModel;
+ (NSURL *)persistentStoreURL;

@end
