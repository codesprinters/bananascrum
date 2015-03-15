###########################
Git practices and standards
###########################

.. note:: This document is just draft. Any changes should be discussed in team.

Basic git workflow
==================

We're using continous integration to catch errors early. That means commits to origin/master should be done at least once a day.
On the other hand we'd like to pick commits that make particular feature (for code review). That's why working on feature
branches is recommended. When you start working on some item, create feature branch from latest master code:

``git pull origin master``

``git checkout -b feature-branch``

``git push origin feature-branch``

Inside feature branch normal git workflow applies:

``EDIT``

``git commit -am 'Some info'``

``git push origin feature-branch``

When work has reached the state when tests are passing on local branch, or you are about to be punished for not merging into
master at least once a day, merge your changes into master:

``git checkout master``

``git pull origin master``

``git merge feature-branch``

If tests fails on master, merge branch master into feature-branch, fix the tests and merge fixed tests into master. Make sure
all changes regarding particular item are done on feature branch.


Resolving conflicts
===================

Git User's Manual describes well how to `resolve a merge
<http://www.kernel.org/pub/software/scm/git/docs/user-manual.html#resolving-a-merge>`_.

Basically following combo will do:

``git status # See which files are in conflict state``

``EDIT to fix the problem (like in svn)``

``git add conflicting_file``

``git commit # No arguments. Merge is continued``

Also you might be interested in following command:

``git mergetool``

It will help you resolve a merge using some graphical conflict resolution
tools that present on your system.


Branch and tag naming conventions
=================================

All branches and tags should be written in lowercase. Words are separated with hyphen `-`.

Tags
====

Basically we tag releases in such case following naming convention applies:
 * `sprint-NN` - Tag for sprint with number NN
 * `sprint-NN.M` - Tagg for changes backported to sprint NN. Number M should start with 1
 * `jruby-sprint-NN` - Tag for sprint with number NN, created on branch `jruby`
 * `jruby-sprint-NN.M` - Tag for changes backported to sprint NN. Also created on branch `jruby`


Each tag that should be visible by others should be pushed to repo explicitly with command ``git push --tags``.

Branches
========

We use two main development streamlines. Development is performed using 3 branches. Their purpose is a follows:
 * `core` - This is where main development goes. Here we develop funcionality shared in both version. After sending commiti to this brach a merge to bananajam and master should be performed.
 * `master` - This is a branch for a hosted version of the Banana Scrum. It was derived from the core branch and has commits with features like payments, registration, etc.
 * `bananajam` - Branch for shippable version of bananascrum (Pro). It was derived from core branch and has features such as licenses, initial database, setup, etc.
  
**IMPORTANT** new features and bugfixes must be made on branch `core` and merged into `master` and `bananajam` branches.

Backport branches
_________________

Sometimes when bugs go unnoticed to production, we are forced to backport some bugfixes into production. In such case we fix
those bugs on backport branch. Backport branches must have names that sick to following naming convention:
`sprint-NN-backports`. When backport is ready for deployment, tag `sprint-NN.M` is created on such branch to track in what state
code was when on production. We should also create backport branches and tags on `jruby` branch, prefixed with
`jruby-sprint-NN``.

Workflow for backports
======================

Following scenario is used for working with backport branches:

#. Create backport branch for sprint NN from tag ``git checkout -b sprint-NN-backports sprint-NN``
#. Fix bugs on that branch. Make sure unit tests pass on that branch.
#. Merge into master. Wait for CI tool to run tests
#. If tests fail, go to step 2.
#. Switch to branch `sprint-NN-backports`
#. Bump bananascrum version in appconfig.yml to `NN.M`, where NN is sprint number and M is number of backport to be deployed,
   starting from 1.
#. Perform release procedure

Same workflow applies for `jruby` branch. Branch and tag names should start with `jruby-sprint`.
