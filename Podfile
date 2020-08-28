# vim: set ft=ruby
inhibit_all_warnings!
use_frameworks!

platform :ios, '13.6'
source 'https://github.com/CocoaPods/Specs.git'
project 'Pushpin.xcodeproj'

pod 'TMReachability', :git => 'https://github.com/lionheart/Reachability', :commit => 'e34782b386307e386348b481c02c176d58ba45e6'
pod 'KeychainItemWrapper', '~> 1.2'
pod 'TTTAttributedLabel', '~> 1.13'
pod 'BRYHTMLParser'
pod 'MWFeedParser', '1.0.1'
pod 'HTMLParser'
pod 'AFNetworking', '~> 3.0'
pod 'RNCryptor-objc', '~> 3'
pod 'LHSCategoryCollection'
pod 'LHSKeyboardAdjusting', '~> 2.0'
pod 'LHSFMDatabaseAdditions', '~> 0.0'
pod 'LHSTableViewCells'
pod 'FMDB'
pod 'ASPinboard', '~> 1.0'
pod 'QuickTableView'
pod 'SuperLayout', '~> 2.0'
pod 'LionheartExtensions'
pod 'Mixpanel'

target 'Pushpin' do
  pod 'ChimpKit'
  pod 'OpenInChrome', '~> 0.0'
  pod 'LionheartExtensions'
  pod 'QuickTableView'
  pod 'TipJarViewController'
  pod 'Beacon'
  pod 'Firebase/Core'
end

target 'Bookmark Extension' do
end

target 'Read Later Extension' do
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'No'
    end
  end
end
