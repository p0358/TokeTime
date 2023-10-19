#import <UIKit/UIKit.h>
#import <Cephei/HBPreferences.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>
#include <rootless.h>

#define kOverlayViewTag 6942069

// iOS 13
@interface SBFLockScreenDateViewController: UIViewController
-(void)_updateView;
@end

// iOS 12
@interface SBLockScreenDateViewController: UIViewController
-(void)_updateView;
@end

HBPreferences *preferences;
AVAudioPlayer *player;
static BOOL isEnabledAllTheTime;
static NSInteger displayMode;
static BOOL isAudioEnabled;
static NSInteger audioStartAt;
static BOOL didInitSoundAlready = false;
static BOOL werePrefsUpdated = false;

static void prefsDidUpdate() {
    werePrefsUpdated = true;
}

static inline BOOL is420() {
    NSDate *now = [NSDate date];
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"h:mm"];
    NSString *newDateString = [outputFormatter stringFromDate:now];

    return [newDateString isEqualToString: @"4:20"];
}

static void updateTokeView(UIView *v) {

    BOOL isAlreadyThere = false;

    for (UIView *view in v.superview.superview.superview.subviews) {
        if (view.tag == kOverlayViewTag) {
            if (werePrefsUpdated) {
                [view removeFromSuperview]; // preferences were updated, we need to recreate our view
            } else {
                isAlreadyThere = true;
            }
        }
    }
    werePrefsUpdated = false;

    if (isEnabledAllTheTime || is420()) {

        if (!isAlreadyThere) {
            UIImageView *snoopImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:ROOT_PATH_NS(@"/Library/Application Support/TokeTime/snoop.png")]];
            snoopImageView.frame = v.superview.bounds;
            snoopImageView.tag = kOverlayViewTag;
            switch (displayMode) {
                case 1: snoopImageView.contentMode = UIViewContentModeScaleAspectFit; break;
                case 2: snoopImageView.contentMode = UIViewContentModeBottom; break;
                case 0:
                default: snoopImageView.contentMode = UIViewContentModeScaleAspectFill; break;
            }

            if (![snoopImageView isDescendantOfView: v.superview.superview.superview]) {
                [v.superview.superview.superview insertSubview: snoopImageView atIndex: 0];
            }

        }

        if (isAudioEnabled) {

            // init sound if needed
            if (!didInitSoundAlready) {
                player = [[objc_getClass("AVAudioPlayer") alloc] initWithContentsOfURL:[NSURL fileURLWithPath:ROOT_PATH_NS(@"/Library/Application Support/TokeTime/the_next_episode.aac") isDirectory:NO] error:nil];
                didInitSoundAlready = true;
            }

            if (![player isPlaying]) {
                if (audioStartAt > 0) switch (audioStartAt) {
                    case 1: player.currentTime = 10; break;
                }
                [player play];
            }
        }

    } else if (isAlreadyThere) {
        for (UIView *view in v.superview.superview.superview.subviews) {
            if (view.tag == kOverlayViewTag) {
                [view removeFromSuperview];
            }
        }
    }

    if (!isAudioEnabled && didInitSoundAlready && [player isPlaying])
        [player stop];
}

// iOS 13
%hook SBFLockScreenDateViewController
-(void)_updateView {
    %orig;
    updateTokeView([self view]);
}
%end

// iOS 12
%hook SBLockScreenDateViewController
-(void)_updateView {
    %orig;
    updateTokeView([self view]);
}
%end

%ctor {
    preferences = [[HBPreferences alloc] initWithIdentifier:@"net.p0358.toketime"];

    [preferences registerBool:&isEnabledAllTheTime default:NO forKey:@"ShowAllTheTime"];
    [preferences registerInteger:&displayMode default:0 forKey:@"DisplayMode"];
    [preferences registerBool:&isAudioEnabled default:NO forKey:@"AudioEnabled"];
    [preferences registerInteger:&audioStartAt default:0 forKey:@"AudioStartAt"];

    [preferences registerPreferenceChangeBlock:^{
        prefsDidUpdate();
    }];
}
