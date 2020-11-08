pipeline {
    agent any
    tools {
        maven 'M3'
    }

    options {
        buildDiscarder(
            logRotator(artifactNumToKeepStr: '5', numToKeepStr: '10')
        )

        timestamps()
    }
    stages {
        stage('create local branch'){
            when {
                branch 'master'
            }
            steps{
                sh('git checkout -B master')
            }
        }
        stage('Generate navigation'){
            when {
                branch 'master'
            }
            steps{
                sh('./generate_navigation.sh')
            }
        }
        stage('Push') {
            when {
                branch 'master'
            }
            environment { 
                GIT_AUTH = credentials('1f897a89-aed2-478f-9efc-29ae9b6aaa7c') 
            }
            steps {
                sh('''
                    git config --local credential.helper "!f() { echo username=\\$GIT_AUTH_USR; echo password=\\$GIT_AUTH_PSW; }; f"
                    ls
                    git add .;
                    git commit -m "Jenkins Update navigation" || echo;
                    git push origin HEAD:master || echo;
                ''')
            }
        }
        stage('artifactory build') {
            steps {
                rtMavenResolver (
                    id: 'hop-resolver',
                    serverId: 'ART',
                    releaseRepo: 'hop-releases',
                    snapshotRepo: 'hop-snapshots'
                )  
 
                rtMavenDeployer (
                    id: 'hop-deployer',
                    serverId: 'ART',
                    releaseRepo: 'hop-releases-local',
                    snapshotRepo: 'hop-snapshots-local',
                    // By default, 3 threads are used to upload the artifacts to Artifactory. You can override this default by setting:
                    threads: 6
                )

                rtMavenRun (
                    // Tool name from Jenkins configuration.
                    tool: 'M3',
                    pom: 'pom.xml',
                    goals: 'clean install',
                    // Maven options.
                    opts: '-Xms1024m -Xmx4096m',
                    resolverId: 'hop-resolver',
                    deployerId: 'hop-deployer'
                )
            }
        }
        stage('Start Website Build') {
            when {
                branch 'master'
            }
            steps {
                script {
                    build job: "hop-website/master", wait: false
                }
            }
        }
    }
}
