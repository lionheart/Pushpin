#import "HSAttachmentPicker.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>

#import "HSAttachmentPickerPhotoPreviewController.h"

@interface HSAttachmentPicker () <HSAttachmentPickerPhotoPreviewControllerDelegate, UIDocumentMenuDelegate, UIDocumentPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property(nonatomic) HSAttachmentPicker *selfReference;

@end

@implementation HSAttachmentPicker

-(void)showAttachmentMenu {
    self.selfReference = self;
    UIAlertController *picker = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSString *showPhotosPermissionSettingsMessage = [NSBundle.mainBundle objectForInfoDictionaryKey:@"NSPhotoLibraryUsageDescription"];
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera] && showPhotosPermissionSettingsMessage != nil) {
        UIAlertAction *takePhotoAction = [UIAlertAction actionWithTitle:[self translateString:@"Take Photo"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self validatePhotosPermissions:^{
                [self showImagePicker:UIImagePickerControllerSourceTypeCamera];
            }];
        }];
        [picker addAction:takePhotoAction];
    }

    if (showPhotosPermissionSettingsMessage != nil) {
        UIAlertAction *useLastPhotoAction = [UIAlertAction actionWithTitle:[self translateString:@"Use Last Photo"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self validatePhotosPermissions:^{
                [self useLastPhoto];
            }];
        }];
        [picker addAction:useLastPhotoAction];
    }

    if (showPhotosPermissionSettingsMessage != nil) {
        UIAlertAction *chooseFromLibraryAction = [UIAlertAction actionWithTitle:[self translateString:@"Choose from Library"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self validatePhotosPermissions:^{
                [self showImagePicker:UIImagePickerControllerSourceTypePhotoLibrary];
            }];
        }];
        [picker addAction:chooseFromLibraryAction];
    }


    UIAlertAction *importFileFromAction = [UIAlertAction actionWithTitle:[self translateString:@"Import File from"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self showDocumentPicker];
    }];
    [picker addAction:importFileFromAction];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[self translateString:@"Cancel"] style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self dismissed];
    }];
    [picker addAction:cancelAction];

    [self.delegate attachmentPickerMenu:self showController:picker completion:nil];
}

#pragma mark - import file
-(void)showDocumentPicker {
    @try {
        NSArray *documentTypes = [[NSArray alloc] initWithObjects:(NSString*)kUTTypeItem, nil];
        if (@available(iOS 11.0, *)) {
            UIDocumentPickerViewController *documentMenu = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:documentTypes inMode:UIDocumentPickerModeImport];
            documentMenu.delegate = self;
            [self.delegate attachmentPickerMenu:self showController:documentMenu completion:nil];
        } else {
            UIDocumentMenuViewController *documentMenu = [[UIDocumentMenuViewController alloc] initWithDocumentTypes:documentTypes inMode:UIDocumentPickerModeImport];
            documentMenu.delegate = self;
            [self.delegate attachmentPickerMenu:self showController:documentMenu completion:nil];
        }
    }
    @catch (NSException *exception) {
        [self showError:[self translateString:@"This application is not entitled to access iCloud"]];
    }
}

#pragma mark - use last photo
-(void)useLastPhoto {
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:fetchOptions];
    if (fetchResult.count == 0) {
        [self showError:[self translateString:@"There doesn't seem to be a photo taken yet."]];
        return;
    }
    [self uploadPhoto:fetchResult.lastObject];
}

#pragma mark - permissions check for photos
-(void)validatePhotosPermissions:(void(^)(void))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (PHPhotoLibrary.authorizationStatus == PHAuthorizationStatusAuthorized) {
            completion();
        } else {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status != PHAuthorizationStatusAuthorized) {
                    [self showPhotosPermissionSettingsMessage];
                } else {
                    completion();
                }
            }];
        }
    });
}

-(void)showPhotosPermissionSettingsMessage {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *accessDescription = [NSBundle.mainBundle objectForInfoDictionaryKey:@"NSPhotoLibraryUsageDescription"];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:accessDescription message:[self translateString:@"To give permissions tap on 'Change Settings' button"] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[self translateString:@"Cancel"] style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:[self translateString:@"OK"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }];
        [alert addAction:cancelAction];
        [alert addAction:okAction];
        [self.delegate attachmentPickerMenu:self showController:alert completion:nil];
    });
}

#pragma mark - open image picker for camera or photo library
-(void)showImagePicker:(UIImagePickerControllerSourceType)sourceType {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.allowsEditing = NO;
    imagePicker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString*)kUTTypeImage, (NSString*)kUTTypeMovie, nil];
    imagePicker.videoQuality = UIImagePickerControllerQualityTypeLow;
    imagePicker.sourceType = sourceType;
    [self.delegate attachmentPickerMenu:self showController:imagePicker completion:^{
        UIApplication.sharedApplication.statusBarHidden = YES;
    }];
}

#pragma mark - save from camera
- (void)saveVideoFromCamera:(NSDictionary<NSString *,id> * _Nonnull)info {
    NSURL *url = info[UIImagePickerControllerMediaURL];
    NSMutableDictionary *placeholder = [[NSMutableDictionary alloc]init];
    [PHPhotoLibrary.sharedPhotoLibrary performChanges:^{
        PHAssetChangeRequest *request = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
        placeholder[@"asset"] = request.placeholderForCreatedAsset;
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            NSData *contents = [NSFileManager.defaultManager contentsAtPath:url.path];
            NSString *filename = [NSString stringWithFormat:@"%@.mov", NSUUID.UUID.UUIDString];
            [self upload:contents filename:filename image:nil];
        } else {
            NSString *errorMessage = [NSString stringWithFormat:[self translateString:@"Unable to save video: %@"], error.localizedDescription];
            [self showError:errorMessage];
        }
    }];
}

- (void)savePhotoFromCamera:(NSDictionary<NSString *,id> * _Nonnull)info {
    [PHPhotoLibrary.sharedPhotoLibrary performChanges:^{
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        [PHAssetChangeRequest creationRequestForAssetFromImage:image];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            [self useLastPhoto];
        } else {
            NSString *errorMessage = [NSString stringWithFormat:[self translateString:@"Unable to save photo: %@"], error.localizedDescription];
            [self showError:errorMessage];
        }
    }];
}

- (NSString *)translateString:(NSString *)key {
    NSBundle *bundle = self.translationsBundle ? self.translationsBundle : NSBundle.mainBundle;
    return [bundle localizedStringForKey:key value:nil table:self.translationTable];
}

- (void)upload:(NSData *)data filename:(NSString *)filename image:(UIImage *)image {
    [self.delegate attachmentPickerMenu:self upload:data filename:filename image:image];
    [self dismissed];
}

- (void)dismissed {
    if (self.delegate && [self.delegate respondsToSelector:@selector(attachmentPickerMenuDismissed:)]) {
        [self.delegate attachmentPickerMenuDismissed:self];
    }
    self.selfReference = nil;
}

- (void)showError:(NSString *)errorMessage {
    [self.delegate attachmentPickerMenu:self showErrorMessage:errorMessage];
    [self dismissed];
}

#pragma mark - upload operations
-(void)uploadSavedMedia:(NSDictionary<NSString *,id> *)info {
    PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsWithALAssetURLs:@[info[UIImagePickerControllerReferenceURL]] options:nil];
    for (PHAsset* asset in assets) {
        switch (asset.mediaType) {
            case PHAssetMediaTypeImage:
                [self uploadPhoto:asset];
                break;

            case PHAssetMediaTypeVideo:
                [self uploadMovie:info];
                break;

            default:
                [self showError:[self translateString:@"Selected media type is unsupported"]];
                break;
        }
    }
}

-(void)uploadMovie:(NSDictionary<NSString *,id> *)info {
    NSURL *fileURL = info[UIImagePickerControllerMediaURL];
    NSData *videoData = [NSFileManager.defaultManager contentsAtPath:fileURL.path];
    NSString *filename = [NSString stringWithFormat:@"%@.mov", NSUUID.UUID.UUIDString];
    [self upload:videoData filename:filename image:nil];
}

-(void)uploadPhoto:(PHAsset*)photo {
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    CGSize targetSize = photo.pixelWidth > photo.pixelHeight ? CGSizeMake(1024, 768) : CGSizeMake(768, 1024);
    requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    requestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
    requestOptions.synchronous = YES;
    [PHImageManager.defaultManager requestImageForAsset:photo targetSize:targetSize contentMode:PHImageContentModeAspectFit options:requestOptions resultHandler:^(UIImage *result, NSDictionary *info) {
        NSData *data = UIImageJPEGRepresentation(result, 0.5);
        NSString *filename = [photo valueForKey:@"filename"] ?: @"photo.jpg";
        [self upload:data filename:filename.lowercaseString image:result];
    }];
}

#pragma mark - HSAttachmentPickerPhotoPreviewControllerDelegate
- (void)photoPreview:(HSAttachmentPickerPhotoPreviewController * _Nonnull)photoPreview usePhoto:(NSDictionary<NSString *,id> * _Nonnull)info {
    [self uploadSavedMedia:info];
}

#pragma mark - UIDocumentMenuDelegate
-(void)documentMenu:(UIDocumentMenuViewController *)documentMenu didPickDocumentPicker:(UIDocumentPickerViewController *)documentPicker{
    documentPicker.delegate = self;
    [self.delegate attachmentPickerMenu:self showController:documentPicker completion:nil];
}

-(void)documentMenuWasCancelled:(UIDocumentMenuViewController *)documentMenu {
    [self dismissed];
}

#pragma mark - UIDocumentPickerDelegate
-(void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    [self upload:[NSData dataWithContentsOfURL:url] filename:url.path.lastPathComponent image:nil];
}

-(void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    [self dismissed];
}

#pragma mark - UIImagePickerControllerDelegate
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    if (picker.sourceType != UIImagePickerControllerSourceTypeCamera) {
        NSString *mediaType = info[UIImagePickerControllerMediaType];
        if ([mediaType isEqualToString:(NSString*)kUTTypeMovie]) {
            [picker dismissViewControllerAnimated:YES completion:nil];
            [self uploadSavedMedia:info];
        } else {
            HSAttachmentPickerPhotoPreviewController *previewController = [[HSAttachmentPickerPhotoPreviewController alloc] init];
            previewController.delegate = self;
            previewController.info = info;
            [picker pushViewController:previewController animated:YES];
        }
        return;
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (info[UIImagePickerControllerMediaType] == (NSString*)kUTTypeMovie) {
        [self saveVideoFromCamera:info];
    } else {
        [self savePhotoFromCamera:info];
    }
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:^{
        [self dismissed];
    }];
}

@end
