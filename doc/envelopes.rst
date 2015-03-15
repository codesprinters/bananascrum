##############
JSON envelopes
##############

We use JSON format for server-to-client communication. Preferred method for sending envelopes is through ``render_json`` method available
in all controllers.

Successful and error responses
------------------------------

HTTP status codes are used to distinguish wether response is successful or
not. Successful responses must have status code 200. Such distinction allows
us to handle successful and error responses in different javascript functions.

Envelope format
---------------

There is no predefined structure for JSON envelope. However it is not advised
to use names starting with underscore on top level. Some generic messages from
application might override these settings. They all have names starting with
underscore.

Predefined keys
---------------

* ``_flashes`` - flashes set in controllers are sent to application within this
  key. They are stored in proper severity. Allowed severities are notice,
  warning and error

* ``_error`` - Information about error that occurred on server side.

* ``_participants`` - List of sprint participants to display.

* ``_burnchart`` - Open_flash_chart data objects to display Burnup and Burndown Charts.

* ``_unlock`` - ID of the item to release lock after the action.

* ``_projects`` - HTML for list of projects in upper-right menu.

* ``_project_members`` - Information about quantity of team members per projects used in admin panel.

Participants and burnchart keys are set by after filters defined in application_controller. If you need the action to refreshes those you need to set ``@sprint`` variable and code::

    prepend_after_filter :refresh_burnchart, :only => [ :action ]
    prepend_after_filter :refresh_participants, :only => [ :action ]
    
    
Definining handlers
-------------------

There is a common way to add handlers for more keys. To do it write code like this::

    bs.envelope.registerHandler(key, callback);

Function callback will receive one parametter, which is content of envelope for the key. This callback will be used both for HTTP requests and Juggernaut messages.

Error handling
--------------

There is a default function for handling errors that just pops up an alert,
but it can (and should) be replaced in particular cases by providing
callback to ``bs.post`` or ``bs.get`` javascript functions.

If ajax request causes an error on server side (eg. 404 Not Found), client is
notified in envelope with details about the error. Details are stored in
``_error`` key in envelope. There are two attributes describing error

* ``type``: Type of error - useful for debugging. Usually written in snake_case
* ``message``: Human-readable description of the message. Popped up in alert by
  default error handler

There is a convention to throw an exception, if you are unable to handle error
in custom error handler. Such exception will be caught and handled by default
handler. This way application will behave more consistently when unusual
sitiations happen. For example, if you expect that error of type
``set_current_project`` to be sent by server, you should write a function
as follows::

    var error = function(xhr) {
      // Don't worry about exception. Default error handler will serve it 
      var envelope = JSON.parse(xhr.responseText);
      if (envelope._error.type == 'not_found) {
        // Handle this error gently
        // You've got pretty text describing what happened in
        // envelope._error.message
      } else {
        throw "I don't know how to handle this type of error";
      }
    }

