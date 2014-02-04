//
//  PPBrowserActivity.h
//  Pushpin
//
//  Created by Andy Muldowney on 10/15/13.
//
//

#import <UIKit/UIKit.h>

@interface PPBrowserActivity : UIActivity

@property (nonatomic, retain) NSString *urlScheme;
@property (nonatomic, retain) NSString *browserName;
@property (nonatomic, retain) NSString *urlString;

- (id)initWithUrlScheme:(NSString *)scheme;
- (id)initWithUrlScheme:(NSString *)scheme browser:(NSString *)browser;

@end
