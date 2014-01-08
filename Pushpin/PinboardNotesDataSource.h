//
//  PinboardNotesDataSource.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/28/13.
//
//

#import <Foundation/Foundation.h>
#import "GenericPostViewController.h"

@interface PinboardNotesDataSource : NSObject <GenericPostDataSource>

@property (nonatomic, strong) NSArray *notes;
@property (nonatomic, strong) NSArray *strings;
@property (nonatomic, strong) NSArray *heights;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSLocale *locale;

- (void)metadataForNote:(NSDictionary *)note callback:(void (^)(NSAttributedString *string, NSNumber *height))callback;

@end
