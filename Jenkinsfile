// NONPROD App registration Client ID within Azure
NONPROD_ARM_CLIENT_ID = "<>"
NONPROD_ARM_TENANT_ID = "<>"
NONPROD_ARM_SUBSCRIPTION_ID = "<>"
NONPROD_ARM_SECRET = "<>"
NONPROD_DEPLOYMENT_STORAGE_RESOURCE_GROUP_NAME = "<>"
NONPROD_DEPLOYMENT_STORAGE_ACCOUNT_NAME = "<>"
NONPROD_DEPLOYMENT_STORAGE_CONTAINER = "<>"
NONPROD_DATABRICKS_WORKSPACE_URL = "<>"

// PROD App registration Client ID within Azure
PRD_ARM_CLIENT_ID = "<>"
PRD_ARM_TENANT_ID = "<>"
PRD_ARM_SUBSCRIPTION_ID = "<>"
PRD_CLIENT_JENKINS_ID = "<>"
PRD_DEPLOYMENT_STORAGE_RESOURCE_GROUP_NAME = "<>"
PRD_DEPLOYMENT_STORAGE_ACCOUNT_NAME = "<>"
PRD_DEPLOYMENT_STORAGE_CONTAINER = "<>"
PRD_DATABRICKS_WORKSPACE_URL = ""

def login_and_grunt(
    clientID, 
    clientSecret, 
    subscriptionID = NONPROD_ARM_SUBSCRIPTION_ID,
    terraformAction = "plan", 
    tenantID = NONPROD_ARM_TENANT_ID,
    deploymentStorageResourceGroupName = NONPROD_DEPLOYMENT_STORAGE_RESOURCE_GROUP_NAME,
    deploymentStorageAccountName = NONPROD_DEPLOYMENT_STORAGE_ACCOUNT_NAME,
    deploymentStorageContainer = NONPROD_DEPLOYMENT_STORAGE_CONTAINER,
    databricksWorkspaceUrl = NONPROD_DATABRICKS_WORKSPACE_URL) {
    withCredentials([
        string(credentialsId: clientSecret, variable: 'clntscrt')]) {
        sh """#!/bin/bash
            echo "Attempting to invoke terragrunt..."
            if [[ ! $terraformAction =~ ^(plan|apply)\$ ]]; then
                echo "Not a plan or apply, please pass the correct action."
                exit 1
            else
                # Set Creds and az login, these have to be set for the terraform provider
                echo "Export Environment Variables..."

                export ARM_CLIENT_ID="${clientID}"
                export ARM_CLIENT_SECRET="${clntscrt}"
                export ARM_TENANT_ID="${tenantID}"
                export ARM_SUBSCRIPTION_ID="${subscriptionID}"

                export TF_VAR_databricks_workspace_url="${databricksWorkspaceUrl}"

                export DEPLOYMENT_STORAGE_RESOURCE_GROUP_NAME="${deploymentStorageResourceGroupName}"
                export DEPLOYMENT_STORAGE_ACCOUNT_NAME="${deploymentStorageAccountName}"
                export DEPLOYMENT_STORAGE_CONTAINER="${deploymentStorageContainer}"

                echo "Attempting az login..."
                az login --service-principal -u ${clientID} -p ${clntscrt} --tenant ${tenantID}
                az account set --subscription="${subscriptionID}"

                echo "Running terragrunt validate..."
                cd ./impl/security
                terragrunt run-all validate
                if [[ "${terraformAction}" == "plan" ]]; then
                    echo "Action: plan was passed, proceeding with action"
                    terragrunt run-all plan --terragrunt-non-interactive
                elif  [[ "${terraformAction}" == "apply" ]]; then
                    echo "Action: apply was passed, proceeding with action"
                    terragrunt run-all apply --terragrunt-non-interactive
                else
                    echo "Action: ${terraformAction}: Unknown scenario hit.."
                fi
            fi
            """
    }
}

pipeline {
    options {
        buildDiscarder(logRotator(numToKeepStr: '5'))
        disableConcurrentBuilds()
    }
    agent {
        node {
            label 'linux'
        }
    }
    stages {
        stage("Prepare") {
            steps {
                echo "Sending Build notification"
                cleanWs(
                deleteDirs: true,
                disableDeferredWipeout: true,
                patterns: [[pattern: 'build_cache/**', type: 'EXCLUDE']])
                checkout scm
            }
        }
        stage("IAC Linting") {
            steps {
                sh '''#!/bin/bash
                        # Terraform FMT check, fail if formating errors
                        terraform fmt --recursive
                        '''
            }
        }
        stage('Run IAC Tests') {
            steps {
                script {
                    try {
                    withCredentials([string(credentialsId: NONPROD_ARM_SECRET, variable: 'clntscrt')]) {
                        sh """#!/bin/bash
                        az login --service-principal -u ${NONPROD_ARM_CLIENT_ID} -p ${clntscrt} --tenant ${NONPRoD_ARM_TENANT_ID}
                        az account set --subscription="${DEV_ARM_SUBSCRIPTION_ID}"
                        # cd dir from where go needs to run
                        # go test ./... -timeout 10000s -v
                        # terratest_log_parser -testlog test_output.log -outputdir ./
                        """
                    }
                    } catch(err) {
                    step([$class: 'JUnitResultArchiver', testResults: '--junit-xml=${TESTRESULTPATH}/TEST-*.xml'])
                    if (currentBuild.result == 'UNSTABLE')
                        currentBuild.result = 'FAILURE'
                    throw err
                    }
                }
            }
        }
        stage('tfenv install') {
            steps {
                //Install specific version of terraform, will use .terraform-version file for specific version
                    sh '''#!/bin/bash
                        tfenv install
                        '''
            }
        }
        stage('Dynamic Deploy') {
            steps {
                script {
                    if (env.BRANCH_NAME.startsWith('feature/')) {
                        stage("Validate against NONPROD") {
                            // Run a plan
                            login_and_grunt(NONPROD_ARM_CLIENT_ID, NONPROD_ARM_SECRET)                            
                        }
                    }
                    if (env.BRANCH_NAME == 'main') {
                        stage("Deploy to Databricks") {
                            // Apply to portal
                            login_and_grunt(PRD_ARM_CLIENT_ID, PRD_ARM_SECRET, PRD_ARM_SUBSCRIPTION_ID, "apply", PRD_ARM_TENANT_ID, PRD_DEPLOYMENT_STORAGE_RESOURCE_GROUP_NAME, PRD_DEPLOYMENT_STORAGE_ACCOUNT_NAME, PRD_DEPLOYMENT_STORAGE_CONTAINER, PRD_DATABRICKS_WORKSPACE_URL)
                        }
                    }
                }
            }
        }
    }
    post {
        // Clean after build
        always {
            cleanWs(cleanWhenNotBuilt: false,
                    deleteDirs: true,
                    disableDeferredWipeout: true,
                    notFailBuild: true,
                    patterns: [[pattern: 'build_cache/**', type: 'EXCLUDE']])
        }
    }
}