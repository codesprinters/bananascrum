Exporting Data
==============

1. Find the domain_id to export.
2. Invoke the task for exporting sql data:

  ::

  > rake export:domain domain_id=#{selected domain id} > import.sql

3. Check the generated sql file (It may contain artifacts from the rake task).
4. Invoke the task for exporting attachments:

  ::

  > rake export:attachments domain_id=#{selected domain id}

5. Deliver the generated ``*.sql`` and ``*.zip`` files to the client.

