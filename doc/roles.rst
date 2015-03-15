########################
User roles specification
########################

Definition of terms
===================

We have the following roles possible in banana scrum

* Scrum Master
* Product Owner
* Team Member


Behaviour after logging in
--------------------------
If user had selected project during last session next time he will be logged as follows:
**Product Owner** is redirected to the backlog of recently selected project.
**Scrum Master** and **Team Member** are redirected to sprint page of selected project.

If user has many roles including **Product Owner** he will be redirected as **Product Owner**

Same scenario applies when changing project by choosing one from drop down list.

Access to actions
-----------------
If user has **Product Owner** role only he has limited access to some actions.

**Product Owner**

* can't never perform any actions on tasks,
* can't create, edit or destroy sprint or any of it's parameters (ie. end date, name etc.),
* can't edit any estimates of items which are already in sprint, he can do this when item is still on backlog,
* when on Product Backlog screen **Product Owner** can do anything (except all task actions). All actions related to items are allowed. (incl. comments, attachments, tags).

If user has other role besides **Product Owner** or is an admin all of above restrictions no longer exists.

Visibility
----------
There's no difference in system visibility which depends on user roles other than on links which lead to restricted actions as described earlier.
