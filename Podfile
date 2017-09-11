# vim: set ft=ruby

platform :ios, '10.3'

source 'https://github.com/CocoaPods/Specs.git'
project 'Pushpin.xcodeproj'

inhibit_all_warnings!
use_frameworks!

pod 'TMReachability', :git => 'https://github.com/lionheart/Reachability', :commit => 'e34782b386307e386348b481c02c176d58ba45e6'
pod 'KeychainItemWrapper', '~> 1.2'
pod 'TTTAttributedLabel', '~> 1.13'
pod 'BRYHTMLParser'
pod 'MWFeedParser', '1.0.1'
pod 'HTMLParser'
pod 'AFNetworking', '~> 3.0'
pod 'RNCryptor-objc', '~> 3'
pod 'LHSCategoryCollection', :path => '../LHSCategoryCollection'
pod 'LHSKeyboardAdjusting', :path => '../LHSKeyboardAdjusting'
pod 'LHSFMDatabaseAdditions', '~> 0.0'
pod 'LHSTableViewCells'
pod 'FMDB'
pod 'ASPinboard', '~> 1.0'

target 'Pushpin' do
  pod 'Mixpanel'
  pod 'ChimpKit'
  pod 'OpenInChrome', '~> 0.0'
  pod 'Google-Mobile-Ads-SDK'
  pod '1PasswordExtension', '~> 1.8'
end

target 'Bookmark Extension' do
  pod 'Mixpanel-AppExtension'
end

target 'Read Later Extension' do
  pod 'Mixpanel-AppExtension'
end
