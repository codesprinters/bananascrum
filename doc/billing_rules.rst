#####################
Billing specification
#####################

**Status: version 1, official**

Definition of terms
===================

Following is the definition of how certain terms are to be understood in this spec:

* **domain** - an account on the system used by a team/company, that has a name, an access URL (http://domain.bananascrum.com) and contains users and projects.
* **user account** - a user account used by the users to log into their Banana Scrum domain, it has a name that is unique within one domain, it can be locked or unlocked. 

Definition of plans
===================

Plans are billing constructs that are used to bill Banana Scrum clients.
Plans are applied per domain per month and differ by:

* number of active (non-locked) users,
* number of active (not archived) projects,
* number of items on the backlog per project,
* disk space used (by attachments to backlogs),
* additional functionality availability.

Plans can have different prices, at least one plan will be free. Plans can 
also be public or confidential. Confidential plans won't be shown to general
users on the screen where they can choose the plan to use, only site admin
will be able to apply this plan to selected domains.

Therefore, a plan consists of:

1. Plan name.
2. maximal number of active (non-locked) users,
3. maximal number of active (not archived) projects,
4. maximal number of items on the backlog per project,
5. disk space (for attachments to backlogs items), in MB,
6. Set of flags defining features available.
	* ability to use https encrypted access, 
	* ability to replace site logo with own logo on the login screen, 
	* ability to change the color schema of the UI, 
	* Timeline view

Active users
------------

Depending on the plan applied a given domain can only have a certain number of
active users in a given month. If the number of users is equal to the limit
defined in the current plan it is not possible to add new users, users have to
be deleted or locked before a new user account can be created. 

Locked users are not counted towards the limit. A locked user can not be
unlocked if the number of active users equals the limit of active users from
the current plan. 

Active projects
---------------

Active projects are projects that are not archived. Users can make any changes
only to active projects - it is not possible to edit archived projects in any
way. Exception: admin users can remove archived projects completely. 

Also, archived projects do not appear in the dropdown list used for switching
projects for regular users - they do appear there after a separate heading for
domain admin users. All users who had rights to archived projects can still
view their contents. When number of active projects is equal to the limit in
the current plan it is not possible to add new projects or un-archive old
projects. 

Number of backlog items
-----------------------

When the limit of backlog items defined in the current plan is reached (or exceeded) in a
given project then no more items can be added to the backlog. When a user
tries to add backlog items a flash message is displayed informing the user that the plan limit has been reached.  

Items assigned to sprints (moved to sprint backlogs) do not count towards the limit of backlog items. However, when the limit is reached it is not possible to drop items from sprint backlog (move them back to the main backlog). When trying to do so a messages is displayed informing the user about it.

Disk space
----------

Total disk space used is computed by adding the sizes of all file attachments in all projects. Attachments in the archived projects also do count towards this limit. If the total disk space used is equal or greater than the limit in the plan it is not possible to add new file attachments in any project within given domain. When adding a new file attachment its size is checked against the difference between the limit defined in the current plan and the current disk use - files bigger than unused limit are not allowed. 

Other functionality
-------------------

Certain functions are available only in some plans.

Following functions as of now are available only in some plans:

* ability to use https encrypted access,
* ability to replace site logo with own logo on the login screen,
* ability to change the color schema of the UI,
* Timeline view. 

Billing rules
=============

Each new domain is created with a plan. For all new domains the plan is chosen by the user during account creation. At least one plan will be free and visible to the users - the user will have the option of choosing this free plan. 

Domains with paid plans
-----------------------

Each domain is billed monthly, in a cycle that starts on the day it was created with a paid plan. Each domain is billed on the first day of its own cycle. Price from the current plan is applied to the credit card stored by the payment gateway/PayPal. User is notified with an e-mail, attached to the e-mail is the invoice that is generated in PDF. Invoices are also available in the Admin panel (with full billing history).

Billing starts 30 days after a new domain with a paid plan is created. In this way an initial 30 day free trail period is implemented. If domain is cancelled (removed) from the server before those 30 days no charges are applied. Domain created with a paid plan can not be downgraded to a free plan within this first 30 days.

A valid credit card number is required to create a new domain with a paid plan. 

Plan changes
------------

When the user requests plan change we always check the domain against the rules/limits of the desired plan to see if the domain will "fit". If not the user is informed that his account is to big for the selected plan and is informed why (eg. too many users - you have X plan you want allows Y etc.). 

If a change is between paid plans then change from a cheaper plan to a more expensive plan is considered an upgrade, if the change is from a more expensive plan to a cheaper plan it is considered a downgrade. Change from any paid plan to a free plan is considered a downgrade. 

Site admin can arbitrarily change plans applied to a given domain. 

Upgrades
^^^^^^^^

When domain is upgraded the upgraded plan takes effect immediately, however new amount will be charged on the next billing cycle. 

If upgrade is from a free plan charges are applied immediately - a valid credit card number has to be presented and transaction has to be confirmed (payment successfully completed) by the payment gateway for the upgrade to take effect. The billing cycle starts on the day the upgrade was successfully completed, next charges will be applied on the same day next month. 

In the period between upgrade taking place and charging for the next month downgrade is not possible. Further upgrades are permitted. Complete account removal is permitted - in that case charges are not returned.

Downgrades
^^^^^^^^^^

Downgrade is possible at any time except after an upgrade was ordered but not yet charged (see above). Downgrade takes effect immediately, but no refunds or partial billing is ever taking place. New amount will be applied in the next billing cycle. Before this happens the downgrade can be cancelled. If downgrade is cancelled domain limits revert to the original plan. An upgrade to a different paid plan is also possible after downgrade has been selected but before the payment is applied - in that case the downgrade is cancelled and then upgrade applied.

Downgrade is not possible before the usage in the domain is not lowered to fit into the new limits. In other words number of users, projects and disk space used have to be lower than the limits in the new plan before this operation is allowed. This is checked when the user requests the downgrade, obviously, because downgrade effects are immediate. If those conditions are not met the user gets an error message (explaining in detail which limits are preventing the downgrade from being applied) and the plan applied doesn't change.

Also, all additional features will be disabled immediately and some content will be lost (eg. if custom logo was used and the domain is downgraded to a plan without this option the logo will be discarded). User should be warned about this before the change is effected. 

Prices and charging
===================

Prices are expressed in Euros (EUR). Prices are defined along the plans in the database. 

Conversion to other currencies is handled by the payment processing gateway - we always charge the end amount in Euros. Charges are made to a credit card through a payment gateway. Credit card numbers are never collected or processed by us - always by the payment gateway. 

*For plan definitions and prices see other document (pricing model).*

First time charge
-----------------

Process described in this section will be implemented in future. At the moment the only supported way for paying for Banana Scrum account is PayPal.

First time charge for an upgrade from a free account will be processed immediately. If we don't get a response from the payment gw that the transaction was completed successfully (money successfully collected) we don't permit the upgrade and return the user to the payment screen prompting to enter correct billing data. 

First time charge for a new domain with a paid plan is processed as follows: 

* upon domain creation billing data is collected *by the payment gateway* and credit card number is verified, a lock is established on the credit card for the amount due depending on the plan,
* when billing date arrives and account was not deleted the payment gateway is told to change the lock into charge, otherwise the lock is dropped. 

Recurring charges
-----------------

For recurring charges the payment gw is told the amount. How it is done will depend on the particular GW we choose. 

PayPal payments
---------------

For PayPal payments we use the Express Checkout service. After the user has decided to upgrade his account to the paid plan he is redirected to the PayPal login screen. There he has an option to either log in to his account or to pay with his credit card (without loggin in). This way or another he must accept the subsciption request in the PayPal interface. When he does, we receive the POST information from PayPal about the success. From now on we do not send any requests to PayPal unless user decides to down/upgrade his account.

When the billing start date arrives, our site is notified about charging the client by a POST request. In case something goes wrong we also get a POST request informing about the failure. The user has two ways of cancelling his subsribtion: he can either downgrade his domain from our interface, or login to his PayPal account and cancel the subscription from PayPal interface. If he ellects the second option we are notified about it with a POST request. Afterwards we will not be notified about failing payments. In such case the account will be blocked after the payment period ends (see Domain locking rules).

Invoicing
=========

Each time a charge is successfully applied an invoice is produced. Different invoicing rules apply to clients from Poland and from outside Poland. Both types of invoices look different and have different numbering schema as described below.

Name of the buyer, billing address etc. is stated on the invoice exactly as typed in by the user into appropriate domain profile. No changes to this information are possible retroactively. 

*For detailed information see separate document (in Polish) - fakturowanie.*

Domain locking rules
====================

Domains can be locked for non-payment. Non payment is when the payment gateway was not able to process the recurring fee for a domain at the beginning of its billing cycle. 

Following rules apply.

Let's assume the day the payment was due is D. Then:

* D+1 and payment not received - a warning message is displayed on all accounts, e-mail is sent to domain admins,
* D+6 - a warning message is displayed warning of imminent domain locking, e-mail is sent to domain admins,
* D+8 - domain is locked, users that are not admins can't log in - are shown an error message, users that are admins can log in, but they can only access the payment page so that they can enter a CC number to pay. 

System admin has always an option to override this by assigning a free month, multiple months or switching to a free plan.

Migration from the current state
================================

When billing is introduced all current users will be migrated to a special, publicly not available free plan. This plan - called "Exisiting Bananas" will have no limits introduced by the new free plan, will be valid for 6 (six) months only. After that all users on "Existing Bananas" will be upgraded to a paid plan appropriate to their usage of things limited by plans. They will have 30 days to downgrade to free account or pay and stay on their paid plan.

*Since this is a one-time event it will be handled manually, no implementation of plan durations or automatic changes is expected.*

Payment gateway
===============

We'll use PayPal. 

*(This section should be revised)*

We still consider using the DotPay payment gateway which is documented in the following specifications.

* `Technical specification <_static/dotpay_instrukcja_techniczna_v05.pdf>`_
* `Rebilling API <_static/dotpay_api_rebilling_v10.pdf>`_

