//
//  ServoPlaybackController.h
//  Trenchwalk
//
//  Created by Greg Cotten on 7/21/15.
//  Copyright © 2015 Greg Cotten. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServoController.h"

typedef NS_ENUM(NSInteger, PlaybackMode) {
    PlaybackModeDuration,
    PlaybackModeSpeed
};

@interface ServoPlaybackController : NSObject

@property (weak) IBOutlet ServoController *servoController;

@property (assign, nonatomic) NSInteger startPosition;
@property (assign, nonatomic) NSInteger endPosition;

@property (assign, nonatomic) PlaybackMode playbackMode;
@property (assign, nonatomic) double playbackDurationInSeconds;
@property (assign, nonatomic) double playbackMotorSpeed;

@end
