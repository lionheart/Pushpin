//
//  Note.h
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 10/2/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Note : NSManagedObject

@property (nonatomic, retain) NSDate * created_at;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSNumber * length;
@property (nonatomic, retain) NSString * pinboard_hash;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSDate * updated_at;

@end
