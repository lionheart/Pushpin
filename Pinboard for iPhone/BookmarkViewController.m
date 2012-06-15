//
//  PostViewController.m
//  Pinboard for iPhone
//
//  Created by Dan Loewenherz on 5/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BookmarkViewController.h"
#import "PinboardClient.h"
#import "BookmarkCell.h"
#import "GRMustache.h"
#import "NSAttributedString+Attributes.h"

@interface BookmarkViewController ()

@end

@implementation BookmarkViewController

@synthesize url = _url;
@synthesize parameters = _parameters;
@synthesize posts;
@synthesize labels;

- (id)initWithStyle:(UITableViewStyle)style url:(NSString *)url parameters:(NSDictionary *)parameters {
    self = [super initWithStyle:style];
    if (self) {
        _url = url;
        _parameters = parameters;
        self.posts = [NSMutableArray array];
        self.labels = [NSMutableArray array];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"About"
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:nil
                                                                                 action:nil];
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    for (int i=0; i<10; i++) {
        OHAttributedLabel *label;
        NSMutableAttributedString *attributedString = [NSMutableAttributedString attributedStringWithString:@"Hello there!"];
        [attributedString setFont:[UIFont fontWithName:@"Helvetica" size:18]];
        label.attributedText = attributedString;
        [label addCustomLink:[NSURL URLWithString:@"http://google.com/"] inRange:NSMakeRange(0, 5)];
        label.textAlignment = UITextAlignmentLeft;

        /*
        NSString *rendering = [GRMustacheTemplate renderObject:[NSDictionary dictionaryWithObjectsAndKeys:@"ID Theives Loot Tax Checks, Filing Early and Often", @"description", @"MIAMI — Besieged by identity theft, Florida now faces a fast-spreading form of fraud so simple and lucrative that some violent criminals have traded their guns for laptops. And the target is the…", @"extension", nil]
                                                  fromResource:@"Bookmark"
                                                        bundle:nil
                                                         error:NULL];
        */

        [self.labels addObject:label];
    }
    return;
    
    PinboardClient *client = [PinboardClient sharedClient];
    [client path:self.url
      parameters:self.parameters
         success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
             for (id post in JSON) {
                 [self.posts addObject:post];
             }
             /*
             for (id post in JSON) {
                 UIWebView *webView = [[UIWebView alloc] init];
                 webView.delegate = self;
                 
                 webView.scalesPageToFit = false;
                 //        webView.userInteractionEnabled = false;
                 webView.scrollView.scrollEnabled = false;
                 webView.scrollView.bounces = false;
                 
                 NSString *rendering = [GRMustacheTemplate renderObject:[NSDictionary dictionaryWithObjectsAndKeys:[post objectForKey:@"description"], @"description", [post objectForKey:@"extension"], @"extension", nil]
                                                           fromResource:@"Bookmark"
                                                                 bundle:nil
                                                                  error:NULL];
                 
                 NSString *path = [[NSBundle mainBundle] bundlePath];
                 NSURL *baseURL = [NSURL fileURLWithPath:path];
                 [webView loadHTMLString:rendering baseURL:baseURL];
                 [self.webViews addObject:webView];
                 */
             [self.tableView reloadData];
         }
         failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
         }];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.labels.count;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    OHAttributedLabel *label = [self.labels objectAtIndex:indexPath.row];
    CGSize size = [label.attributedText sizeConstrainedToSize:CGSizeMake(320, 20)];
    return size.height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSString *identifier = [NSString stringWithFormat:@"Cell_%d", indexPath.row];
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:identifier];
    }
    
    UIWebView *webView = [self.loadedWebViews objectAtIndex:indexPath.row];
    webView.frame = cell.contentView.frame;
    webView.scalesPageToFit = YES;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell.contentView addSubview:webView];

    return cell;
}

@end
