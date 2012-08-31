//
//  Bookmark.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 8/28/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface Bookmark : NSManagedObject

@property (nonatomic, retain) NSDate * created_on;
@property (nonatomic, retain) NSString * extended;
@property (nonatomic, retain) NSString * meta;
@property (nonatomic, retain) NSNumber * others;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSNumber * shared;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * pinboard_hash;
@property (nonatomic, retain) NSManagedObject *tags;

@end
