source 'https://cdn.cocoapods.org/'

platform :ios, :deployment_target => 11.0
inhibit_all_warnings!
use_frameworks!

def shared_pods
  pod 'AWSS3', '~> 2.10'
end

target 'SimpleLogger' do
  shared_pods
end

target 'SimpleLoggerTests' do
  shared_pods
  pod 'KIF', :configurations => ['Debug']
  pod 'OCMock', :configurations => ['Debug']
end

# the compiler complains about the deploy target for all pods
# deleting the setting for each pod target so it will inherit
# from the main project
# https://stackoverflow.com/questions/54704207/the-ios-simulator-deployment-targets-is-set-to-7-0-but-the-range-of-supported-d
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end
