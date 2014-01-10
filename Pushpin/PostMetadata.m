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
#import "AppDelegate.h"
#import "PPPinboardMetadataCache.h"
#import "PPBadgeWrapperView.h"
#import "PPBookmarkCell.h"

#import <TTTAttributedLabel/TTTAttributedLabel.h>
#import <LHSCategoryCollection/UIApplication+LHSAdditions.h>

@interface PPBookmarkLayoutItem : NSObject <NSCopying>

@property (nonatomic, strong) NSTextContainer *titleTextContainer;
@property (nonatomic, strong) NSTextContainer *linkTextContainer;
@property (nonatomic, strong) NSTextContainer *descriptionTextContainer;

@property (nonatomic, strong) NSLayoutManager *titleLayoutManager;
@property (nonatomic, strong) NSLayoutManager *linkLayoutManager;
@property (nonatomic, strong) NSLayoutManager *descriptionLayoutManager;

@property (nonatomic, strong) NSTextStorage *titleTextStorage;
@property (nonatomic, strong) NSTextStorage *linkTextStorage;
@property (nonatomic, strong) NSTextStorage *descriptionTextStorage;

+ (PPBookmarkLayoutItem *)layoutItemForWidth:(CGFloat)width;
- (instancetype)initWithWidth:(CGFloat)width;

@end

@implementation PPBookmarkLayoutItem

+ (PPBookmarkLayoutItem *)layoutItemForWidth:(CGFloat)width {
    return [[PPBookmarkLayoutItem alloc] initWithWidth:width];
}

- (instancetype)initWithWidth:(CGFloat)width {
    self = [super init];
    if (self) {
        NSDictionary *titleAttributes = @{NSFontAttributeName: [PPTheme titleFont]};
        NSDictionary *descriptionAttributes = @{NSFontAttributeName: [PPTheme descriptionFont]};
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.paragraphSpacingBefore = 3;
        paragraphStyle.paragraphSpacing = 0;
        paragraphStyle.lineHeightMultiple = 0.7;
        NSDictionary *linkAttributes = @{NSFontAttributeName: [PPTheme urlFont],
                                         NSParagraphStyleAttributeName: paragraphStyle
                                         };

        // Calculate ellipsis size for each element
        CGSize ellipsisSizeTitle = [ellipsis sizeWithAttributes:titleAttributes];
        CGSize ellipsisSizeLink = [ellipsis sizeWithAttributes:linkAttributes];
        CGSize ellipsisSizeDescription = [ellipsis sizeWithAttributes:descriptionAttributes];

        self.titleTextContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(width - ellipsisSizeTitle.width - 20, CGFLOAT_MAX)];
        self.linkTextContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(width - ellipsisSizeLink.width - 20, CGFLOAT_MAX)];
        self.descriptionTextContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(width - ellipsisSizeDescription.width - 20, CGFLOAT_MAX)];
        
        self.titleLayoutManager = [[NSLayoutManager alloc] init];
        self.titleLayoutManager.hyphenationFactor = 0;
        [self.titleLayoutManager addTextContainer:self.titleTextContainer];
        
        self.linkLayoutManager = [[NSLayoutManager alloc] init];
        self.linkLayoutManager.hyphenationFactor = 0;
        [self.linkLayoutManager addTextContainer:self.linkTextContainer];

        self.descriptionLayoutManager = [[NSLayoutManager alloc] init];
        self.descriptionLayoutManager.hyphenationFactor = 0;
        [self.descriptionLayoutManager addTextContainer:self.descriptionTextContainer];
        
        self.titleTextStorage = [[NSTextStorage alloc] initWithString:emptyString];
        [self.titleTextStorage addLayoutManager:self.titleLayoutManager];
        
        self.linkTextStorage = [[NSTextStorage alloc] initWithString:emptyString];
        [self.linkTextStorage addLayoutManager:self.linkLayoutManager];
        
        self.descriptionTextStorage = [[NSTextStorage alloc] initWithString:emptyString];
        [self.descriptionTextStorage addLayoutManager:self.descriptionLayoutManager];
        
        [self.titleLayoutManager glyphRangeForTextContainer:self.titleTextContainer];
        [self.linkLayoutManager glyphRangeForTextContainer:self.linkTextContainer];
        [self.descriptionLayoutManager glyphRangeForTextContainer:self.descriptionTextContainer];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    PPBookmarkLayoutItem *copy = [[[self class] alloc] init];
    if (copy) {
        copy.titleTextContainer = self.titleTextContainer;
        copy.linkTextContainer = self.linkTextContainer;
        copy.descriptionTextContainer = self.descriptionTextContainer;
        copy.titleLayoutManager = self.titleLayoutManager;
        copy.linkLayoutManager = self.linkLayoutManager;
        copy.descriptionLayoutManager = self.descriptionLayoutManager;
        copy.titleTextStorage = self.titleTextStorage;
        copy.linkTextStorage = self.linkTextStorage;
        copy.descriptionTextStorage = self.descriptionTextStorage;
    }
    return copy;
}

@end

@interface PostMetadata ()

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

+ (PostMetadata *)metadataForPost:(NSDictionary *)post
                       compressed:(BOOL)compressed
                            width:(CGFloat)width
                tagsWithFrequency:(NSDictionary *)tagsWithFrequency {
    BOOL read;
    if (post[@"unread"]) {
        read = ![post[@"unread"] boolValue];
    }
    else {
        read = NO;
    }

    BOOL dimmed = [AppDelegate sharedDelegate].dimReadPosts && read;

    PostMetadata *result = [[PPPinboardMetadataCache sharedCache] cachedMetadataForPost:post compressed:compressed dimmed:dimmed width:width];
    if (result) {
        return result;
    }
    
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];

    NSString *title = [post[@"title"] stringByTrimmingCharactersInSet:whitespace];
    if ([title isEqualToString:@""]) {
        title = @"Untitled";
    }

    NSString *description = [post[@"description"] stringByTrimmingCharactersInSet:whitespace];
    NSString *tags = post[@"tags"];
    
    NSMutableString *content = [NSMutableString stringWithFormat:@"%@", title];
    NSRange titleRange = NSMakeRange(0, title.length);
    
    NSURL *linkUrl = [NSURL URLWithString:post[@"url"]];
    NSString *linkHost = [linkUrl host];
    if ([linkHost hasPrefix:@"www."]) {
        linkHost = [linkHost stringByReplacingCharactersInRange:NSMakeRange(0, 4) withString:@""];
    }

    NSRange linkRange = NSMakeRange(titleRange.location + titleRange.length + 1, linkHost.length);
    [content appendString:[NSString stringWithFormat:@"\n%@", linkHost]];
    
    NSRange descriptionRange;
    if ([description isEqualToString:emptyString]) {
        descriptionRange = NSMakeRange(NSNotFound, 0);
    }
    else {
        descriptionRange = NSMakeRange(linkRange.location + linkRange.length + 1, description.length);
        [content appendString:[NSString stringWithFormat:@"\n%@", description]];
    }

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.paragraphSpacingBefore = 3;
    paragraphStyle.paragraphSpacing = 0;
    paragraphStyle.lineHeightMultiple = 0.7;
    
    NSMutableParagraphStyle *defaultParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    defaultParagraphStyle.paragraphSpacingBefore = 0;
    defaultParagraphStyle.headIndent = 0;
    defaultParagraphStyle.tailIndent = 0;
    defaultParagraphStyle.lineHeightMultiple = 1;
    defaultParagraphStyle.hyphenationFactor = 0;
    defaultParagraphStyle.lineSpacing = 1;
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

    NSAttributedString *titleString = [[NSAttributedString alloc] initWithString:title attributes:titleAttributes];
    NSAttributedString *linkString = [[NSAttributedString alloc] initWithString:linkHost attributes:linkAttributes];
    NSAttributedString *descriptionString = [[NSAttributedString alloc] initWithString:description attributes:descriptionAttributes];
    
    CGSize titleSize;
    CGSize linkSize;
    CGSize descriptionSize;
    CGSize constraintSize = CGSizeMake(width - 22, CGFLOAT_MAX);

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
    if (dimmed) {
        privateColor = HEX(0xddddddff);
        starredColor = HEX(0xddddddff);
    }
    else {
        privateColor = HEX(0xfdbb6dff);
        starredColor = HEX(0xf0b2f7ff);
    }

    if (post[@"private"]) {
        if ([post[@"private"] boolValue]) {
            [badges addObject:@{ @"type": @"image", @"image": @"badge-private", @"options": @{ PPBadgeNormalBackgroundColor: privateColor } }];
        }
    }
    
    if (post[@"starred"]) {
        if ([post[@"starred"] boolValue]) {
            [badges addObject:@{ @"type": @"image", @"image": @"badge-favorite", @"options": @{ PPBadgeNormalBackgroundColor: starredColor } }];
        }
    }

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
            else {
                if (dimmed) {
                    options[PPBadgeNormalBackgroundColor] = HEX(0xDDDDDDFF);
                }
            }
            
            [badges addObject:@{@"type": @"tag", @"tag": tag, @"options": options}];
        }
    }

    __block NSNumber *height;
    dispatch_sync(dispatch_get_main_queue(), ^{
        PPBadgeWrapperView *badgeWrapperView = [[PPBadgeWrapperView alloc] initWithBadges:badges options:@{ PPBadgeFontSize: @([PPTheme badgeFontSize]) } compressed:compressed];
        CGFloat badgeHeight = [badgeWrapperView calculateHeightForWidth:constraintSize.width];
        height = @(titleSize.height + linkSize.height + descriptionSize.height + badgeHeight + 10);
    });

    PostMetadata *metadata = [[PostMetadata alloc] init];
    metadata.height = height;
    metadata.titleString = titleString;
    metadata.descriptionString = descriptionString;
    metadata.linkString = linkString;
    metadata.badges = badges;

    [[PPPinboardMetadataCache sharedCache] cacheMetadata:metadata forPost:post compressed:compressed dimmed:dimmed width:width];
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
