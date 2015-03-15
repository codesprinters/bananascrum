================
Project glossary
================

The project glossary describes the meaning of some important terms used in the
project.

.. glossary::

domain
    Banana Scrum is a hosted application that can support multiple domains.Domain
    represents a single organization using the application.
    Domain is the fundamental security compartment. All data is assigned to a domain and data
    from one domain cannot be seen or modified in another. Moreover no information
    can cross the domain boundary. Each domain has an unique URL used to access it
    that is assigned when the domain is registered.

.. glossary::

account
    Sometimes we use the term account when we mention domain in the user interface.
    There is no difference in meaning but we believe the term account is easier
    to understand for users.
    *(Comment: I think using account in this context should be phased out. If
    domain is too difficult for users some other term, like organization account
    could be used to avoid confusion with user accounts.)*

.. glossary::

user or user account
    A user can log in with his login name and password and use the application.
    He can only see projects he is assigned to. A given login name is
    valid only within the context of a single domain. Consequently, same login
    names can be used in different domains.

administrator or domain admin
    Special kind of user who has a permission to manage his domain (including managing 
    users and projects). registration
    Process during which a new domain is created, including the first administrator user. In order to register captcha has to be filled and activation email confirmed.

.. glossary::

project
    Project is tracked in the application. Users are assigned to projects by an
    administrator. Most of the time users work in the context of a single
    project.  Administrator can *archive* a project, such project cannot be
    modified anymore, though it might be unarchived later.

.. glossary::

role
    User can have one or more roles in a given project. Role can be one of the following

    * Product Owner: cannot modify data on a sprint, cannot have tasks assigned
    * Team Member
    * Scrum Master: cannot have tasks assigned

*(Why Scrum Master can't have tasks assigned?!? Who and when introduced this
limitation and why?)*

.. glossary::

backlog item
    Requirement for a project, often described as an user story. The sample format
    is "As [role] I should be able to [action]". Item has an estimate in
    units depending on the project (eg. Ideal Days or Story Points). Item is
    *completed* if it has at least one task and all tasks are completed.

.. glossary::

task
    Specific thing to be done in order to implement a given backlog item (user story).
    For example "Implement foo in the module Bar". Tasks are estimated in
    hours remaining. Item is *completed* when the estimate falls to zero.

tag
    Tags can be assigned to backlog items and items can be filtered on tags.

product backlog
    Prioritized list of backlog items for a project.

sprint
    Sprint is an iteration of work with a fixed time-frame, backlog items are moved to a sprint during sprint planning.

sprint backlog
    List of backlog items assigned to a given sprint.

attachment
    File attached to a backlog item.

comment
    Note added to a backlog item by an user.

burn-up chart, burn-down chart
    Charts representing the progress of a given sprint. Detailed specification of these charts can be found in a separate document.

impediment
    Impediment is an issue that emerged and has been posted. Impediments have status, resolved impediment is an impediment that has been removed.

