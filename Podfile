platform :ios, '8.0'
use_frameworks!

target 'Blurv' do
pod 'Parse', '1.13.0'
pod 'ParseFacebookUtilsV4', '1.9.1'
pod 'pop', '1.0.9'
pod 'Fabric', '1.6.7'
pod 'Firebase', '2.5.1'
pod 'Crashlytics', '3.7.0'
pod 'SVProgressHUD', '2.0.3'
pod 'KMPlaceholderTextView', '1.2.0'
pod 'FacebookImagePicker', '2.0.9'
pod 'MARKRangeSlider', '1.0.1'
pod 'Koloda', '3.1.1'
pod 'SDWebImage', '3.7.2'

end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ""
            config.build_settings['CODE_SIGNING_REQUIRED'] = "NO"
            config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
        end
    end
end