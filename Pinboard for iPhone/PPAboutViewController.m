//
//  PPAboutViewController.m
//  Pushpin
//
//  Created by Dan Loewenherz on 5/31/13.
//
//

#import "AppDelegate.h"
#import "PPAboutViewController.h"
#import "PPGroupedTableViewCell.h"
#import "WCAlertView.h"
#import <QuartzCore/QuartzCore.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "RDActionSheet.h"

@interface PPAboutViewController ()

@end

@implementation PPAboutViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        NSArray *credits = @[@[@"Rachel", @"For always believing in me."], @[@"Dante and Isabelle", @"For inspiring me and for making me laugh."], @[@"Maciej Ceglowski", @"For making Pinboard."]];
        NSArray *beta = @[@[@"Michael Solis", [NSNull null], @"morphopod"], @[@"Phil Havens", [NSNull null], @"philhavens"]];
        NSArray *translations = @[@[@"Riccardo Mori", @"Italian", @"morrick"], @[@"James Lepthien", @"German", @"0x86DD"], @[@"Jérôme Tomasini", @"French", @"c0wb0yz"], @[@"Vítor Galvão", @"Portuguese", @"vhgalvao"]];
        NSArray *licenses = @[@[@"TTTAttributedLabel", @"Copyright (c) 2011 Mattt Thompson (http://mattt.me/)"
                                "\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:"
                                "\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software."
                                "\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.", @"https://github.com/mattt/TTTAttributedLabel"],
                              @[@"KeychainItemWrapper", @"Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc. (\"Apple\") in consideration of your agreement to the following terms, and your use, installation, modification or redistribution of this Apple software constitutes acceptance of these terms.  If you do not agree with these terms, please do not use, install, modify or redistribute this Apple software."
                                "\n\nIn consideration of your agreement to abide by the following terms, and subject to these terms, Apple grants you a personal, non-exclusive license, under Apple's copyrights in this original Apple software (the \"Apple Software\"), to use, reproduce, modify and redistribute the Apple Software, with or without modifications, in source and/or binary forms; provided that if you redistribute the Apple Software in its entirety and without modifications, you must retain this notice and the following text and disclaimers in all such redistributions of the Apple Software.  Neither the name, trademarks, service marks or logos of Apple Inc. may be used to endorse or promote products derived from the Apple Software without specific prior written permission from Apple.  Except as expressly stated in this notice, no other rights or licenses, express or implied, are granted by Apple herein, including but not limited to any patent rights that may be infringed by your derivative works or by other works in which the Apple Software may be incorporated."
                                "\n\nThe Apple Software is provided by Apple on an \"AS IS\" basis.  APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS."
                                "\n\nIN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
                                "\n\nCopyright (C) 2010 Apple Inc. All Rights Reserved.", @"http://developer.apple.com/library/ios/#samplecode/GenericKeychain/Listings/Classes_KeychainItemWrapper_m.html"],
                              @[@"ASPinboard", @"Copyright 2012-2013 Aurora Software LLC"
                              "\n\nLicensed under the Apache License, Version 2.0 (the \"License\"); you may not use this file except in compliance with the License.  You may obtain a copy of the License at"
                              "\n\n\thttp://www.apache.org/licenses/LICENSE-2.0"
                              "\n\nUnless required by applicable law or agreed to in writing, software distributed under the License is distributed on an \"AS IS\" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.", @"https://github.com/aurorasoftware/ASPinboard"],
                              @[@"fmdb", @"Copyright (c) 2008 Flying Meat Inc."
                                "\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:"
                                "\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software."
                                "\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.", @"https://github.com/ccgus/fmdb"],
                              @[@"Reachability", @"Copyright (c) 2011-2013, Tony Million."
                                "\nAll rights reserved."
                                "\n\nRedistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:"
                                "\n\n1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer."
                                "\n\n2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution."
                                "\n\nTHIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.", @"https://github.com/tonymillion/Reachability",],
                              @[@"oauthconsumer", [NSNull null], @"https://github.com/jdg/oauthconsumer"], @[@"RPSTPasswordManagementAppService", [NSNull null], @"https://github.com/Riposte/RPSTPasswordManagementAppService"]];
        NSArray *description = @[@[@"About Pushpin", @"Pushpin is the product of overwhelming amounts of caffeine, 80's club music, and kittens. Lionheart Software builds beautiful applications for the iPhone and for the web."], @[@"Follow Pushpin on Twitter", [NSNull null]], @[@"Review Pushpin on iTunes", [NSNull null]]];
        NSArray *team = @[@[@"Dan Loewenherz", @"Product design and development.", @"dwlz"], @[@"Martin Karasek", @"Visual design.", [NSNull null]]];
        self.data = @[description, team, credits, translations, beta, licenses];
        self.titles = @[[NSNull null], @"Team", @"Credits", @"Translations", @"Beta Testers", @"Software"];
        self.expandedIndexPaths = [NSMutableArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]];
        
        self.heights = [NSMutableDictionary dictionary];
        UIFont *font = [UIFont fontWithName:@"Avenir-Medium" size:16];
        UIFont *fixedWidthFont = [UIFont fontWithName:@"Courier" size:12];
        NSInteger index = 0;
        for (NSArray *list in self.data) {
            for (NSArray *pair in list) {
                NSString *title = pair[0];
                NSString *description = pair[1];

                if ([title isEqual:[NSNull null]]) {
                    self.heights[title] = @(0);
                }
                else {
                    self.heights[title] = @(MIN(22, [title sizeWithFont:font constrainedToSize:CGSizeMake(280, CGFLOAT_MAX)].height));
                }
                if ([description isEqual:[NSNull null]]) {
                    self.heights[description] = @(0);
                }
                else {
                    if (index == 5) {
                        self.heights[description] = @([description sizeWithFont:fixedWidthFont constrainedToSize:CGSizeMake(280, CGFLOAT_MAX)].height);
                    }
                    else {
                        self.heights[description] = @([description sizeWithFont:font constrainedToSize:CGSizeMake(280, CGFLOAT_MAX)].height);
                    }
                }
            }
            index++;
        }
        
        self.loadingIndicator = [[PPLoadingView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    UIMenuItem *copyURLMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy URL", nil) action:@selector(copyURL:)];
    UIMenuItem *followOnTwitterMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Follow on Twitter", nil) action:@selector(followUserOnTwitter:)];
    [[UIMenuController sharedMenuController] setMenuItems:@[followOnTwitterMenuItem, copyURLMenuItem]];
    [[UIMenuController sharedMenuController] update];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == [self.titles indexOfObject:@"Translations"]) {
        return YES;
    }
    if (indexPath.section == [self.titles indexOfObject:@"Software"]) {
        return YES;
    }
    if (indexPath.section == [self.titles indexOfObject:@"Beta Testers"]) {
        return YES;
    }
    return NO;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.data[section] count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *title = self.titles[section];
    if (![title isEqual:[NSNull null]]) {
        float width = tableView.bounds.size.width;
        
        int fontSize = 17;
        int padding = 15;
        UIFont *font = [UIFont fontWithName:@"Avenir-Heavy" size:fontSize];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(padding, 16, width - padding, fontSize)];
        label.text = title;
        label.backgroundColor = [UIColor clearColor];
        label.textColor = HEX(0x4C566CFF);
        label.shadowColor = [UIColor whiteColor];
        label.shadowOffset = CGSizeMake(0,1);
        label.font = font;
        CGSize textSize = [title sizeWithFont:label.font];
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, textSize.height)];
        [view addSubview:label];
        return view;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSString *title = self.titles[section];
    if (![title isEqual:[NSNull null]]) {
        UIFont *font = [UIFont fontWithName:@"Avenir-Heavy" size:17];
        return [self.titles[section] sizeWithFont:font constrainedToSize:CGSizeMake(300, CGFLOAT_MAX)].height + 20;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat topHeight = [self.heights[self.data[indexPath.section][indexPath.row][0]] floatValue];
    CGFloat bottomHeight = [self.heights[self.data[indexPath.section][indexPath.row][1]] floatValue];
    if (bottomHeight > 80 && ![self.expandedIndexPaths containsObject:indexPath]) {
        bottomHeight = 22;
    }

    return topHeight + bottomHeight + 20;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    self.selectedIndexPath = indexPath;
    return NO;
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (self.selectedIndexPath.section == [self.titles indexOfObject:@"Software"]) {
        return action == @selector(copyURL:);
    }
    else if (self.selectedIndexPath.section == [self.titles indexOfObject:@"Translations"]) {
        return action == @selector(followUserOnTwitter:);
    }
    else if (self.selectedIndexPath.section == [self.titles indexOfObject:@"Beta Testers"]) {
        return action == @selector(followUserOnTwitter:);
    }
    return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    static NSString *ChoiceCellIdentifier = @"ChoiceCell";
    PPGroupedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[PPGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ChoiceCellIdentifier];
    }
    
    cell.accessoryView = nil;
    
    cell.textLabel.font = [UIFont fontWithName:@"Avenir-Medium" size:16];

    if (indexPath.section == [self.titles indexOfObject:@"Software"]) {
        cell.detailTextLabel.font = [UIFont fontWithName:@"Courier" size:12];
    }
    else {
        cell.detailTextLabel.font = [UIFont fontWithName:@"Avenir-Medium" size:16];
    }
    cell.detailTextLabel.numberOfLines = 0;
    cell.textLabel.text = nil;
    cell.detailTextLabel.text = nil;
    cell.imageView.image = nil;
    
    if (indexPath.section == 0 && indexPath.row == 1) {
        cell.imageView.image = [UIImage imageNamed:@"twitter"];
    }
    else if (indexPath.section == 0 && indexPath.row == 2) {
        cell.imageView.image = [UIImage imageNamed:@"apple"];
    }
    
    NSString *title = self.data[indexPath.section][indexPath.row][0];
    NSString *detail = self.data[indexPath.section][indexPath.row][1];
    
    CGFloat height = [self tableView:tableView heightForRowAtIndexPath:indexPath];
    CALayer *selectedBackgroundLayer = [PPGroupedTableViewCell baseLayerForSelectedBackgroundForHeight:height];
    if (indexPath.row > 0) {
        [selectedBackgroundLayer addSublayer:[PPGroupedTableViewCell topRectangleLayerForHeight:height]];
    }
    
    if (indexPath.row < [self.data[indexPath.section] count] - 1) {
        [selectedBackgroundLayer addSublayer:[PPGroupedTableViewCell bottomRectangleLayerForHeight:height]];
    }
    [cell setSelectedBackgroundViewWithLayer:selectedBackgroundLayer forHeight:height];

    if (![title isEqual:[NSNull null]]) {
        cell.textLabel.text = title;
    }
    if ([self.heights[detail] floatValue] > 80 && ![self.expandedIndexPaths containsObject:indexPath]) {
        cell.detailTextLabel.font = [UIFont fontWithName:@"Avenir-Medium" size:16];
        if (indexPath.section == [self.titles indexOfObject:@"Software"]) {
            cell.detailTextLabel.text = @"Tap to view license.";
        }
        else {
            cell.detailTextLabel.text = @"Tap to expand.";
        }
    }
    else {
        if (![detail isEqual:[NSNull null]]) {
            cell.detailTextLabel.text = detail;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 0 && indexPath.row == 1) {
        [self followScreenName:@"pushpin_app"];
    }
    else if (indexPath.section == 0 && indexPath.row == 3) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/pushpin-for-pinboard-best/id548052590"]];
    }
    else {
        if ([self.expandedIndexPaths containsObject:indexPath]) {
            [self.expandedIndexPaths removeObject:indexPath];
        }
        else {
            [self.expandedIndexPaths addObject:indexPath];
        }

        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }
}


- (void)followScreenName:(NSString *)screenName {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ACAccountStore *accountStore = [[ACAccountStore alloc] init];
        ACAccountType *twitter = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        
        void (^AccessGrantedBlock)(WCAlertView *) = ^(WCAlertView *loadingAlertView) {
            self.twitterAccountActionSheet = [[RDActionSheet alloc] initWithTitle:NSLocalizedString(@"Select Twitter Account:", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) primaryButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];

            NSMutableDictionary *accounts = [NSMutableDictionary dictionary];
            for (ACAccount *account in [accountStore accountsWithAccountType:twitter]) {
                [self.twitterAccountActionSheet addButtonWithTitle:account.username];
                [accounts setObject:account.identifier forKey:account.username];
            }

            if (loadingAlertView) {
                [loadingAlertView dismissWithClickedButtonIndex:0 animated:YES];
            }

            void (^Tweet)(NSString *) = ^(NSString *username) {
                ACAccount *account = [accountStore accountWithIdentifier:accounts[username]];
                SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                        requestMethod:SLRequestMethodPOST
                                                                  URL:[NSURL URLWithString:@"https://api.twitter.com/1.1/friendships/create.json"]
                                                           parameters:@{@"screen_name": screenName, @"follow": @"true"}];
                [request setAccount:account];
                [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                    [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:NO];
                    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
                    if (response[@"errors"]) {
                        NSString *code = [NSString stringWithFormat:@"Error #%@", response[@"errors"][0][@"code"]];
                        NSString *message = [NSString stringWithFormat:@"%@", response[@"errors"][0][@"message"]];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            WCAlertView *alertView = [[WCAlertView alloc] initWithTitle:code message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"Uh oh.", nil) otherButtonTitles:nil];
                            [alertView show];
                        });
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            WCAlertView *alertView = [[WCAlertView alloc] initWithTitle:NSLocalizedString(@"Success", nil) message:[NSString stringWithFormat:@"You are now following @%@!", screenName] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
                            [alertView show];
                        });
                    }
                }];
            };

            if ([accounts count] == 0) {
            }
            else if ([accounts count] == 1) {
                [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];

                ACAccount *account = [accountStore accountsWithAccountType:twitter][0];
                Tweet(account.username);
            }
            else {
                [[AppDelegate sharedDelegate] setNetworkActivityIndicatorVisible:YES];

                self.twitterAccountActionSheet.callbackBlock = ^(RDActionSheetCallbackType result, NSInteger buttonIndex, NSString *buttonTitle) {
                    if (result == RDActionSheetCallbackTypeClickedButtonAtIndex && ![buttonTitle isEqualToString:@"Cancel"]) {
                        Tweet(buttonTitle);
                    }
                };

                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.twitterAccountActionSheet showFrom:self.navigationController.view];
                });
            }
        };
        
        if (!twitter.accessGranted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                WCAlertView *loadingAlertView = [[WCAlertView alloc] initWithTitle:@"Loading" message:@"Requesting access to your Twitter accounts." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
                [loadingAlertView show];

                self.loadingIndicator.center = CGPointMake(loadingAlertView.bounds.size.width/2, loadingAlertView.bounds.size.height-45);
                [self.loadingIndicator startAnimating];
                [loadingAlertView addSubview:self.loadingIndicator];

                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [accountStore requestAccessToAccountsWithType:twitter
                                                          options:nil
                                                       completion:^(BOOL granted, NSError *error) {
                                                           if (granted) {
                                                               AccessGrantedBlock(loadingAlertView);
                                                           }
                                                           else {
                                                               [loadingAlertView dismissWithClickedButtonIndex:0 animated:YES];
                                                           }
                                                       }];
                });
            });
        }
        else {
            AccessGrantedBlock(nil);
        }
    });
}

- (void)copyURL:(id)sender {
    [[UIPasteboard generalPasteboard] setString:self.data[self.selectedIndexPath.section][self.selectedIndexPath.row][2]];
}

- (void)followUserOnTwitter:(id)sender {
    NSString *screenName = self.data[self.selectedIndexPath.section][self.selectedIndexPath.row][2];
    if (![screenName isEqual:[NSNull null]]) {
        [self followScreenName:screenName];
    }
}

@end
