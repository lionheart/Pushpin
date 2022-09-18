#import <Foundation/Foundation.h>

@interface HSBeaconCustomFieldDefinition : NSObject

-(instancetype)initWithDictionary: (NSDictionary *)dictionary;

@property (readonly, nonatomic) NSNumber *fieldId;

@property (readonly, nonatomic) NSString *type;

@property (readonly, nonatomic) NSString *name;

@property (readonly, nonatomic) NSArray<NSDictionary *> *options;

@end
