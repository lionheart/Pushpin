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
#import "NSAttributedString+Attributes.h"
#import "TTTAttributedLabel.h"
#import "ASManagedObject.h"
#import "Bookmark.h"

static NSString *const kFontName = @"Helvetica";
static float kLargeFontSize = 16.0f;
static float kSmallFontSize = 13.0f;

@interface BookmarkViewController ()

@end

@implementation BookmarkViewController

@synthesize url = _url;
@synthesize parameters = _parameters;
@synthesize bookmarks;
@synthesize strings;
@synthesize heights;

- (void)pinboard:(Pinboard *)pinboard didReceiveResponse:(NSMutableArray *)response {
    NSManagedObjectContext *context = [ASManagedObject sharedContext];
    NSMutableArray *hashes = [NSMutableArray array];
    
    for (NSDictionary *element in response) {
        [hashes addObject:[element objectForKey:@"hash"]];
    }
    
    [hashes sortUsingComparator:(NSComparator)^(id obj1, id obj2) {
        return [obj1 caseInsensitiveCompare:obj2];
    }];

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Bookmark"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"pinboard_hash in %@", hashes]];
    [request setSortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"pinboard_hash" ascending:YES]]];
    
    NSError *error = nil;
    NSArray *fetchRequestResponse = [context executeFetchRequest:request error:&error];

    int i = 0;
    int j = 0;
    bool update_existing;
    Bookmark *bookmark;
    while (i < [hashes count]) {
        update_existing = false;
        NSString *hash = [hashes objectAtIndex:i];
        if (j < [fetchRequestResponse count]) {
            bookmark = [fetchRequestResponse objectAtIndex:j];
            update_existing = [bookmark.pinboard_hash isEqualToString:hash];
        }
        
        if (update_existing) {
            j++;
        }
        else {
            bookmark = (Bookmark *)[NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:context];
        }

        NSDictionary *element = [response objectAtIndex:i];
        bookmark.url = [element objectForKey:@"href"];
        bookmark.title = [element objectForKey:@"description"];
        bookmark.extended = [element objectForKey:@"extended"];
        bookmark.pinboard_hash = [element objectForKey:@"hash"];
        bookmark.read = [NSNumber numberWithBool:([[element objectForKey:@"toread"] isEqualToString:@"no"])];
        bookmark.shared = [NSNumber numberWithBool:([[element objectForKey:@"shared"] isEqualToString:@"yes"])];
        [self.bookmarks addObject:bookmark];
        i++;
    }

    [context save:nil];

    UIFont *largeHelvetica = [UIFont fontWithName:kFontName size:kLargeFontSize];
    UIFont *smallHelvetica = [UIFont fontWithName:kFontName size:kSmallFontSize];

    for (int i=0; i<[hashes count]; i++) {
        Bookmark *bookmark = [self.bookmarks objectAtIndex:i];

        CGFloat height = 10.0f;
        height += ceilf([bookmark.title sizeWithFont:largeHelvetica constrainedToSize:CGSizeMake(300.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
        height += ceilf([bookmark.extended sizeWithFont:smallHelvetica constrainedToSize:CGSizeMake(300.0f, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height);
        [self.heights addObject:[NSNumber numberWithFloat:height]];

        NSString *content;
        if (![bookmark.extended isEqualToString:@""]) {
            content = [NSString stringWithFormat:@"%@\n%@", bookmark.title, bookmark.extended];
        }
        else {
            content = [NSString stringWithFormat:@"%@", bookmark.title];
        }

        NSMutableAttributedString *attributedString = [NSMutableAttributedString attributedStringWithString:content];

        [attributedString setFont:largeHelvetica range:[content rangeOfString:bookmark.title]];
        [attributedString setFont:smallHelvetica range:[content rangeOfString:bookmark.extended]];
        [attributedString setTextColor:HEX(0x555555ff)];

        if (bookmark.read.boolValue) {
            [attributedString setTextColor:HEX(0x2255aaff) range:[content rangeOfString:bookmark.title]];
        }
        else {
            [attributedString setTextColor:HEX(0xcc2222ff) range:[content rangeOfString:bookmark.title]];
        }
        [attributedString setTextAlignment:kCTLeftTextAlignment lineBreakMode:kCTLineBreakByWordWrapping];
        [self.strings addObject:attributedString];
    }

    [self.tableView reloadData];
}

- (id)initWithStyle:(UITableViewStyle)style url:(NSString *)url parameters:(NSDictionary *)parameters {
    self = [super initWithStyle:style];
    if (self) {
        self.url = url;
        self.parameters = parameters;
        self.bookmarks = [NSMutableArray array];
        self.strings = [NSMutableArray array];
        self.heights = [NSMutableArray array];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add"
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(addNewBookmark)];
    }
    return self;
}

- (void)addNewBookmark {
    NSManagedObjectContext *context = [ASManagedObject sharedContext];
    NSError *error = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Bookmark"];
    NSMutableArray *mutableFetchResults = [[context executeFetchRequest:request error:&error] mutableCopy];
    NSLog(@"%d", [mutableFetchResults count]);
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    Pinboard *pinboard = [Pinboard pinboardWithEndpoint:self.url delegate:self];
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
