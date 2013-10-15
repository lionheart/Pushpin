//
//  PPReadLaterActivity.h
//  Pushpin
//
//  Created by Andy Muldowney on 10/15/13.
//
//

#import <UIKit/UIKit.h>

@interface PPReadLaterActivity : UIActivity

@property (nonatomic) NSUInteger service;
@property (nonatomic, retain) NSString *serviceName;
@property (nonatomic, retain) id delegate;

- (id)initWithService:(NSUInteger)type;

@end
