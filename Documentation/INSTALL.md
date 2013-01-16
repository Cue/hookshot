# hookshot installation


## Get the code

If you're using git 1.8, you can use `git subtree` for easy inclusion of the hookshot codebase:

~~~~~~~~~~~~.bash
git subtree add --prefix=path/within/repo/for/hookshot --squash \
    git@github.com:Cue/hookshot.git master
~~~~~~~~~~~~

Later, you can upgrade to the latest revision of hookshot with:

~~~~~~~~~~~~.bash
git subtree pull --prefix=path/within/repo/for/hookshot --squash \
    git@github.com:Cue/hookshot.git master
~~~~~~~~~~~~

If you make changes and want to submit a pull request, fork hookshot, and then:

~~~~~~~~~~~~.bash
git subtree pull --prefix=path/within/repo/for/hookshot --squash \
    git@github.com:YourGitUsername/hookshot.git master
~~~~~~~~~~~~

and then submit your pull request from your forked repo.

Alternately, just download all the files in `Classes`, `bin`, and `hookshot.xcodeproj` and save them in a convenient place.

=======

## Install Python dependencies

In your Terminal:

~~~~~~~~~~~~~~~~~~~.bash
pip install argparse
pip install flask
~~~~~~~~~~~~~~~~~~~


## Add to your project

Open Finder, navigate to `hookshot.xcodeproj`, and drag it in to your project:

![Drag hookshot in to your project](https://raw.github.com/Cue/hookshot/master/Documentation/Images/DragSubproject.png)

should result in something like this:

![After adding hookshot](https://raw.github.com/Cue/hookshot/master/Documentation/Images/AfterDragSubproject.png)

Select the subproject, then choose `Build Settings`.  Search for `c++`

* Ensure `C++ Language Dialect` is `GNU++11` or `C++11`

* Ensure `C++ Standard Library` is `libc++`

![C++ settings](https://raw.github.com/Cue/hookshot/master/Documentation/Images/CPlusPlusSettings.png)

Search for `header`

* Add relative or full path to `hookshot/Classes` to `Header Search Paths`

![Header search paths](https://raw.github.com/Cue/hookshot/master/Documentation/Images/HeaderSearchPaths.png)

Search for `preprocessor`

* Add `HOOKSHOT_ENABLED=1` to `Preprocessor Macros` for your `Debug` target(s)

Select your root project.  For each the target you want to use hookshot with

* Select `Build Phases`

* Open the `Link Binary With Libraries` panel

![Before linking libraries](https://raw.github.com/Cue/hookshot/master/Documentation/Images/BeforeLinkLibraries.png)

* Add `libhookshot.a`

* Add `libc++.dylib`

![Link libraries](https://raw.github.com/Cue/hookshot/master/Documentation/Images/LinkLibraries.png)

You're now ready to start using hookshot!


## Instrument your code

We recommend adding instrumentation in your AppDelegate class's `initialize` method:

~~~~~~~~~~~~~~~~~~~~~~~~~.objc
+ (void)initialize;
{
    if (self != [AppDelegate class]) {
        return;
    }
    if ([[[[NSProcessInfo processInfo] environment] objectForKey:@"HookshotProfile"] isEqualToString:@"YES"]) {
        PROFILE_CLASS(self);
        PROFILE_CLASS([UIWebView class]);
    }
}
~~~~~~~~~~~~~~~~~~~~~~~~~

We use the environment variable strategy shown above to almost completely eliminate the cost of hookshot when you aren't using it.  hookshot is an instrumenting profiler, so when it's on your application will run slower (probably noticeably slower).

The good news: most of hookshot is installed at runtime (see above), so you can enable or disable it with an environment variable.

We recommend creating a special scheme for running with profiling turned on.  We use a scheme instead of a target because it's much faster to switch between the two (no re-indexing in XCode!).

* Click `Product` > `Manage Schemes`

* Duplicate your main scheme

* Rename it to something like "(your scheme name) with hookshot"

* Add an environment variable named `HookshotEnable` and set it to `YES`

![Manage Schemes](https://raw.github.com/Cue/hookshot/master/Documentation/Images/ManageSchemes.png)

![Hookshot scheme](https://raw.github.com/Cue/hookshot/master/Documentation/Images/HookshotScheme.png)

More information on how to use hookshot in your code is available in the [README](/Cue/hookshot/blob/master/README.md).
