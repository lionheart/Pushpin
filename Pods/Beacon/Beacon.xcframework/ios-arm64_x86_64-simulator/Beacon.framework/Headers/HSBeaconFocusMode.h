@import Foundation;

/// HSBeaconFocusMode represents various configuration modes of Beacon.
/// Allowing you to customize the experience your users have, from getting in contact
/// right away, to a more self service approach.  More info is available AT https://docs.helpscout.com/article/1296-work-with-beacon-modes
typedef NS_ENUM(NSUInteger, HSBeaconFocusMode) {
    HSBeaconFocusModeNeutral,
    HSBeaconFocusModeSelfService,
    HSBeaconFocusModeAskFirst
};
