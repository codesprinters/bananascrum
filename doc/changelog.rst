#########
Changelog
#########

Banana Scrum 2.24
=================

``Hosted version``:

* Fix xhr only request filters bug (adding new users).

``PRO version``:

* Fix xhr only request filters bug (adding new users).

Banana Scrum 2.23
=================

``Hosted version``:

* Fix task counting issues after jQuery upgrade.

``PRO version``:

* Fix task counting issues after jQuery upgrade.

Banana Scrum 2.22
=================

``Hosted version``:

* Fix IE9 drag & drop issues (jQuery, jQuery UI update).

``PRO version``:

* Fix IE9 drag & drop issues (jQuery, jQuery UI update).
* Fix links in notification emails (remove subdomain info).

Banana Scrum 2.21
=================

``Hosted version``:

* Fix no error message upon insufficient privileges for given roles.
* Prevent the new backlog item button to reload the form once it was opened.
* Add missing template for pdf cards.
* Fix payment amount precision in notification e-mails
* Add the instant item copy feature

``PRO version``:

* Fix no error message upon insufficient privileges for given roles.
* Prevent the new backlog item button to reload the form once it was opened.
* Add missing template for pdf cards.
* Fix payment amount precision in notification e-mails
* Add the instant item copy feature

Banana Scrum 2.20
=================

``Hosted version``:

* Fix index cards rendering error
* Fix paid accounts count in Site Admin
* Fix ambiguous label for notifications field for users

``PRO version``:

* Fix index cards rendering error
* Fix paid accounts count in Site Admin
* Fix ambiguous label for notifications field for users

Banana Scrum 2.19
=================

``Hosted version``:

* Compatibility changes for JRuby 1.5 upgrade
* Fix for broken CSV export/import
* Remaining work days shouldn't be visible on the last day of sprint. Old layout
  fixes.
* Total estimate in hours for given item wasn't recalculated in the old
  layout.

``PRO version``:

* Compatibility changes for JRuby 1.5 upgrade
* Fix for broken CSV export/import
* Remaining work days shouldn't be visible on the last day of sprint. Old layout
  fixes.
* Total estimate in hours for given item wasn't recalculated in the old
  layout.

Banana Scrum 2.18
=================

``Hosted version``:

* User selectable date format. Each user can choose a date format on their
  profile edit screen. From that point, every date that is displayed in the
  application would be formatted according to user preference.

* Learning resources presented at the end of the account creation process.

``PRO version``:

* User selectable date format. Each user can choose a date format on their
  profile edit screen. From that point, every date that is displayed in the
  application would be formatted according to user preference.

* Learning resources presented at the end of the account creation process.

Banana Scrum 2.17
=================

``Hosted version``:

* Added index card generation. Users can generate a PDF file containing a set
  of index cards to be printed, cut and used on a conventional board on
  planning meetings. Index cards can be generated on the sprint page
  (generated cards would represent items and / or tasks from given sprint) or
  on the backlog page. Users can generate cards representing Backlog Items and
  cards representing Tasks as well.
* Added remaining workdays on the about section on the sprint page.
* Bugfix: Proper date presented on invoices.

``PRO version``:

* Added index card generation. Users can generate a PDF file containing a set
  of index cards to be printed, cut and used on a conventional board on
  planning meetings. Index cards can be generated on the sprint page
  (generated cards would represent items and / or tasks from given sprint) or
  on the backlog page. Users can generate cards representing Backlog Items and
  cards representing Tasks as well.
* Added remaining workdays on the about section on the sprint page.

Banana Scrum 2.16
=================

``Hosted version``:

* Fixed country selection drop down with proper country code mapping which
  affected the invoice generation process
* Fix and change domain.full_name to domain.name in users' csv export in
  SiteAdmin
* Change misleading header from 'Likes spam' to 'Notifications' in SiteAdmin 
* Fixed the attachments bug (customers were unable to add attachments >1MB due
  to nginx configuration).

``PRO version``:

no changes

Banana Scrum 2.15
=================

``Hosted version``:

* View domain billing data (customer details) in SiteAdmin
* Domain totals in SiteAdmin
* Fixed timezones bug
* Select invoices to be shown by invoice type / numbering series

``PRO version``:

no changes

Banana Scrum 2.14
=================

``Hosted version``:

no changes

``PRO version``:

* Fixed initial account data import from the hosted version
