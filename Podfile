platform :osx, '10.14'

target 'XcodeRichPresence' do
  use_frameworks!
  pod 'SwordRPC'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
        config.build_settings['MACH_O_TYPE'] = 'staticlib'
    end
  end
end