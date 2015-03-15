################
Coding standards
################

.. note:: Changes to this section should be agreed upon on the project mailing list first.

We use the official Code Sprinters coding standards as described on `the Wiki <https://sites.google.com/a/codesprinters.com/code-sprinters/sprawy-techniczne/standardy-kodowania>`_.

Exceptions, new rules or rules we would like to place emphasis on are noted below.

* Indent CSS and JS files with 2 spaces.
* Follow `some-string` (words separated by hyphens) convention for CSS class names and ids
* Remember not to use model classes in migrations, this leads to migrations that are not-deterministic
