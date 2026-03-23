# Pavlovia.org (GitLab hosted) Data Access Tools

R functions to streamline authentication, directory setup, and cloning of Pavlovia.org (GitLab) repositories for data analysis workflows.

## Prerequisites

- Git installed and configured on your system
- [Pavlovia.org](Pavlovia.org) account with access to target repositories (hosted on Gitlab)
- Existing R Project with Git initialized (for `.gitignore` staging features)

## R Library Installation

Install the required R packages from CRAN:

```bash
install.packages(c("cli", "fs", "gert", "gitcreds", "httr", "here", "glue"))
```

Package purposes:
- `{cli}` & `{glue}`: Formatted console output and messaging
- `{fs}`: Cross-platform file system operations
- `{gert}`: Git operations (clone, commit, push)
- `{gitcreds}`: Secure credential storage
- `{httr}`: HTTP requests for URL building
- `{here}`: Path management relative to project root

System Dependencies:
Ensure Git is installed:

- Windows: Git for Windows (https://git-scm.com/download/win)
- macOS: brew install git or Xcode Command Line Tools
- Linux: sudo apt-get install git (Ubuntu/Debian)

## Step 1: Create and Store Personal Access Token (PAT)

The function `pavlovia_create_and_store_personal_access_token()` opens your browser to generate a PAT and securely stores it.

```bash
pavlovia_create_and_store_personal_access_token()
```

What this does:
1. Opens browser to Pavlovia.org to ensure login and account access
2. Generates a pre-filled token creation URL with recommended scopes (read_repository, read_api)
3. Prompts you to copy the generated token (starts with glpat-)
4. Stores the token securely using `{gitcreds}` (encrypted in your OS credential store)

Parameters:
- `host_url`: Pavlovia/GitLab host url
- `gitlab_url`: Gitlab url
- `pavlovia_url`: Pavlovia.org url
- `token_name`: Name to assign to the token when created
- `scopes`: Token scopes 
- `set_credentials_locally`: Store the token securely

Note: Treat tokens like passwords. Never commit them to version control!

## Step 2: Setup Repository Directory

As a sub-directory of your GitHub repository, create a dedicated directory for housing your Pavlovia/Gitlab experiment project repository. The sub-directory is named `pavlovia-gitlab/` by default.   (data with automatic `.gitignore` protection:

```bash
pavlovia_setup_repo_directory()
```

What this does:
1. Creates the directory `pavlovia-gitlab/` (default) in your project root parent repository
2. Adds the directory to `.gitignore` to ensure the repo is not included in your parent repository
3. Stages and pushes the `.gitignore` update to your remote repository

Parameters:
- `repo_path`: Target directory name (default: `"pavlovia-gitlab"`)
- `is_ignored`: If TRUE, adds directory to `.gitignore`
- `append_ignore`: If TRUE, appends to end of `.gitignore`
- `stage_and_push`: If TRUE, commits and pushes `.gitignore` changes

## Step 3: Clone the Repository

Clone the Pavlovia/Gitlab experiment repository from https://gitlab.pavlovia.org using your stored credentials, username, and experiment name:

```bash
pavlovia_clone_repo(
  user_name = "your-pavlovia-username",
  repo_name = "your-experiment-repo-name",
)
```

Parameters:
- `host_url`: GitLab/Pavlovia URL (default: https://gitlab.pavlovia.org)
- `user_name`: Your Pavlovia.org username
- `repo_name`: Repository/Experiment name to clone
- `repo_path`: Local directory path for the Pavlovia/Gitlab repository (created automatically)

## Complete Workflow Example

   # 1. Setup authentication (one-time per machine, reauthenticate token as needed)
   `pavlovia_create_and_store_gitlab_token()`
   
   # 2. Prepare directory structure
   `pavlovia_setup_repo_directory()` 
   
   # 3. Clone specific experiment
   ```
   pavlovia_clone_repo(
     user_name = "jsmith",
     repo_name = "stroop-task-2024"
   )
   ```
```

## Ongoing Data Management

After the initial setup and cloning, use these functions to update data from Pavlovia and sync it to your parent repository.

### Pull Latest Changes from Pavlovia

Update your local clone with the latest data collected on Pavlovia:

```bash
pavlovia_pull_repo()
```

What this does:
1. Pulls the latest commits from the remote Pavlovia/GitLab repository (e.g., updated data)
2. Copies/updates your data from `pavlovia-gitlab/data/` to `data/raw/pavlovia-gitlab` to be used inside your parent repository

Parameter(s):
- `repo_path`: Path to the cloned repository (default: `"pavlovia-gitlab"`)

Typical usage in ongoing workflow:

```bash
# Pulls changes to update the Pavlovia repository
pavlovia_pull_repo()
```

### Copy Data to Analysis Repository

Copy collected data from the Pavlovia.org repository into your project's data directory, commits the changes, and pushed to your remote (by default using `stage_and_commit = TRUE`):

```bash
pavlovia_copy_and_push_data(
  dest_dir = "data/raw",
  repo_path = "pavlovia-gitlab",
  overwrite = TRUE,
  stage_and_commit = TRUE
  )
```

What this does:
1. Copies contents from `pavlovia-gitlab/data/` to `data/raw/pavlovia-gitlab/` in your project
2. Automatically stages the newly copied data files
3. Commits with a simple message "Add new data"
4. Pushes to your analysis repository (if `stage_and_commit = TRUE`)

Parameters:
- `dest_dir`: Destination directory in your project (default: `"data/raw"`)
- `repo_path: Source repository path (default: `repo_path = `"pavlovia-gitlab"` expanded to `pavlovia-gitlab/data/`)
- `overwrite`: If TRUE, overwrites existing files (default: TRUE)
- `stage_and_commit`: If TRUE, automatically stages, commits, and pushes changes (default: TRUE)

### Complete Update Workflow

For regular data updates, run both functions in sequence:

```bash
# 1. Pull latest data from Pavlovia.org experiment repo
pavlovia_pull_repo()
   
# 2. Copy data directory to your parent repo data directory and push
pavlovia_copy_and_push_data()

# 3. Your data processing workflow continued...

See ```pavlovia-workflow-tools/pavlovia-workflow-example.R```
```

This workflow ensures:
- You have the latest participant data from your Pavlovia/Gitlab experiment repository
- Participant data are backed up to your local and remote repository

### Important Notes

- The copy function only stages files within the destination directory (`data/raw/pavlovia-gitlab/`), not the entire repository
- If no new files are detected (nothing to stage), the function will notify you and skip commit/push
- Ensure your `.gitignore` in the parent project does NOT ignore the `data/raw/pavlovia-gitlab/` directory if you want to version control the copied data
- The Pavlovia source directory (`pavlovia-gitlab/`) remains ignored but the copied data in desitation directory, `data/raw/pavlovia-gitlab/`, can be tracked by Git


## Directory Structure

After setup, your project will look like:

   project-root-directory/
   ├── .git/                     # Parent repository `.git` directory
   ├── .gitignore                # Parent repository ignore file, updated with `pavlovia-gitlab/`
   ├── pavlovia-gitlab/          # Cloned repos (ignored by git)
   │   ├── data/
   │   └── stroop-experiment.psyexp
   ├── data/                     # Main data directory
   │   └── raw/                  # Raw data sub-directory
   │       └── pavlovia-gitlab/  # Copied version of Pavlovia.org experiment data
   ├── docs/                     # Documentation and dictionaries
   ├── figs/                     # Saved plots
   ├── pavlovia-workflow-tools/  # Configuration functions
   │   ├── pavlovia-workflow-functions.R
   │   └── pavlovia-workflow-example.R
   ├── refs/                     # References
   ├── report/                   # Markdown files and reporting
   ├── src/                      # Source code for data, figs, funcions, etc. References
   └── README.md

## Troubleshooting

Gitlab Credentials not found:

Run `gitcreds::gitcreds_get()` to verify your token is stored. If missing, re-run `pavlovia_create_and_store_gitlab_token()`.

Permission denied when cloning:
Ensure your PAT (personal access token) includes `read_repository` scope and has not expired (default: 30 days on Pavlovia).

Directory already exists:
The setup functions are idempotent—running them multiple times will not cause errors, but cloning will fail if the target directory already contains files.

## Security Notes

- Tokens are stored using your OS native credential manager (Keychain on macOS, Credential Manager on Windows)
- The `pavlovia-gitlab/` directory is automatically added to `.gitignore` to prevent token leakage or data commits
- Never share your tokens or commit them to a repository to expose them
- Never stage your `pavlovia-gitlab/` directory housing your Pavlovia/Gitlab repo
