//
//  PinboardClient.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PinboardClient.h"
#import "AFJSONRequestOperation.h"
#import "AppDelegate.h"

@implementation PinboardClient

+ (PinboardClient *)sharedClient {
    static PinboardClient *_sharedClient = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:API_ENDPOINT]];
    });
    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [self setDefaultHeader:@"Accept"
                     value:@"text/plain"];
    [self setAuthorizationHeaderWithUsername:delegate.username
                                    password:delegate.password];
    
    return self;
}

- (void)path:(NSString *)path
  parameters:(NSDictionary *)parameters 
     success:(void (^)(NSURLRequest *, NSHTTPURLResponse *, id))success
     failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON))failure {
    NSMutableURLRequest *request = [self requestWithMethod:@"GET"
                                                      path:path 
                                                parameters:parameters];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request 
                                                                                        success:success
                                                                                        failure:failure];
    [operation start];
}

- (void)path:(NSString *)path
     success:(void (^)(NSURLRequest *, NSHTTPURLResponse *, id))success
     failure:(void (^)(NSURLRequest *, NSHTTPURLResponse *, NSError *, id))failure {
    NSMutableURLRequest *request = [self requestWithMethod:@"GET"
                                                      path:path 
                                                parameters:nil];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request 
                                                                                        success:success
                                                                                        failure:failure];
    [operation start];
}

@end
