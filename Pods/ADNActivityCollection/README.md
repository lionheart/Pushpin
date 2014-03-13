ADN Activity Collection
=====================

<img src="https://raw.github.com/brennanMKE/ADNActivityCollection/master/ADNActivity.png" width="320px" alt="Screenshot" align="right" />

## UIActivities to share with App.net (ADN) apps from an Activity Sheet

The Activity Sheet is new iOS 6. It provides for abstractions to share content from apps to 
multiple services in a very decoupled way. Custom activities can be added as options.
Sharing messages to App.net (ADN) with apps like Netbot and Felix can help get more content
onto ADN and give users sharing options they want. This sample project will provide a collection
of activities which will detect if an ADN app is available and make it available as an option if
it is. (screenshot below)

## How to use ADN Activity Collection

The source files you would need are in the ADNActivities folder. There is the base class and
the Felix, Netbot and other activities. The images used for the icons are drawn in code thanks to
[PaintCode](http://www.paintcodeapp.com/) so there are no resources you need to add or manage
in your project.  Finally you may need to add frameworks to your project such as Core Graphics.

Once you have the source files added you can use the example in SSTViewController to set up
the activities which are shown by the Activity Sheet. It creates an array of activity items which
includes an NSString and NSURL value if both fields are populated. A URL is simply added to the
NSString value for the ADN activities but Twitter and Facebook using them as links. If Felix,
Netbot or another ADN client has the option to take an NSURL value it could be passed as well
to share on ADN.

See the PaintCode documents included with this project as examples of what is needed to provide
a new icon for an activity.

## What about my favorite ADN app?

More apps can be supported. All that is needed is a URL Scheme with a way to send a new post
over to the app. Felix, Netbot, Riposte and hAppy are currently supported. Below are links to
their docs covering their URL Scheme support.

 * [Felix](http://tigerbears.com/felix/urls.html)
 * [Netbot](http://tapbots.com/blog/development/tweetbot-url-scheme) (Same as Tweetbot)
 * [Riposte](http://riposteapp.net/release-notes.html)
 * [hAppy](http://dasdom.de/Dominik_Hauser_Development/hAppy_url_schemes.html)

## Return URL Scheme (deprecated)

One additional parameter which is sent to the other apps is a value which can be used to return
to the calling app once the post operation has completed. This way the sequence of sharing returns
to the originating app. It is likely developers will be more likely to integrate ADN clients with
these activities if they know they are not sending users away from their app with this option.
ADN clients should return to the calling app once the post is completed or canceled.

To support the Return URL Scheme simply use the parameter returnURLScheme and once the operation to
post has completed or is canceled use that value to open the calling application to return to it. The
returning application should handle that interaction if any customization is wanted, but there may
not be any necessary actions.

Included within this project (open the Workspace) there is an example ADN Client which works with the 
ADN Activities application. It can even be used with the Simulator to show how the interaction
works between a calling application and a client. The Return URL Scheme is used to complete
the activity as intended.

## X-Callback-URL

Instead of the Return URL Scheme the code base will be replaced with the [x-callback-url specification](http://x-callback-url.com/specifications/).
This specification is used by [Google Chrome Mobile](https://developers.google.com/chrome/mobile/docs/ios-links)
to allow apps to open content in apps made by Google and then return to the originating app.

## No View Controller

For other sharing options there is typically a view controller which allows the user to edit and
share the content from within the app. Since these activities are meant to use a third party app
to authenticate with ADN and complete the post there is no view controller. It makes sense to
warn they user they are about to leave the app though, so a view controller which can preview
the message and allow the user to cancel if they choose instead if jumping to another app could
be added later.

## Contributions

Additional ADN clients can be supported on iOS by simply using the current activities as a reference.
The Felix and Netbot activities use a base class which does much of the work. Simply fork this project
on GitHub and submit a Pull Request once you are ready. Pull Requests will be reviewed and added if
they appear to be ready to be included with the collection.

## Support

Issue tracking on GitHub can be used for any issues which come up. Otherwise I can be found on ADN. 

## Your App Here

Are you using the ADN Activity Collection in your app? I'd like to add a list of apps which are using
it here so others can see real-world examples. Simply reach out to my on ADN with my details below.

## Elsewhere with ADN

This solution and others are listed with [ADN Developer Resources](https://github.com/appdotnet/api-spec/wiki/Developer-Resources#wiki-objectivec)
where you can find other bits you can use with your development work.

Brennan Stehling on App.net  
[@smallsharptools](http://alpha.app.net/smallsharptools)

