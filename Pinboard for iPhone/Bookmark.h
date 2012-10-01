//
//  Bookmark.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 9/30/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Tag;

@interface Bookmark : NSManagedObject

@property (nonatomic, retain) NSDate * created_on;
@property (nonatomic, retain) NSString * extended;
@property (nonatomic, retain) NSString * meta;
@property (nonatomic, retain) NSNumber * others;
@property (nonatomic, retain) NSString * pinboard_hash;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSNumber * shared;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSSet *tags;
@end

@interface Bookmark (CoreDataGeneratedAccessors)

- (void)addTagsObject:(Tag *)value;
- (void)removeTagsObject:(Tag *)value;
- (void)addTags:(NSSet *)values;
- (void)removeTags:(NSSet *)values;

@end
