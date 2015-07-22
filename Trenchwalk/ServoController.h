//
//  ServoController.h
//  Trenchwalk
//
//  Created by Greg Cotten on 7/12/15.
//  Copyright © 2015 Greg Cotten. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ORSSerialPort/ORSSerialPort.h>

typedef NS_ENUM(NSInteger, ServoSpeed) {
    ServoSpeedHone,
    ServoSpeedPlayback,
    ServoSpeedCasual
};

@interface ServoController : NSObject <ORSSerialPortDelegate>


@property (strong) ORSSerialPort *serialPort;

@property (assign) NSInteger servoID;
@property (strong) NSString *servoState;

@property (assign) BOOL didInitialize;
@property (assign) BOOL isInPlayback;

@property (assign, nonatomic) NSInteger servoCurrentPosition;
@property (assign) NSInteger motorTargetSpeed;
@property (assign, nonatomic) NSInteger servoTargetPosition;

@property (assign) NSInteger servoPositionDifference;

@property (assign, nonatomic) ServoSpeed servoSpeed;
@property (nonatomic) NSInteger motorMaxSpeed;


- (void)closeConnection;

@end
