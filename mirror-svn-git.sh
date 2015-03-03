#!/bin/bash

set -eu

PROJECT_ROOT=$1
SVN_REPO=$2
GIT_REPO=$3
AUTHORS_FILE=$4
SVN_TRUNK=${5:-"trunk"}
SVN_BRANCHES=${6:-"branches"}
SVN_TAGS=${7:-"tags"}

SVN_LAYOUT="--trunk=$SVN_TRUNK --branches=$SVN_BRANCHES --tags=$SVN_TAGS"

SVN_CLONE="${PROJECT_ROOT}/svn-clone"
GIT_BARE="${PROJECT_ROOT}/git-bare-tmp"

if [ ! -d "${PROJECT_ROOT}" ];
then
  mkdir -p "${PROJECT_ROOT}"
fi

cd "${PROJECT_ROOT}"

echo "==="
echo "Mirror the original Subversion repository to a svn clone repository: $SVN_CLONE with layout: $SVN_LAYOUT"
echo "==="
if [ ! -d "${SVN_CLONE}" ];
then
  echo "First run, doing a full git-svn clone, this may take a while..."
  git svn clone --no-metadata --prefix="svn/" "${SVN_REPO}" -A "${AUTHORS_FILE}" ${SVN_LAYOUT} "${SVN_CLONE}"
  cd "${SVN_CLONE}"
else
  echo "git-svn clone already exists, doing a rebase..."
  cd "${SVN_CLONE}"
  git remote rm bare || echo "failed to delete remote:bare, proceeding anyway"
  git svn fetch --fetch-all -A "${AUTHORS_FILE}"
fi

git remote add bare "${GIT_BARE}"
git config remote.bare.push 'refs/remotes/*:refs/heads/*'

if [ -d "${GIT_BARE}" ];
then
  rm -rf "${GIT_BARE}"
fi

mkdir -p "${GIT_BARE}"
cd "${GIT_BARE}"
git init --bare .
git symbolic-ref HEAD refs/heads/svn/trunk
git config user.name "vdupain"
git config user.email "vdupain@gmail.com"

cd "${SVN_CLONE}"
git push bare

cd "${GIT_BARE}"
echo "==="
echo "Rename Subversion's \"trunk\" branch to Git's standard \"master\" branch."
echo "==="
git branch -m svn/trunk master

echo "==="
echo "Cleanup useless entries"
echo "==="
echo "rewrite the commit log messages: removing git svn-id strings"
git filter-branch --msg-filter 'sed -e "/^git-svn-id:/d"' -- --all
echo "prune empty commits"
git filter-branch -f --tree-filter '' --tag-name-filter cat --prune-empty -- --all

echo "==="
echo "Remove bogus branches of the form \"name@REV\"."
echo "==="
git for-each-ref --format='%(refname)' refs/heads/svn | grep '@[0-9][0-9]*' | cut -d / -f 3- | while read ref; do
  echo "removing bogus branch $ref"; git branch -D "$ref";
done

echo "==="
echo "Convert git-svn tag branches to proper tags."
echo "==="
git for-each-ref --format='%(refname)' refs/heads/svn/tags | cut -d / -f 5 |  while read ref; do
  echo "converting "$ref" to proper git tag \"refs/heads/svn/tags/$ref\"";
  git tag -a "$ref" -m "Convert "$ref" to proper git tag." "refs/heads/svn/tags/$ref";
  git branch -D "svn/tags/$ref"
done

echo "==="
echo "Check if tag still exists in Subversion"
echo "==="
git tag -l | while read tag ; do
  set -e
  echo "check tag '"${tag}"'" 
  set +e
  svn ls ${SVN_REPO}/${SVN_TAGS}/${tag} > /dev/null 2>&1 
  if [ "$?" -ne 0 ]; then
    echo "Tag '"${tag}"' doesn't exist anymore, will remove it from git repository."
    set -e
    git tag -d ${tag}
  fi
done

echo "==="
echo "Rename svn branches to git branches and check if branches still exists in Subversion"
echo "==="
git branch --list "svn/*" | cut -d / -f 2 | while read branch ; do
  set -e
  echo "renaming and checking branch '"${branch}"'" 
  git branch -m "svn/${branch}" "${branch}"
  set +e
  svn ls ${SVN_REPO}/${SVN_BRANCHES}/${branch} > /dev/null 2>&1 
  if [ "$?" -ne 0 ]; then
    set -e
    echo "Branch '"${branch}"' doesn't exist anymore, will remove it from git repository."
    git branch -D ${branch}
  fi
done

echo "==="
echo "Call GC to manually cleanup/compress the repo"
echo "==="
git gc --aggressive --prune=now;

echo "==="
echo "Final push to remote Git repo"
echo "==="
git remote add origin "${GIT_REPO}"
git config branch.master.remote origin
git config branch.master.merge refs/heads/master
git push --force --tags --prune origin  master
git push --all --prune

#rm -rf "${GIT_BARE}"
