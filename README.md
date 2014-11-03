A Redis-backed statistics storage and querying library written in Ruby.

Redisrank was created taking as reference a Gem called Redistat by Jimeh.
The motivations for the gem creation were similar to the Redistat too, I had a
collection solution which was MySQL-based with the following requirements.

* Fetch the top most ... 
* This ranks should be fetched in any time-range
* Screamingly fast

## Installation

    gem install redisrank

If you are using Ruby 1.8.x, it's recommended you also install the
`SystemTimer` gem, as the Redis gem will otherwise complain.

## Usage (Crash Course)

view\_stats.rb:

```ruby
require 'redisrank'

class ViewRank
  include Redisrank::Model
end

# if using Redisrank in multiple threads set this
# somewhere in the beginning of the execution stack
Redisrank.thread_safe = true
```


### Simple Example

Store:

```ruby
ViewRank.store('hello', {:world => 4})
ViewRank.store('hello', {:world => 2}, 2.hours.ago)
```

Fetch:

```ruby
ViewRank.find('hello', 1.hour.ago, 1.hour.from_now).all
  #=> [{'world' => 4}]
ViewRank.find('hello', 3.hour.ago, 1.hour.from_now).rank
  #=> {'world' => 4}
ViewRank.find('hello', 3.hour.ago, 1.hour.ago).rank
  #=> {'world' => 2}
```

### Other usefull Use Cases



## Terminology

### Scope

A type of global-namespace for storing data. When using the `Redisrank::Model`
wrapper, the scope is automatically set to the class name. In the examples
above, the scope is `ViewRank`. Can be overridden by calling the `#scope`
class method on your model class.

### Label

Identifier string to separate different types and groups of statistics from
each other. The first argument of the `#store`, `#find`, and `#fetch` methods
is the label that you're storing to, or fetching from.

Labels support multiple grouping levels by splitting the label string with `/`
and storing the same stats for each level. For example, when storing data to a
label called `views/product/44`, the data is stored for the label you specify,
and also for `views/product` and `views`. You may also configure a different
group separator using the `Redisrank.group_separator=` method. For example:

```ruby
Redisrank.group_separator = '|'
```

A word of caution: Don't use a crazy number of group levels. As two levels
causes twice as many `hincrby` calls to Redis as not using the grouping
feature. Hence using 10 grouping levels, causes 10 times as many write calls
to Redis.

### Input Statistics Data

You provide Redisrank with the data you want to store using a Ruby Hash. This
data is then stored in a corresponding Redis hash with identical key/field
names.

Key names in the hash also support grouping features similar to those
available for Labels. Again, the more levels you use, the more write calls to
Redis, so avoid using 10-15 levels.

### Depth (Storage Accuracy)

Define how accurately data should be stored, and how accurately it's looked up
when fetching it again. By default Redisrank uses a depth value of `:hour`,
which means it's impossible to separate two events which were stored at 10:18
and 10:23. In Redis they are both stored within a date key of `2011031610`.

You can set depth within your model using the `#depth` class method. Available
depths are: `:year`, `:month`, `:day`, `:hour`, `:min`, `:sec`

### Time Ranges

When you fetch data, you need to specify a start and an end time. The
selection behavior can seem a bit weird at first when, but makes sense when
you understand how Redisrank works internally.

For example, if we are using a Depth value of `:hour`, and we trigger a fetch
call starting at `1.hour.ago` (13:34), till `Time.now` (14:34), only stats
from 13:00:00 till 13:59:59 are returned, as they were all stored within the
key for the 13th hour. If both 13:00 and 14:00 was returned, you would get
results from two whole hours. Hence if you want up to the second data, use an
end time of `1.hour.from_now`.

### The Finder Object

Calling the `#find` method on a Redisrank model class returns a
`Redisrank::Finder` object. The finder is a lazy-loaded gateway to your
data. Meaning you can create a new finder, and modify instantiated finder's
label, scope, dates, and more. It does not call Redis and fetch the data until
you call `#total`, `#all`, `#map`, `#each`, or `#each_with_index` on the
finder.

This section does need further expanding as there's a lot to cover when it
comes to the finder.


## Key Expiry

Support for expiring keys from Redis is available, allowing you too keep
varying levels of details for X period of time. This allows you easily keep
things nice and tidy by only storing varying levels detailed stats only for as
long as you need.

In the below example we define how long Redis keys for varying depths are
stored. Second by second stats are available for 10 minutes, minute by minute
stats for 6 hours, hourly stats for 3 months, daily stats for 2 years, and
yearly stats are retained forever.

```ruby
class ViewRank
  include Redisrank::Model

  depth :sec

  expire \
    :sec => 10.minutes.to_i,
    :min => 6.hours.to_i,
    :hour => 3.months.to_i,
    :day => 2.years.to_i
end
```

Keep in mind that when storing stats for a custom date in the past for
example, the expiry time for the keys will be relative to now. The values you
specify are simply passed to the `Redis#expire` method.


## Internals

### Storing / Writing

Redisrank stores all data into a Redis hash keys. The Redis key name the used
consists of three parts. The scope, label, and datetime:

    {scope}/{label}:{datetime}

For example, this...

```ruby
ViewRank.store('views/product/44', {'count/chrome/11' => 1})
```

...would store the follow hash of data...

```ruby
{ 'count' => 1, 'count/chrome' => 1, 'count/chrome/11' => 1 }
```

...to all 12 of these Redis hash keys...

    ViewRank/views:2011
    ViewRank/views:201103
    ViewRank/views:20110315
    ViewRank/views:2011031510
    ViewRank/views/product:2011
    ViewRank/views/product:201103
    ViewRank/views/product:20110315
    ViewRank/views/product:2011031510
    ViewRank/views/product/44:2011
    ViewRank/views/product/44:201103
    ViewRank/views/product/44:20110315
    ViewRank/views/product/44:2011031510

...by creating the Redis key, and/or hash field if needed, otherwise it simply
increments the already existing data.

It would also create the following Redis sets to keep track of which child
labels are available:

    ViewRank.label_index:
    ViewRank.label_index:views
    ViewRank.label_index:views/product

It should now be more obvious to you why you should think about how you use
the grouping capabilities so you don't go crazy and use 10-15 levels. Storing
is done through Redis' `hincrby` call, which only supports a single key/field
combo. Meaning the above example would call `hincrby` a total of 36 times to
store the data, and `sadd` a total of 3 times to ensure the label index is
accurate. 39 calls is however not a problem for Redis, most calls happen in
less than 0.15ms (0.00015 seconds) on my local machine.


### Fetching / Reading

By default when fetching statistics, Redisrank will figure out how to do the
least number of reads from Redis. First it checks how long range you're
fetching. If whole days, months or years for example fit within the start and
end dates specified, it will fetch the one key for the day/month/year in
question. It further drills down to the smaller units.

It is also intelligent enough to not fetch each day from 3-31 of a month,
instead it would fetch the data for the whole month and the first two days,
which are then removed from the summary of the whole month. This means three
calls to `hgetall` instead of 29 if each whole day was fetched.

### Buffer

The buffer is a new, still semi-beta, feature aimed to reduce the number of
Redis `hincrby` that Redisrank sends. This should only really be useful when
you're hitting north of 30,000 Redis requests per second, if your Redis server
has limited resources, or against my recommendation you've opted to use 10,
20, or more label grouping levels.

Buffering tries to fold together multiple `store` calls into as few as
possible by merging the statistics hashes from all calls and groups them based
on scope, label, date depth, and more. You configure the the buffer by setting
`Redisrank.buffer_size` to an integer higher than 1. This basically tells
Redisrank how many `store` calls to buffer in memory before writing all data to
Redis.


## Todo

* More details in Readme.
* Documentation.
* Anything else that becomes apparent after real-world use.


## Credits

[Encore Alert](http://encorealert.com/) that allowed me to spend some
company time to further develop the project. @jimeh for creating the Redistat 
that was not a inspiration but the base version of Redisrank.


## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.  (if you want to
  have your own version, that is fine but bump version in a commit by itself I
  can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.


## License and Copyright

Copyright (c) 2011 Jim Myhrberg.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
