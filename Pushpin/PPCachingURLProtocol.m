//
//  PPCachingURLProtocol.m
//  Pushpin
//
//  Created by Dan Loewenherz on 11/3/14.
//  Copyright (c) 2014 Lionheart Software. All rights reserved.
//

#import "PPCachingURLProtocol.h"
#import "PPAppDelegate.h"

static NSString *PPCachingEnabledKey = @"PPCachingEnabled";

@interface PPCachingURLProtocol ()

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSURLResponse *response;

- (void)reset;
- (NSURLRequest *)canonicalRequest;

@end

@implementation PPCachingURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if ([NSURLProtocol propertyForKey:PPCachingEnabledKey inRequest:request] == nil) {
        if ([request.URL.host rangeOfString:@"api.pinboard.in"].location != NSNotFound) {
            return NO;
        }
        if ([request.URL.host rangeOfString:@"feeds.pinboard.in"].location != NSNotFound) {
            return NO;
        }
        else if ([request allHTTPHeaderFields] == nil) {
            return YES;
        }
        return [[request valueForHTTPHeaderField:@"User-Agent"] containsString:@"AppleWebKit"];
    }

    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (NSCachedURLResponse *)cachedResponseByFollowingRedirects:(NSURLRequest *)request {
    NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
    NSHTTPURLResponse *HTTPURLResponse = (NSHTTPURLResponse *)cachedResponse.response;
    
    if ([@[@301, @302, @303, @307, @308] containsObject:@(HTTPURLResponse.statusCode)]) {
        NSString *redirectedURL = HTTPURLResponse.allHeaderFields[@"Location"];
        if (redirectedURL.length > 0) {
            NSMutableURLRequest *redirectedRequest = request.mutableCopy;
            redirectedRequest.URL = [NSURL URLWithString:redirectedURL];
            return [self cachedResponseByFollowingRedirects:redirectedRequest];
        }
        else {
            return cachedResponse;
        }
    }
    return cachedResponse;
}

- (void)startLoading {
    NSCachedURLResponse *cachedResponse = [self cachedResponseByFollowingRedirects:self.canonicalRequest];
    if (cachedResponse) {
        [self.client URLProtocol:self didReceiveResponse:cachedResponse.response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [self.client URLProtocol:self didLoadData:cachedResponse.data];
        [self.client URLProtocolDidFinishLoading:self];
    }
#if FORCE_OFFLINE
    else {
        [self.client URLProtocol:self didFailWithError:[NSError errorWithDomain:PPErrorDomain code:0 userInfo:nil]];
    }
#else
    else {
        self.data = [NSMutableData data];

        NSMutableURLRequest *newRequest = [self.request mutableCopy];
        [NSURLProtocol setProperty:@(YES) forKey:PPCachingEnabledKey inRequest:newRequest];
        self.connection = [[NSURLConnection alloc] initWithRequest:newRequest delegate:self startImmediately:YES];
    }
#endif
}

- (void)stopLoading {
    [self.connection cancel];
    [self reset];
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
    [self.data appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
    [self reset];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.response = response;
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.client URLProtocolDidFinishLoading:self];
    
    NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:self.response data:self.data];
    [[NSURLCache sharedURLCache] storeCachedResponse:cachedResponse forRequest:self.canonicalRequest];
    
    [self reset];
}

#pragma mark - Others

- (void)reset {
    self.data = [NSMutableData data];
    self.connection = nil;
    self.response = nil;
}

- (NSURLRequest *)canonicalRequest {
    NSURLRequest *request = [NSURLRequest requestWithURL:self.request.URL];
    return request;
}

@end
