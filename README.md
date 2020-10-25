# SimpleLogger
`SimpleLogger` is an easy to use log file generator for iOS that uploads to Amazon S3.

[![codebeat badge](https://codebeat.co/badges/f00f7099-2c82-4867-9e15-e28c3996fecb)](https://codebeat.co/projects/github-com-simplymadeapps-simple-logger-master)
[![Build Status](https://travis-ci.org/simplymadeapps/simple-logger.svg?branch=master)](https://travis-ci.org/simplymadeapps/simple-logger)

## Requirements
`SimpleLogger` works on iOS 11+ and requires ARC to build. It depends on the following Apple Frameworks which should already be included with Xcode:

* Foundation.framework
* AWSS3

## Adding SimpleLogger to your project

### Cocoapods

[CocoaPods](http://cocoapods.org) is the recommended way to add `SimpleLogger` to your project.

1. Add a pod entry for SimpleLogger to your Podfile `pod 'SimpleLogger', '~-> 1.0.0'`
2. Install the pod(s) by running `pod install`.
3. Include `SimpleLogger` wherever you need it with `#import "SimpleLogger.h"`.

### Source files

You can directly add the contents of the `SimpleLogger` folder to your project. It contains `SimpleLogger.h/m` as well as a category for date helpers and a header for the defaults. You will need to link to the `AWSS3` framework provided by Amazon for this to work. Cocoapods will automatically include it.

## Usage

### Local Logging

If you only want to log the files out locally you can just dive right in with the log event method:

```objective-c
[SimpleLogger addLogEvent:@"Log some event to today's file."];
```

This will create a file with the current date in the documents directory using the default date/time formatting.
`[2017-8-14 10:10:10] Log some event to today's file.`

### Advanced Setup

You can customize many of the logging formats and settings:

```objective-c
// number of days of log files are retained by the logger (default 7)
[[SimpleLogger sharedLogger] setRetentionDays:7];

// log event formatter date format
[[[SimpleLogger sharedLogger] logFormatter] setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
// the log event formatter defaults to en-US locale
// create your own or overwrite to locale of choice

// file name date format
// be sure to set this one before writing your first log event to avoid duplicate files for same day
// the filename formatter defaults to en-US locale
// create your own or overwrite to locale of choice
[[SimpleLogger sharedLogger] setFilenameFormatter:yourDateFormatter];

// filename extension
[[SimpleLogger sharedLogger] setFilenameExtension:@"log"];

// folder location inside your AWSS3 bucket
[[SimpleLogger sharedLogger] setFolderLocation:@"Your/Folder/Location"];
```

### Upload Logs to Amazon

You must initialize `SimpleLogger` with the correct Amazon AWS S3 credentials and bucket to upload your log files. If you plan to upload, call the initializer early enough in your app to let the Amazon library to initialize and be ready for upload. We recommend during app startup in the AppDelegate.

```objective-c
[SimpleLogger initWithAWSRegion:AWSRegionUSEast1 bucket:@"my-bucket-name" accessToken:@"MYAMAZONACCESSTOKEN" secret:@"MYAMAZONSECRET"];
```

You should NOT manually set the variables even though it is possible. Use the initializer method to validate your values and pass them to AWSS3 to avoid crashing your application.

iOS 9 users need to support App Transport Security (ATS). To prevent uploads from failing, add the following keys to your `Info.plist`.

```objective-c
<key>NSAppTransportSecurity</key>
    <dict>
            <key>NSExceptionDomains</key>
            <dict>
            <key>amazonaws.com</key>
            <dict>
                    <key>NSThirdPartyExceptionMinimumTLSVersion</key>
                    <string>TLSv1.0</string>
                    <key>NSThirdPartyExceptionRequiresForwardSecrecy</key>
                    <false/>
                    <key>NSIncludesSubdomains</key>
                    <true/>
            </dict>
            <key>amazonaws.com.cn</key>
            <dict>
                    <key>NSThirdPartyExceptionMinimumTLSVersion</key>
                    <string>TLSv1.0</string>
                    <key>NSThirdPartyExceptionRequiresForwardSecrecy</key>
                    <false/>
                    <key>NSIncludesSubdomains</key>
                    <true/>
            </dict>
            </dict>
    </dict>
```

## License

This code is distributed under the terms and conditions of the [MIT license](LICENSE).

## Author

This library was written by [Bill Burgess](https://github.com/billburgess), Co-Founder and iOS/Mac Developer for [Simply Made Apps](https://www.simpleinout.com).

## Android

You can find the Android companion library at [SimpleLogger-Android](https://github.com/simplymadeapps/simple-logger-android).
