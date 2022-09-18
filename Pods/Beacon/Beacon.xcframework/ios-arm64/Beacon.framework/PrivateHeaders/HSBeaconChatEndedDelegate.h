@protocol HSBeaconChatEndedDelegate

- (void)chatEndedWithNoAvailableAgents;
- (void)chatEndedWithRequestToViewConversationsForEmail:(NSString *)email;

@end
