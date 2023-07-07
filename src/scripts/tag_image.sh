#!/bin/bash
ORB_STR_REPO="$(circleci env subst "${ORB_STR_REPO}")"
ORB_STR_SOURCE_TAG="$(circleci env subst "${ORB_STR_SOURCE_TAG}")"
ORB_STR_TARGET_TAG="$(circleci env subst "${ORB_STR_TARGET_TAG}")"

# pull the image manifest from ECR
MANIFEST="$(aws ecr batch-get-image --repository-name "${ORB_STR_REPO}" --image-ids imageTag="${ORB_STR_SOURCE_TAG}" --query 'images[].imageManifest' --output text)"
EXISTING_TAGS=$(aws ecr list-images --repository-name aws-ecr-orb-816b53be3921413610f14619567bac79fd01cf9c-named-profile --filter "tagStatus=TAGGED")
IFS="," read -ra ECR_TAGS <<<"${ORB_STR_TARGET_TAG}"

for tag in "${ECR_TAGS[@]}"; do
    # if skip_when_tags_exist is true
    if [ "$ORB_BOOL_SKIP_WHEN_TAGS_EXIST" -eq "1" ]; then
        # tag image if tag does not exist
        if ! echo "${EXISTING_TAGS}" | grep "${tag}"; then
            aws ecr put-image --repository-name "${ORB_STR_REPO}" --image-tag "${tag}" --image-manifest "${MANIFEST}"
        fi
    # tag image when skip_when_tags_exist is false
    else
        aws ecr put-image --repository-name "${ORB_STR_REPO}" --image-tag "${tag}" --image-manifest "${MANIFEST}"
    fi
done
