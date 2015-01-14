//
//  PostMetadata.m
//  Pushpin
//
//  Created by Dan Loewenherz on 12/18/13.
//
//

#import "PostMetadata.h"
#import "PPConstants.h"
#import "PPTheme.h"
#import "PPPinboardMetadataCache.h"
#import "PPBadgeWrapperView.h"
#import "PPBookmarkCell.h"
#import "PPSettings.h"

#import <TTTAttributedLabel/TTTAttributedLabel.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>

@interface PostMetadata ()

+ (NSDateFormatter *)dateFormatter;
+ (NSMutableDictionary *)layoutObjectCache;
+ (NSAttributedString *)stringByTrimmingTrailingPunctuationFromAttributedString:(NSAttributedString *)string offset:(NSInteger *)offset;

@end

@implementation PostMetadata

+ (NSMutableDictionary *)layoutObjectCache {
    static dispatch_once_t onceToken;
    static NSMutableDictionary *objectCache;
    dispatch_once(&onceToken, ^{
        objectCache = [NSMutableDictionary dictionary];
    });
    return objectCache;
}

+ (NSDateFormatter *)dateFormatter {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLocale *locale = [NSLocale currentLocale];
        formatter = [[NSDateFormatter alloc] init];
        formatter.locale = locale;
        formatter.dateStyle = NSDateFormatterShortStyle;
    });
    return formatter;
}

+ (PostMetadata *)metadataForPost:(NSDictionary *)post
                       compressed:(BOOL)compressed
                            width:(CGFloat)width
                tagsWithFrequency:(NSDictionary *)tagsWithFrequency {
    return [PostMetadata metadataForPost:post
                              compressed:compressed
                                   width:width
                       tagsWithFrequency:tagsWithFrequency
                                   cache:YES];
}

+ (PostMetadata *)metadataForPost:(NSDictionary *)post
                       compressed:(BOOL)compressed
                            width:(CGFloat)width
                tagsWithFrequency:(NSDictionary *)tagsWithFrequency
                            cache:(BOOL)cache {
    BOOL read;
    if (post[@"unread"]) {
        read = ![post[@"unread"] boolValue];
    }
    else {
        read = NO;
    }

    BOOL dimmed = [PPSettings sharedSettings].dimReadPosts && read;

    if (cache) {
        PostMetadata *result = [[PPPinboardMetadataCache sharedCache] cachedMetadataForPost:post
                                                                                 compressed:compressed
                                                                                     dimmed:dimmed
                                                                                      width:width];
        if (result) {
            return result;
        }
    }
    
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];

    NSString *title = [post[@"title"] stringByTrimmingCharactersInSet:whitespace];
    if ([title isEqualToString:@""]) {
        title = @"Untitled";
    }

    NSString *description = [post[@"description"] stringByTrimmingCharactersInSet:whitespace];

    NSString *tags = post[@"tags"];

    NSRange titleRange = NSMakeRange(0, title.length);
    
    NSURL *linkUrl = [NSURL URLWithString:post[@"url"]];
    NSString *linkHost = [linkUrl host];
    if ([linkHost hasPrefix:@"www."]) {
        linkHost = [linkHost stringByReplacingCharactersInRange:NSMakeRange(0, 4) withString:@""];
    }

    BOOL showDateByDescription = NO;
    if (post[@"created_at"]) {
        NSString *date = [[self dateFormatter] stringFromDate:post[@"created_at"]];

        if (showDateByDescription) {
            if ([description isEqualToString:emptyString]) {
                description = date;
            }
            else {
                description = [NSString stringWithFormat:@"%@ · %@", date, description];
            }
        }
        else {
            linkHost = [NSString stringWithFormat:@"%@ · %@", date, linkHost];
        }
    }

    NSRange linkRange = NSMakeRange(titleRange.location + titleRange.length + 1, linkHost.length);

    NSRange descriptionRange;
    if ([description isEqualToString:emptyString]) {
        descriptionRange = NSMakeRange(NSNotFound, 0);
    }
    else {
        descriptionRange = NSMakeRange(linkRange.location + linkRange.length + 1, description.length);
    }

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.paragraphSpacing = 0;
    paragraphStyle.lineHeightMultiple = 1;
    
    NSMutableParagraphStyle *defaultParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    defaultParagraphStyle.paragraphSpacingBefore = 0;
    defaultParagraphStyle.headIndent = 0;
    defaultParagraphStyle.tailIndent = 0;
    defaultParagraphStyle.lineHeightMultiple = 1;
    defaultParagraphStyle.hyphenationFactor = 0;
    defaultParagraphStyle.lineBreakMode = NSLineBreakByWordWrapping;

    NSMutableDictionary *linkAttributes = [@{NSFontAttributeName: [PPTheme urlFont],
                                             NSParagraphStyleAttributeName: paragraphStyle } mutableCopy];
    
    NSMutableDictionary *titleAttributes = [@{NSFontAttributeName: [PPTheme titleFont],
                                              NSParagraphStyleAttributeName: defaultParagraphStyle } mutableCopy];

    NSMutableDictionary *descriptionAttributes = [@{NSFontAttributeName: [PPTheme descriptionFont],
                                                    NSParagraphStyleAttributeName: defaultParagraphStyle} mutableCopy];

    if (dimmed) {
        titleAttributes[NSForegroundColorAttributeName] = HEX(0xb3b3b3ff);
        linkAttributes[NSForegroundColorAttributeName] = HEX(0xcdcdcdff);
        descriptionAttributes[NSForegroundColorAttributeName] = HEX(0x96989Dff);
    }
    else {
        titleAttributes[NSForegroundColorAttributeName] = HEX(0x000000ff);
        linkAttributes[NSForegroundColorAttributeName] = HEX(0xb4b6b9ff);
        descriptionAttributes[NSForegroundColorAttributeName] = HEX(0x585858ff);
    }
    
    if (!title) {
        title = @"";
    }
    
    if (!linkHost) {
        linkHost = @"";
    }
    
    if (!description) {
        description = @"";
    }

    NSAttributedString *titleString = [[NSAttributedString alloc] initWithString:title attributes:titleAttributes];
    NSMutableAttributedString *linkString = [[NSMutableAttributedString alloc] initWithString:linkHost attributes:linkAttributes];
    NSAttributedString *descriptionString = [[NSAttributedString alloc] initWithString:description attributes:descriptionAttributes];
    
    CGSize titleSize;
    CGSize linkSize;
    CGSize descriptionSize;
    CGSize constraintSize = CGSizeMake(width - 20, CGFLOAT_MAX);

    // Calculate our shorter strings if we're compressed
    // We use TTTAttributedLabel's method here because it sizes strings a tiny bit differently than NSAttributedString does
    if (compressed) {
        titleSize = [TTTAttributedLabel sizeThatFitsAttributedString:titleString
                                                     withConstraints:constraintSize
                                              limitedToNumberOfLines:1];
        linkSize = [TTTAttributedLabel sizeThatFitsAttributedString:linkString
                                                    withConstraints:constraintSize
                                             limitedToNumberOfLines:1];
        descriptionSize = [TTTAttributedLabel sizeThatFitsAttributedString:descriptionString
                                                           withConstraints:constraintSize
                                                    limitedToNumberOfLines:2];
    }
    else {
        titleSize = [TTTAttributedLabel sizeThatFitsAttributedString:titleString
                                                     withConstraints:constraintSize
                                              limitedToNumberOfLines:0];
        linkSize = [TTTAttributedLabel sizeThatFitsAttributedString:linkString
                                                    withConstraints:constraintSize
                                             limitedToNumberOfLines:1];
        descriptionSize = [TTTAttributedLabel sizeThatFitsAttributedString:descriptionString
                                                           withConstraints:constraintSize
                                                    limitedToNumberOfLines:0];
    }

    NSMutableArray *badges = [NSMutableArray array];

    UIColor *privateColor;
    UIColor *starredColor;
    UIColor *offlineColor;
    if (dimmed) {
        privateColor = HEX(0xddddddff);
        starredColor = HEX(0xddddddff);
        offlineColor = HEX(0xddddddff);
    }
    else {
        privateColor = HEX(0xfdbb6dff);
        starredColor = HEX(0xf0b2f7ff);
        offlineColor = HEX(0x30A1C1FF);
    }

    PPSettings *settings = [PPSettings sharedSettings];
    if (post[@"private"] && !settings.hidePrivateLock) {
        if ([post[@"private"] boolValue]) {
            [badges addObject:@{ @"type": @"image", @"image": @"badge-private", @"options": @{ PPBadgeNormalBackgroundColor: privateColor } }];
        }
    }
    
    if (post[@"starred"]) {
        if ([post[@"starred"] boolValue]) {
            [badges addObject:@{ @"type": @"image", @"image": @"badge-favorite", @"options": @{ PPBadgeNormalBackgroundColor: starredColor } }];
        }
    }

    if (post[@"offline"]) {
        if ([post[@"offline"] boolValue]) {
            [badges addObject:@{ @"type": @"image", @"image": @"badge-cloud", @"options": @{ PPBadgeNormalBackgroundColor: offlineColor } }];
        }
    }

    __block CGFloat badgeHeight = 0;
    if (tags && ![tags isEqualToString:emptyString]) {
        // Order tags in the badges by frequency
        NSMutableArray *tagList = [[tags componentsSeparatedByString:@" "] mutableCopy];

        if (tagsWithFrequency) {
            [tagList sortUsingComparator:^NSComparisonResult(NSString *first, NSString *second) {
                return tagsWithFrequency[first] > tagsWithFrequency[second];
            }];
        }
        
        BOOL lightOnDark = YES;
        for (NSString *tag in tagList) {
            NSMutableDictionary *options = [NSMutableDictionary dictionary];
            if ([tag hasPrefix:@"via:"]) {
                if (lightOnDark) {
                    options[PPBadgeNormalBackgroundColor] = HEX(0x6EBBCCFF);
                }
                else {
                    options[PPBadgeNormalBackgroundColor] = HEX(0xECECECFF);
                    options[PPBadgeFontColor] = HEX(0x444444FF);
                }
            }

            if (dimmed) {
                options[PPBadgeNormalBackgroundColor] = HEX(0xDDDDDDFF);
            }

            [badges addObject:@{@"type": @"tag", @"tag": tag, @"options": options}];
        }
    }
    
    if (badges.count > 0) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSMutableDictionary *options = [NSMutableDictionary dictionary];
            options[PPBadgeFontSize] = @([PPTheme badgeFontSize]);
            if (dimmed) {
                options[PPBadgeNormalBackgroundColor] = HEX(0xDDDDDDFF);
            }

            PPBadgeWrapperView *badgeWrapperView = [[PPBadgeWrapperView alloc] initWithBadges:badges
                                                                                      options:options
                                                                                   compressed:compressed];
            [badgeWrapperView layoutIfNeeded];
            badgeHeight = [badgeWrapperView calculateHeightForWidth:constraintSize.width];
        });
    }

    PostMetadata *metadata = [[PostMetadata alloc] init];
    metadata.titleHeight = titleSize.height;
    metadata.descriptionHeight = descriptionSize.height;
    metadata.badgeHeight = badgeHeight;
    metadata.linkHeight = linkSize.height;
    metadata.height = @(titleSize.height + linkSize.height + descriptionSize.height + badgeHeight + 16);
    metadata.titleString = titleString;
    metadata.descriptionString = descriptionString;
    metadata.linkString = linkString;
    metadata.badges = badges;

    if (cache) {
        [[PPPinboardMetadataCache sharedCache] cacheMetadata:metadata forPost:post compressed:compressed dimmed:dimmed width:width];
    }
    return metadata;
}

+ (NSAttributedString *)stringByTrimmingTrailingPunctuationFromAttributedString:(NSAttributedString *)string offset:(NSInteger *)offset {
    NSRange punctuationRange = [string.string rangeOfCharacterFromSet:[NSCharacterSet punctuationCharacterSet] options:NSBackwardsSearch];
    if (punctuationRange.location != NSNotFound && (punctuationRange.location + punctuationRange.length) >= string.length) {
        *offset += punctuationRange.location - string.length;
        return [[NSAttributedString alloc] initWithAttributedString:[string attributedSubstringFromRange:NSMakeRange(0, punctuationRange.location)]];
    }
    
    return string;
}

@end
