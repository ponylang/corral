"""
# Logger package

Provides basic logging facilities. For most use cases, the `StringLogger` class
will be used. On construction, it takes 2 parameters and a 3rd optional
parameter:

* LogLevel below which no output will be logged
* OutStream to log to
* Optional LogFormatter

If you need to log arbitrary objects, take a look at `ObjectLogger[A]` which
can log arbitrary objects so long as you provide it a lambda to covert from A
to String.

## API Philosophy

The API for using Logger is an attempt to abide by the Pony philosophy of first,
be correct and secondly, aim for performance. One of the ways that logging can
slow your system down is by having to evaluate expressions to be logged
whether they will be logged or not (based on the level of logging). For example:

`logger.log(Warn, name + ": " + reason)`

will construct a new String regardless of whether we will end up logging the
message or not.

The Logger API uses boolean short circuiting to avoid this.

`logger(Warn) and logger.log(name + ": " + reason)`

will not evaluate the expression to be logged unless the log level Warn is at
or above the overall log level for our logging. This is as close as we can get
to zero cost for items that aren't going to end up being logged.

## Example programs

### String Logger

The following program will output 'my warn message' and 'my error message' to
STDOUT in the standard default log format.

```pony
use "../logger"

actor Main
  new create(env: Env) =>
    let logger = StringLogger(
      Warn,
      env.out)

    logger(Fine) and logger.log("my fine message")
    logger(Info) and logger.log("my info message")
    logger(Warn) and logger.log("my warn message")
    logger(Error) and logger.log("my error message")
```

### Logger[A]

The following program will output '42' to STDOUT in the standard default log
format.

```pony
use "../logger"

actor Main
  new create(env: Env) =>
    let logger = Logger[U64](Fine, env.out, {(a) => a.string() })

    logger(Error) and logger.log(U64(42))
```

## Custom formatting your logs

The Logger package provides an interface for formatting logs. If you wish to
override the standard formatting, you can create an object that implements:

```pony
interface val LogFormatter
  fun apply(
    msg: String,
    file_name: String,
    file_linenum: String,
    file_linepos: String): String
```

This can either be a class or because the interface only has a single apply
method, can also be a lambda.
"""

class val Logger[A]
  """
  A configurable logger that converts values of type A
  to strings and writes them to an output stream when
  the log level is at or above the configured threshold.
  """
  let _level: LogLevel
  let _out: OutStream
  let _f: {(A): String} val
  let _formatter: LogFormatter

  new val create(
    level: LogLevel,
    out: OutStream,
    f: {(A): String} val,
    formatter: LogFormatter = DefaultLogFormatter)
  =>
    _level = level
    _out = out
    _f = f
    _formatter = formatter

  fun apply(level: LogLevel): Bool =>
    level() >= _level()

  fun log(value: A, loc: SourceLoc = __loc): Bool =>
    _out.print(_formatter(_f(consume value), loc))
    true

primitive StringLogger
  """
  Creates a `Logger[String]` from the given log level,
  output stream, and optional formatter.
  """
  fun apply(
    level: LogLevel,
    out: OutStream,
    formatter: LogFormatter = DefaultLogFormatter)
    : Logger[String]
  =>
    Logger[String](
      level,
      out,
      {(s: String): String => s },
      formatter)
