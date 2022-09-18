#import <Foundation/Foundation.h>

#import "HSBeaconAttachment.h"

@interface HSBeaconAttachmentProgressObserver: NSObject

@property HSBeaconAttachment *attachment;
@property UITableView *table;
@property NSURLSessionTask *task;

-(instancetype)initWithAttachment: (HSBeaconAttachment *)attachment table: (UITableView *)table;

-(void)observeTask: (NSURLSessionTask *)task;

-(void)stopObserving;

@end
