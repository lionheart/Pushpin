//
//  Pinboard.m
//  ASPinboard
//
//  Created by Daniel Loewenherz on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Pinboard.h"

@implementation Pinboard

@synthesize response;
@synthesize datetime;
@synthesize username;
@synthesize bookmark;
@synthesize data = _data;
@synthesize delegate = _delegate;
@synthesize parser;
@synthesize endpoint;

+ (Pinboard *)pinboardWithEndpoint:(NSString *)endpoint delegate:(id<PinboardDelegate>)delegate {
    Pinboard *pinboard = [[Pinboard alloc] init];
    pinboard.endpoint = endpoint;
    pinboard.delegate = delegate;
    return pinboard;
}

- (void)parse {
    NSString* path = [[NSBundle mainBundle] pathForResource:@"recent" 
                                                     ofType:@"xml"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    [self parseWithData:data];
    return;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.pinboard.in/v1/%@", self.endpoint]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.data = [NSMutableData dataWithLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSURLCredential *credential = [NSURLCredential credentialWithUser:@"dlo"
                                                             password:@"papa c6h12o5a 0P"
                                                          persistence:NSURLCredentialPersistenceForSession];
    [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self parseWithData:self.data];
}

- (void)parseWithData:(NSData *)data {
    self.parser = [[NSXMLParser alloc] initWithData:data];
    self.parser.delegate = self;
    self.parser.shouldProcessNamespaces = YES;
    self.parser.shouldReportNamespacePrefixes = NO;
    self.parser.shouldResolveExternalEntities = NO;
    [self.parser parse];
}

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    self.response = [NSMutableArray array];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    [self.delegate pinboard:self didReceiveResponse:self.response];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {

    if ([elementName isEqualToString:@"post"]) {
        [self.response addObject:[Bookmark bookmarkWithAttributes:attributeDict]];
    }
    else if ([elementName isEqualToString:@"tag"]) {
        
    }
}

@end
