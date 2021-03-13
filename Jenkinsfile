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

def AGENT_LABEL = env.AGENT_LABEL ?: 'git-websites'

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
        stage('checkout Hop Code') {
            when {
                branch 'asf-site'
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
                branch 'asf-site'
            }
            steps {
                    sh 'mkdir ./tmp'
                    sh "find ./hop -name '*.adoc' -exec cp -prv --parents '{}' './tmp/' ';'"
            }
        }
        stage('Process Docs') {
            when {
                branch 'asf-site'
            }
            steps {
                echo 'Adding new Files from Hop'
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
                    cd ..
                    rm -rf ./tmp
                    rm -rf ./hop
                '''
                /*echo 'Generate new Navigation'
                sh './generate_navigation.sh'*/
                }
        }
        stage('Deploy') {
            when {
                branch 'asf-site'
            }
            steps {
                dir('deploy/staging') {
                    deleteDir()
                    sh 'git clone -b asf-site https://gitbox.apache.org/repos/asf/incubator-hop-docs.git .'
                    sh "cp -R $WORKSPACE/hop-dev-manual/. ./hop-dev-manual/"
                    sh "cp -R $WORKSPACE/hop-doc-resources/. ./hop-doc-resources/"
                    sh "cp -R $WORKSPACE/hop-tech-manual/. ./hop-tech-manual/"
                    sh "cp -R $WORKSPACE/hop-user-manual/. ./hop-user-manual/"
                    sh 'git add .'
                    sh 'git commit -m "Documentation updated to $(git rev-parse --short HEAD)" || echo'
                    sh 'git push origin asf-site || echo'
                }
            }
       }
        stage('Website update') {
            when {
                branch 'asf-site'
            }
            steps {
                build job: 'Hop/Hop-website/master', wait: false
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
