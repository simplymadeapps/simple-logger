Pod::Spec.new do |s|

  s.name         = 'SimpleLogger'
  s.version      = '2.0'
  s.summary      = 'SimpleLogger is an easy to use log file generator for iOS that uploads to Amazon S3.'

  s.homepage     = 'https://github.com/simplymadeapps/simple-logger'
  s.license      = 'MIT'
  s.author       = { 'Bill Burgess' => 'bill@simplymadeapps.com' }

  s.ios.deployment_target = '11.0'

  s.source       = { :git => 'https://github.com/simplymadeapps/simple-logger.git', :tag => s.version }
  s.source_files  = 'SimpleLogger/*.{h,m}'
  s.requires_arc = true

  s.dependency 'AWSS3'

end
