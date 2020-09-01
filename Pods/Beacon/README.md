# Beacon SDK

[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Beacon.svg)](https://img.shields.io/cocoapods/v/Beacon.svg)

Help Scout's Beacon SDK allows you to embed the same Beacon functionality we have for the web inside your iOS app. Beacons provide a quick and straightforward way for customers to flip through your knowledge base or reach out to your team.

## Requirements

The Beacon SDK 2.0 requires iOS 11.0+.

Xcode 11 is required to build with the Beacon SDK.

## Installation

### CocoaPods

Beacon is available through [CocoaPods][1]. To install it, add the following line to your `Podfile`:

```ruby
pod 'Beacon'
```

Beacon is currently distributed as a dynamic framework so the `use_frameworks!` flag will also need to be present in your Podfile.

### Carthage

Beacon can be installed using Carthage by adding the following line to your `Cartfile` and then following the [Carthage installation instructions][2]:

```ruby
github "helpscout/beacon-ios-sdk"
```

_Because of the way Beacon is distributed, attempting to use the `--no-use-binaries` flag when building will fail._

### Manually

Beacon can be installed manually by linking the Beacon framework and bundle. To do so, download the Beacon framework from [here](https://github.com/helpscout/beacon-ios-sdk/releases) and integrate it similar to [how Carthage integrates frameworks](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application).

## Additional Setup

Our [developer site](https://developer.helpscout.com/beacon-2/ios/#additional-setup) has information on configuring up your application to work with Beacon's email attachments and push notifications.

## Sample Application

To run the example project in this repo, clone and run `carthage bootstrap` from the root directory. Once the bootstrap is complete, cd into the Example directory `cd Example`, open `Beacon Example.xcodeproj` and run the `BeaconExample` scheme.

## Documentation

See our [developer site](https://developer.helpscout.com/beacon-2/ios/) for more customization options available through the SDK.

[1]:    http://cocoapods.org
[2]:    https://github.com/Carthage/Carthage#adding-frameworks-to-an-application
