//
//  MixpanelDummy.m
//  Pushpin
//
//  Created by Dan Loewenherz on 2/3/14.
//
//

#import "MixpanelProxy.h"

@implementation MixpanelPeopleProxy

- (void)set:(NSString *)name to:(NSNumber *)amount {

}

@end

@implementation MixpanelProxy

+ (MixpanelProxy *)sharedInstance {
    static MixpanelProxy *proxy;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxy = [[MixpanelProxy alloc] init];
    });
    return proxy;
}

+ (MixpanelProxy *)sharedInstanceWithToken:(NSString *)token {
    return [MixpanelProxy sharedInstance];
}

- (void)identify:(NSString *)identification {

}

- (void)track:(NSString *)event {

}

- (void)track:(NSString *)event properties:(NSDictionary *)properties {

}

@end
