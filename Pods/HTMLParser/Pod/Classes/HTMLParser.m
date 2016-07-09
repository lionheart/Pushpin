//
//  GeolHTMLParser.m
//  Geolive 1.0
//
//  Created by Nick Blackwell on 2012-11-14.
//  Copyright (c) 2012 Nicholas Blackwell. All rights reserved.
//

#import "HTMLParser.h"

@implementation HTMLParser


+(NSString *) StripHTML:(NSString *)html{

    if(html==nil)return @"";
    NSRange r;
    NSString *s = [html copy];
    while ((r = [s rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound){
        s = [s stringByReplacingCharactersInRange:r withString:@""];
    }
    return s;
    
}


+(NSArray *)ParseImageUrls:(NSString *)html{
    NSMutableArray *images=[[NSMutableArray alloc] init];
    if(html==nil)return [NSArray array];
    NSString *s=[html copy];
    NSString *t=[s lowercaseString];
    NSRange r;
    while((r=[t rangeOfString:@"<img"]).location!=NSNotFound){
       // NSLog(s);
        s=[s substringFromIndex:r.location+4];
        long start=[s rangeOfString:@"src"].location;
        if(start==NSNotFound)continue;
        s=[s substringFromIndex:start+3];
        start=[s rangeOfString:@"\""].location;
        if(start==NSNotFound)continue;
        s=[s substringFromIndex:start+1];
        long end=[s rangeOfString:@"\""].location;
        if(end==NSNotFound)continue;
        
        NSString * img=[s substringToIndex:end];
        [images addObject:img];
        t=[s lowercaseString];
    }

    return images;

}

@end
