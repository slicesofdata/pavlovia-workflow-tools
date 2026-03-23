################################################################################
# Script Name: pavlovia-workflow-functions.R
# Author: slicesofdata
# GitHub: slicesofdata
# Date Created: 03-18-2026
#
# Purpose: These functions allow for building integration with 
# Pavlovia.org experiments hosted on Gitlab.
#
# Functions and usage:
# pavlovia_create_and_store_personal_access_token() creates GitLab 
#    Personal Access Token (PAT) and stores it on your computer 
#
# pavlovia_setup_repo_directory() sets up a directory 
#    structure for the Gitlab repo and ensures it's ignored
#    in the parent directory by modifying the .gitignore files
# 
# pavlovia_clone_repo() clones GitLab repository  
#  
# pavlovia_pull_repo() pull latest changes from GitLab 
#
# pavlovia_copy_and_push_data()
################################################################################
library(cli)
library(fs)
library(gert)
library(gitcreds)
library(httr)

#' Create GitLab Personal Access Token
#' 
#' Opens browser to GitLab token creation page with pre-filled parameters.
#' Similar to usethis::create_github_token() but includes credential setting
#' using gitcreds::gitcreds_set()
#' 
#' @param host_url Pavlovia/GitLab host url
#' @param gitlab_url Gitlab url
#' @param pavlovia_url Pavlovia.org url
#' @param token_name Name to assign to the token when created
#' @param scopes Token scopes (default: read_repository for data cloning)
#' @param set_credentials_locally Store the token securely
pavlovia_create_and_store_personal_access_token <- function(
    host_url     = "https://gitlab.pavlovia.org",
    gitlab_url   = "https://gitlab.com",
    pavlovia_url = "https://pavlovia.org/",
    token_name   = paste0("data-access-", Sys.Date()), # general name
    scopes = c("read_repository", "read_api"),
    set_credentials_locally = TRUE
) {
  
  require(httr)
  require(cli)
  
  # Build URL with query parameters (this works!)
  # for project access tokens
  # paste0(host_url, "/", "<user_name>", "/", "<experiment_name>","/-/settings/access_tokens")
  token_type <- "/-/profile/personal_access_tokens"
  base_url <- paste0(host_url, token_type)
  
  # set the url query (NOTE: date of expiration must be set manually)
  query <- list(
    name = token_name,
    scopes = paste(scopes, collapse = ",")
  )
  # build the url with parameters
  url <- modify_url(base_url, query = query)
  
  # Step 1: Login
  if (grepl("pavlovia", host_url, fixed = TRUE)) {
    cli_alert_info("Step 1: Log into your Pavlovia.org account")
    cli_text("Open: {.url {pavlovia_url}}")
  } else {
    cli_alert_info("Step 1: Log into your GitLab.com account") 
    cli_text("Open: {.url {gitlab_url}}")
  }
  readline("Press Enter when you are logged in... ")
  
  # Step 2: Token creation (pre-filled!)
  cli_text("")
  cli_alert_info("Step 2: Open the pre-filled token creation page (url below) and review the pre-filled token settings:")
  cli_bullets(c(
    "*" = "Token name: {.val {token_name}}",
    "*" = "Scopes: {.val {paste(scopes, collapse = ', ')}}",
    "*" = "Review/Adjust Expiration: Set manually (1 month default)"
  ))
  cli_text("")
  cli_text("URL: {.url {url}}")
  #cli_text("")
  #cli_alert_info("Review pre-filled settings:")
  cli_text("")
  cli_alert_info("Click the URL link above and navigate to the page, then click 'Add new token', then scroll down the page to 'create personal access token', and then copy it to the clipboard.") 
  #               then copy the token (starts with 'glpat-')")
  
  #cli_alert_info("Opening browser to create token...")
  #utils::browseURL(url)
  
  readline("Review instructions above and\nthen press Enter once token is copied to clipboard... ")
  
  if (set_credentials_locally) {
  # Step 3: Store credentials with error handling
  cli_text("")
  cli_alert_info("Step 3: Securely store the token")
  cli_text("You will now be prompted to enter the token")
  readline("Press Enter to launch credential prompt... ")
  
  # Try to set credentials, handle abort gracefully
  result <- tryCatch({
    gitcreds::gitcreds_set(url = host_url)
    cli_alert_success("Setup complete! Token stored for {host_url}")
    TRUE
  }, error = function(e) {
    if (grepl("abort", e$message, ignore.case = TRUE)) {
      cli_alert_warning("Credential update aborted. Existing credentials kept.")
      cli_text("To retry later, run: ")
      cli_code(glue::glue('gitcreds::gitcreds_set(url = "{host_url}")'))
      FALSE
    } else {
      cli_alert_danger("Error storing credentials: {e$message}")
      FALSE
    }
  })

  invisible(list(url = url, success = result))
  }
}
# usage: pavlovia_create_and_store_gitlab_token()

################################################################################
#

pavlovia_create_and_store_project_level_token <- function(
    
  ) {
  message("Coming soon...")
}


################################################################################
#' Setup directory structure and gitignore for external data
#' 
#' @param repo_path Target directory for external data
#' @param is_ignored If TRUE, adds directory to .gitignore file
#' @param append_ignore If TRUE, appends the dir to end of .gitignore (no other option currently)
#' @param stage_and_push If TRUE, stages and pushes
#' @return Invisible path to directory
pavlovia_setup_repo_directory <- function(
    repo_path      = "pavlovia-gitlab",
    is_ignored     = TRUE,
    append_ignore  = TRUE,
    stage_and_push = TRUE
    ) {
  
  # Create directory (idempotent)
  fs::dir_create(repo_path)
  cli_alert_success("Repo source directory ready: {.path {path_wd(repo_path)}}")
  
  # Update .gitignore file with contents
  if (is_ignored) {
    gitignore_patterns <- c(paste0("/", repo_path, "/"), paste0("/", repo_path, "/*"))
    gitignore_path     <- fs::path(".gitignore")
    
    if (!fs::file_exists(gitignore_path)) {
      cli_alert_info("Creating: {.path {gitignore_path}}")
      writeLines(gitignore_patterns, gitignore_path)
      cli_alert_success("Created {.path .gitignore}")
    } else {
      existing     <- readLines(gitignore_path, warn = FALSE)
      new_patterns <- setdiff(gitignore_patterns, existing)
      if (length(new_patterns) > 0) {
        ignore_content <- c(
          "## Ignore Pavlovia/GitLab repo directory (auto-generated by setup)",
          new_patterns
        )
        cat(paste(ignore_content, collapse = "\n"), 
            file = gitignore_path, 
            append = append_ignore,  # Use the parameter here
            sep = "\n"
        )
        cli_alert_success("Updated {.path .gitignore}")
      } 
    }
  }
  
  # Commit gitignore changes
  if (fs::dir_exists(".git") && stage_and_push) {
    gert::git_add(".gitignore")
    status <- gert::git_status()
    
    if (nrow(status) > 0 && ".gitignore" %in% status$file) {
      # add message and push
      gert::git_commit(paste0("Add ", repo_path, " sub-directory for external repo"))
      gert::git_push()
      cli_alert_success("Committed and Pushed .gitignore changes")
    }
  }
  invisible(path_wd(repo_path))
}

# usage:
# pavlovia_setup_repo_directory()

################################################################################
#' Clone GitLab repository (one-time setup)
#' 
#' @param host_url Gitlab/Pavlovia url
#' @param user_name Pavlovia user name (for GitLab repository)
#' @param repo_name Pavlovia repository name (hosted at GitLab)
#' @param repo_path Path into which to clone the repo 
pavlovia_clone_repo <- function(
    host_url = "https://gitlab.pavlovia.org",
    user_name, 
    repo_name,
    repo_path = "pavlovia-gitlab"
    ) {
  # create the directory and update .gitignore file
  pavlovia_setup_repo_directory(repo_path = repo_path)
  
  # build the url for the repo
  repo_url <- 
    sprintf(paste0(host_url, "/%s/%s.git"), user_name, repo_name)

  # clone
  dir_create(here::here(repo_path), recurse = TRUE)
  
  if (dir_exists(path(repo_path))) {
    message(paste0("Cloning Pavlovia/Gitlab repository to ", repo_path, "/"))
    # clone to path
    gert::git_clone(url = repo_url, path = repo_path)
  }
}

################################################################################
#' Pull latest changes from GitLab (ongoing updates)
#' 
#' @param repo_path Path to existing Gitlab/Pavlovia repo
#' @return Invisible path to repo
pavlovia_pull_repo <- function(
    repo_path = "pavlovia-gitlab"
    ) {
  
  if (!fs::dir_exists(repo_path)) {
    cli_abort("Directory {.path {repo_path}} not found.")
  }
  
  if (!fs::dir_exists(fs::path(repo_path, ".git"))) {
    cli_abort("{.path {repo_path}} is not a git repository.")
  }
  
  cli_alert_info("Pulling latest changes into {.path {repo_path}}...")
  
  tryCatch({
    gert::git_pull(repo = repo_path, verbose = FALSE)
    cli_alert_success("Repository updated")
  }, error = function(e) {
    cli_abort("Pull failed: {e$message}")
  })
  
  invisible(fs::path_wd(repo_path))
}

################################################################################
#' Clone GitLab repository (one-time setup)
#' 
#' @param dest_dir Path to parent repo data directory for saving
#' @param repo_path Path into which to clone the repo 
#' @param overwrite If TRUE, overwrites existing files 
#' @param stage_and_commit If TRUE, stages, commits, and pushes data update to 
#' parent repo
pavlovia_copy_and_push_data <- function(
    dest_dir  = "data/raw",
    repo_path = "pavlovia-gitlab",
    overwrite = TRUE,
    stage_and_commit = TRUE
    ) {
  
  # ensure directory exists
  dest_dir_stage <- paste0(dest_dir, "/", repo_path)
  dest_dir <- here::here(dest_dir, repo_path)
  fs::dir_create(here::here(dest_dir), recurse = TRUE) 
  
  # pavlovia repo data
  source_dir <- here::here(repo_path, "data")
  
  # copy to destination
  if (fs::dir_exists(source_dir)) {
    fs::dir_copy(path = source_dir, 
                 new_path = dest_dir, 
                 overwrite = overwrite
    )
    message(paste0("Data directory copied:\n  from ", source_dir, 
                   "\n  to   ", here::here(dest_dir), "\n"))
  }
  # stage
  if (stage_and_commit) {
    # stage
    cli_alert_info(paste0("Staging: ", dest_dir_stage))
    message("")
    gert::git_add(paste0(dest_dir_stage, "/"))
    
    # get count of staged (not new untracked files)
    git_status <- gert::git_status()
    num_staged <- nrow(git_status[git_status$staged == TRUE, ])
    
    # then commit and push
    if (num_staged > 0) {
      gert::git_commit("Add new data")
      cli_alert_success("Committed new data changes")
      
      # push to remote
      gert::git_push()
      cli_alert_success("Pushed new data changes")
    } else {
      cli_alert_info("No files staged - directory might be empty, contain no new files, or already committed. Nothing staged/committed/pushed")
    }
  }
}

################################################################################
pavlovia_pull_and_copy <- function() {
  # pull first
  pavlovia_pull_repo()
  # then copy and push
  pavlovia_copy_and_push_data()
}

################################################################################
cli_alert_success("Functions defined successfully!")
