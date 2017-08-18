//
//  PPSearchExamplesViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 2/16/14.
//
//

@import LHSTableViewCells;

#import "PPSearchExamplesViewController.h"
#import "PPTheme.h"
#import "PPNotification.h"

static NSString *CellIdentifier = @"CellIdentifier";

@interface PPSearchExamplesViewController ()

@property (nonatomic, strong) NSArray *examples;
@property (nonatomic, strong) NSString *text;

- (void)openSQLiteFTSDocumentation;

@end

@implementation PPSearchExamplesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.examples = @[@{@"example": @"url:apple",
                        @"description": @"Bookmarks with \"apple\" in the URL." },
                      @{@"example": @"url:apple title:ios",
                        @"description": @"Bookmarks with \"apple\" in the URL and \"ios\" in the title." },
                      @{@"example": @"tags:programming tags:python",
                        @"description": @"Bookmarks tagged with both \"programming\" and \"python\"." },
                      @{@"example": @"tags:programming OR tags:python",
                        @"description": @"Bookmarks tagged either \"programming\" or \"python\". Note that the \"OR\" must be capitalized." },
                      @{@"example": @"tags:programming NOT tags:python",
                        @"description": @"Bookmarks tagged with \"programming\" but NOT \"python\"." },
                      @{@"example": @"(url:wirecutter OR url:anand) title:mac",
                        @"description": @"Bookmarks from either the Wirecutter or AnandTech that have \"mac\" in the title." },
                      @{@"example": @"((url:macstories OR url:macdrifter OR url:appstorm) AND title:pinboard) OR description:pushpin",
                        @"description": @"Bookmarks from either Macdrifter, Macstories, or Appstorm that have \"pinboard\" in the title OR bookmarks with pushpin in the description." },
                      ];
    self.title = NSLocalizedString(@"Advanced Searching", nil);
    
    self.text = @"Pushpin uses SQLite FTS (full-text search) internally to index bookmarks and to facilitate advanced searching. Indexed fields include 'title', 'description', 'tags', and 'url'. To search for text within a field, just type the field, a colon, and then the phrase you're looking for. If you don't specify a field, Pushpin will search within all fields.\n\n"
    "Tap the action button in the top right to read more about SQLite FTS advanced query syntax (pay attention to the examples with the MATCH keyword, since Pushpin feeds your input right into that), or check out the examples below.";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                           target:self
                                                                                           action:@selector(openSQLiteFTSDocumentation)];
    [self.tableView registerClass:[LHSTableViewCellValue1 class] forCellReuseIdentifier:CellIdentifier];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.examples.count + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return CGRectGetHeight([self.text boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.tableView.frame) - 40, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [PPTheme detailLabelFont]} context:nil]) + 40;
    } else {
        return CGRectGetHeight([self.examples[indexPath.section - 1][@"example"] boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.tableView.frame)- 30, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [PPTheme textLabelFont]} context:nil]) + 30;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                            forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;

    if (indexPath.section == 0) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        cell.textLabel.font = [PPTheme detailLabelFont];
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.text = self.text;
    } else {
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;

        cell.textLabel.font = [PPTheme textLabelFont];
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.text = self.examples[indexPath.section - 1][@"example"];
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return nil;
    } else {
        return self.examples[section - 1][@"description"];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section > 0) {
        [[UIPasteboard generalPasteboard] setString:self.examples[indexPath.section - 1][@"example"]];
        
        [PPNotification notifyWithMessage:NSLocalizedString(@"Copied search to clipboard.", nil)];
    }
}

- (void)openSQLiteFTSDocumentation {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.sqlite.org/fts3.html#section_3"] options:@{} completionHandler:nil];;
}

@end
