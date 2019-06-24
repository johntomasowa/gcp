#!/usr/bin/env bash

// Copyright 2019 {{COMPANY NAME LLC}}
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

GCP_PROJECT_NAME=sadhguru
GCP_PROJECT_ID=${GCP_PROJECT_NAME}-$RANDOM
GCP_ORGANIZATION_ID=$(gcloud organizations list | awk '!/^DISPLAY_NAME/ { print $2 }')
GCP_BILLING_ACCOUNT_ID=$(gcloud beta billing accounts list | awk '!/^ACCOUNT_ID/ { print $1 }')
GCP_SERVICE_ACCOUNT_NAME=gcp-admin-service-account
GCP_SERVICE_ACCOUNT_CREDENTIALS=${HOME}/.config/gcloud/${GCP_SERVICE_ACCOUNT_NAME}.json

# Create new project.
gcloud projects create ${GCP_PROJECT_ID} \
    --name=${GCP_PROJECT_NAME} \
    --organization=${GCP_ORGANIZATION_ID} \
    --set-as-default

# Link project to billing account.
gcloud beta billing projects link ${GCP_PROJECT_ID} \
    --billing-account=${GCP_BILLING_ACCOUNT_ID}

# Create admin service account in GCP project.
gcloud beta iam service-accounts create ${GCP_SERVICE_ACCOUNT_NAME} \
    --description="GCP admin service account to view GCP projects & manage Google Cloud Storage" \
    --display-name="GCP admin service account"

# Download JSON credentials.
gcloud iam service-accounts keys create ${GCP_SERVICE_ACCOUNT_CREDENTIALS} \
    --iam-account=${GCP_SERVICE_ACCOUNT_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com

# Grant Platform Admin service account permission to view GCP projects & manage Google Cloud Storage.
for ROLE in 'viewer' 'storage.admin'; do
    gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} \
        --member=serviceAccount:${GCP_SERVICE_ACCOUNT_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com \
        --role roles/${ROLE}
done

# Enable API's for Platform Admin account.
for API in 'cloudresourcemanager' 'cloudbilling' 'iam' 'compute'; do
    gcloud services enable "${API}.googleapis.com"
done

# Grant Platform Admin service account permission to create GCP Projects & assign billing accounts.
for ROLE in 'resourcemanager.projectCreator' 'billing.user'; do
    gcloud organizations add-iam-policy-binding ${GCP_ORGANIZATION_ID} \
        --member=serviceAccount:${GCP_SERVICE_ACCOUNT_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com \
        --role roles/${ROLE}
done
