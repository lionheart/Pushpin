# Change Log
All notable changes to the Heap library will be documented in this file.

The format is based on [Keep a Changelog][cl] and this project adheres to
[Semantic Versioning][sv].

[cl]: http://keepachangelog.com/
[sv]: http://semver.org/

## [7.2.0] - 2020-08-27

### Added
- Support for iOS 14 (beta 5).
- Capture app background/foreground visiblity status for every autocaptured event.

## [7.1.1] - 2020-07-13

### Fixed
- Fixed an issue where certain UTF-16 strings are truncated incorrectly, possibly causing a crash.

## [7.1.0] - 2020-07-01

### Added
- Allow the disabling of tracking events using `setTrackingEnabled:` or the `disableTracking` property on `HeapOptions`.

## [7.0.2] - 2020-07-13

### Fixed
- Fixed an issue where certain UTF-16 strings are truncated incorrectly, possibly causing a crash.

## [7.0.1] - 2020-06-30

### Fixed
- Fixed an issue where calls to `[Heap track]` from a background thread could be dropped.

## [7.0.0] - 2020-06-17

### Breaking changes
- Dropped support for iOS versions below 10.0.

### Added
- Allow disabling autocapture when an app has been backgrounded through a `disableAutocaptureWhenBackgrounded` property on `HeapOptions`.
- Expose `heapIgnore` as a property, as opposed to only through User Defined Runtime Attributes in the Interface Builder.

### Changed
- Use an improved format for sending events to Heap.

## [6.8.1] - 2020-06-04

### Fixed
- Fixed an issue where the event visualizer pairing popup would not be displayed for apps using `UISceneDelegate`.
- Fixed an issue where the event visualizer pairing popup would appear, then immediately disappear.
- Fixed an issue where install/upgrade events would not fire for certain installations.

## [6.8.0] - 2020-05-18

### Added
- Send telemetry data to Heap when the library detects an internal error.

### Fixed
- Fixed an issue where the event visualizer would break pairing when the device goes to sleep.
- Fixed an issue where a call to `[Heap resetIdentity]` would be ignored if it was immediately preceded by a call to  `[Heap identify]`.
- Fixed an issue where the event visualizer would receive no data from apps whose application delegate didn't contain a `window` property.

## [6.7.1] - 2020-05-18

### Fixed

- Fixed an issue where the event visualizer would receive no data from apps whose application delegate didn't contain a `window` property.

## [6.7.0] - 2020-04-03

### Added

- Added the ability to capture the IDFA (identifier for advertisers) and IDFV (identifier for vendors).

### Fixed

- Fixed an issue where the `[Heap userId]` API would return `nil` for non-anonymous users.
- Fixed an issue where view ancestry data would be dropped for retried requests.

## [6.6.3] - 2020-05-18

### Fixed

- Fixed an issue where the event visualizer would receive no data from apps whose application delegate didn't contain a `window` property.

## [6.6.2] - 2020-04-03

### Fixed

- Fixed an issue where the `[Heap userId]` API would return `nil` for non-anonymous users.
- Fixed an issue where view ancestry data would be dropped for retried requests.

## [6.6.1] - 2020-03-11

### Fixed

- Fixed a thread-safety issue related to sessionization logic - previously, calls
  to `[Heap identify]` and `[Heap track]` could potentially result in a crash if
  called from a background thread.

## [6.6.0] - 2020-01-23

### Added

- Added new `initialize` function for more explicit initialization of the Heap library.
- Added `disableTextCapture` initialization option to disable capturing the text of click events for PII purposes.
- Added `debug` initialization option to start debug logging of Heap activity via NSLog.
- Added support for reporting view hierarchies.

### Fixed

- Fixed an issue (particularly manifesting in iOS 13) where the View Controller on an event could incorrectly be attributed to a dismissed modal view.
- Improved Event Visualizer pairing alert and screenshot capture.

### Deprecated

- `setAppId` has been deprecated, please use `initialize` instead.

## [6.5.4] - 2020-03-11

### Fixed

- Fixed a thread-safety issue related to sessionization logic - previously, calls
  to `[Heap identify]` and `[Heap track]` could potentially result in a crash if
  called from a background thread.

## [6.5.3] - 2019-12-11

### Fixed

- Many non-alphanumeric characters are properly escaped for transmission.

## [6.5.2] - 2019-12-10

### Fixed

- Fixed an issue where some debug noise was not suppressed in console log output.

## [6.5.1] - 2019-12-05

### Fixed

- Fixed an issue where first-time app install events were not being properly recorded.

## [6.5.0] - 2019-12-03

### Added

- Added new methods for tracking events from frameworks.
- Capture view ancestry information for all touch & fieldedit events.
- Capture target text for `ASButtonNode` instances from the [Texture][texture] library.

### Fixed

- The Event Visualizer trigger gesture works on `UIWindow` instances instantiated after app launch.
- Stability improvements for UISegmentedControl autocapture.
- Suppress recording spurious system view controllers, particularly those used by iOS 13.

## [6.4.1] - 2019-11-20

### Fixed

- Fixed issues with incorrect view controller class names being captured on iOS 13.

## [6.4.0] - 2019-10-04

### Changed

- Page views are now triggered when child view controllers are presented.

## [6.3.0] - 2019-09-06

### Added

- Added protection to avoid possible crashes, disabling capture when errors occur.

### Fixed

- Fixed instrumentation of `UISegmentedControl`s on iOS 9.
- Fixed an error when opening multiple Event Visualizer sessions.

## [6.2.1] - 2019-08-13

### Fixed

- Fixed a bug related to user id generation across app restarts.

## [6.2.0] - 2019-07-24

### Fixed

- The gesture used to initiate Event Visualizer pairing mode was modified, so as not to interfere with application audio.

## [6.1.0] - 2019-07-12

### Added
  - Add the `[Heap startEVPairing]` and `[Heap stopEVPairing]` APIs; this enables programmatic control of the event visualizer pairing mode.
  - Allow entering the event visualizer pairing mode from an iOS simulator using the `Hardware → Shake Gesture` command.

### Fixed
  - Improve sessionization semantics; sessions now expire after 5 idle minutes, regardless of the app's background/foreground state.

## [6.0.0] - 2019-07-09

### Breaking changes

- Dropped support for iOS versions below 9.0.

### Added

- Enhanced the pairing flow for the iOS event visualizer.

## [5.4.1] - 2019-06-20

### Fixed
- Fixed an issue related to UISegmentedControl components in OS versions earlier than iOS 10 that wasn't fixed adequately in the last release.

## [5.4.0] - 2019-06-18

### Added
- Exposed a programmatic way to reset the user identity.

### Fixed
- Fixed an issue where observing UISegmentedControl components would crash on an OS earlier than iOS 10.
- Fixed an issue where accessibility identifiers could be accessed off the main queue.

## [5.3.1] - 2019-06-07

### Added
- Capture app lifecycle events (installation & upgrade).

### Fixed
- Fixed an issue where the incorrect target text was being reported for touches on `UISegmentedControl` instances.

## [5.1.1] - 2019-03-08
### Fixed
- UIButtonBarButtons may show an internal selector (e.g. "_invoke:forEvent") instead of the actual code's selector name.  When this situation occurs, the selector is omitted from the event.
- Fixed an issue that was causing crashes in the Main Thread Checker during some UITests.

## [5.1.0] - 2018-12-19
### Added
- Events triggered by ViewControllers now include the `title` property of the ViewController.

## [5.0.8] - 2018-10-09
### Fixed
- Fixed a crash with the Event Visualier for apps built on Xcode 10.

## [5.0.7] - 2018-08-17
- Fixed a crash caused when Heap was loaded along with Firebase/Performance.

## [5.0.6] - 2018-04-03
- Fixed a situation that could cause events to have the wrong screenview properties.

## [5.0.5] - 2018-02-06
### Fixed
- Fixed possible crash when view controller class is nil.

## [5.0.4] - 2017-09-25
### Fixed
- Moved some code from a background thread to main thread to satisfy XCode's Main Thread Checker diagnostic.

## [5.0.3] - 2017-09-11
### Fixed
- addUserProperties failed to work if user was already identified.

## [5.0.2] - 2017-07-18
### Fixed
- Protect against nil view controller name.

## [5.0.1] - 2017-07-04
### Fixed
- Fixed the view controller name sent to the Event Visualizer on touch events.

## [5.0.0] - 2017-07-04
### Fixed
- Correctly capture names of several types of nested view controllers.
- Removed deprecated form of identify API.

## [4.0.1] -- unreleased
### Added
- Include this changelog in the package on CocoaPods

## [4.0.0] - 2017-03-08
### Added
- Improved library documentation.
- Annotated methods to improve usability from Swift.
- Allow hiding views from Heap by adding a boolean user defined attribute
  called `heapIgnore` in Interface Builder and setting it to true.

### Fixed
- Changed view controller capture to more accurately represent the current
  view.

### Deprecated
These methods were already deprecated in 3.0.0, but we're highlighting
them here as we intend to remove them in a future release.

- The `identifyDeprecated:` method is (obviously) deprecated, and should
  be replaced by `identify:`. See [user identities and properties
  documentation][id] for the correct usage.
- The `setEventProperties:` and `unsetEventProperty:` methods are
  deprecated, and should be replaced by `addEventProperties:` and
  `removeEventProperty:` respectively. The new methods are aliases, so
  simply replacing calls will work.

[id]: https://developers.heap.io/docs/using-identify
[texture]: https://github.com/TextureGroup/Texture
