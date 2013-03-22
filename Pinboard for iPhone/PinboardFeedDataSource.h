//
//  PinboardFeedDataSource.h
//  Pushpin for Pinboard
//
//  Created by Dan Loewenherz on 3/22/13.
//
//

#import <Foundation/Foundation.h>
#import "GenericPostViewController.h"

@interface PinboardFeedDataSource : NSObject <GenericPostDataSource>

@property (nonatomic, strong) NSMutableArray *posts;
@property (nonatomic, strong) NSString *endpoint;
@property (nonatomic, strong) NSURL *endpointURL;

- (id)initWithEndpoint:(NSString *)endpoint;
+ (PinboardFeedDataSource *)dataSourceWithEndpoint:(NSString *)endpoint;

@end
