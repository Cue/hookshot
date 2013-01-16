# hookshot

## Hooks for debugging and profiling Objective C code.

hookshot uses Objective C runtime hooks to help you understand where your app is spending its time.

(screenshot of thread dump + profile results)

**hookshot uses undocumented Apple APIs.**  This is necessary for profiling and debugging, but will get your application rejected during App Store review if hookshot makes it in to production code.  Follow the installation instructions to ensure hookshot is properly configured.

## Installation

[Step-by-step installation instructions](/Cue/hookshot/blob/master/Documentation/INSTALL.md)

## Profiling

hookshot provides a whitelist based instrumenting profiler.  You can use it to time critical parts of your code and identify bottlenecks.

Once you've [installed](/Cue/hookshot/blob/master/Documentation/INSTALL.md) hookshot in your project and run it, you can start exploring your data.

### Basic hooks

Early in your application's run, you can instrument any classes you want to measure performance of:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.objc
PROFILE_CLASS([AppDelegate class]);
PROFILE_CLASS([UIWebView class]);
PROFILE_CLASS_EXCEPT([AnotherClass class],
    [NSValue valueWithPointer:@selector(someFrequentlyCalledSelector)],
    [NSValue valueWithPointer:@selector(anotherFrequentlyCalledSelector)])
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You can omit messages you know are called frequently where you suspect profiling overhead will distort your results.

### profile.py

[/bin/profile.py](/Cue/hookshot/blob/master/bin/profile.py) will analyze your latest profile data dump and summarize it:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ bin/profile.py
Using /Users/robbywalker/Library/Application Support/iPhone Simulator/6.0/Applications/C1FB13C1-C230-4435-8A10-F7BED5A6B475/Documents/profile-23274
message                                                                              calls     ownTime       avgOwn      maxOwn         total
AppDelegate.doSomethingExpensive                                                     27        562.433ms     20.8309ms   21.1630ms      562.433ms
UIWebView.webView:decidePolicyForNavigationAction:request:frame:decisionListener:    2         19.480ms      9.7400ms    19.4440ms      20.110ms
UIWebView._webViewCommonInitWithWebView:scalesPageToFit:shouldEnableReachability:    1         11.725ms      11.7250ms   11.7250ms      12.780ms
AppDelegate.application:didFinishLaunchingWithOptions:                               1         7.913ms       7.9130ms    7.9130ms       25.179ms
UIWebView.webView:didFinishLoadForFrame:                                             1         3.458ms       3.4580ms    3.4580ms       3.473ms
UIWebView._updateViewSettings                                                        3         2.327ms       0.7757ms    1.7870ms       2.430ms
AppDelegate.applicationDidBecomeActive:                                              2         1.825ms       0.9125ms    1.8250ms       522.812ms
UIWebView._updateRequest                                                             3         0.548ms       0.1827ms    0.5250ms       0.548ms
UIWebView.initWithCoder:                                                             1         0.448ms       0.4480ms    0.4480ms       14.090ms
UIWebView.webView:decidePolicyForMIMEType:request:frame:decisionListener:            1         0.335ms       0.3350ms    0.3350ms       0.335ms
UIWebView._edgeExpressionInContainer:vertical:max:                                   4         0.289ms       0.0722ms    0.0990ms       0.397ms
...
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

We can see here that our example expensive method is, in fact, expensive.

A summary of your command line options is always available with `bin/profile.py -h` but we'll cover the most interesting ones here.

#### Change which profile file to read

The summary is pulled from the latest profile file to be written by your Simulator.  You can also run on a device and extract the Applications' data directory to your Desktop.  The rest works automatically.

You can override the default smart-find functionality if you want:

~~~~~~~~~~~
bin/profile.py <pid>
~~~~~~~~~~~

will find a dump file (in the Simulator directory or recursively from your Desktop) called `profile-<pid>` and use that.

### View thread activity visually

~~~~~~~~~~~
bin/profile.py --server
~~~~~~~~~~~

Once the server is running, open [localhost:8020](http://localhost:8020) to view a graphical representation of thread activity.

![The snapshot server](https://raw.github.com/Cue/hookshot/master/Documentation/Images/SnapshotServer.png)

Hovering over a bar will show what call it represents.  Clicking on any given call will replace that call by the timings of any
other instrumented methods it called.

We have found this _extremely_ useful for finding subtle performance bugs caused by thread interactions.  For example, it
will become obvious if and when the main thread is blocking on other threads and why.

#### Change the sort order

You can sort profiled messages by `--ownTime` (the default), `--calls` count, `--average` time per call,
`--total` time per call, or `--max` time for a single call.

For example:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ bin/profile.py --total
Using /Users/robbywalker/Library/Application Support/iPhone Simulator/6.0/Applications/C1FB13C1-C230-4435-8A10-F7BED5A6B475/Documents/profile-23274
message                                                                              calls     ownTime       avgOwn      maxOwn         total
AppDelegate.doSomethingExpensive                                                     27        562.433ms     20.8309ms   21.1630ms      562.433ms
AppDelegate.applicationDidBecomeActive:                                              2         1.825ms       0.9125ms    1.8250ms       522.812ms
AppDelegate.application:didFinishLaunchingWithOptions:                               1         7.913ms       7.9130ms    7.9130ms       25.179ms
UIWebView.webView:decidePolicyForNavigationAction:request:frame:decisionListener:    2         19.480ms      9.7400ms    19.4440ms      20.110ms
UIWebView.initWithCoder:                                                             1         0.448ms       0.4480ms    0.4480ms       14.090ms
...
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#### Filter what messages are shown

You can filter by thread:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ bin/profile.py --thread WebThread
Using /Users/robbywalker/Library/Application Support/iPhone Simulator/6.0/Applications/C1FB13C1-C230-4435-8A10-F7BED5A6B475/Documents/profile-23274
message                                                                            calls     ownTime       avgOwn      maxOwn         total
UIWebView.webView:resource:canAuthenticateAgainstProtectionSpace:forDataSource:    3         0.055ms       0.0183ms    0.0280ms       0.055ms
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

by message regex:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ bin/profile.py --message '.*did'
Using /Users/robbywalker/Library/Application Support/iPhone Simulator/6.0/Applications/C1FB13C1-C230-4435-8A10-F7BED5A6B475/Documents/profile-23274
message                                                                  calls     ownTime       avgOwn      maxOwn         total
AppDelegate.application:didFinishLaunchingWithOptions:                   1         7.913ms       7.9130ms    7.9130ms       25.179ms
UIWebView.webView:didFinishLoadForFrame:                                 1         3.458ms       3.4580ms    3.4580ms       3.473ms
UIWebView._didMoveFromWindow:toWindow:                                   1         0.212ms       0.2120ms    0.2120ms       0.261ms
UIWebView.nsis_valueOfVariable:didChangeInEngine:                        4         0.130ms       0.0325ms    0.0400ms       0.232ms
UIWebView.webView:resource:didFinishLoadingFromDataSource:               12        0.100ms       0.0083ms    0.0140ms       0.100ms
UIWebView.webView:didStartProvisionalLoadForFrame:                       1         0.062ms       0.0620ms    0.0620ms       0.587ms
UIWebView.view:didSetFrame:oldFrame:                                     2         0.056ms       0.0280ms    0.0370ms       2.029ms
UIWebView.webView:didFirstLayoutInFrame:                                 2         0.023ms       0.0115ms    0.0130ms       0.023ms
UIWebView.webView:didReceiveServerRedirectForProvisionalLoadForFrame:    1         0.018ms       0.0180ms    0.0180ms       0.026ms
UIWebView.webView:didClearWindowObject:forFrame:                         1         0.016ms       0.0160ms    0.0160ms       0.016ms
UIWebView.webView:didReceiveTitle:forFrame:                              1         0.015ms       0.0150ms    0.0150ms       0.015ms
UIWebView.webView:didCommitLoadForFrame:                                 1         0.010ms       0.0100ms    0.0100ms       0.010ms
UIWebView.didMoveToSuperview                                             1         0.004ms       0.0040ms    0.0040ms       0.004ms
UIWebView.didAddSubview:                                                 1         0.004ms       0.0040ms    0.0040ms       0.004ms
UIWebView.didMoveToWindow                                                1         0.003ms       0.0030ms    0.0030ms       0.003ms
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

or by class:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ bin/profile.py --class 'AppDelegate'
Using /Users/robbywalker/Library/Application Support/iPhone Simulator/6.0/Applications/C1FB13C1-C230-4435-8A10-F7BED5A6B475/Documents/profile-23274
message                                                   calls     ownTime       avgOwn      maxOwn         total
AppDelegate.doSomethingExpensive                          27        562.433ms     20.8309ms   21.1630ms      562.433ms
AppDelegate.application:didFinishLaunchingWithOptions:    1         7.913ms       7.9130ms    7.9130ms       25.179ms
AppDelegate.applicationDidBecomeActive:                   2         1.825ms       0.9125ms    1.8250ms       522.812ms
AppDelegate.isKindOfClass:                                4         0.020ms       0.0050ms    0.0060ms       0.020ms
AppDelegate.allocWithZone:                                1         0.018ms       0.0180ms    0.0180ms       0.018ms
AppDelegate.setWindow:                                    1         0.010ms       0.0100ms    0.0100ms       0.010ms
AppDelegate.init                                          1         0.009ms       0.0090ms    0.0090ms       0.009ms
AppDelegate.window                                        2         0.006ms       0.0030ms    0.0030ms       0.006ms
AppDelegate.setViewController:                            1         0.005ms       0.0050ms    0.0050ms       0.005ms
AppDelegate.viewController                                1         0.004ms       0.0040ms    0.0040ms       0.004ms
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Instance counting

You can use hookshot to track how many instances of a given class are live.

~~~~~~~~~~~~
COUNT_INSTANCES(cls);
~~~~~~~~~~~~

It's best to install this hook in your AppDelegate `initialize` or in the `initialize` of the class you want to count instances of.

This will result in log messages like:

~~~~~~~~~~~~
HookshotDemo[25220:11303] UIImage: 8 (after dealloc)
~~~~~~~~~~~~

### C++

You can also instance count for C++ classes, but only if they have no super class.   You also can't configure this part at runtime - it'll be on when hookshot is built in (Debug builds) and off otherwise.

When you define your class, instead of

~~~~~~~~~~~~
class ClassName {
  ...
}
~~~~~~~~~~~~

write

~~~~~~~~~~~~
COUNTED_CPP_CLASS(X) {
  ...
}
~~~~~~~~~~~~

In your implementation file, at the top, add:

~~~~~~~~~~~~
COUNTED_CPP_CLASS_IMPLEMENTATION_PREAMBLE(ClassName)
~~~~~~~~~~~~

## Generic Instrumentation

The above features are built on top of a generic capability for instance message instrumentation defined
in [Classes/CCInstanceMessageInstrumentation.h](/Cue/hookshot/blob/master/Classes/CCInstanceMessageInstrumentation.h)

We'd love to hear what (non-production!) uses you find for it.

## Known Limitations

* hookshot can not instrument messages with templated C++ response types.  hookshot will automatically detect these messages and not instrument them, and warn you about them in logs.

* hookshot crashes when instrumenting messages with varargs.  hookshot cannot detect these messages and ignore them, so you will have to use `PROFILE_CLASS_EXCEPT` or `PREVENT_INSTRUMENTATION` to work around this.

## Contributing

We know there is a lot more that can be done to build great tools so we can all write more performant applications.

We're always happy to receive pull requests!

## License

Copyright 2012 The hookshot Authors.

Published under The Apache License, see LICENSE
