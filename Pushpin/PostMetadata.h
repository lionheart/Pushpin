//
//  PostMetadata.h
//  Pushpin
//
//  Created by Dan Loewenherz on 12/18/13.
//
//

#import <Foundation/Foundation.h>

@class PPBadgeWrapperView;

@interface PostMetadata : NSObject

@property (nonatomic, strong) NSAttributedString *titleString;
@property (nonatomic, strong) NSAttributedString *descriptionString;
@property (nonatomic, strong) NSAttributedString *linkString;
@property (nonatomic, strong) NSNumber *height;
@property (nonatomic, strong) NSArray *badges;
@property (nonatomic, strong) PPBadgeWrapperView *badgeWrapperView;

+ (PostMetadata *)metadataForPost:(NSDictionary *)post
                       compressed:(BOOL)compressed
                            width:(CGFloat)width
                tagsWithFrequency:(NSDictionary *)tagsWithFrequency;

@end
