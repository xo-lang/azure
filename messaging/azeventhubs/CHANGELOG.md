# azeventhubs changes

Newest first. The module's Xo version is v0.1.0; each entry names the Go
release it follows.

## Unreleased

Follows Go's `sdk/messaging/azeventhubs/v2` v2.0.2 (was v1.4.0). Each
change is checked against the lines Go v2.0.2's own functions print for
the same inputs (`ehv2vectors_test.xo`).

**Breaking**, as Go v2's only break: offsets are strings.
`ReceivedEventData.offset`, `Checkpoint.offset`, `StartPosition.offset`
and `PartitionProperties.last_enqueued_offset` are `Str` (a
geo-replicated hub's offsets are not numbers). Stored checkpoints are
read and written as before; a checkpoint's `offset` metadata is no
longer parsed.

Added:

- `EventHubProperties.geo_replication_enabled`, from the hub's
  `georeplication_factor` (above 1). A READ reply without the factor,
  or with an unsigned or string one, is the error `invalid value for
  georeplication_factor`, and each other field's error names it
  (`invalid value for partition_ids`, `name`, `created_at`), as Go v2's.
- `ERROR_COND_GEO_REPLICATION_OFFSET` and
  `is_geo_replication_offset_error`: the condition is fatal, and the
  Processor opens that partition again from the earliest event,
  inclusive.
- `CAPABILITY_GEO_DR_REPLICATION`: every producer, partition and
  `$management` link asks for `com.microsoft:georeplication` in its
  Attach (the CBS link does not), as Go v2's.

Fixed: the management replies' integers are read as Go's
ConvertToInt64 reads them, signed only; an unsigned sequence number is
`invalid message format`.

Already in the v1.4.0 port: v2.0.2's one quick retry after a link
detach.

Building needs xo 2d8ae0c82 or later; the tests need xo fad59ead6 or
later.
