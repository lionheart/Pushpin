//
//  PostMetadata.h
//  Pushpin
//
//  Created by Dan Loewenherz on 12/18/13.
//
//

#import <Foundation/Foundation.h>

static dispatch_once_t dispatchOnceForWidth(CGFloat width);

@interface PostMetadata : NSObject

@property (nonatomic, strong) NSAttributedString *string;
@property (nonatomic, strong) NSNumber *height;
@property (nonatomic, strong) NSArray *links;
@property (nonatomic, strong) NSArray *badges;

+ (PostMetadata *)metadataForPost:(NSDictionary *)post
                       compressed:(BOOL)compressed
                            width:(CGFloat)width
                tagsWithFrequency:(NSDictionary *)tagsWithFrequency;

@end
