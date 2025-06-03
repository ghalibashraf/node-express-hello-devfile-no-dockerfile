pipeline {
    agent any

    options {
        timestamps()
        timeout(time: 10, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    parameters {
        string(
            name: 'HOST_PORT', 
            defaultValue: '8080', 
            description: 'Port on host to expose the app'
        )
        string(
            name: 'CONTAINER_PORT', 
            defaultValue: '8080', 
            description: 'Port inside container used by the app'
        )
        string(
            name: 'IMAGE_NAME', 
            defaultValue: 'node-hello-app', 
            description: 'Base name for Docker image'
        )
        string(
            name: 'TEST_CONTAINER', 
            defaultValue: 'ci-test', 
            description: 'Name of the test container'
        )
        string(
            name: 'WAIT_TIME', 
            defaultValue: '5', 
            description: 'Seconds to wait before testing'
        )
    }


    triggers {
        pollSCM('H/5 * * * *')
    }

    environment {
        DIND_CONTAINER        = 'jenkins-docker'
        BRIDGE_NETWORK        = 'jenkins'
        REGISTRY              = 'registry:5000'
        IMAGE                 = "${params.IMAGE_NAME}"
        JENKINS_DOCKER_ALIAS  = 'docker'
        CONTAINER_PORT        = "${params.CONTAINER_PORT}"
        HOST_PORT             = "${params.HOST_PORT}"
        TEST_CONTAINER        = "${params.TEST_CONTAINER}"
        WAIT_TIME             = "${params.WAIT_TIME}"
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
                        error "Error: ${e.getMessage()}. Could not reach Docker-in-Docker container! Ensure '${DIND_CONTAINER}' is running and attached to network '${BRIDGE_NETWORK}'."
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
                    try {
                        echo "Building and tagging ${FULL_IMAGE}"
                        def img = docker.build(FULL_IMAGE)
                        echo "Pushing ${FULL_IMAGE} to local registry."
                        docker.withRegistry("http://${REGISTRY}", '') {
                            img.push()
                        }
                    } catch (e) {
                        error "Error: ${e.getMessage()}."
                    }
                }
            }
        }

        stage('Tests') {
            steps {
                script {
                    try {
                        echo 'Running docker image from local registry.'
                        sh "docker run -d --name ${TEST_CONTAINER} -e PORT=${CONTAINER_PORT} -p ${HOST_PORT}:${CONTAINER_PORT} ${FULL_IMAGE}"
                        echo 'Waiting for the container to start.'
                        sh "sleep ${WAIT_TIME}"
                        echo 'Hitting the /hello endpoint multiple times to verify counter increments.'
                        for (int i = 1; i <= 5; i++) {
                            echo "Request ${i}"
                            sh "curl -s http://${JENKINS_DOCKER_ALIAS}:${HOST_PORT}/hello"
                            sleep 1
                        }
                    } catch (e) {
                        error "Error: ${e.getMessage()}."
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully.'
        }

        failure {
            echo 'Pipeline failed.'
        }
        cleanup {
            echo 'Starting post cleanup...'

            script {
                def containerExists = sh(script: "docker ps -a -q -f name=${TEST_CONTAINER}", returnStdout: true).trim()
                if (containerExists) {
                    echo "Removing container ${TEST_CONTAINER}."
                    sh "docker rm -f ${TEST_CONTAINER}"
                }
                else {
                    echo "${TEST_CONTAINER} not found."
                }
            }
        }
    }
}
