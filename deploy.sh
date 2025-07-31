#!/usr/bin/env bash
# ref: https://github.com/jekyll/jekyll

set -eu  # Exit on error or unset variable

PAGES_BRANCH="gh-pages"

SITE_DIR="_output"

_backup_dir="$(mktemp -d)"

GITHUB_TOKEN="${secrets.ALT_GITHUB_TOKEN}"


init() {
  # Check if the script is running in a GitHub Actions environment
  if [[ -z ${GITHUB_ACTION+x} ]]; then
    echo "ERROR: Not allowed to deploy outside of the GitHub Action environment."
    exit 1
  fi
}

build() {
  # clean
  if [[ -d $SITE_DIR ]]; then
    rm -rf "$SITE_DIR"
  fi

  # Run the Ruby script to generate the output
  bundle exec ruby "./scaffold.rb"
}

setup_gh() {
  if [[ -z $(git branch -av | grep "$PAGES_BRANCH") ]]; then
    git checkout -b "$PAGES_BRANCH"
  else
    git checkout "$PAGES_BRANCH"
  fi
}

backup() {
  mv "$SITE_DIR"/* "$_backup_dir"
  mv .git "$_backup_dir"

  if [[ -f CNAME ]]; then
    mv CNAME "$_backup_dir"
  fi
}

flush() {
  rm -rf ./*
  rm -rf .[^.] .??*

  shopt -s dotglob nullglob

  mv "$_backup_dir"/* .
}

deploy() {
  # Configure Git user for the commit
  git config --global user.name "ZhgChgLiBot"
  git config --global user.email "no-reply@zhgchg.li"

  # Reset the current HEAD to prepare for new commits
  git update-ref -d HEAD
  git add -A
  git commit -m "[Automation] Site update No.${GITHUB_RUN_NUMBER}"

  # Push the new branch to the remote repository
  git push -u origin "$PAGES_BRANCH" --force
}

main() {
  init
  build
  setup_gh
  backup
  flush
  deploy
}

# Execute the main function
main
