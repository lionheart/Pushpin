#import <Foundation/Foundation.h>

#import "HSBeaconAgent.h"
#import "HSBeaconAttachment.h"
#import "HSBeaconBaseAPIClient.h"
#import "HSBeaconConversation.h"
#import "HSBeaconConversationThread.h"
#import "HSBeaconCustomFieldDefinition.h"
#import "HSBeaconEmailMessage.h"
#import "HSBeaconPaginatedResponse.h"
#import "HSBeaconReplyMessage.h"
#import "HSBeaconSecurityInfo.h"

@interface HSBeaconMessagingAPIClient: HSBeaconBaseAPIClient

- (NSURLSessionDataTask *)registerForPushNotificationsWithVendorID:(NSString *)vendorID securityInfo:(HSBeaconSecurityInfo *)securityInfo token:(NSData *)token completion:(ErrorCompletionHandler)completion;

- (NSURLSessionDataTask *)registerForPushNotificationsWithVendorID:(NSString *)vendorID securityInfo:(HSBeaconSecurityInfo *)securityInfo token:(NSData *)token email:(nullable NSString *)email completion:(ErrorCompletionHandler)completion;

- (NSURLSessionDataTask *)subscribeToNotificationsForConversation:(NSString *)conversationID securityInfo:(HSBeaconSecurityInfo *)securityInfo completion:(ErrorCompletionHandler)completion;

- (NSURLSessionDataTask *)validateSignature:(HSBeaconSecurityInfo *)securityInfo completion:(BooleanCompletionHandler)completion;

- (NSURLSessionDataTask *)identifyUser:(HSBeaconSecurityInfo *)securityInfo completion:(BooleanCompletionHandler)completion;

- (NSURLSessionDataTask *)sendMessage:(HSBeaconEmailMessage *)message securityInfo:(HSBeaconSecurityInfo *)securityInfo completion:(StringCompletionHandler)completion;

- (NSURLSessionUploadTask *)uploadAttachment:(HSBeaconAttachment *)attachment securityInfo:(HSBeaconSecurityInfo *)securityInfo completion:(StringCompletionHandler)completion;

- (NSURLSessionTask *)deleteAttachment:(HSBeaconAttachment *)attachment securityInfo:(HSBeaconSecurityInfo *)securityInfo completion:(ErrorCompletionHandler)completion;

- (NSURLSessionTask *)getPreviousMessages:(HSBeaconSecurityInfo *)securityInfo page:(int)page completion: (void (^)(HSBeaconPaginatedResponse *response, NSError *error))completion;

- (NSURLSessionTask *)getPreviousMessagesCountWithSecurityInfo:(HSBeaconSecurityInfo *)securityInfo completion:(void (^)(NSNumber *previousMessagesCount, NSError *error))completion;

- (NSURLSessionTask *)getConversation:(long)conversationID securityInfo:(HSBeaconSecurityInfo *)securityInfo completion:(void (^)(HSBeaconConversation *conversation, NSArray<HSBeaconConversationThread *> *threads, NSError *error))completion;

- (NSURLSessionTask *)getConversationThreads:(long)conversationID securityInfo:(HSBeaconSecurityInfo *)securityInfo page:(int)page completion:(void (^)(HSBeaconPaginatedResponse *response, NSError *error))completion;

- (NSURLSessionDataTask *)getFieldsWithCompletionHandler:(void (^)(NSArray<HSBeaconCustomFieldDefinition *> *fields, NSError *error))completion;

- (NSURLSessionDataTask *)sendReply:(HSBeaconReplyMessage *)message securityInfo:(HSBeaconSecurityInfo *)securityInfo completion: (ErrorCompletionHandler)completion;

- (NSURLSessionDownloadTask *)downloadAttachment:(long)attachmentID conversationID:(long)conversationID securityInfo:(HSBeaconSecurityInfo *)securityInfo completion:(void (^)(NSURL *location, NSError *error))completion;

- (NSURLSessionTask *)markThreadAsRead:(long)threadId conversationId:(long)conversationId securityInfo:(HSBeaconSecurityInfo *)securityInfo;

@end
