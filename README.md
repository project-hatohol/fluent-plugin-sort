# README

## Name

fluent-plugin-sort

## Description

Fluent-plugin-sort is a [Fluentd](http://www.fluentd.org/) plugin to
sort messages in buffer. Fluentd doesn't guarantee message order but
you may keep message order.

If you use large buffer, you will keep order of many messages but
messages are delayed. If you use small buffer, you will keep order of
some messages but messages are delayed a bit.

## Install

    % gem install fluent-plugin-sort

## Usage

Fluentd doesn't guarantee message order. It means that messages may be
out of order. Fluent-plugin-sort plugin reduces the case.

Fluent-plugin-sort keeps received messages before routing the next
output plugin. Fluent-plugin-sort sorts buffered messages when buffer
is flushed. It will reduce out of order messages but it's not
perfect. Some messages may be out of order.

Here are sample configuration:

    <match message.**>
      type sort
      add_tag_prefix sorted.
      flush_interval 60
    </match>

You can reduce out of order messages by increasing `flush_interval`
parameter in `type sort` configuration. If its value is large, many
messages will be sorted at once. It reduces out of order messages. But
large flush interval delays message routing. Tune the parameter
carefully.

You can use fluent-plugin-sort for log archive system. See
[Log archive at project-hatohol/hatohol Wiki](https://github.com/project-hatohol/hatohol/wiki/Log-archive). It
describes architectures, how to set up and how to configure.

## Reference

Fluent-plugin-sort is a buffered output plugin. You can use buffer
related parameters.

### Included mix-ins

* `Fluent::HandleTagNameMixin`: It adds the following parameters:
  * `add_tag_prefix`
  * `add_tag_suffix`
  * `remove_tag_prefix`
  * `remove_tag_suffix`

### Parameters

#### `sort_key`:

Default: `time`

It specifies key for sort. You can sort messages by time-stamp in a
fluent message or a record value.

If you want to use time-stamp in a fluent message, specify
`time`. `time` is the default value.

Example:

    <match>
      type sort
      sort_key time
    </match>

If you want to use a record value, specify record key with
`attribute:` prefix.

Here is an example to use `id` value:

    <match>
      type sort
      sort_key attribute:id
    </match>

Buffered records:

    [
      {"id": 2},
      {"id": 4},
      {"id": 1},
      {"id": 3}
    ]

Sorted result:

    [
      {"id": 1},
      {"id": 2},
      {"id": 3},
      {"id": 4}
    ]

You can use deep record value by separating by `.`. Using `.` as
delimiter is inspired by [JSONPath](http://goessner.net/articles/JsonPath/).

Here is an example to use `body.time-stamp` value:

    <match>
      type sort
      sort_key attribute:body.time-stamp
    </match>


Buffered records:

    [
      {"body": {"time-stamp": 1413272109}},
      {"body": {"time-stamp": 1413272107}},
      {"body": {"time-stamp": 1413272108}},
      {"body": {"time-stamp": 1413272106}}
    ]

Sorted result:

    [
      {"body": {"time-stamp": 1413272106}},
      {"body": {"time-stamp": 1413272107}},
      {"body": {"time-stamp": 1413272108}},
      {"body": {"time-stamp": 1413272109}}
    ]

If attribute value is `null` or attribute doesn't exist, the message
is treated as the most oldest message.

Buffered records:

    [
      {"body": {"time-stamp":    1413272109}},
      {"body": {"time-stamp":    1413272107}},
      {"body": {"time-stamp":    1413272108}},
      {"body": {"no-time-stamp": true}}
    ]

Sorted result:

    [
      {"body": {"no-time-stamp": true}},
      {"body": {"time-stamp":    1413272107}},
      {"body": {"time-stamp":    1413272108}},
      {"body": {"time-stamp":    1413272109}}
    ]

## Authors

* Project Hatohol

## License

LGPL 2.1 or later. See doc/text/lgpl-2.1.txt for details.

## Place to share information of fluent-plugin-sort

Use
[GitHub issues](https://github.com/project-hatohol/fluent-plugin-sort/issues)
to submit a question and bug report. You can use English or Japanese
on it.

## Source

The repository for fluent-plugin-sort is on
[GitHub](https://github.com/project-hatohol/fluent-plugin-sort/).

## Thanks

* ...
