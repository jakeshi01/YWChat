#
# Be sure to run `pod lib lint YWChat.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'YWChat'
  s.version          = '1.0.4'
  s.summary          = 'pod for YWIM'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/jakeshi01/YWChat'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'jakeshi01' => '18922189211@189.cn' }
  s.source           = { :git => 'https://github.com/jakeshi01/YWChat.git' }

  s.ios.deployment_target = '9.0'

  s.source_files = ['Class/***/**','Class/*']

  s.requires_arc = true

  s.frameworks   = [
    'UIKit',
    'AddressBook',
    'SystemConfiguration',
    'CoreLocation',
    'CoreTelephony',
    'CoreData',
    'MobileCoreServices',
    'ImageIO',
    'AudioToolbox',
    'AVFoundation',
    'AssetsLibrary',
    'CoreMotion'
  ]
  s.libraries = ['stdc++.6.0.9', 'z', 'sqlite3.0', 'resolv']
  s.resources = ['wx/WXFrameworks/yw_1222.jpg', 'wx/WXFrameworks/WXOpenIMSDKResource.bundle', 'wx/WXFrameworks/WXOUIModuleResources.bundle']
  s.compiler_flags = '-ObjC'
  
   s.vendored_frameworks = [
    'wx/WXFrameworks/WXOUIModule.framework',
    'wx/WXFrameworks/WXOpenIMTribeKit.framework',
    'wx/WXFrameworks/WXOpenIMSDKFMWK.framework'
  ]


end
