################################################################################
# Script Name: pavlovia-workflow-example.R
# Author: slicesofdata
# GitHub: sliecesofdata
# Date Created: 03-21-2026
#
# Purpose: This script provides an example usage of the workflow 
# for setting up and cloning a repository as well as routine 
# data processing workflow.
#
################################################################################

################################################################################
# define functions
source(here::here("pavlovia-workflow-tools", "pavlovia-workflow-functions.R"))
################################################################################
# usage for token 
pavlovia_create_and_store_personal_access_token()
# setup directory (one time)
pavlovia_setup_repo_directory()
# clone repo (one time)
pavlovia_clone_repo()

################################################################################
# data processing workflow: pull and copy
# re-run pavlovia_create_and_store_personal_access_token() once token expires
pavlovia_pull_repo()
pavlovia_copy_and_push_data()

################################################################################
# 
