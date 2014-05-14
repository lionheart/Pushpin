//
//  PinboardNotesDataSource.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/28/13.
//
//

@import Foundation;

#import "PPGenericPostViewController.h"

@interface PPPinboardNotesDataSource : NSObject <PPDataSource>

@property (nonatomic, strong) NSMutableArray *posts;
@property (nonatomic, strong) NSMutableArray *metadata;

- (void)metadataForNote:(NSDictionary *)not callback:(void (^)(NSAttributedString *string, NSNumber *height))callback;

@end
