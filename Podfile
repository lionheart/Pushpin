platform :ios, '9.3'

source 'https://github.com/CocoaPods/Specs.git'
project 'Pushpin.xcodeproj'

inhibit_all_warnings!
use_frameworks!

target 'PushpinFramework' do
  pod 'Reachability', '3.2'
  pod 'FMDB', '~> 2.4'
  pod 'KeychainItemWrapper', '1.2'
  pod 'TTTAttributedLabel', '1.13.0'
  pod 'Mixpanel', '2.6.2'
  pod 'uservoice-iphone-sdk', '3.2.3'
  pod 'LHSCategoryCollection', '0.0.17'
  pod 'LHSFMDatabaseAdditions', '0.0.3'
  pod 'LHSTableViewCells'
  pod 'BRYHTMLParser'
  pod 'TextExpander', '3.0.5'
  pod 'MWFeedParser', '1.0.1'
  pod 'ASPinboard', :path => 'Vendor/ASPinboard'
  pod 'HTMLParser'
  pod 'OpenInChrome', '0.0.1'
  pod 'AFNetworking', '2.2.0'
  pod 'LHSKeyboardAdjusting', '0.0.1'
  pod 'RNCryptor', '~> 4.0'
  pod '1PasswordExtension', '~> 1.8'
  pod 'YHRoundBorderedButton', '0.1.0'
  pod 'ChimpKit'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
