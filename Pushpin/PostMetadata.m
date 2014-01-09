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

#import <TTTAttributedLabel/TTTAttributedLabel.h>
#import <LHSCategoryCollection/NSAttributedString+Attributes.h>
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
    NSRange linkRange = NSMakeRange((titleRange.location + titleRange.length) + 1, linkHost.length);
    [content appendString:[NSString stringWithFormat:@"\n%@", linkHost]];
    
    NSRange descriptionRange;
    if ([description isEqualToString:emptyString]) {
        descriptionRange = NSMakeRange(NSNotFound, 0);
    }
    else {
        descriptionRange = NSMakeRange((linkRange.location + linkRange.length) + 1, [description length]);
        [content appendString:[NSString stringWithFormat:@"\n%@", description]];
    }
    
    NSRange tagRange;
    if ([tags isEqualToString:emptyString]) {
        tagRange = NSMakeRange(NSNotFound, 0);
    }
    else {
        // Set the offset to one because of the line break between the title and tags
        NSInteger offset = 1;
        if (descriptionRange.location != NSNotFound) {
            // Another line break is included if the description isn't empty
            offset++;
        }
        tagRange = NSMakeRange(titleRange.length + descriptionRange.length + offset, tags.length);
    }
    
    NSMutableAttributedString *attributedString = [NSMutableAttributedString attributedStringWithString:content];
    
    NSDictionary *titleAttributes = @{NSFontAttributeName: [PPTheme titleFont]};
    NSDictionary *descriptionAttributes = @{NSFontAttributeName: [PPTheme descriptionFont]};
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.paragraphSpacingBefore = 3;
    paragraphStyle.paragraphSpacing = 0;
    paragraphStyle.lineHeightMultiple = 0.7;
    NSDictionary *linkAttributes = @{NSFontAttributeName: [PPTheme urlFont],
                                     NSParagraphStyleAttributeName: paragraphStyle
                                     };
    
    [attributedString addAttributes:titleAttributes range:titleRange];
    [attributedString addAttributes:descriptionAttributes range:descriptionRange];
    [attributedString addAttributes:linkAttributes range:linkRange];
    
    [attributedString addAttribute:NSForegroundColorAttributeName value:HEX(0x33353Bff) range:attributedString.fullRange];
    
    // Calculate our shorter strings if we're compressed
    if (compressed) {
        PPBookmarkLayoutItem *layout = [self layoutObjectCache][@(width)];
        if (!layout) {
            layout = [PPBookmarkLayoutItem layoutItemForWidth:width];
            [self layoutObjectCache][@(width)] = layout;
        };
        
        NSRange titleLineRange, descriptionLineRange, linkLineRange;

        // Get the compressed substrings
        NSAttributedString *titleAttributedString, *descriptionAttributedString, *linkAttributedString;
        
        titleAttributedString = [attributedString attributedSubstringFromRange:titleRange];
        [layout.titleTextStorage setAttributedString:titleAttributedString];

        // Throws _NSLayoutTreeLineFragmentRectForGlyphAtIndex invalid glyph index 0 when title is of length 0
        [layout.titleLayoutManager lineFragmentRectForGlyphAtIndex:0 effectiveRange:&titleLineRange];
        
        if (descriptionRange.location != NSNotFound) {
            descriptionAttributedString = [attributedString attributedSubstringFromRange:descriptionRange];
            [layout.descriptionTextStorage setAttributedString:descriptionAttributedString];
            
            descriptionLineRange = NSMakeRange(0, 0);
            NSUInteger index, numberOfLines, numberOfGlyphs = [layout.descriptionLayoutManager numberOfGlyphs];
            NSRange tempLineRange;
            for (numberOfLines=0, index=0; index < numberOfGlyphs; numberOfLines++){
                [layout.descriptionLayoutManager lineFragmentRectForGlyphAtIndex:index effectiveRange:&tempLineRange];
                descriptionLineRange.length += tempLineRange.length;
                if (numberOfLines >= [PPTheme maxNumberOfLinesForCompressedDescriptions] - 1) {
                    break;
                }
                index = NSMaxRange(tempLineRange);
            }
            descriptionLineRange.length = MIN(descriptionLineRange.length, descriptionAttributedString.length);
        }
        
        // Set this to hide links
        // linkRange = NSMakeRange(NSNotFound, 0);
        if (linkRange.location != NSNotFound) {
            linkAttributedString = [attributedString attributedSubstringFromRange:linkRange];
            [layout.linkTextStorage setAttributedString:linkAttributedString];
            [layout.linkLayoutManager lineFragmentRectForGlyphAtIndex:0 effectiveRange:&linkLineRange];
        }
        
        // Re-create the main string
        NSAttributedString *tempAttributedString;
        NSString *tempString;
        NSString *trimmedString;
        NSInteger characterOffset = 0;
        
        if (titleAttributedString && titleLineRange.location != NSNotFound) {
            tempString = [[titleAttributedString attributedSubstringFromRange:titleLineRange] string];
            trimmedString = [tempString stringByTrimmingCharactersInSet:whitespace];
            characterOffset = trimmedString.length - tempString.length;
            
            tempAttributedString = [[NSAttributedString alloc] initWithString:trimmedString attributes:titleAttributes];
            if (titleLineRange.length < titleRange.length) {
                tempAttributedString = [self stringByTrimmingTrailingPunctuationFromAttributedString:tempAttributedString offset:&characterOffset];
                attributedString = [NSMutableAttributedString attributedStringWithAttributedString:tempAttributedString];
                [attributedString appendAttributedString:[NSAttributedString attributedStringWithString:ellipsis]];
                characterOffset++;
            }
            else {
                attributedString = [NSMutableAttributedString attributedStringWithAttributedString:tempAttributedString];
            }
            
            [attributedString appendAttributedString:[NSAttributedString attributedStringWithString:newLine]];
            characterOffset++;
            
            titleRange = NSMakeRange(0, titleLineRange.length + characterOffset);
        }
        
        if (linkAttributedString && linkLineRange.location != NSNotFound) {
            tempString = [[[linkAttributedString attributedSubstringFromRange:linkLineRange] string] stringByTrimmingCharactersInSet:whitespace];
            trimmedString = [tempString stringByTrimmingCharactersInSet:whitespace];
            characterOffset = trimmedString.length - tempString.length;
            
            tempAttributedString = [[NSAttributedString alloc] initWithString:trimmedString attributes:linkAttributes];
            if (linkLineRange.length < linkRange.length) {
                tempAttributedString = [self stringByTrimmingTrailingPunctuationFromAttributedString:tempAttributedString offset:&characterOffset];
                [attributedString appendAttributedString:tempAttributedString];
                [attributedString appendAttributedString:[NSAttributedString attributedStringWithString:ellipsis]];
                characterOffset++;
            }
            else {
                [attributedString appendAttributedString:tempAttributedString];
            }
            
            [attributedString appendAttributedString:[NSAttributedString attributedStringWithString:newLine]];
            characterOffset++;
            
            linkRange = NSMakeRange(titleRange.length, linkLineRange.length + characterOffset);
        }
        
        if (descriptionAttributedString && descriptionLineRange.location != NSNotFound) {
            tempString = [[[descriptionAttributedString attributedSubstringFromRange:descriptionLineRange] string] stringByTrimmingCharactersInSet:whitespace];
            trimmedString = [tempString stringByTrimmingCharactersInSet:whitespace];
            characterOffset = trimmedString.length - tempString.length;
            
            tempAttributedString = [[NSAttributedString alloc] initWithString:trimmedString attributes:descriptionAttributes];
            
            if (descriptionLineRange.length < descriptionRange.length) {
                tempAttributedString = [self stringByTrimmingTrailingPunctuationFromAttributedString:tempAttributedString offset:&characterOffset];
                [attributedString appendAttributedString:tempAttributedString];
                [attributedString appendAttributedString:[NSAttributedString attributedStringWithString:ellipsis]];
                characterOffset++;
            }
            else {
                [attributedString appendAttributedString:tempAttributedString];
            }
            
            descriptionRange = NSMakeRange(titleRange.length + linkRange.length, attributedString.fullRange.length - titleRange.length - linkRange.length);
        }
    }

    if (dimmed) {
        [attributedString addAttribute:NSForegroundColorAttributeName value:HEX(0xb3b3b3ff) range:titleRange];
        [attributedString addAttribute:NSForegroundColorAttributeName value:HEX(0xcdcdcdff) range:linkRange];
        [attributedString addAttribute:NSForegroundColorAttributeName value:HEX(0x96989Dff) range:descriptionRange];
    }
    else {
        [attributedString addAttribute:NSForegroundColorAttributeName value:HEX(0x000000ff) range:titleRange];
        [attributedString addAttribute:NSForegroundColorAttributeName value:HEX(0xb4b6b9ff) range:linkRange];
        [attributedString addAttribute:NSForegroundColorAttributeName value:HEX(0x585858ff) range:descriptionRange];
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
    
    // We use TTTAttributedLabel's method here because it sizes strings a tiny bit differently than NSAttributedString does
    CGSize size = [TTTAttributedLabel sizeThatFitsAttributedString:attributedString
                                                   withConstraints:CGSizeMake(width - 20, CGFLOAT_MAX)
                                            limitedToNumberOfLines:0];
    
    __block NSNumber *height;
    dispatch_sync(dispatch_get_main_queue(), ^{
        PPBadgeWrapperView *badgeWrapperView = [[PPBadgeWrapperView alloc] initWithBadges:badges options:@{ PPBadgeFontSize: @([PPTheme badgeFontSize]) } compressed:compressed];
        height = @(size.height + [badgeWrapperView calculateHeightForWidth:(width - 20)] + 10);
    });
    
    PostMetadata *metadata = [[PostMetadata alloc] init];
    metadata.height = height;
    metadata.string = attributedString;
    metadata.badges = badges;

    [[PPPinboardMetadataCache sharedCache] cacheMetadata:metadata forPost:post compressed:compressed dimmed:dimmed width:width];
    return metadata;
}

+ (NSAttributedString *)stringByTrimmingTrailingPunctuationFromAttributedString:(NSAttributedString *)string offset:(NSInteger *)offset {
    NSRange punctuationRange = [string.string rangeOfCharacterFromSet:[NSCharacterSet punctuationCharacterSet] options:NSBackwardsSearch];
    if (punctuationRange.location != NSNotFound && (punctuationRange.location + punctuationRange.length) >= string.length) {
        *offset += punctuationRange.location - string.length;
        return [NSAttributedString attributedStringWithAttributedString:[string attributedSubstringFromRange:NSMakeRange(0, punctuationRange.location)]];
    }
    
    return string;
}

@end
