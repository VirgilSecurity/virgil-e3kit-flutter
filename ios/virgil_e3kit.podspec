Pod::Spec.new do |s|
  s.name             = 'virgil_e3kit'
  s.version          = '0.0.1'
  s.summary          = 'Virgil virgil_e3kit kit.'
  s.description      = <<-DESC
Virgil virgil_e3kit.
                       DESC
  s.homepage         = 'http://virgilsecurity.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'VirgilSecurity' => 'help@virgilsecurity.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'VirgilE3Kit', '~> 3.0.1'
  s.platform = :ios, '8.0'
  
  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'  
end
