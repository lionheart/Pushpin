#import <UIKit/UIKit.h>
#import <HSWebView.h>
#import <HSBeaconContext.h>
#import <HSBeaconConversationThread.h>

NS_ASSUME_NONNULL_BEGIN

@interface HSBeaconConversationDetailsWebView : HSWebView

extern NSString * _Nonnull const ShowMorePath;

@property (nonatomic) HSBeaconContext *beaconContext;

- (void)setup;

- (void)addHeader:(NSString *)header;

- (void)addThreads:(NSArray <HSBeaconConversationThread *> *)threads oldestThread:(HSBeaconConversationThread *_Nullable)oldestThread;

- (void)scrollToLast;

- (void)clearThreads;

- (void)showWaiting:(NSString *)receivedText waitingText:(NSString *)waitingText;

@end

NS_ASSUME_NONNULL_END
