# azservicebus

Azure Service Bus for Xo, a port of Go's `sdk/messaging/azservicebus`
v1.11.0 over std/amqp. Names and shapes follow Go's: `new_client`,
`new_client_from_connection_string`, `new_sender`, `send_message`,
`new_message_batch`, `schedule_messages`, `new_receiver_for_queue`,
`receive_messages`, `complete_message`, and the rest.

What it does:

- Connection strings with a key, a signature or
  `UseDevelopmentEmulator=true` (plain `amqp://`, a port allowed), and
  Entra ID credentials (`jwt` tokens for
  `https://servicebus.azure.net//.default`). Each entity's link is
  authorized with a CBS put-token first.
- Sending one message, batches, scheduling and cancelling scheduled
  messages.
- `AMQPAnnotatedMessage` (std/amqp's `Message`, every section):
  `send_amqp_annotated_message`, `schedule_amqp_annotated_messages` and
  `add_amqp_annotated_message`, sent as Go's (a batch of them checked
  byte for byte against Go's).
- Receiving in peek-lock or receive-and-delete mode, from queues,
  subscriptions and their dead letter sub-queues; complete, abandon,
  defer and dead letter (on the link, or on `$management` for deferred
  messages); receiving deferred messages by sequence number; peeking;
  renewing a message's lock.
- Session receivers for a named session (`accept_session_for_queue`,
  `accept_session_for_subscription`) or the next free one
  (`accept_next_session_for_queue`, `_for_subscription`, the session
  read from the attach reply), with the lock's expiry from the attach,
  session state and lock renewal.
- Listing an entity's sessions (`new_list_sessions_for_queue_pager`,
  `_for_subscription_pager`): those with messages, or with
  `session_state_updated_after` those whose state changed after a time,
  in pages of 100 on `$management`, as Go's.
- Batches in one transfer of message format 0x80013700, sized from the
  link's attach as Go's; settlements in receive settle mode second that
  wait for the service's answer (a lost lock shows in the call);
  `properties_to_modify` on abandon and defer.
- Retries and recovery as Go's: `ClientOptions.retry_options`
  (`RetryOptions`: 3 retries, 4 s doubling with jitter, 120 s cap by
  default). Each error carries its `RecoveryKind`: a busy server or a
  timeout is retried as it is, a forced detach gets a new link (one
  quick retry that does not count), a dropped connection gets a new
  connection and new links, and not found, unauthorized and lock lost
  are returned at once. Links attach lazily and again on the next
  connection. A message settles on the link it came on while that link
  is current, else on `$management` by its lock token; a settlement
  that went through is refused a second time without a request.
- Errors with Go's codes (`unauthorized`, `notfound`, `locklost`,
  `timeout`, `connlost`, `closed`) and the AMQP condition.
- The admin client (package `admin`, Go's `azservicebus/admin`): create,
  update, get, get runtime properties, delete and list pagers for
  queues, topics, subscriptions and rules, and the namespace's
  properties, over the Atom API (`api-version=2024-05`). Each try is
  signed for its URL (SAS, or the credential's JWT as Go sends it), and
  forward targets get supplementary tokens. Bodies match Go's byte for
  byte (checked against Go's own requests). Rules take SQL, true, false
  and correlation filters with typed parameters, SQL actions, and keep
  unknown filter and action types as XML.


Where the AMQP side differs from Go v1.11.0:

- `receive_messages` issues manual credit for what it asks, as Go's, and
  then drains what is left, so no message stays locked to the link
  between calls. Go keeps the credit and releases late messages from a
  background loop; the outcome is the same without a background task.
- A link that names no max message size (AMQP's 0, no limit) gives a
  batch with no limit; Go would refuse every message.

Where admin differs from Go v1.11.0, each a Go bug:

- Rule and SQL parameters are written in key order (Go: map order).
- A subscription's `Status` is sent (Go drops it from the body;
  Azure/azure-sdk-for-go#27943).
- The subscription pagers send no stray `%3F=` parameter.
- A rule with no name is put to `.../Rules/$Default`, the name its body
  carries (Go puts it to `.../Rules/`; Azure/azure-sdk-for-go#27945).
- An unknown filter or action whose XML declares `xmlns:i` goes back
  well formed (Go writes its type attribute twice;
  Azure/azure-sdk-for-go#27944).
- A rule entry without an Action reads as no action (Go panics;
  Azure/azure-sdk-for-go#27946).

Durations stay ISO 8601 strings, as Go keeps them. A runtime time is
None where Go has its zero time (an entity never accessed).

Tests run against std/amqptest's in-process broker on the test world's
network (`xo test .`).
