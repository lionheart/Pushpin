//
//  PPWebViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/21/13.
//
//

#import <UIKit/UIKit.h>

@interface PPWebViewController : UIViewController

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) NSString *urlString;

- (void)goBack:(id)sender;
+ (PPWebViewController *)webViewControllerWithURL:(NSString *)url;

@end
