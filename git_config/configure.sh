#!/bin/bash

# Update Filters
git config filter.xcode.clean "git_config/clean-project-file"
git config filter.xcode.smudge cat

git config filter.pbxproj.clean "git_config/sort-Xcode-project-file"
git config filter.pbxproj.smudge cat

git config merge.bundleversion.name "bundle version merge driver"
git config merge.bundleversion.driver "git_config/bundle-merge-driver %O %A %B"

# Install hooks
mkdir -p .git/hooks
cp git_config/hooks/post-checkout .git/hooks
cp git_config/hooks/pre-commit .git/hooks

if [ -f git_config/hooks/post-checkout-user ]; then
    cat git_config/hooks/post-checkout-user >> .git/hooks/post-checkout
fi

