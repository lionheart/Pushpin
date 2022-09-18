@interface HSBeaconConversationHTMLGenerator : NSObject

- (NSString *)avatarWithImageURL:(NSURL *)url;
- (NSString *)avatarWithInitials:(NSString *)initials tintColors:(NSString *)tintColors;
- (NSString *)htmlForAvatar:(NSString *)avatarInnerHtml colorHexString:(NSString *)colorHexString;
- (NSString *)htmlForAttachment:(NSNumber*)attachmentId filename:(NSString *)filename;
- (NSString *)htmlForAttachments:(NSArray*)attachmentHTMLs;
- (NSString *)htmlNewIndicator:(BOOL)isNewThread;
- (NSString *)htmlForThreadContainer:(BOOL)shouldShowMore;
- (NSString *)htmlForShowMoreButton;

@end
