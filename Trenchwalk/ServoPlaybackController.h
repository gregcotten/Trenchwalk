//
//  ServoPlaybackController.h
//  Trenchwalk
//
//  Created by Greg Cotten on 7/21/15.
//  Copyright © 2015 Greg Cotten. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServoController.h"

@interface ServoPlaybackController : NSObject

@property (weak) IBOutlet ServoController *servoController;

@property (assign) NSInteger startPosition;
@property (assign) NSInteger endPosition;

@property (assign) double playbackDurationInSeconds;

@end
