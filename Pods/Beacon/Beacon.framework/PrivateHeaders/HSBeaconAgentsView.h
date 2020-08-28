#import <UIKit/UIKit.h>
#import "HSView.h"
#import "HSBeaconAgent.h"

static CGFloat const DEFAULT_AGENT_SIZE = 50.0;
static CGFloat const DEFAULT_SINGLE_AGENT_SIZE = 68.0;

@interface HSBeaconAgentsView : HSView

@property (nonatomic, strong) UIColor *agentViewBackgroundColor;
@property (nonatomic, strong) UIColor *agentViewBorderColor;
@property (nonatomic, strong) UIColor *agentViewInitialsColor;
/// Whether or not the Agent image views should animate in when they're set
/// Defaults to YES
@property (nonatomic, assign) BOOL animateAgentsIn;
@property (nonatomic, assign) BOOL hideAgentsWithoutAvatars;
@property (nonatomic, assign) BOOL dropShadow;

- (void)setAgents:(NSArray<HSBeaconAgent *> *) agents agentSize:(CGFloat)agentSize;

@end
