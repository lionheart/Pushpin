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

static NSString *const kFontName = @"Helvetica";

@interface BookmarkViewController ()

@end

@implementation BookmarkViewController

@synthesize context;
@synthesize url = _url;
@synthesize parameters = _parameters;
@synthesize bookmarks;
@synthesize strings;
@synthesize heights;

- (void)pinboard:(Pinboard *)pinboard didReceiveResponse:(NSMutableArray *)response {
    self.bookmarks = [response copy];

    UIFont *largeHelvetica = [UIFont fontWithName:kFontName size:17];
    UIFont *smallHelvetica = [UIFont fontWithName:kFontName size:14];

    for (int i=0; i<10; i++) {
        Bookmark *bookmark = [self.bookmarks objectAtIndex:i];
        
        CGFloat height = 10.0f;
        height += ceilf([bookmark.description sizeWithFont:largeHelvetica constrainedToSize:CGSizeMake(300.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
        height += ceilf([bookmark.extended sizeWithFont:smallHelvetica constrainedToSize:CGSizeMake(300.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
        [self.heights addObject:[NSNumber numberWithFloat:height]];

        NSString *content;
        if (![bookmark.extended isEqualToString:@""]) {
            content = [NSString stringWithFormat:@"%@\n%@", bookmark.description, bookmark.extended];
        }
        else {
            content = [NSString stringWithFormat:@"%@", bookmark.description];
        }

        NSMutableAttributedString *attributedString = [NSMutableAttributedString attributedStringWithString:content];

        [attributedString setFont:largeHelvetica range:[content rangeOfString:bookmark.description]];
        [attributedString setFont:smallHelvetica range:[content rangeOfString:bookmark.extended]];
        [attributedString setTextColor:[UIColor blackColor]];
        [attributedString setTextColor:HEX(0x5511aa) range:[content rangeOfString:bookmark.description]];
        [attributedString setTextAlignment:kCTLeftTextAlignment lineBreakMode:kCTLineBreakByWordWrapping];
        [self.strings addObject:attributedString];
    }

    [self.tableView reloadData];
}

- (id)initWithStyle:(UITableViewStyle)style url:(NSString *)url parameters:(NSDictionary *)parameters {
    self = [super initWithStyle:style];
    if (self) {
        _url = url;
        _parameters = parameters;
        self.context = [[NSManagedObjectContext alloc] init];
        self.bookmarks = [NSMutableArray array];
        self.strings = [NSMutableArray array];
        self.heights = [NSMutableArray array];
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
    return [self.strings count];
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [[self.heights objectAtIndex:indexPath.row] floatValue];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"BookmarkCell";
    BookmarkCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[BookmarkCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    NSAttributedString *string = [self.strings objectAtIndex:indexPath.row];
    [cell.textView setText:string];
    cell.textView.delegate = self;
    cell.textView.userInteractionEnabled = YES;
    [cell layoutSubviews];
    return cell;
}

@end
