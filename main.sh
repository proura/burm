#!/bin/bash

#################################################################
# Example of how to create and destroy a repositary in pulp_deb #
#################################################################

source pulp_config.cfg
source pulp_functions.sh

##########
# CREATE #
##########
# add_repository repositoy_name --> return REPO_HREF
REPO_HREF="$(add_repository "drlm")"

# add_package package_path_and_name --> return PACKAGE_HREF
PACKAGE_HREF="$(add_package ./packages/drlm_2.4.0_all.deb)"

# add_repository_package repository_HREF package_HREF --> return NEW_VERSION_REPO_HREF
add_repository_package $REPO_HREF $PACKAGE_HREF

# add_publication repository_name signing_service --> return PUB_HREF or task status "failed"
PUB_HREF="$(add_publication "drlm" "sign_deb_release")"

# add_distribution distribution_name base_path publication_href --> return DIST_HREF
DIST_HREF="$(add_distribution "drlm" "drlm" "$PUB_HREF")"

###########
# DESTROY #
###########
# del_distribution distribution_name
del_distribution_by_href "$DIST_HREF"

# del_publication_by_href
del_publication_by_href "$PUB_HREF"

# del_repository_by_href
del_repository_by_href "$REPO_HREF"

# clean_orphans
clean_orphans
