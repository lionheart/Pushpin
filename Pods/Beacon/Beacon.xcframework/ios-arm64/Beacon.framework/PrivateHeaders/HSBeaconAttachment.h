#import <UIKit/UIKit.h>
#import <Beacon/HSBeaconContactForm.h>

NS_ASSUME_NONNULL_BEGIN

@interface HSBeaconAttachment: NSObject <HSBeaconContactFormAttachment>

@property(readonly, nonatomic) NSString *filename;
@property(readonly, nonatomic) UIImage *image;
@property(readonly, nonatomic) CFStringRef uti;
@property(readonly, nonatomic) NSString *contentType;
@property(readonly, nonatomic) long size;

@property(nonatomic, strong, nullable) NSData *data;
@property(nonatomic) NSString *attachmentId;
@property(nonatomic) float progress;
@property(nonatomic) BOOL uploadStarted;

- (nonnull instancetype)initWithData:(NSData *_Nonnull)data filename:(NSString *_Nonnull)filename image:(UIImage *_Nullable)image;

+ (NSData *)dataForAttachmentWithFilename:(NSString *)filename data:(NSData *)data image:(UIImage *_Nullable)image;

@end

NS_ASSUME_NONNULL_END
