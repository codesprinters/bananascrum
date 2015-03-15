######################
Juggernaut integration
######################

In order to synchronize every action on product backlog, sprint planning and sprint pages without page reload we exchange information through Comet connections using `Juggernaut <http://juggernaut.rubyforge.org/>`_.

Assumptions
===========

During the design phase we have agreed to the following basic assumptions

* Every change of an element on the project page (backlog, sprint or planning) should be managed by the single HTTP request sent by the client who triggers the change, no more.
* The rest of the clients should get all the information necessary to update their interfaces by the Juggernaut message, without the need of performing some additional HTTP requests.
* Locks are advisory. Their work only in the view layer, and are not taken into account by the model. There is no timeout clearing the lock. Locks are removed by the user or after the disconnection with juggernaut of the client   who created the lock.
* Clients are forbidden to send brodcasts. We use this channel to receive updates 
* It is impossible to connect with other project channel or worse, to other domain. This is managed by the JuggernautSession model.

Implementation
==============

Basic info
----------

Banana Scrum is using it's own hacked version of juggernaut, so please **DON'T** use of the shelf one. Changes include renaming of few modules to suit rails naming convention, and some sanity checks to prevent deadlocks.

``rake juggernaut:start`` should nicely run juggernaut server in background, using RAILS_ENV you provide. For stopping (how you stop something that's unstoppable?) you can use ``rake juggernaut:stop``.

Server side communication implementation
----------------------------------------

The assumption for this to work was that server broadcasts the information about the change of some resource along with all data needed to update the client page. All one have to do to add the controller action which notifies clients is to add::

    prepend_after_filter :juggernaut_broadcast ...

to this action. Client is identified by the ``JuggernautSession`` object which is created during page rendering. The id of this object is passed with all the non-get requests in the application (as ``session_id`` parameter).

Format of message sent to the clients
-------------------------------------

Format is as follows::

    message = { 
      operation: Identifies action which triggered the broadcast with format 'controller/action'. There are also two special actions: 
               'current_locks' - received after subscription, 'disconnected' - triggered when client exits project page
      envelope: JSON envelope rendered in response to the request. In case of actions which renders plain text or html, the response is wrapped in { :html => response } JSON.
      session_id: ID of JuggernautSession object used by the client who sent the request. This is used to ignore broadcasts triggered by the client himself
    }

Java Script client side implementation
--------------------------------------

All the callbacks are defined in ``bs/callbacks.js`` file. To register a callback one have to use following function::

    bs.juggernaut.registerCallback(operation, callback);

Callback function should take one parameter (envelope, see above) and will be called when some other client triggers a broadcast identified by the operation (format 'controller/action'). This function is ment to update the user interface to the current state. All the actions triggered by envelopes elements (flashes, burnchart refreshes, sprint participants) are managed before passing envelope to the callback, so one doesn't have to care about this part any more.

Locks
-----

For the actions which are not instant we use item locking. Examples of such actions are: editing item description, dragging the item, etc. Locks are are represented as the FK constraint from backlog_items table (``locked_by_id`` column) into juggernaut_session table (``id``). Locks have advisory purpose only, which means we don't prevent changes on models locked by other users. This is only ment to have user interface represatation.

To lock/unlock a backlog item we have to send HTTP POST. Javascript functions which manages this are bs.mutex.lock and bs.mutex.unlock defined in mutex.js file.

Server internals
================

Connection process
------------------

Connection beetween flash client and the Juggernaut server is being established in following steps:

* User opens a page where we use juggernaut (backlog, sprint or planning). Server-side code creates the JuggernautSession object. It's id is passed to bs._sessionId JS variable along with HTML and passed to flash client.
* Flash object opens socket connection to our server on port 5002 and sends handshake message (JSON), which format is as follows::

      handshake = {
        :command => :subscribe,
        :session_id => @session_id,
        :client_id => @session_id,
        :channels => [@channel]
      }

 Channel above is id of project object.

* Juggernaut server sends GET HTTP request to ``/juggernaut/suscribe?session_id=...`` url. session_id is passed in params. If response code is else than 200 socket connection is closed. After this request ends the client is registed by Juggernaut server and can receive messages. For this reason we cannot send any messages to the client from the code of suscribe action. To solve this problem we introduced dirty hack. We fork another process and send further messages from it.

* Rails application (in fork) orders the Juggernaut server to send to the client list of current locks and all the messages broadcasted in time beetween creation of JuggernautSession object and subscription.

Disconnection
-------------

When the user leaves page with the flash object the socket connection is closed. Juggernaut server sends HTTP GET to ``/juggernaut/disconnected?session_id=..`` URL. During this request we clear all locks made by user and notify clients about it. 10 seconds later Juggernaut server sends HTTP GET to ``/juggernaut/logged_out?session_id=...`` URL. We destroy JuggernautSession object.

JuggernautCache
---------------

``JuggernautCache`` is a layer introduced to solve the problem of lost messages sent in the critical time between creation of ``JuggernautSession`` object and successful subscription from the flash client. For slow connections it can go up even to 5 seconds. In case anything changes on page during this time the client would end up in having outdated user interface. 

To solve this problem we store messages in MemCache. The ``juggernaut_message_id`` resource keeps the counter of send messages. When we create ``JuggernautSession`` object we store current value. After the subscription we send all messages with ``stored_id <= id <= current_id``. Messages itself are kept in resources named ``message_<id>`` and expire after 10 seconds to prevent high memory usage.

store_messages configuration option
-----------------------------------

If you look up juggernaut documentation you will find the ``store_messages`` option. This is not stable and should not be used. For details look into `ticket #537 <https://dev.codesprinters.com/trac/bananascrum/ticket/537>`_.
