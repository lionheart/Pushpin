//
//  Pinboard.h
//  ASPinboard
//
//  Created by Daniel Loewenherz on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Bookmark;
@protocol PinboardDelegate;

@interface Pinboard : NSObject <NSXMLParserDelegate, NSURLConnectionDataDelegate, NSURLConnectionDelegate, NSURLConnectionDownloadDelegate>

@property (nonatomic, retain) NSMutableData *data;
@property (nonatomic, retain) NSString *endpoint;
@property (nonatomic, retain) NSXMLParser *parser;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *datetime;
@property (nonatomic, retain) NSMutableArray *response;
@property (nonatomic, retain) id <PinboardDelegate> delegate;

+ (Pinboard *)pinboardWithEndpoint:(NSString *)endpoint delegate:(id <PinboardDelegate>)delegate;
- (void)parse;
- (void)add:(Bookmark *)bookmark;
- (void)parseWithData:(NSData *)data;

@end

@protocol PinboardDelegate <NSObject>

- (void)pinboard:(Pinboard *)pinboard didReceiveResponse:(NSMutableArray *)response;

@end