# Beacon SDK

[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Beacon.svg)](https://img.shields.io/cocoapods/v/Beacon.svg)

Help Scout's Beacon SDK allows you to embed the same Beacon functionality we have for the web inside your iOS app. Beacons provide a quick and straightforward way for customers to flip through your knowledge base or reach out to your team.

## Requirements

The Beacon SDK 2.0 requires iOS 11.0+.

As of Beacon 2.1.0 Xcode 12 is required to build with the Beacon SDK.
Beacon 2.0.x requires Xcode 11.4

### Supported platform and language versions

* iOS 11 to 14
* Swift 5
* Xcode 12

## Installation

### CocoaPods

Beacon is available through [CocoaPods][1]. To install it, add the following line to your `Podfile`:

```ruby
pod 'Beacon'
```

Beacon is currently distributed as a dynamic framework so the `use_frameworks!` flag will also need to be present in your Podfile.

### Swift Package Manager

Beacon is available through [Swift Package Manager](https://swiftpackageregistry.com/helpscout/beacon-ios-sdk). To install it, simply follow [Apple’s guidance](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app) for adding the Beacon-iOS package dependency in Xcode.

### Carthage 🛑

**As of Beacon 2.1.0, Beacon is (temporarily 🤞) no longer available to be distributed via Carthage.  This is because Beacon is now distributed as an XCFramework which is (as of October 29th, 2020) not supported by Carthage.  More info about the progress the Carthage team is making can be found on this [issue](https://github.com/Carthage/Carthage/issues/3019) or the following Pull Requests [1](https://github.com/Carthage/Carthage/pull/3071), [2](https://github.com/Carthage/Carthage/pull/2881).**

Beacons up to version 2.0.2 can be installed using Carthage by adding the following line to your `Cartfile` and then following the [Carthage installation instructions][2]:

```ruby
github "helpscout/beacon-ios-sdk"
```

_Because of the way Beacon is distributed, attempting to use the `--no-use-binaries` flag when building will fail._

### Manually

Beacon can be installed manually by linking the `Beacon.xcframework`. To do so, download the `Beacon.xcframework.zip` from [here](https://github.com/helpscout/beacon-ios-sdk/releases) and [add Beacon.xcframework to your Xcode project](https://developer.apple.com/library/archive/technotes/tn2435/_index.html).

## Additional Setup

Our [developer site](https://developer.helpscout.com/beacon-2/ios/#additional-setup) has information on configuring up your application to work with Beacon's email attachments and push notifications.

## Sample Applications

This repository includes two sample applications, one written in Objective-C and one written with SwiftUI.  

To run the Objective-C example you can cd into the Examples/Obj-C Example directory `cd Examples/Obj-C\ Example`, open `Beacon Example.xcodeproj` and run the `BeaconExample` scheme.

To run the SwiftUI example you can cd into the Examples/SwiftUI Example directory `cd Examples/SwiftUI\ Example`, open `Beacon SwiftUI Example.xcodeproj` and run the `Beacon SwiftUI Example` scheme.  For it to run properly you'll need to provide a valid Beacon identifer on Line 10 of `SettingsView.swift`.

## Documentation

See our [developer site](https://developer.helpscout.com/beacon-2/ios/) for more customization options available through the SDK.

[1]:    http://cocoapods.org
[2]:    https://github.com/Carthage/Carthage#adding-frameworks-to-an-application
