#import "HSAttachmentPickerPhotoPreviewController.h"

@implementation HSAttachmentPickerPhotoPreviewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImageView *image = [[UIImageView alloc] initWithImage:_info[UIImagePickerControllerOriginalImage]];
    self.view = image;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.contentMode = UIViewContentModeScaleAspectFit;
    self.title = @"Preview";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Use" style:UIBarButtonItemStyleDone target:self action:@selector(usePhoto)];
}

-(void)usePhoto {
    [self.navigationController dismissViewControllerAnimated:true completion:nil];
    [_delegate photoPreview:self usePhoto:self.info];
}

@end
