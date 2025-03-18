# Uncomment the next line to define a global platform for your project
platform :ios, '17.4'

target 'Places' do
# Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Firebase Pods
  pod 'Firebase/Core'
  pod 'Firebase/Analytics'
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Storage'
  pod 'Firebase/Database'
  pod 'FirebaseFirestoreSwift'
  pod 'FirebaseAppCheck'
  pod 'FirebaseInstallations'


  # Google Sign-In Pods
  pod 'GoogleSignIn'
  pod 'GoogleSignInSwiftSupport'

  # SDWebImage Pods
  pod 'SDWebImage'
  pod 'SDWebImageSwiftUI'

  # Naver Map Pods
  pod 'NMapsMap'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end

