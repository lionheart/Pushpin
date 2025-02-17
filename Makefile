beta: appstore
	bundle exec fastlane beta

bump_version:
	bundle exec fastlane bump_version

appstore: bump_version
	# Most recently, this does not work. In order to bump the bundle version
	# correctly, I ran this, and then uploaded using the Xcode organizer.
	bundle exec fastlane appstore

all: appstore beta
	echo "Done"

add_license:
	go install github.com/google/addlicense@latest
	./scripts/add_license.sh
