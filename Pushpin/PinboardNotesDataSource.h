//
//  PinboardNotesDataSource.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/28/13.
//
//

@import Foundation;

#import "GenericPostViewController.h"

@interface PinboardNotesDataSource : NSObject <GenericPostDataSource>

@property (nonatomic, strong) NSMutableArray *posts;
@property (nonatomic, strong) NSMutableArray *metadata;

- (void)metadataForNote:(NSDictionary *)not callback:(void (^)(NSAttributedString *string, NSNumber *height))callback;

@end
