## svn2git

```
mirror-svn-git.sh $PROJECT_ROOT $SVN_REPO $GIT_REPO $AUTHORS_FILE $SVN_TRUNK $SVN_BRANCHES $SVN_TAGS
```

## Testing
* Forking this repository for testing purposes: https://github.com/vdupain/svn2git-dogfooding
* Checkout this forked repository with Subversion (https://help.github.com/articles/support-for-subversion-clients/)

```
svn co --depth empty https://github.com/username/svn2git-dogfooding
```

* Making commits to Subversion and other stuffs
 
```
cd svn2git-dogfooding
svn up trunk
svn up branches
svn copy trunk branches/more_awesome
svn commit -m 'Added more_awesome topic branch'
echo "azerty" >> branches/more_awesome/myfile.txt
svn commit -m "updating myfile.txt in more_awesome branch"
```

* Synch repo

```
mirror-svn-git.sh /tmp/svn2git/mirror https://github.com/username/svn2git-dogfooding git@github.com:username/svn2git-dogfooding.git $(pwd)/authors.txt
```


## thanks

* [Kevin Menard's svn2git](https://github.com/nirvdrum/svn2git)
* [Arnaud Heritier's script](https://gist.github.com/aheritier/8824148)
* [Atlassian Blogs: Moving Confluence from Subversion to git](http://blogs.atlassian.com/2012/01/moving-confluence-from-subversion-to-git)
