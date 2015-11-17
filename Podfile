platform :ios, '9.0'

source 'https://github.com/CocoaPods/Specs.git'

inhibit_all_warnings!

pod 'Reachability', '3.2'
pod 'FMDB', '2.4'
pod 'KeychainItemWrapper', '1.2'
pod 'TTTAttributedLabel', '1.13.0'
pod 'Mixpanel', '2.6.2'
pod 'uservoice-iphone-sdk', '3.2.3'
pod 'LHSCategoryCollection', '0.0.17'
pod 'LHSFMDatabaseAdditions', :local => 'Specs/LHSFMDatabaseAdditions.podspec'
pod 'LHSTableViewCells'
pod 'LHSDiigo', :local => 'Vendor/LHSDiigo'
pod 'LHSDelicious', :local => 'Vendor/LHSDelicious'
pod 'HTMLParser', :local => 'Specs/HTMLParser.podspec'
pod 'TextExpander', '3.0.5'
pod 'MWFeedParser', '1.0.1'
pod 'ASPinboard', :local => 'Vendor/ASPinboard'
pod 'OpenInChrome', '0.0.1'
pod 'AFNetworking', '2.2.0'
pod 'LHSKeyboardAdjusting', '0.0.1'
pod 'RNCryptor', '2.2'
pod '1PasswordExtension', '1.6.4'
pod 'YHRoundBorderedButton', '0.1.0'
pod 'ChimpKit'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
