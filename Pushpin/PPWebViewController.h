/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Pushpin for Pinboard
 * Copyright (C) 2025 Lionheart Software LLC
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

//
//  PPWebViewController.h
//  Pushpin
//
//  Created by Dan Loewenherz on 5/21/13.
//
//

@import UIKit;
@import MessageUI;
@import WebKit;

#import "PPAppDelegate.h"
#import "PPToolbar.h"

#if TARGET_OS_MACCATALYST
@interface PPWebViewController : UIViewController <WKNavigationDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate, NSURLConnectionDataDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>
#else
@interface PPWebViewController : UIViewController <UIWebViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate, NSURLConnectionDataDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>
#endif

@property (nonatomic, strong) UIView *statusBarBackgroundView;
@property (nonatomic, strong) UIView *webViewContainer;

#if TARGET_OS_MACCATALYST
@property (nonatomic, strong) WKWebView *webView;
#else
@property (nonatomic, strong) UIWebView *webView;
#endif

@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSString *urlString;
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UIBarButtonItem *activityIndicatorBarButtonItem;

@property (nonatomic, strong) UIView *showToolbarAndTitleBarHiddenView;
@property (nonatomic, strong) UIView *toolbarBackgroundView;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *markAsReadButton;
@property (nonatomic, strong) UIButton *editButton;
@property (nonatomic, strong) UIButton *addButton;
@property (nonatomic, strong) UIButton *mobilizeButton;
@property (nonatomic, strong) UIActivityIndicatorView *indicator;

@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *bottomTapGestureRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *readerLongPressGestureRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *backButtonLongPressGestureRecognizer;

@property (nonatomic) BOOL alreadyLoaded;
@property (nonatomic) BOOL isFullscreen;
@property (nonatomic) BOOL selectedActionSheetIsVisible;
@property (nonatomic) BOOL shouldMobilize;
@property (nonatomic) BOOL prefersStatusBarHidden;
@property (nonatomic) UIStatusBarStyle preferredStatusBarStyle;

@property (nonatomic) NSInteger numberOfRequests;
@property (nonatomic) NSInteger numberOfRequestsCompleted;
@property (nonatomic) NSInteger numberOfRequestsInProgress;

@property (nonatomic, strong) NSMutableArray *history;
@property (nonatomic, strong) NSLayoutConstraint *topLayoutConstraint;
@property (nonatomic, strong) NSLayoutConstraint *toolbarConstraint;
@property (nonatomic, strong) NSMutableArray *navigationHistory;
@property (nonatomic, strong) NSDictionary *selectedLink;
@property (nonatomic, strong) UIAlertController *backActionSheet;
@property (nonatomic, strong) UIAlertController *actionSheet;
@property (nonatomic, strong) UIAlertController *selectedActionSheet;
@property (nonatomic, strong) UIAlertController *openLinkExternallyAlertView;
@property (nonatomic, strong) UITapGestureRecognizer *singleTapGestureRecognizer;
@property (nonatomic, strong) UIView *toolbar;
@property (nonatomic, strong) NSTimer *webViewTimeoutTimer;

@property (nonatomic, copy) void (^callback)(void);

- (void)gestureDetected:(UIGestureRecognizer *)recognizer;
- (void)actionButtonTouchUp:(id)sender;
- (void)backButtonTouchUp:(id)sender;
- (void)copyURL:(NSURL *)url;
- (void)showEditViewController;
- (void)showAddViewController;
- (void)showAddViewController:(NSDictionary *)data;
- (void)toggleMobilizer;
- (void)toggleMobilizerAnimated:(BOOL)animated loadOriginalURL:(BOOL)loadOriginalURL;
- (void)enableOrDisableButtons;
- (void)loadURL;
- (void)stopLoading;
- (NSURL *)url;
- (NSInteger)numberOfRequestsInProgress;
- (void)webViewLoadTimedOut;

- (void)tintButtonsWithColor:(UIColor *)color;

+ (PPWebViewController *)webViewControllerWithURL:(NSString *)url;
+ (void)mobilizedPageForURL:(NSURL *)url withCompletion:(void (^)(NSDictionary *, NSError *))completion;

@end
