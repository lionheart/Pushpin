# Heap for iOS

*Heap is a modern take on analytics.* There's no need to ship event tracking code, no need to wait days or weeks for data to accumulate, no need to muddle your codebase, and no need to fumble with rigid reports.

For the first time, meaningful product questions can be answered just as soon as they're asked.

See `CHANGELOG.md` for what's new.


# Installation

We recommend using <a href='http://cocoapods.org' target='_blank'>Cocoapods</a> to quickly and easily add Heap:

1. Install Cocoapods by running <code class='inline-code'>sudo gem install cocoapods</code>.
2. Create a file in your Xcode project directory called `Podfile`.
3. Add the following line to your Podfile:
  ```ruby
     pod 'Heap'
  ```
4. Run <code class='inline-code'>pod install</code> within your Xcode project directory.
5. Initialize Heap with your app ID. We recommend doing this in `applicationDidFinishLaunching:` or `application:didFinishLaunchingWithOptions:` in your Application delegate as follows:
  ```objectivec
     #import "Heap.h"

     - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
         [Heap initialize:@"YOUR_APP_ID"];
     #ifdef DEBUG
         [Heap enableVisualizer];
     #endif

         /* Other launch code goes here */

         return YES;
     }
  ```
6. Make sure you open the file with the extension .xcworkspace

Or you can install Heap manually:
  1. [Download the Heap iOS library](https://cdn.heapanalytics.com/ios/heap-ios-latest.zip).
  2. Unzip the downloaded file and drag `libHeap.a` and `Heap.h` into your XCode project. Make sure to select *Copy items if needed*.
  3. Click on the project (blue project icon), and select "Build Settings".
  4. Within Build Settings, change "Other Linker Flags" to include `-all_load -ObjC` as a flag.
  5. <a href='https://developer.apple.com/library/ios/recipes/xcode_help-project_editor/Articles/AddingaLibrarytoaTarget.html' target='_blank'>Link your app</a> to these libraries:
    * CFNetwork.framework
    * Foundation.framework
    * libicucore.tbd
    * Security.framework
    * SystemConfiguration
    * UIKit
  6. Initialize Heap with your app ID, as illustrated in the code snippet above.

## Using Heap with Swift

The Heap library should work fine if you use an [Objective-C bridge header](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/BuildingCocoaApps/MixandMatch.html) with your Swift project.

  ```swift
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.

        Heap.initialize("YOUR_APP_ID");
        #if DEBUG
            Heap.enableVisualizer();
        #endif

        return true
    }
  ```

## Using Heap with iMessage Apps

Heap should work with standalone iMessage apps if you override `didBecomeActive`.

  ```swift
    func didBecomeActive(with conversation: MSConversation) {

        Heap.initialize("YOUR_APP_ID");
        #if DEBUG
            Heap.enableVisualizer();
        #endif
    }
  ```

---

Having trouble with iOS installation? [Here are solutions for common problems](https://help.heap.io/heap-administration/data-management/event-visualizer/#troubleshooting).
