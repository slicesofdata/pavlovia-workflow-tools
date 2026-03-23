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

# configure configure and clone (step by step)
repo_cloned = FALSE # set to TRUE once cloned initially
# get and set token
if (!repo_cloned) {
  # create token as necessary
  pavlovia_create_and_store_personal_access_token()
}
# build directory structure
if (!repo_cloned) {
  # setup directory (one time)
  pavlovia_setup_repo_directory()
}
# clone repository
if (!repo_cloned) {
  # clone repo (one time)
  pavlovia_clone_repo(user_name = "your-pavlovia-username", 
                      repo_name = "experiment-repo-name"
                      )
}
# end setup

################################################################################
# data processing workflow: pull and copy
# re-run pavlovia_create_and_store_personal_access_token() once token expires
pavlovia_pull_repo()
pavlovia_copy_and_push_data()

################################################################################
################## Begin data processing #######################################
################################################################################
# load libraries

################################################################################
# read data 

################################################################################
# clean data

################################################################################
# end
