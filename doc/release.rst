#################
Release checklist
#################

.. note:: Changes to this section should be agreed upon on the project mailing list first.

Basic rules
===========

* The release has to be finished before midnight release day (in the timezone of the project)
* Everybody stays at the office until the release is complete 

Prerequisites
=============

Things that have to be checked **before** starting the release process.

#. Unit, functional and integration tests are green
#. Selenium tests are green
#. Critical and blocker tickets are resolved, even ones not assigned to the current iteration
#. Tickets in Trac assigned to current iteration are done or at least reviewed and reassigned to the next sprint
#. Backlog items on the sprint are completed
#. Tester has stated clearly that the release is ready to roll 

Actions
=======

Things to be done during the release process.

#. Update the ``BananaScrum::Version`` module's constants with the new version number on the core branch
#. Merge the version bump from the ``core`` branch to master and ``bananajam``.
#. Create tag `sprint-NN` on branch `master` and `jruby-sprint-NN` on branch `jruby`. Make sure it is stored in repo ``git push --tags``
#. Create tar.gz package for distribution from tag `jruby-sprint-NN`: ``rake dist:package``
#. Publish the created package in the ``Pro Zone`` on www.bananascrum.com
#. Close milestone in Trac, ensure that a milestone for the next iteration exists

Deployment
==========

Things to be done during the deployment process, which doesn't necessarily have to happen at the same time as the release.

#. Deploy the application with ``cap deploy TAG=sprint-NN``
#. Manually Check ``demo`` and ``cs`` domains for correctness

Special steps
=============

Special steps that have to be done manually after a given release (eg. scripts, changes in the server configuration etc.) should be described below.

Sprint 25
---------

* Run rake data:migrate_from_s3
* Change USE_AWS_S3 to false

Sprint 26
---------

* Run rake app:stats:migrate database=bananascrum_stats to migrate old statistics data into production database

Sprint 33
---------

* On production machine, run `rake juggernaut:restart` to make sure that new
  version of juggernaut is running

Sprint 37
---------
* On production, update attachments_path: ':rails_root/uploads/attachments'
  in appconfig.yml to desired absolute path.
