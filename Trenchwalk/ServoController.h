//
//  ServoController.h
//  Trenchwalk
//
//  Created by Greg Cotten on 7/12/15.
//  Copyright © 2015 Greg Cotten. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ORSSerialPort/ORSSerialPort.h>

@interface ServoController : NSObject <ORSSerialPortDelegate>

@property (strong) ORSSerialPort *serialPort;

@property (assign) NSInteger servoID;
@property (strong) NSString *servoState;

@property (assign) BOOL didInitialize;
@property (assign) BOOL isInPlayback;

@property (assign) int32_t servoCurrentPosition;
@property (assign) int32_t motorTargetSpeed;
@property (assign, nonatomic) int32_t servoTargetPosition;


- (void)closeConnection;

@end
