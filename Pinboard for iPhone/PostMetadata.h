//
//  PostMetadata.h
//  Pushpin
//
//  Created by Dan Loewenherz on 12/18/13.
//
//

#import <Foundation/Foundation.h>

@interface PostMetadata : NSObject

@property (nonatomic, strong) NSAttributedString *string;
@property (nonatomic, strong) NSNumber *height;
@property (nonatomic, strong) NSArray *links;
@property (nonatomic, strong) NSArray *badges;

+ (NSArray *)tagsWithFrequency;
+ (PostMetadata *)metadataForPost:(NSDictionary *)post compressed:(BOOL)compressed tagsWithFrequency:(NSDictionary *)tagsWithFrequency;

@end
