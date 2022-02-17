# Ondat Platform Documentation

[![Documentation Rendering](https://github.com/ondat/documentation/actions/workflows/doc-rendering.yml/badge.svg)](https://github.com/ondat/documentation/actions/workflows/doc-rendering.yml)
[![Lint and Link Checking](https://github.com/ondat/documentation/actions/workflows/doc-linting.yml/badge.svg)](https://github.com/ondat/documentation/actions/workflows/doc-linting.yml)

This repository contains the Ondat Markdown documentation content published [here](https://docs.ondat.io).  
The documentation is readeable directly out of this repository without the need of CMS rendering.

The `main` branch is the *latest* version of the documentation being pushed to https://docs.ondat.io.

# Contribute

Feel free to contribute! We love feedback and interaction with the Community ;)  

The below how to assume a general knowledge on how to use Git and GitHub or similar service.  
If you are new to Git and GitHub, the following learning path will help you: <https://lab.github.com/githubtraining/introduction-to-github>

## How to

* Fork the repository
* Clone the forked repository from your GitHub account:  

```git clone git@github.com:ondat/documentation.git```

```
Cloning into 'documentation'...
remote: Enumerating objects: 860, done.
remote: Counting objects: 100% (860/860), done.
remote: Compressing objects: 100% (628/628), done.
remote: Total 860 (delta 448), reused 603 (delta 215), pack-reused 0
Receiving objects: 100% (860/860), 87.45 MiB | 1.37 MiB/s, done.
Resolving deltas: 100% (448/448), done.
Updating files: 100% (274/274), done.

```  

* Create a branch like "new-use-case" or "fixing-type-in-rancher-installation":  

```git checkout -b new-use-case```

* Create the new content using using only Markdown and include the header defining title and link as shown below

```
cat docs/usecases/argocd.md
---
title: "ArgoCD"
linkTitle: "ArgoCD"
---

ArgoCD rocks!
```

* Commit the content and push it:  

```git add --all . && git commit -m "adding a new use case about ArgoCD"```

```
[new-use-case f20b38f] adding a new use case about ArgoCD
 1 file changed, 7 insertions(+)
 create mode 100644 docs/usecases/argocd.md
```

```git push --set-upstream origin new-use-case```  

```
Enumerating objects: 8, done.
Counting objects: 100% (8/8), done.
Delta compression using up to 12 threads
Compressing objects: 100% (5/5), done.
Writing objects: 100% (5/5), 446 bytes | 446.00 KiB/s, done.
Total 5 (delta 3), reused 0 (delta 0), pack-reused 0
remote: Resolving deltas: 100% (3/3), completed with 3 local objects.
remote: 
remote: Create a pull request for 'new-use-case' on GitHub by visiting:
remote:      https://github.com/ondat/documentation/pull/new/new-use-case
remote: 
To github.com:ondat/documentation.git
 * [new branch]      new-use-case -> new-use-case
Branch 'new-use-case' set up to track remote branch 'new-use-case' from 'origin'.
 ```

* Create a Pull Request and document your contribution
* an Ondat team member will review your PR contribution and merge it

## How to render locally the docs

* Install hugo __extended__ from the [hugo release
  page](https://github.com/gohugoio/hugo/releases) for instance the `hugo_extended_0.92.1_macOS-ARM64.tar.gz`
* Clone the documentation-backend: ```git clone https://github.com/ondat/documentation-backend.git```
* Create symbolic links for the content into the backend directory:

```shell
PATH_TO_DOCS_SOURCE=/path/to/the/source/of/docs 
PATH_TO_DOCS_BACKEND=/path/to/the/backend/repo
rsync -az $PATH_TO_DOCS_SOURCE/docs/ $PATH_TO_DOCS_BACKEND/hugo-backend/content/docs
rsync -az $PATH_TO_DOCS_SOURCE/sh/ $PATH_TO_DOCS_BACKEND/hugo-backend/static/sh
rsync -az $PATH_TO_DOCS_SOURCE/yaml/ $PATH_TO_DOCS_BACKEND/hugo-backend/static/yaml
rsync -az $PATH_TO_DOCS_SOURCE/images/docs/ $PATH_TO_DOCS_BACKEND/hugo-backend/static/images/docs
rsync -az $PATH_TO_DOCS_SOURCE/images/generic/ $PATH_TO_DOCS_BACKEND/hugo-backend/static/images/generic
```

* Go in documentation-backend/hugo-backend and run ```hugo server -D --config config/latest.toml```
* Open a browser to <http://127.0.0.1:1313>
