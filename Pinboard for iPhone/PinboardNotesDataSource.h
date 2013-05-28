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

@property (nonatomic, strong) NSMutableArray *notes;

@end
