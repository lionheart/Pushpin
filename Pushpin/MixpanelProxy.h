//
//  MixpanelDummy.h
//  Pushpin
//
//  Created by Dan Loewenherz on 2/3/14.
//
//

#import <Foundation/Foundation.h>

@interface MixpanelPeopleProxy : NSObject

- (void)set:(NSString *)name to:(id)amount;

@end

@interface MixpanelProxy : NSObject

@property (nonatomic, strong) MixpanelPeopleProxy *people;

+ (MixpanelProxy *)sharedInstance;
+ (MixpanelProxy *)sharedInstanceWithToken:(NSString *)token;

- (void)identify:(NSString *)identification;
- (void)track:(NSString *)event;
- (void)track:(NSString *)event properties:(NSDictionary *)properties;

@end
