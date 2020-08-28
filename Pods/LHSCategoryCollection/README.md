# LHSCategoryCollection

This is a collection of helpful categories for use in iOS projects.

## Usage

LHSCategoryCollection has a lot of great categories that are quick and easy to use. Here, I'm going to cover a few functions of the UIView+LHSAdditions category.

### Necessary import and protocol for using the UIView+LHSAdditions of LHSCategoryCollection

```objc
#import <LHSCategoryCollection/UIView+LHSAdditions.h>
```

### For these samples, we will be using three views

```objc
@property (nonatomic, strong) UIView *redBox;
@property (nonatomic, strong) UIView *greenBox;
@property (nonatomic, strong) UIView *blueBox;
```

### Initialize your views in the viewDidLoad method

```objc
self.redBox = [[UIView alloc] init];
self.redBox.translatesAutoresizingMaskIntoConstraints = NO;
self.redBox.backgroundColor = [UIColor redColor];

self.greenBox = [[UIView alloc] init];
self.greenBox.translatesAutoresizingMaskIntoConstraints = NO;
self.greenBox.backgroundColor = [UIColor greenColor];

self.blueBox = [[UIView alloc] init];
self.blueBox.translatesAutoresizingMaskIntoConstraints = NO;
self.blueBox.backgroundColor = [UIColor blueColor];
```

### To size a view with margins

```objc
[self.view addSubview:self.blueBox];
[self.blueBox lhs_expandToFillSuperviewWithVerticalMargin:20 horizontalMargin:20];
```

### To center a view vertically and horizontally

```objc
[self.blueBox addSubview:self.redBox];
[UIView lhs_addConstraints:@"H:[view(100)]" views:@[self.redBox]];
[UIView lhs_addConstraints:@"V:[view(100)]" views:@[self.redBox]];
[self.blueBox lhs_centerHorizontallyForView:self.redBox];
[self.blueBox lhs_centerVerticallyForView:self.redBox];
```

The end result looks like this:

![image](http://i.imgur.com/m6FuBmd.png)

### To position views with margins 

```objc
NSDictionary *metrics = @{
                          @"verticalMargin": @(55),
                          @"horizontalMargin": @(15)
                          };


NSDictionary *views = @{
                        @"greenBox": self.greenBox,
                        @"redBox": self.redBox
                        };

[self.view addSubview:self.redBox];
[self.view addSubview:self.greenBox];

[UIView lhs_addConstraints:@"H:|-(horizontalMargin)-[view]-(horizontalMargin)-|" metrics:metrics views:@[self.redBox, self.greenBox]];
[self.redBox lhs_fillHeightOfSuperview];
[self.view lhs_addConstraints:@"V:|-(verticalMargin)-[greenBox]-(verticalMargin)-|" metrics:metrics views:views];
```

The end result looks like this:

![image](http://i.imgur.com/PNA3DvM.png)

## Requirements

You will not have any issues if you are building for iOS 7 or higher.

## Installation

LHSCategoryCollection is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "LHSCategoryCollection"
```

## Author

Dan Loewenherz, dan@lionheartsw.com

## License

LHSCategoryCollection is available under the Apache 2.0 license. See the LICENSE file for more info.


