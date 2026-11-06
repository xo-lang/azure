# azeventhubs

Azure Event Hubs for Xo, a port of Go's `sdk/messaging/azeventhubs`
v1.4.0 over std/amqp. Names and shapes follow Go's:
`new_producer_client`, `new_producer_client_from_connection_string`,
`new_event_data_batch`, `add_event_data`, `send_event_data_batch`,
`new_consumer_client`, `new_partition_client`, `receive_events`,
`get_event_hub_properties`, `get_partition_properties`.

What it does:

- Connection strings with a key, a signature or
  `UseDevelopmentEmulator=true` (plain `amqp://`, a port allowed), the
  event hub from the string's `EntityPath` or the argument (exactly one,
  as Go's), and Entra ID credentials (`jwt` tokens for
  `https://eventhubs.azure.net//.default`). Each link's path is
  authorized with a CBS put-token first, its expiration a string of
  Unix seconds as Go's.
- Batches in one transfer of message format 0x80013700 to the hub, to a
  partition (`partition_id`) or by `partition_key` (on every event and
  the envelope), sized from the link's max message size; each event
  gets a UUID message id when it has none. The sizes and the encoded
  transfer match Go's byte for byte (checked against Go's own
  EventDataBatch).
- `AMQPAnnotatedMessage` (std/amqp's `Message`, every section) added
  to a batch with `add_amqp_annotated_message`, sent with a properties
  and an annotations section as Go's (checked byte for byte).
- Partition clients for a consumer group with Go's start positions
  (earliest, latest, offset, sequence number, enqueued time, inclusive
  or not) as selector filters, an owner level (`com.microsoft:epoch`;
  a receiver that loses the partition gets `ownershiplost`), the
  instance id as receiver name, and prefetch (300 by default, or off:
  each receive gives the credit it wants). After a receive the next
  link starts after the last event returned.
- Received events with the sequence number, offset, enqueued time and
  partition key annotations, the rest as system properties, and the raw
  AMQP message; an annotation of the wrong type is an error, as Go's.
- The hub's and a partition's properties from the namespace's
  `$management` node (a READ with the entity's token).
- The Processor (`new_processor`, `run`, `next_partition_client`):
  partitions claimed in a `CheckpointStore` and balanced among the
  consumer group's Processors (balanced, one partition per round, or
  greedy), renewed every update interval with Go's jitter, expired or
  given up ownerships taken over, and a partition client per owned
  partition at owner level 0, starting after its checkpoint (or its own
  or the default start position). `update_checkpoint` records the last
  event processed; a stopped Processor closes its clients and gives its
  partitions up.
- `InMemoryCheckpointStore` (`new_in_memory_checkpoint_store`), with
  etag checked claims, `expire_ownership` and `relinquish_ownership`
  (Go has it only in its tests).
- `checkpoints.BlobStore` (`checkpoints.new_blob_store(client, container)`),
  over this repo's azblob: each ownership and checkpoint is an empty
  block blob named `<namespace>/<hub>/<group>/ownership/<partition>` or
  `.../checkpoint/<partition>` whose metadata holds `ownerid`, or
  `sequencenumber` and `offset`. A claim with an etag sets the metadata
  with `If-Match`, one without creates the blob with `If-None-Match: *`,
  and a lost race (412 or 409) is skipped. The requests are checked line
  for line against Go's BlobStore on the same fake blob service.
- Retries and recovery as Go's (`retry_options`: 3 retries, 4 s
  doubling with jitter, 120 s cap by default): a busy server or a
  timeout is retried as it is, a forced detach gets a new link (one
  quick retry that does not count), a dropped connection a new
  connection; ownership lost, not found, unauthorized and a partition
  that does not exist (`com.microsoft:argument-out-of-range`) are
  returned at once.
- Errors with Go's codes (`unauthorized`, `connlost`, `ownershiplost`)
  and the AMQP condition.

Where it differs from Go v1.4.0:

- `receive_events` takes its wait as `ReceiveEventsOptions.timeout_ms`
  (Go: the context). When it ends with no events the result is an empty
  list, not the context's error.
- With prefetch off, the credit a receive did not use is drained at its
  end (Go keeps it for the next receive).
- A link that names no max message size (AMQP's 0, no limit) gives a
  batch with no limit; Go would refuse every event.
- The management link pair is opened for each request and closed
  after (Go keeps one).
- `Processor.run` runs until the calling task is cancelled (Go: until
  its context ends), and `next_partition_client` waits until its task
  is cancelled or the Processor stops. New partitions get their clients
  one after another within a round (Go: concurrently).
- The in-memory store's errors are errors (Go's test store panics), and
  its lists hold only the asked hub and group.

- `checkpoints.new_blob_store` takes an azblob `Client` and a container
  name (Go: a `container.Client`; this azblob has one client per
  account).

Not yet: web sockets and custom endpoints.

Tests run against std/amqptest's in-process broker in its event hub
mode on the test world's network (`xo test .`).
