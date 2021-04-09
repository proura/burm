#!/bin/bash

function get_tasks () {
  http -a $PULP_USER:$PULP_PASS $BASE_ADDR/pulp/api/v3/tasks/
}

function get_task_status () {
  local TASK_HREF="$1"
  http -a $PULP_USER:$PULP_PASS $BASE_ADDR$TASK_HREF | jq -r '.state'
}

function get_task_created_resources () {
  local TASK_HREF="$1"
  http -a $PULP_USER:$PULP_PASS $BASE_ADDR$TASK_HREF | jq -r '.created_resources[]'
}

function add_repository () {
  local REPO_NAME="$1"
  local REPO_DESCRIPTION="$2"
  if [ -n "$2" ]; then
    http -a $PULP_USER:$PULP_PASS post $BASE_ADDR/pulp/api/v3/repositories/deb/apt/ name="$REPO_NAME" description="$REPO_DESCRIPTION" | jq -r '.pulp_href'
  else
    http -a $PULP_USER:$PULP_PASS post $BASE_ADDR/pulp/api/v3/repositories/deb/apt/ name="$REPO_NAME" | jq -r '.pulp_href'
  fi
}

function add_repository_package () {
  local REPO_HREF="$1"
  local PKG_HREF="$2"
  TASK_HREF="$(http -a $PULP_USER:$PULP_PASS post $BASE_ADDR${REPO_HREF}modify/ add_content_units:="[\"$BASE_ADDR$PKG_HREF\"]" | jq -r '.task')"
  while [ "$(get_task_status $TASK_HREF)" == "running" ] || [ "$(get_task_status $TASK_HREF)" == "waiting" ]; do
    sleep 1
  done 
  
  if [ "$(get_task_status $TASK_HREF)" == "completed" ]; then
    get_task_created_resources $TASK_HREF
  else
    get_task_status $TASK_HREF
  fi
}

function get_repositories () {
  http -a $PULP_USER:$PULP_PASS $BASE_ADDR/pulp/api/v3/repositories/ 
}

function get_repository_href () {
  local REPO_NAME="$1"
  http -a $PULP_USER:$PULP_PASS $BASE_ADDR/pulp/api/v3/repositories/ | jq -r '.results[] | select(.name == "'$REPO_NAME'") | .pulp_href'
}

function del_repository_by_href () {
  local REPO_HREF="$1"
  TASK_HREF="$(http -a $PULP_USER:$PULP_PASS delete $BASE_ADDR$REPO_HREF | jq -r '.task')"
  while [ "$(get_task_status $TASK_HREF)" == "running" ] || [ "$(get_task_status $TASK_HREF)" == "waiting" ]; do
    sleep 1
  done 
  get_task_status $TASK_HREF
}

function del_repository_by_name () {
  local REPO_NAME="$1"
  REPO_HREF="$(get_repository_href $REPO_NAME)"
  del_repository_by_href "$REPO_HREF"
}

function del_repository () {
  local REPO_NAME="$1"
  del_repository_by_name "$REPO_NAME"
}

function get_packages () {
  http -a $PULP_USER:$PULP_PASS $BASE_ADDR/pulp/api/v3/content/deb/packages/
}

function add_package () {
  local FILE_NAME="$1"
  TASK_HREF="$(http -a $PULP_USER:$PULP_PASS --form post $BASE_ADDR/pulp/api/v3/content/deb/packages/ file@"$FILE_NAME" | jq -r '.task')"
  while [ "$(get_task_status $TASK_HREF)" == "running" ] || [ "$(get_task_status $TASK_HREF)" == "waiting" ]; do
    sleep 1
  done

  if [ "$(get_task_status $TASK_HREF)" == "completed" ]; then
    get_task_created_resources $TASK_HREF
  else
    get_task_status $TASK_HREF
  fi
}

function add_distribution () {
  local DIST_NAME="$1"
  local DIST_BASE="$2"
  local PUBLICATION_HREF="$3"
  TASK_HREF="$(http -a $PULP_USER:$PULP_PASS post $BASE_ADDR/pulp/api/v3/distributions/deb/apt/ name="$DIST_NAME" base_path="$DIST_BASE" publication=$BASE_ADDR$PUBLICATION_HREF | jq -r '.task')"
  while [ "$(get_task_status $TASK_HREF)" == "running" ] || [ "$(get_task_status $TASK_HREF)" == "waiting" ]; do
    sleep 1
  done

  if [ "$(get_task_status $TASK_HREF)" == "completed" ]; then
    get_task_created_resources $TASK_HREF
  else
    get_task_status $TASK_HREF
  fi
}

function get_distributions () {
  http -a $PULP_USER:$PULP_PASS $BASE_ADDR/pulp/api/v3/distributions/deb/apt/
}

function get_distribution_href () {
  local DIST_NAME="$1"
  http -a $PULP_USER:$PULP_PASS $BASE_ADDR/pulp/api/v3/distributions/deb/apt/ | jq -r '.results[] | select(.name == "'$DIST_NAME'") | .pulp_href'
}

function del_distribution_by_href () {
  local DIST_HREF="$1"
  TASK_HREF="$(http -a $PULP_USER:$PULP_PASS delete $BASE_ADDR$DIST_HREF | jq -r '.task')"
  while [ "$(get_task_status $TASK_HREF)" == "running" ] || [ "$(get_task_status $TASK_HREF)" == "waiting" ]; do
    sleep 1
  done
  get_task_status $TASK_HREF
}

function del_distribution_by_name () {
  local DIST_NAME="$1"
  DIST_HREF="$(get_distribution_href $DIST_NAME)"
  del_distribution_by_href "$DIST_HREF"
}

function del_distribution () {
  local DIST_NAME="$1"
  del_distribution_by_name "$DIST_NAME"
}

function get_signingservices () {
  http -a $PULP_USER:$PULP_PASS $BASE_ADDR/pulp/api/v3/signing-services/
}

function get_signingservice_href () {
  local SIGNING_SERVICE_NAME="$1"
  http -a $PULP_USER:$PULP_PASS $BASE_ADDR/pulp/api/v3/signing-services/ | jq -r '.results[] | select(.name == "'$SIGNING_SERVICE_NAME'") | .pulp_href'
}

function add_publication () {
  local REPO_NAME="$1"
  local SIGNING_SERVICE_NAME="$2"
  REPO_HREF="$(get_repository_href $REPO_NAME)"
  SIGNING_SERVICE_HREF="$(get_signingservice_href $SIGNING_SERVICE_NAME)"
  TASK_HREF="$(http -a $PULP_USER:$PULP_PASS post $BASE_ADDR/pulp/api/v3/publications/deb/apt/ repository="$REPO_HREF" simple=true signing_service="$SIGNING_SERVICE_HREF" | jq -r '.task')"
  while [ "$(get_task_status $TASK_HREF)" == "running" ] || [ "$(get_task_status $TASK_HREF)" == "waiting" ]; do
    sleep 1
  done

  if [ "$(get_task_status $TASK_HREF)" == "completed" ]; then
    get_task_created_resources $TASK_HREF
  else
    get_task_status $TASK_HREF
  fi 
}

function get_publications () {
  http -a $PULP_USER:$PULP_PASS $BASE_ADDR/pulp/api/v3/publications/deb/apt/
}

function del_publication_by_href () {
  local PUB_HREF="$1"
  http -a $PULP_USER:$PULP_PASS delete $BASE_ADDR$PUB_HREF 
}

function clean_orphans () {
  TASK_HREF="$(http -a $PULP_USER:$PULP_PASS delete $BASE_ADDR/pulp/api/v3/orphans/| jq -r '.task')"
  while [ "$(get_task_status $TASK_HREF)" == "running" ] || [ "$(get_task_status $TASK_HREF)" == "waiting" ]; do
    sleep 1
  done
  get_task_status $TASK_HREF
}
