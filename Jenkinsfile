/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

def AGENT_LABEL = env.AGENT_LABEL ?: 'ubuntu'

pipeline {

    agent {
        label AGENT_LABEL
    }

    options {
        buildDiscarder(
            logRotator(artifactNumToKeepStr: '5', numToKeepStr: '10')
        )
        disableConcurrentBuilds()
    }

    stages {
        stage('Initialization') {
              steps {
                  echo 'Building Branch: ' + env.BRANCH_NAME
                  echo 'Using PATH = ' + env.PATH
              }
         }
         stage('Cleanup') {
              steps {
                  echo 'Cleaning up the workspace'
                  deleteDir()
              }
         }
        stage('Checkout') {
            steps {
                echo 'Checking out branch ' + env.BRANCH_NAME
                checkout scm
            }
        }
        stage('checkout Hop Code') {
            when {
                branch 'master'
            }
            steps {
                dir('hop') {
                    deleteDir()
                    sh 'git clone -b master https://github.com/apache/incubator-hop.git .'
                }
            }
        }
        stage('Copy project docs') {
            when {
                branch 'master'
            }
            steps {
                    sh 'mkdir ./tmp'
                    sh "find ./hop -name '*.adoc' -exec cp -prv --parents '{}' './tmp/' ';'"
            }
        }
        stage('Process Docs') {
            when {
                branch 'master'
            }
            steps {
                sh '''
                    cd ./tmp;
                    for f in $(find ./ -name '*.adoc')
                    do
                    echo "Processing $f"
                    FILEPATH=$(grep -nr "documentationPath" $f | awk -F  ":" '{print $4}' | sed -e 's/^[[:space:]]*//');
                    if ! [ -z "$FILEPATH" ]
                    then
                        mkdir -p ../hop-user-manual/modules/ROOT/pages$FILEPATH && cp $f ../hop-user-manual/modules/ROOT/pages$FILEPATH;
                    fi
                    done
                    rm -rf ./tmp
                    rm -rf ./hop
                '''
                sh 'git add .'
                //sh 'git commit -m "Documentation updated to $GIT_COMMIT"'
                //sh 'git push --force origin master'
            }
        }
    }
    post {
        always {
            cleanWs()
            emailext(
                subject: '${DEFAULT_SUBJECT}',
                body: '${DEFAULT_CONTENT}',
                recipientProviders: [[$class: 'CulpritsRecipientProvider']]
            )
        }
    }
}
