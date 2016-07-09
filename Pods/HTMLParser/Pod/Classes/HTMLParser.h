//
//  GeolHTMLParser.h
//  Geolive 1.0
//
//  Created by Nick Blackwell on 2012-11-14.
//  Copyright (c) 2012 Nicholas Blackwell. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HTMLParser : NSObject
+(NSString *) StripHTML:(NSString *)html;
+(NSArray *) ParseImageUrls:(NSString *)html;

@end
