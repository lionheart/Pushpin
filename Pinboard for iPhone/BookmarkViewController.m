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
#import "TTTAttributedLabel.h"

@interface BookmarkViewController ()

@end

@implementation BookmarkViewController

@synthesize url = _url;
@synthesize parameters = _parameters;
@synthesize bookmarks;
@synthesize labels;

- (void)pinboard:(Pinboard *)pinboard didReceiveResponse:(NSMutableArray *)response {
    self.bookmarks = [response copy];
    
    for (int i=0; i<10; i++) {
        OHAttributedLabel *label = [[OHAttributedLabel alloc] init];
        Bookmark *bookmark = [self.bookmarks objectAtIndex:i];
        NSString *content = [NSString stringWithFormat:@"%@\n%@", bookmark.description, bookmark.extended];
        NSMutableAttributedString *attributedString = [NSMutableAttributedString attributedStringWithString:content];

        [attributedString setFont:[UIFont fontWithName:@"Helvetica" size:18] range:[content rangeOfString:bookmark.description]];
        [attributedString setFont:[UIFont fontWithName:@"Helvetica" size:16] range:[content rangeOfString:bookmark.extended]];

        [attributedString setTextColor:[UIColor blackColor]];
        [attributedString setTextColor:HEX(0x5511aa) range:[content rangeOfString:bookmark.description]];

        [attributedString setTextAlignment:kCTLeftTextAlignment lineBreakMode:kCTLineBreakByWordWrapping];
        label.attributedText = attributedString;
        label.lineBreakMode = kCTLineBreakByWordWrapping;
        [label addCustomLink:[NSURL URLWithString:@"http://google.com/"] inRange:[content rangeOfString:bookmark.description]];
        label.textAlignment = UITextAlignmentLeft;
        label.underlineLinks = false;
        
        CGSize size = [label.attributedText sizeConstrainedToSize:CGSizeMake(320, 1000)];
        [label setFrame:CGRectMake(0, 0, size.width, size.height)];
        [label setNeedsDisplay];
        
        /*
         NSString *rendering = [GRMustacheTemplate renderObject:[NSDictionary dictionaryWithObjectsAndKeys:@"ID Theives Loot Tax Checks, Filing Early and Often", @"description", @"MIAMI — Besieged by identity theft, Florida now faces a fast-spreading form of fraud so simple and lucrative that some violent criminals have traded their guns for laptops. And the target is the…", @"extension", nil]
         fromResource:@"Bookmark"
         bundle:nil
         error:NULL];
         */
        
        //        NSLog(@"%@", label);
        [self.labels addObject:label];
    }

    [self.tableView reloadData];
}

- (id)initWithStyle:(UITableViewStyle)style url:(NSString *)url parameters:(NSDictionary *)parameters {
    self = [super initWithStyle:style];
    if (self) {
        _url = url;
        _parameters = parameters;
        self.bookmarks = [NSMutableArray array];
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
    Pinboard *pinboard = [Pinboard pinboardWithEndpoint:@"posts/recent?count=10" delegate:self];
    [pinboard parse];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.labels count];
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    OHAttributedLabel *label = [self.labels objectAtIndex:indexPath.row];
    return label.frame.size.height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    OHAttributedLabel *label = [self.labels objectAtIndex:indexPath.row];
    //    NSLog(@"%@", label.attributedText);
    [cell setAutoresizingMask:UIViewAutoresizingNone];
    [cell.contentView addSubview:label];
    return cell;
}

@end
