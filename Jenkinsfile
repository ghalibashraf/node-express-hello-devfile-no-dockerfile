pipeline {
    agent any

    options {
        timestamps()
        timeout(time: 10, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    triggers {
        pollSCM('H/5 * * * *')
    }

    environment {
        DIND_CONTAINER        = 'jenkins-docker'
        BRIDGE_NETWORK        = 'jenkins'
        REGISTRY              = 'registry:5000'
        IMAGE                 = 'node-hello-app-2'
        JENKINS_DOCKER_ALIAS  = 'docker'
        CONTAINER_PORT        = '8080'
        HOST_PORT             = '8080'
        TEST_CONTAINER        = 'ci-test'
        WAIT_TIME             = '5'
    }

    stages {
        stage('Pre-check Docker') {
            steps {
                echo 'Checking Docker-in-Docker container...'
                script {
                    try {
                        sh "docker version"
                        echo "Docker-in-Docker is up and running."
                    } catch (e) {
                        error "Could not reach Docker-in-Docker container! Ensure '${DIND_CONTAINER}' is running and attached to network '${BRIDGE_NETWORK}'."
                    }
                }
            }
        }

        stage('Clone the Repository') {
            steps {
                echo 'Checking out source code.'
                checkout scm
            }
        }

        stage('Determine Tag') {
            steps {
                script {
                    VERSION    = "${env.BUILD_NUMBER}"
                    FULL_IMAGE = "${REGISTRY}/${IMAGE}:${VERSION}"
                    echo "Image tag: ${FULL_IMAGE}"
                }
            }
        }

        stage('Build, Tag & Push') {
            steps {
                script {
                    echo "Building and tagging ${FULL_IMAGE}"
                    def img = docker.build(FULL_IMAGE)
                    echo "Pushing ${FULL_IMAGE} to local registry."
                    docker.withRegistry("http://${REGISTRY}", '') {
                        img.push()
                    }
                }
            }
        }

        stage('Tests') {
            steps {
                echo 'Running docker image from local registry.'
                sh "docker run -d --name ${TEST_CONTAINER} -p ${HOST_PORT}:${CONTAINER_PORT} ${FULL_IMAGE}"
                echo 'Waiting for the container to start.'
                sh "sleep ${WAIT_TIME}"
                echo 'Hitting the /hello endpoint multiple times to verify counter increments.'
                script {
                    for (int i = 1; i <= 5; i++) {
                        echo "Request ${i}"
                        sh "curl -s http://${JENKINS_DOCKER_ALIAS}:${CONTAINER_PORT}/hello"
                        sleep 1
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up test container.'
            sh "docker rm -f ${TEST_CONTAINER} || true"
        }
    }
}
