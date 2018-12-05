pipeline {
    agent {
        label 'ios-slave'
    }
    environment {
        PATH = "/Users/jenkins/.gem/ruby/2.5.3/bin:/Users/jenkins/.rubies/ruby-2.5.3/lib/ruby/gems/2.5.0/bin:/Users/jenkins/.rubies/ruby-2.5.3/bin:/usr/local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/share/dotnet:/Library/Frameworks/Mono.framework/Versions/Current/Commands"
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
                        sh 'xcrun simctl erase all'

                        sh 'xcrun instruments -w "iPhone X (12.1) [" || sleep 30'
                    }
                }

                stage ('Run Tests') {
                    steps {
                        sh 'xcodebuild CODE_SIGNING_REQUIRED=NO CODE_SIGNING_IDENTITY= PROVISIONING_PROFILE= GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES GCC_GENERATE_TEST_COVERAGE_FILES=YES -sdk iphonesimulator ONLY_ACTIVE_ARCH=YES VALID_ARCHS=x86_64 -destination "platform=iOS Simulator,name=iPhone X,OS=12.1" -workspace "SimpleLoggerExample/SimpleLogger.xcworkspace" -scheme "SimpleLogger" clean build test'
                    }
                }
            }
            post {
                always {
                    sh 'slather'
                    sh 'curl -s https://codecov.io/bash | bash -s - -f test-reports/cobertura.xml -t ${SIMPLE_LOGGER_IOS_CODECOV_TOKEN}'
                }
            }
        }
    }
}
