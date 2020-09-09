# vim: set ft=ruby

load 'remove_unsupported_libraries.rb'

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
pod 'AFNetworking', '~> 4.0'
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

target 'Pushpin' do
  pod 'ChimpKit'
  pod 'OpenInChrome', '~> 0.0'
  pod 'LionheartExtensions'
  pod 'QuickTableView'
  pod 'TipJarViewController', '~> 2.0'
  pod 'Beacon'
  pod 'Firebase/Core'
  pod 'Heap'
end

target 'Bookmark Extension' do
end

target 'Read Later Extension' do
end

# TODO: uncomment to attempt to build for Catalyst 
# excluded = ['TipJarViewController', 'ChimpKit', 'Beacon', 'FirebaseAnalytics', 'FIRAnalyticsConnector', 'GoogleAppMeasurement']

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'No'
    end
  end

#  installer.pods_project.targets.each do |target|
#    if target.name == "Pods-Pushpin"
#      puts "Updating #{target.name} to exclude non-iOS libraries"
#      target.build_configurations.each do |config|
#        xcconfig_path = config.base_configuration_reference.real_path
#        xcconfig = File.read(xcconfig_path)
#        excluded.each { |item| xcconfig.sub!('-framework "' + item + '"', '') }
#        items = excluded.collect { |item| '-framework "' + item + '"' }
#        new_xcconfig = xcconfig + 'OTHER_LDFLAGS[sdk=iphone*] = ' + items.join(' ')
#        File.open(xcconfig_path, "w") { |file| file << new_xcconfig }
#      end
#    end
#  end
end
