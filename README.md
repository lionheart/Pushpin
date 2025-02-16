# Pushpin

<img src="https://img.shields.io/badge/license-GPLv3-blue">

Pushpin is an iOS client for [Pinboard.in](https://pinboard.in), a social bookmarking service.

<a href="https://apps.apple.com/us/app/pushpin-for-pinboard/id548052590"><img width="160px" src="https://2017.lionheartsw.com/static/images/appstore.png" /></a>

<hr/>

Landing page: https://lionheartsw.com/software/pushpin/

- [Features](#features)
- [Demo](#demo)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

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

## Demo

## Requirements

- iOS 15.6+
- Swift 5+
- Xcode 16.2+

## Local Setup

1. Install the Ruby in `.ruby-version` and Bundler.

       rbenv install
       gem install bundler

2. Install gems:

       bundle install

3. Then install iOS dependencies from CocoaPods.

       pod install

3. Open `Pushpin.xcworkspace` to compile and run the project.

## Setup

> [!WARNING]
> I haven't tested this on any other machines besides my own, so please test this out and submit a PR if something is broken.

1. First 
```
git clone git@github.com:lionheart/Pushpin.git
```

## Optional

This project uses a few git hooks and merge drivers to prevent merge conflicts and to keep the project file clean. To set them up, just run:

```
$ git_config/configure.sh
```

The above command will also ensure that any Git commands stay in sync if they're updated.

There are also a few git submodules you're going to need. To set them up, just run:

```
$ git submodule init
$ git submodule update
$ git submodule -q foreach git pull -q origin master
```

## App Store Submission

```
make appstore
```

## Updating Screenshots

```
gem install deliver
deliver init
# wait a few minutes
deliver
```

## License

<img src="https://www.gnu.org/graphics/gplv3-with-text-84x42.png" />

Pushpin is licensed under the [GNU GPL version 3 or any later version](https://www.gnu.org/licenses/gpl-3.0.html), which is considered a strict open-source license.

In short: you can modify and distribute the source code to others (and even sell it!) as long as you make the source code modifications freely available.

If you would like to sell a modified version of the software (or any component thereof) and do *not* want to release the source code, you may [contact me](mailto:dan@lionheartsw.com) and you can purchase a [selling exception](https://www.gnu.org/philosophy/selling-exceptions).
