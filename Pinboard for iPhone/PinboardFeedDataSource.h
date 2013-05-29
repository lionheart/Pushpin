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
@property (nonatomic, strong) NSArray *components;

- (NSURL *)url;
- (id)initWithComponents:(NSArray *)components;
+ (PinboardFeedDataSource *)dataSourceWithComponents:(NSArray *)components;

@end
