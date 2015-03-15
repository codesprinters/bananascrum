###################################
Banana Scrum v2 migration procedure
###################################

Migration goals
===============

The goal of this procedure is to move the Banana Scrum production instance
from the existing infrastructure at OVH to our new production server at
`Rackspace Cloud <http://www.rackspacecloud.com/>`_. The migrated version of Banana Scrum would be also the first
public release of the JRuby implementation. In consequence Banana Scrum would
be from now on hosted on Java application servers (in our case
`Glassfish V3 <http://wiki.glassfish.java.net/Wiki.jsp?page=PlanForGlassFishV3>`_).

Architecture overview
=====================

All requests are handed to the NGINX web server.

Preliminary steps
=================

1. Disable maintenance mode in the capistrano config file
   ``config/deploy.rb``, since capistrano automatically disables the
   maintenance mode after server restart.

2. Import attachments from OVH to the new production server.

   On OVH:

   * ``cd /home/bananascrum/bananascrum.production/shared/bananascrum/uploads``
   * ``tar -czvf attachments.tgz attachments/``

   On Rackspace:

   * ``cd /home/bananascrum/bananascrum.production/shared/bananascrum/uploads``
   * ``scp -P 22000 root@87.98.154.148:/home/bananascrum/bananascrum.production/shared/bananascrum/uploads/attachments.tgz``
   * ``tar -zxvf attachments.tgz``
   * ``rm attachments.tgz``

Procedure steps
===============

#. Start maintenance mode on the production server at Rackspace.
    We'll be redirecting online users from OVH to Rackspace, so we have to prevent
    them from accessing the application while moving the database dump from
    OVH. To accomplish this we're going to turn on the maintenance mode. 

    Maintenance mode is triggered by creating a ``maintenance.txt`` file in the
    ``/home/bananascrum/bananascrum.production/`` directory on the production
    server. If this file is preset all requests received by NGINX would be
    rewritten to a maintenance page. In order to turn off the maintenance mode
    the above file should be deleted.

#. Disable IP filtering in the nginx config file ``/usr/local/nginx/conf/nginx.conf`` on the new production server for the Banana Scrum application (NOT the Site Admin app).

#. Setup `rinetd <http://www.boutell.com/rinetd/>`_ on the production server
   at OVH.
    Rinetd is a small application designed to redirect all tcp connections for
    an ip and port to a different ip and port. We'll use rinetd to redirect
    all users, accessing the old production server to the new production
    instance. At this point all users (regardless of accessing the new instance or the old system) would get the maintenance screen
    as the response to all requests sent to the application. 
    This way we'll prevent application data being out of sync.

    This is necessary to handle users with outdated DNS information. The
    rinetd should be running at the OVH server until all of the updated DNS zone records
    are propagated.

    Ports to be forwarded: ::

        # bindadress    bindport  connectaddress  connectport
        94.23.196.91    80      173.203.106.107         80
        94.23.196.91    443     173.203.106.107         443
        94.23.196.91    5002    173.203.106.107         5002

    The above configuration is already present on the OVH server. Rinetd can
    be run by invoking ``/usr/sbin/rinetd``.

#. Change DNS zones for bananascrum.com to point to the new production instance.

#. Database migration
   The production database should be dumped, sent by scp to the new production
   instance and then imported from the mysql command line.

   On the existing production instance:

   * ``mysqldump -u root -p --add-drop-table bananascrum_production > bs_prod_01-04-2010.sql``
   * ``tar -czf bs_prod_01-04-2010.tgz bs_prod_01-04-2010.sql``
   
   On the new production instance:
   
   As root:
   
   * ``scp -P 22000 root@87.98.154.148:/root/bs_prod_01-04-2010.tgz .``
   * ``tar -zxvf bs_prod_01-04-2010.tgz``

   * recreate database:

     * ``drop database bananascrum_production``
     * ``create database bananascrum_production``

   * ``mysql bananascrum_production -u bananascrum -p < bs_prod_01-04-2010.sql``
   
   As bananascrum: 
   
   * ``cd /home/bananascrum/bananascrum.production/current/bananascrum/``
   * ``rake db:migrate RAILS_ENV=production``
   * ``rake db:populate:themes RAILS_ENV=production``
   * ``rake db:populate:plans RAILS_ENV=production``
   * ``rake app:migrate_plans RAILS_ENV=production``


#. Disable maintenance mode on Rackspace

