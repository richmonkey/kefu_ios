platform :ios, '8.0'
target 'kefu' do
    pod 'gobelieve', :path => './dev.podspec'
#    pod 'gobelieve', :git => 'git@github.com:GoBelieveIO/im_ios.git', :branch => 'kefu'
    pod 'Masonry'
    pod 'JSBadgeView'
    pod 'AFNetworking', '~> 3.0'
    pod 'Objective-LevelDB'
end

post_install do |installer|
    copy_pods_resources_path = "Pods/Target Support Files/Pods-kefu/Pods-kefu-resources.sh"
    string_to_replace = '--compile "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"'
    assets_compile_with_app_icon_arguments = '--compile "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}" --app-icon "${ASSETCATALOG_COMPILER_APPICON_NAME}" --output-partial-info-plist "${BUILD_DIR}/assetcatalog_generated_info.plist"'
    text = File.read(copy_pods_resources_path)
    new_contents = text.gsub(string_to_replace, assets_compile_with_app_icon_arguments)
    File.open(copy_pods_resources_path, "w") {|file| file.puts new_contents }
end
