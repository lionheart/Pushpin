#import <UIKit/UIKit.h>
#import "HSWebView.h"
#import "HSBeaconContext.h"
#import "HSBeaconConversationThread.h"

@interface HSBeaconConversationDetailsWebView : HSWebView

@property (nonatomic) HSBeaconContext *beaconContext;

- (void)setup;

- (void)addHeader:(NSString *)header;

- (void)addThreads:(NSArray <HSBeaconConversationThread *> *)threads;

- (void)scrollToLast;

- (void)clearThreads;

- (void)showWaiting:(NSString *)recievedText waitingText:(NSString *)waitingText;

@end
