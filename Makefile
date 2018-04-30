beta: appstore
	bundle exec fastlane beta

appstore:
	bundle exec fastlane appstore

all: appstore beta
	echo "Done"
