#  LccTools

[<img src="http://bobjacobsen.github.io/ardenwood/lcctools/IconInRectangle.png" height="128" width="128" align="right" />](http://bobjacobsen.github.io/ardenwood/lcctools/index.shtml) A basic application, based on TelnetListenerLib and OpenlcbLibrary, for controlling LCC nodes on a model railroad.

Provides:
 - A throttle
 - A fast clock
 - A turnout control tool
 - A node configuration tool
 - A consisting tool
 - An LCC traffic monitor

Released under the GPL2 license. We're serious about its terms.

Full documentation is [available on the web](https://bobjacobsen.github.io/LccTools/documentation/lcctools/) and is built in XCode once you've installed this package.

To build from the command line (requires [TelnetListenerLib](https://github.com/bobjacobsen/TelnetListenerLib) and [OpenlcbLibrary](https://github.com/bobjacobsen/OpenlcbLibrary) checked out):

    xcodebuild -scheme OlcbTools\ \(macOS\)

or

    xcodebuild -scheme OlcbTools\ \(iOS\)

Note that the Swift XCode project is named `OlcbTools` instead of `LccTools` for historical reasons.
