########################
Banana Scrum Deployment 
########################

This short document describes how to deploy the Banana Scrum application on your Java application server of choice.

Requirements
============
#. MySQL >= 5.0
#. Java JDK >= 1.6
#. Ant >= 1.8.1
#. A Java application server (ex. Jetty, Tomcat) capable of hosting ``*.war`` packaged applications
#. Memcached (optional)

Files in the installation/update package
========================================

 * `bananascrum.war`   - the application package
 * `build.xml` - build instructions for the ant script
 * `database.yml.sample` - sample database config file
 * `config.yml.sample` - sample application config file
 * `livesync_hosts.yml.sample` - sample configuration file to store the IP address and listen port of Banana Scrum LiveSync server
 * `livesync/` - folder containing standalone LiveSync server

Optional:
 * `import.sql` - sql file with the data imported from www.bananascrum.com

Installation
============

#. Create a MySQL database for the application and an admin user account to access it
   For example you can run these commands as the MySQL server super user in the command prompt::

   > CREATE DATABASE bananascrum DEFAULT CHARACTER SET utf8;
   > GRANT ALL ON bananascrum.* TO bananascrum@localhost IDENTIFIED BY 'password';

#. Copy database.yml.sample to database.yml and modify it according to your database server configuration.
#. Copy config.yml.sample to config.yml and edit it, following the instructions below:

   * Set the `banana_domain` to the domain name that your application will
     listen on for requests. The default is ``localhost`` however this option
     could be just as well set to a fully qualified domain name such as
     `bs.your_company.com`.
   * If you wish Banana Scrum to be e-mail enabled set the ``send_emails`` option to ``true`` and 
     check the `E-mail configuration`_ section. The default value for this
     option is ``false``.
   * Create a folder for storing attachments, for example /srv/apps/bananascrum/attachments and
     set the appropriate permissions (depending on your system configuration).
   * If you wish to serve the Banana Scrum application over https, see `Setting up SSL`_ section.
   * If you wish to use the `LiveSync feature`, see `LiveSync server setup`_ section.
   * For heavily used instances we recommend installing `Memcached` (http://memcached.org/). This is not necessary for Banana Scrum Server to run, but it speeds up the application while using the LiveSync feature for large user groups. The Banana Scrum application expects Memcached to be running on the same machine on the default port (TCP 11211).
     
#. If you wish to import your data from www.bananascrum.com, see section `Importing Data`_.
#. Run ``ant`` while being in the build folder and wait for it to complete.
#. The application package file ``bananascrum.war`` is now ready for deployment. Copy it on your web application server.
#. Once Banana Scrum is deployed on your application server go to the URL of
#. **Store database.yml and config.yml files for further updates**

Update
======
#. Overwrite the config files in the update directory with your own or edit them again to fit your current setup.
#. Run ``ant`` in the folder with the update.
#. Replace your old ``bananascrum.war`` on the application server with the one from the update.
#. (Re)Start the server, all necessary database updates will be performed automatically.
#. You're done!

.. _`E-mail configuration`:

E-mail configuration
====================

Email server configuration is optional. If enabled it is used to send notifications
about different events which occur in the application to users.
Set ``home_mail`` value in the ``config.xml`` file (e-mail address Banana Scrum will send 
messages from) and all options for ActionMailer.
You can either use a ``sendmail`` binary on the server (if present) or
configure a SMTP server (local or on an external machine). 

.. _`Importing Data`:

Importing Data
==============

If you are moving from the hosted version you might be interested in importing
your account data. We provide an archive containing a sql file and an archive
with all of your attachments. The sql file will be automaticaly imported upon Banana Scrum installation. 
The attachment files have to be extracted from the archive and placed in the
directory configured in the ``config.yml`` file.

#. Place the ``import.sql`` file in the installer path.
#. Copy the exported attachment files to the path selected for attachment storing.

.. _`Setting up SSL`:

Setting up SSL
==============

To enable https for your instance of Banana Scrum, you should set ``ssl_enabled``
to ``true`` in the ``config.yml``. Setting up ssl depends on your web server
configuration. If you are using a web server (e.g. nginx or Apache) as a proxy to Banana Scrum on the Java application server
you should set the ``X-Forwarded-Proto`` header to https. For the Apache web server, use the following directive::

    RequestHeader Set X-Forwarded-Proto "https"


.. _`LiveSync server setup`:

LiveSync server setup
=====================

Banana Scrum LiveSync Server allows users to see the changes being made to the sprint and backlog pages
as they take place, without the page being reloaded. For example, when one user changes an item's
description, other users, who have the same page opened will see that change
instantly.

Setting up Banana Scrum LiveSync Server requires changes in the Banana Scrum
configuration and running a standalone service, that'll push all of the changes to clients.
Default setup assumes that the Banana Scrum web application and the LiveSync server
will run on the same host. Default port for the LiveSync server is 5001.

Related configuration options:
 * Set the ``livesync_enabled`` option to true in ``config.yml``.
 * Edit the values of ``livesync_hosts.yml`` to change the port numbers there, if 5001 is not suitable for your setup.
 * If the Java executable is not in your ``PATH`` environment variable, you should set the
   ``wrapper.java.command`` option in the ``livesync/conf/wrapper.conf`` file to the full
   path to Java executable.
 * Set the URLs options in ``livesync/conf/livesync.yml`` file to the URLs
   that points to your application. The default values are:

  ::

  :subscription_url: http://localhost:8080/juggernaut/subscribe
  :logout_connection_url: http://localhost:8080/juggernaut/disconnected
  :logout_url: http://localhost:8080/juggernaut/logged_out

  You have to change theese values if your server is listening on the port different than 8080 or the application URL doesn't start at root. Theese options are mandatory, otherwise the livesync server won't work.

Once the server and the web application are configured, you should start the
service, depending on your platform.

Running Banana Scrum LiveSync Server on Linux/Unix
--------------------------------------------------

We use the Java Service Wrapper to launch the LiveSync server in console, or as
a daemon. To launch it in console, run ``./livesync/bin/livesync console``.
The daemon can be started by passing `start` argument to the script. To see the full
list of commands, run the script without arguments. Logs are stored in the
``livesync/logs/wrapper.log`` file.

Running Banana Scrum LiveSync Server on Windows
-----------------------------------------------

There are three bat scripts to control Banana Scrum LiveSync Server. To start
it as standard process, run ``Livesync.bat``, which is located in the
``livesync/bin`` directory. Scripts ``InstallLivesync-NT.bat`` and
``UninstallLivesync-NT.bat`` install and uninstall the LiveSync server as a Windows
Service. Once the service is installed, you should see it on the list of Windows
Services as `Banana Scrum LiveSync Server`.
