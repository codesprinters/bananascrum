#################
Import and export
#################

CSV file format
===============

Item row
--------

CSV files have one row for each backlog/sprint item. At least first field (user story)
per row must be present. Only the first 4 columns in a row are parsed. Redundant columns
are ignored during parse operation. Attribute field values are separated by user separator.
Field separator is detected automatically. The default set of saparator candidates contains
the following characters: ';' ',' '\t'. Attributes may be wrapped with double quotes. Tags
are always separated by commas and have to be enclosed in double quotes.

Task row
--------

Tasks are optional. Task rows are always displayed after item connected with them. In task
row first 4 columns should be empty. Only next 2 columns in a row are parsed. Fifth column
(task summary) must be present. Redundant columns are also ignored.

Special values
--------------

There are two special values of estimate field ``inf`` and ``?``. ``inf`` value
denotes an item with infinite estimate, while ``?`` value can be used for a item
with unknown estimate.

Columns
-------

Item columns
------------

#. User story: text
#. Estimate: [0, 0.5, 1, 2, 3, 5, 8, 13, 20, 40, 100, inf, ?]
#. Description: text
#. Tag: text, list of tags separated by commas

Task columns
------------

#. Summary: text
#. Person: text
#. Estimate: number

In text data double quotes should be preceded by double quotes.

Sample file
===========

::

    "User story 1";5;"Simple item with description";"tag1,tag2,tag3,tag4"
    ;;;;"Summary1";"1"
    ;;;;"Summary2";"5"
    "Silly task";0.5;;"tag1" 
    "Other silly item";40;"Description";
    ;;;;"Summary3";inf
    "User wants all";inf;"Not doable"

Really simple file
==================

Importing can be as simple as creating a list of user stories::

    User Story 1
    User Story 2
    User Story 3
    User Story 4
    User Story 5
    User Story 6
