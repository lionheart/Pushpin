#import <Foundation/Foundation.h>

#import <Beacon/HSBeaconAgent.h>
#import <Beacon/HSBeaconAttachment.h>
#import <Beacon/HSBeaconBaseAPIClient.h>
#import <Beacon/HSBeaconConversation.h>
#import <Beacon/HSBeaconConversationThread.h>
#import <Beacon/HSBeaconCustomFieldDefinition.h>
#import <Beacon/HSBeaconEmailMessage.h>
#import <Beacon/HSBeaconPaginatedResponse.h>
#import <Beacon/HSBeaconReplyMessage.h>
#import <Beacon/HSBeaconSecurityInfo.h>

NS_ASSUME_NONNULL_BEGIN

@interface HSBeaconMessagingAPIClient: HSBeaconBaseAPIClient

- (NSURLSessionDataTask *)registerForPushNotificationsWithVendorID:(NSString *)vendorID securityInfo:(HSBeaconSecurityInfo *)securityInfo token:(NSData *)token completion:(ErrorCompletionHandler)completion;

- (NSURLSessionDataTask *)registerForPushNotificationsWithVendorID:(NSString *)vendorID securityInfo:(HSBeaconSecurityInfo *)securityInfo token:(NSData *)token email:(nullable NSString *)email completion:(ErrorCompletionHandler)completion;

- (NSURLSessionDataTask *)subscribeToNotificationsForConversation:(NSString *)conversationID securityInfo:(HSBeaconSecurityInfo *)securityInfo completion:(ErrorCompletionHandler)completion;

- (NSURLSessionDataTask *)validateSignature:(HSBeaconSecurityInfo *)securityInfo completion:(BooleanCompletionHandler)completion;

- (NSURLSessionDataTask *)identifyUser:(HSBeaconSecurityInfo *)securityInfo completion:(BooleanCompletionHandler)completion;

- (NSURLSessionDataTask *)sendMessage:(HSBeaconEmailMessage *)message securityInfo:(HSBeaconSecurityInfo *)securityInfo completion:(StringCompletionHandler)completion;

- (NSURLSessionUploadTask *)uploadAttachment:(HSBeaconAttachment *)attachment securityInfo:(HSBeaconSecurityInfo *)securityInfo completion:(StringCompletionHandler)completion;

- (NSURLSessionTask *)deleteAttachment:(HSBeaconAttachment *)attachment securityInfo:(HSBeaconSecurityInfo *)securityInfo completion:(ErrorCompletionHandler)completion;

- (NSURLSessionTask *)getPreviousMessages:(HSBeaconSecurityInfo *)securityInfo page:(int)page completion: (void (^)(HSBeaconPaginatedResponse *_Nullable response, NSError *_Nullable error))completion;

- (NSURLSessionTask *)getPreviousMessagesCountWithSecurityInfo:(HSBeaconSecurityInfo *)securityInfo completion:(void (^)(NSNumber *_Nullable previousMessagesCount, NSError *error))completion;

- (NSURLSessionTask *)getConversation:(long)conversationID securityInfo:(HSBeaconSecurityInfo *)securityInfo completion:(void (^)(HSBeaconConversation *_Nullable conversation, NSArray<HSBeaconConversationThread *> *_Nullable threads, NSError *_Nullable error))completion;

- (NSURLSessionTask *)getConversationThreads:(long)conversationID securityInfo:(HSBeaconSecurityInfo *)securityInfo page:(int)page completion:(void (^)(HSBeaconPaginatedResponse *_Nullable response, NSError *_Nullable error))completion;

- (NSURLSessionDataTask *)getFieldsWithCompletionHandler:(void (^)(NSArray<HSBeaconCustomFieldDefinition *> *fields, NSError *error))completion;

- (NSURLSessionDataTask *)sendReply:(HSBeaconReplyMessage *)message securityInfo:(HSBeaconSecurityInfo *)securityInfo completion: (ErrorCompletionHandler)completion;

- (NSURLSessionDownloadTask *)downloadAttachment:(long)attachmentID conversationID:(long)conversationID securityInfo:(HSBeaconSecurityInfo *)securityInfo completion:(void (^)(NSURL *location, NSError *error))completion;

- (NSURLSessionTask *)markThreadAsRead:(long)threadId conversationId:(long)conversationId securityInfo:(HSBeaconSecurityInfo *)securityInfo completion:(ErrorCompletionHandler)completion;

@end

NS_ASSUME_NONNULL_END
