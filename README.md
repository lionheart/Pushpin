# Pushpin for Pinboard

<img src="https://img.shields.io/badge/license-GPLv3-blue">

This repo contains the full source code for Pushpin for Pinboard, a beautiful, blazing-fast, and feature-packed [Pinboard](https://pinboard.in) client for iOS and iPad OS.

<a href="https://apps.apple.com/us/app/pushpin-for-pinboard/id548052590"><img width="135px" src="https://2017.lionheartsw.com/static/images/appstore.png" /></a>

---

- [Screenshots](#screenshots)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [License](#license)

## Screenshots

<img width="200px" src="https://2017.lionheartsw.com/static/images/pushpin-1.png" /> <img width="200px" src="https://2017.lionheartsw.com/static/images/pushpin-2.png" /> <img width="200px" src="https://2017.lionheartsw.com/static/images/pushpin-3.png" /> <img width="200px" src="https://2017.lionheartsw.com/static/images/pushpin-4.png" />

## Features

* Search bookmarks at ridiculous speeds across titles, descriptions, URLs, and tags.
* View bookmarks by unread, starred, private, untagged, public, or specific tags. You can even filter by multiple tags!
* Share links on Twitter, Facebook, or Messages.
* Send your links to Pocket, Instapaper, or Readability.
* View tag suggestions and autocompletions when adding or updating bookmarks.
* Browse Network, Popular, Wikipedia, Fandom, and Japanese feeds.
* View and save feeds for specific users, tags, or any combination of the two.
* Browse tags along with the number of times they've each been used.
* Add bookmarks by switching to Pushpin with a URL on your clipboard.
* Comes with a full-featured in-app browser with support for popular mobilizers.
* Extensive URL scheme support for adding bookmarks on the fly, opening URLs with the in-app browser, or viewing feeds for users or tags.
* Offline reading! Pushpin can download and cache your bookmarks for those times when your Internet connection is spotty. Pushpin will download all page content, including CSS and Javascript, to make your offline browsing experience a great one.

## Requirements

- iOS 15.6+
- Swift 5+
- Xcode 16.2+

## Installation

1. Clone the repository:

       git clone git@github.com:lionheart/Pushpin.git
       cd Pushpin
       git submodule init
       git submodule update
       git submodule -q foreach git pull -q origin master

2. Install the Ruby version in `.tool-versions` and Bundler.

       asdf install
       gem install bundler

3. Install gems:

       bundle install

4. Then install iOS dependencies from CocoaPods.

       bundle exec pod install

5. Open `Pushpin.xcworkspace` to compile and run the project.

       > [!NOTE]
       > You will need to remove references to licensed fonts in the project before compilation.

### Optional

This project uses a few git hooks and merge drivers to prevent merge conflicts and to keep the project file clean. To set them up, just run:

```
$ git_config/configure.sh
```

The above command will also ensure that any Git commands stay in sync if they're updated.

### App Store Submission

Archive in Xcode and upload to App Store Connect.

### Updating Screenshots

```
gem install deliver
deliver init
# wait a few minutes
deliver
```

## License

<img src="https://www.gnu.org/graphics/gplv3-127x51.png" />

Pushpin for Pinboard is licensed under the [GNU GPL version 3 or any later version](https://www.gnu.org/licenses/gpl-3.0.html).

If you would like to use a modified version of the software (or any component thereof) and do _not_ want it to fall under the terms of the GPLv3 (e.g., you'd like to use some of the code in your own app in the App Store), you may [contact me](mailto:dan@lionheartsw.com) to purchase a [selling exception](https://www.gnu.org/philosophy/selling-exceptions).

### Trademark Notice
“Pushpin for Pinboard” is a trademark of Lionheart Software LLC. You may not use the “Pushpin for Pinboard” name, logo, or other brand assets without prior written permission from Lionheart Software LLC.

### Contact

If you have any questions, comments, or suggestions, please send me an email at [contact me](mailto:dan@lionheartsw.com), or reach out on [X](https://twitter.com/dwlz).
