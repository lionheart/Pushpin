beta: appstore
	bundle exec fastlane beta

appstore:
	# Most recently, this does not work. In order to bump the bundle version
	# correctly, I ran this, and then uploaded using the Xcode organizer.
	bundle exec fastlane appstore

all: appstore beta
	echo "Done"
