//
//  PPReadLaterActivity.h
//  Pushpin
//
//  Created by Andy Muldowney on 10/15/13.
//
//

#import <UIKit/UIKit.h>
#import "PPConstants.h"

@interface PPReadLaterActivity : UIActivity

@property (nonatomic) PPReadLaterType service;
@property (nonatomic, retain) NSString *serviceName;
@property (nonatomic, retain) id delegate;

- (id)initWithService:(PPReadLaterType)type;

@end
