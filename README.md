# hookshot

## Hooks for debugging and profiling Objective C code.

hookshot uses Objective C runtime hooks to help you understand where your app is spending its time.

(screenshot of thread dump + profile results)

**hookshot uses undocumented Apple APIs.**  This is necessary for profiling and debugging, but will get your application rejected during App Store review if hookshot makes it in to production code.  Follow the installation instructions to ensure hookshot is properly configured.

## Installation

Step-by-step installation instructions.

## Profiling

hookshot provides a whitelist based instrumenting profiler.  You can use it to time critical parts of your code and identify bottlenecks.

### profile.py flags

TODO

### The snapshot server

(screenshot of snapshot server)

TODO

## Instance counting

You can use hookshot to track how many instances of a given class are live.

TODO

## Limitations

* Can not instrument messages with templated C++ response types.  hookshot will automatically detect these messages and not instrument them, and warn you about them in logs.

* Can not instrument messages with varargs.  hookshot cannot detect these messages, so it will crash your app if you try to instrument varargs messages.  You can use `PROFILE_CLASS_EXCEPT` or `PREVENT_INSTRUMENTATION` to work around this.

## Contributing

We know there is a lot more that can be done to build great tools so we can all write more performant applications.

We're always happy to receive pull requests!

## License

Copyright 2012 The scales Authors.

Published under The Apache License, see LICENSE
