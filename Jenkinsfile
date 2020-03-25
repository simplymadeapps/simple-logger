pipeline {
  agent {
    label 'ios-slave'
  }
  environment {
    PATH = "/Users/jenkins/.gem/ruby/2.5.3/bin:/Users/jenkins/.rubies/ruby-2.5.3/lib/ruby/gems/2.5.0/bin:/Users/jenkins/.rubies/ruby-2.5.3/bin:/usr/local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/share/dotnet:/Library/Frameworks/Mono.framework/Versions/Current/Commands"
    CODECOV_TOKEN = credentials("SIMPLE_LOGGER_CODECOV_TOKEN")
  }

  options {
    timeout(time: 1, unit: 'HOURS')
  }

  stages {
    stage ('Pod Install') {
      steps {
        // install Pods
        sh 'cd SimpleLoggerExample && pod install'
      }
    }

    stage ('Testing - iOS 10') {
      when {
        branch "master"
      }
      stages {
        stage ('Simulator Setup') {
          steps {
            sh 'xcrun simctl shutdown all'
            sh 'xcrun simctl delete iOS10TestDevice || echo Failed to delete iOS 10 device'

            sh 'rm -rf ~/Library/Developer/Xcode/DerivedData'
            sh 'xcrun simctl create iOS10TestDevice "iPhone 6" com.apple.CoreSimulator.SimRuntime.iOS-10-3'
            sh 'xcrun instruments -w "iOS10TestDevice" || sleep 30'
          }
        }

        stage ('Run Tests') {
          steps {
            sh 'xcodebuild CODE_SIGNING_REQUIRED=NO CODE_SIGNING_IDENTITY= PROVISIONING_PROFILE= GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES GCC_GENERATE_TEST_COVERAGE_FILES=YES -sdk iphonesimulator ONLY_ACTIVE_ARCH=YES VALID_ARCHS=x86_64 -destination "platform=iOS Simulator,name=iOS10TestDevice,OS=10.3.1" -workspace "SimpleLoggerExample/SimpleLogger.xcworkspace" -scheme "SimpleLogger" clean build test'
            sh 'slather'
            sh 'curl -s https://codecov.io/bash | bash -s - -v -f test-reports/cobertura.xml -X coveragepy -X gcov -X xcode'
          }
        }
      }
    }

    stage ('Testing - iOS 11') {
      when {
        branch "master"
      }
      stages {
        stage ('Simulator Setup') {
          steps {
            sh 'xcrun simctl shutdown all'
            sh 'xcrun simctl delete iOS11TestDevice || echo Failed to delete iOS 11 device'

            sh 'rm -rf ~/Library/Developer/Xcode/DerivedData'
            sh 'xcrun simctl create iOS11TestDevice "iPhone 7" com.apple.CoreSimulator.SimRuntime.iOS-11-4'
            sh 'xcrun instruments -w "iOS11TestDevice" || sleep 30'
          }
        }

        stage ('Run Tests') {
          steps {
            sh 'xcodebuild CODE_SIGNING_REQUIRED=NO CODE_SIGNING_IDENTITY= PROVISIONING_PROFILE= GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES GCC_GENERATE_TEST_COVERAGE_FILES=YES -sdk iphonesimulator ONLY_ACTIVE_ARCH=YES VALID_ARCHS=x86_64 -destination "platform=iOS Simulator,name=iOS11TestDevice,OS=11.4" -workspace "SimpleLoggerExample/SimpleLogger.xcworkspace" -scheme "SimpleLogger" clean build test'
            sh 'slather'
            sh 'curl -s https://codecov.io/bash | bash -s - -v -f test-reports/cobertura.xml -X coveragepy -X gcov -X xcode'
          }
        }
      }
    }

    stage ('Testing - iOS 12') {
      when {
        branch "master"
      }
      stages {
        stage ('Simulator Setup') {
          steps {
            sh 'xcrun simctl shutdown all'
            sh 'xcrun simctl delete iOS12TestDevice || echo Failed to delete iOS 12 device'

            sh 'rm -rf ~/Library/Developer/Xcode/DerivedData'
            sh 'xcrun simctl create iOS12TestDevice "iPhone 6" com.apple.CoreSimulator.SimRuntime.iOS-12-2'
            sh 'xcrun instruments -w "iOS12TestDevice" || sleep 30'
          }
        }

        stage ('Run Tests') {
          steps {
            sh 'xcodebuild CODE_SIGNING_REQUIRED=NO CODE_SIGNING_IDENTITY= PROVISIONING_PROFILE= GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES GCC_GENERATE_TEST_COVERAGE_FILES=YES -sdk iphonesimulator ONLY_ACTIVE_ARCH=YES VALID_ARCHS=x86_64 -destination "platform=iOS Simulator,name=iOS12TestDevice,OS=12.2" -workspace "SimpleLoggerExample/SimpleLogger.xcworkspace" -scheme "SimpleLogger" clean build test'
            sh 'slather'
            sh 'curl -s https://codecov.io/bash | bash -s - -v -f test-reports/cobertura.xml -X coveragepy -X gcov -X xcode'
          }
        }
      }
    }

    stage ('Testing - iOS 13') {
      stages {
        stage ('Simulator Setup') {
          steps {
            sh 'xcrun simctl shutdown all'
            sh 'xcrun simctl delete iOS13TestDevice || echo Failed to delete iOS device'

            sh 'rm -rf ~/Library/Developer/Xcode/DerivedData'
            sh 'xcrun simctl create iOS13TestDevice "iPhone 11" com.apple.CoreSimulator.SimRuntime.iOS-13-3'
            sh 'xcrun instruments -w "iOS13TestDevice" || sleep 30'
          }
        }

        stage ('Run Tests') {
          steps {
            sh 'xcodebuild CODE_SIGNING_REQUIRED=NO CODE_SIGNING_IDENTITY= PROVISIONING_PROFILE= GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES GCC_GENERATE_TEST_COVERAGE_FILES=YES -sdk iphonesimulator ONLY_ACTIVE_ARCH=YES VALID_ARCHS=x86_64 -destination "platform=iOS Simulator,name=iOS13TestDevice,OS=13.3" -workspace "SimpleLoggerExample/SimpleLogger.xcworkspace" -scheme "SimpleLogger" clean build test'
            sh 'slather'
            sh 'curl -s https://codecov.io/bash | bash -s - -v -f test-reports/cobertura.xml -X coveragepy -X gcov -X xcode'
          }
        }
      }
    }
  }

  post {
    cleanup {
      sh 'xcrun simctl shutdown all'
      sh 'rm -rf ~/Library/Developer/Xcode/DerivedData'
      sh 'xcrun simctl delete iOS10TestDevice || echo Failed to delete iOS10TestDevice'
      sh 'xcrun simctl delete iOS11TestDevice || echo Failed to delete iOS11TestDevice'
      sh 'xcrun simctl delete iOS12TestDevice || echo Failed to delete iOS12TestDevice'
      sh 'xcrun simctl delete iOS13TestDevice || echo Failed to delete iOS13TestDevice'
    }

    success {
      mail body: "<h2>SimpleLogger (iOS) Build Success</h2>Build Number: ${env.BUILD_NUMBER}<br>Branch: ${env.GIT_BRANCH}<br>Build URL: ${env.JENKINS_URL}blue/organizations/jenkins/Simple%20Logger/detail/${env.GIT_BRANCH}/${env.BUILD_NUMBER}/pipeline",
        charset: 'UTF-8',
           from: 'notice@simpleinout.com',
       mimeType: 'text/html',
        subject: "SimpleLogger (iOS) Build Success: ${env.JOB_NAME}",
             to: "bill@simplymadeapps.com";
    }

    failure {
      mail body: "<h2>SimpleLogger (iOS) Build Failure</h2>Build Number: ${env.BUILD_NUMBER}<br>Branch: ${env.GIT_BRANCH}<br>Build URL: ${env.JENKINS_URL}blue/organizations/jenkins/Simple%20Logger/detail/${env.GIT_BRANCH}/${env.BUILD_NUMBER}/pipeline",
        charset: 'UTF-8',
           from: 'notice@simpleinout.com',
       mimeType: 'text/html',
        subject: "SimpleLogger (iOS) Build Failure: ${env.JOB_NAME}",
             to: "contact@simplymadeapps.com";
    }
  }
}
