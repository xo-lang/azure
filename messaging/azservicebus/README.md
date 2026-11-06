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
- Receiving in peek-lock or receive-and-delete mode, from queues,
  subscriptions and their dead letter sub-queues; complete, abandon,
  defer and dead letter (on the link, or on `$management` for deferred
  messages); receiving deferred messages by sequence number; peeking;
  renewing a message's lock.
- Errors with Go's codes (`unauthorized`, `notfound`, `locklost`,
  `timeout`, `connlost`, `closed`) and the AMQP condition.

Not yet, with what each needs:

- Session receivers (`accept_session_for_queue`,
  `accept_next_session_for_queue`, session state and lock renewal): next.
- A batch is one transfer in Go (message format 0x80013700); here each
  message is its own transfer, since std/amqp's `send` takes no message
  format.
- `receive_messages` grants one credit at a time and does not drain;
  after it returns, the link may hold one locked message that the next
  call returns (Go drains its credit). Needs manual credit and drain in
  std/amqp.
- Settling on the link does not wait for the service's answer (Go's
  receiver settle mode second does), so a lost lock shows on the next
  operation rather than in `complete_message`.
- `properties_to_modify` on abandon and defer (needs annotations on
  std/amqp's `modify`), the admin client, and retries and link recovery.

Tests run against std/amqptest's in-process broker on the test world's
network (`xo test .`).
