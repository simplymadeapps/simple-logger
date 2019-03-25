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
    stage ('Testing - Latest') {
      stages {
        stage ('Simulator Setup') {
          steps {
            sh 'xcrun simctl shutdown all'
            sh 'xcrun simctl delete iOSTestDevice || echo Failed to delete iOS 10 device'

            sh 'rm -rf ~/Library/Developer/Xcode/DerivedData'
            sh 'xcrun simctl create iOSTestDevice "iPhone X" 12.1'
            sh 'xcrun instruments -w "iOSTestDevice" || sleep 30'
          }
        }

        stage ('Run Tests') {
          steps {
            sh 'xcodebuild CODE_SIGNING_REQUIRED=NO CODE_SIGNING_IDENTITY= PROVISIONING_PROFILE= GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES GCC_GENERATE_TEST_COVERAGE_FILES=YES -sdk iphonesimulator ONLY_ACTIVE_ARCH=YES VALID_ARCHS=x86_64 -destination "platform=iOS Simulator,name=iOSTestDevice,OS=12.1" -workspace "SimpleLoggerExample/SimpleLogger.xcworkspace" -scheme "SimpleLogger" clean build test'
            sh 'slather'
            sh 'curl -s https://codecov.io/bash | bash -s - -f test-reports/cobertura.xml -t ${CODECOV_TOKEN} -X coveragepy -X gcov -X xcode'
          }
        }
      }
    }
  }

  post {
    cleanup {
      sh 'xcrun simctl shutdown all'
      sh 'rm -rf ~/Library/Developer/Xcode/DerivedData'
      sh 'xcrun simctl delete iOSTestDevice || echo Failed to delete iOSTestDevice' 
    }

    success {
      mail body: "<h2>Jenkins Build Success</h2>Build Number: ${env.BUILD_NUMBER}<br>Branch: ${env.GIT_BRANCH}<br>Build URL: ${env.JENKINS_URL}/blue/organizations/jenkins/Simple%20Logger%20iOS/detail/${env.GIT_BRANCH}/${env.BUILD_NUMBER}/pipeline",
        charset: 'UTF-8',
           from: 'notice@simpleinout.com',
       mimeType: 'text/html',
        subject: "Jenkins Build Success: ${env.JOB_NAME}",
             to: "bill@simplymadeapps.com";
    }

    failure {
      mail body: "<h2>Jenkins Build Failure</h2>Build Number: ${env.BUILD_NUMBER}<br>Branch: ${env.GIT_BRANCH}<br>Build URL: ${env.JENKINS_URL}/blue/organizations/jenkins/Simple%20Logger%20iOS/detail/${env.GIT_BRANCH}/${env.BUILD_NUMBER}/pipeline",
        charset: 'UTF-8',
           from: 'notice@simpleinout.com',
       mimeType: 'text/html',
        subject: "Jenkins Build Failure: ${env.JOB_NAME}",
             to: "bill@simplymadeapps.com";
    }
  }
}
