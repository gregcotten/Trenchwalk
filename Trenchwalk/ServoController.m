//
//  ServoController.m
//  Trenchwalk
//
//  Created by Greg Cotten on 7/12/15.
//  Copyright © 2015 Greg Cotten. All rights reserved.
//

#import "ServoController.h"
#import <ORSSerialPort/ORSSerialPortManager.h>
#import <ORSSerialPort/ORSSerialRequest.h>
#import <Cocoa/Cocoa.h>

#import "VVApp.h"

#import "MocoJoServoProtocol.h"
#import "MocoProtocolConstants.h"

dispatch_source_t CreateDispatchTimer(double interval, dispatch_queue_t queue, dispatch_block_t block)
{
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    if (timer)
    {
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), interval * NSEC_PER_SEC, (1ull * NSEC_PER_SEC) / 10);
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    return timer;
}

@interface ServoController ()

@property (weak) IBOutlet NSWindow *ownerWindow;
@property (strong) dispatch_queue_t timerSerialQueue;
@property (strong) dispatch_source_t updateTimer;
@property (assign) BOOL isConnecting;
@property (assign) BOOL didReceiveFirstPosition;

@end

@implementation ServoController

-(instancetype)init{
    if (self = [super init]){
        self.servoState = @"Not Connected";
        self.isInPlayback = NO;
        self.didInitialize = NO;
        self.timerSerialQueue = dispatch_queue_create("Servo Timer Serial Dispatch", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

-(IBAction)connect:(id)sender{
    [self closeConnection];
    [self openConnection];
}

-(IBAction)disconnect:(id)sender{
    [self closeConnection];
}

-(void)openConnection{
    self.isConnecting = YES;
    //self.serialPort = [ORSSerialPort serialPortWithPath:@"/dev/cu.usbserial-A6009AXX"];
    
    //self.serialPort = (ORSSerialPort *)[[ORSSerialPortManager sharedSerialPortManager] availablePorts].firstObject;
    
    NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/dev/" error:nil];
    NSArray *serialPorts = [dirFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH 'cu.usbserial'"]];
    
    self.serialPort = [ORSSerialPort serialPortWithPath:[NSString stringWithFormat:@"/dev/%@", serialPorts.firstObject]];
    
    if (!self.serialPort) {
        return;
    }
    self.serialPort.delegate = self;
    self.serialPort.allowsNonStandardBaudRates = YES;
    self.serialPort.baudRate = @(MocoJoServoBaudRate);
    self.servoState = [NSString stringWithFormat:@"Connecting to %@...", self.serialPort.path];
    self.servoID = MocoAxisJibLift;
    self.didReceiveFirstPosition = NO;
    [self.serialPort open];

}

-(void)handshakeServo:(NSTimer *)timer{
    self.servoState = @"Handshaking...";

    NSData *command = [self.class servoDataPacketFromArray:@[@(self.servoID), @(MocoJoServoHandshakeRequest)]];
    ORSSerialRequest *request =
    [ORSSerialRequest requestWithDataToSend:command
                                   userInfo:@(MocoJoServoHandshakeRequest)
                            timeoutInterval:2
                          responseEvaluator:^BOOL(NSData *data) {
                              if (data.length != 6) {
                                  return NO;
                              }
                              return ((char *)data.bytes)[1] == MocoJoServoHandshakeSuccessfulResponse;
                          }];
    [self.serialPort sendRequest:request];
}

-(void)initializeServo{
    self.servoState = @"Initializing...";

    NSData *command = [self.class servoDataPacketFromArray:@[@(self.servoID), @(MocoJoServoInitializeRequest)]];

    ORSSerialRequest *request =
    [ORSSerialRequest requestWithDataToSend:command
                                   userInfo:@(MocoJoServoInitializeRequest)
                            timeoutInterval:2
                          responseEvaluator:nil];
    [self.serialPort sendRequest:request];

    self.didInitialize = YES;
    self.servoSpeed = ServoSpeedCasual;
    [self beginTimedUpdate];
    self.servoState = @"Idle";

}

-(BOOL)beginTimedUpdate{
    if (self.updateTimer) {
        return NO;
    }

    self.updateTimer = CreateDispatchTimer(.05f, self.timerSerialQueue, ^{
        [self timedUpdate];
    });
    
    return YES;
}

-(void)endTimedUpdate{
    if (self.updateTimer) {
        dispatch_source_cancel(self.updateTimer);
    }
    self.updateTimer = nil;
}

-(void)timedUpdate{
    if (self.serialPort.isOpen && self.didInitialize) {
        
        dispatch_async(self.timerSerialQueue, ^{
            [self.serialPort sendRequest:[self updateCurrentPositionRequest]];
            [self.serialPort sendRequest:[self updateMotorTargetSpeedRequest]];
            if (self.didReceiveFirstPosition) {
                [self.serialPort sendRequest:[self updateServoWithTargetPositionRequest]];
            }
        });
    }
}

-(ORSSerialRequest *)updateCurrentPositionRequest{
    NSData *command = [self.class servoDataPacketFromArray:@[@(self.servoID), @(MocoJoServoGetCurrentPosition)]];
    ORSSerialRequest *request =
    [ORSSerialRequest requestWithDataToSend:command
                                   userInfo:@(MocoJoServoGetCurrentPosition)
                            timeoutInterval:2
                          responseEvaluator:^BOOL(NSData *data) {
                              if (data.length != 6) {
                                  return NO;
                              }
                              return ((char *)data.bytes)[1] == MocoJoServoCurrentPosition;
                          }];
    return request;
    
}

-(ORSSerialRequest *)updateMotorTargetSpeedRequest{
    NSData *command = [self.class servoDataPacketFromArray:@[@(self.servoID), @(MocoJoServoGetMotorTargetSpeed)]];
    ORSSerialRequest *request =
    [ORSSerialRequest requestWithDataToSend:command
                                   userInfo:@(MocoJoServoGetMotorTargetSpeed)
                            timeoutInterval:2
                          responseEvaluator:^BOOL(NSData *data) {
                              if (data.length != 6) {
                                  return NO;
                              }
                              return ((char *)data.bytes)[1] == MocoJoServoMotorTargetSpeed;
                          }];
    return request;

}

-(ORSSerialRequest *)updateServoWithTargetPositionRequest{
    Byte *targetAsBytes = (Byte *)[self.class fourBytesFromLongInt:self.servoTargetPosition].bytes;
    NSData *command = [self.class servoDataPacketFromArray:@[@(self.servoID),
                                                             @(MocoJoServoSetTargetPosition),
                                                             @(targetAsBytes[0]),
                                                             @(targetAsBytes[1]),
                                                             @(targetAsBytes[2]),
                                                             @(targetAsBytes[3])]];
    ORSSerialRequest *request =
    [ORSSerialRequest requestWithDataToSend:command
                                   userInfo:@(MocoJoServoSetTargetPosition)
                            timeoutInterval:2
                          responseEvaluator:nil];
    
    return request;
    
}

-(void)setServoSpeed:(ServoSpeed)servoSpeed{
    if (servoSpeed == ServoSpeedCasual) {
        self.motorMinSpeed = 0;
        self.motorMaxSpeed = 600;
    }
    else if(servoSpeed == ServoSpeedHone){
        self.motorMinSpeed = 0;
        self.motorMaxSpeed = 700;
    }
    else if(servoSpeed == ServoSpeedPlayback){
        self.motorMinSpeed = 0;
        self.motorMaxSpeed = 3200;
    }
}

-(void)setServoCurrentPosition:(NSInteger)servoCurrentPosition{
    _servoCurrentPosition = servoCurrentPosition;
    self.servoPositionDifference = self.servoTargetPosition - self.servoCurrentPosition;
}

-(void)setServoTargetPosition:(NSInteger)servoTargetPosition{
    _servoTargetPosition = servoTargetPosition;
    self.servoPositionDifference = self.servoTargetPosition - self.servoCurrentPosition;
}

-(void)setMotorMaxSpeed:(NSInteger)motorMaxSpeed{
    _motorMaxSpeed = motorMaxSpeed;
    if (self.didInitialize) {
        dispatch_async(self.timerSerialQueue, ^{
            [self.serialPort sendRequest:[self updateServoWithMaxMotorSpeedRequest]];
        });
    }

}

-(void)setMotorMinSpeed:(NSInteger)motorMinSpeed{
    _motorMinSpeed = motorMinSpeed;
    if (self.didInitialize) {
        dispatch_async(self.timerSerialQueue, ^{
            [self.serialPort sendRequest:[self updateServoWithMinMotorSpeedRequest]];
        });
    }
}

-(ORSSerialRequest *)updateServoWithMinMotorSpeedRequest{
    Byte *minMotorSpeedAsBytes = (Byte *)[self.class fourBytesFromLongInt:self.motorMinSpeed].bytes;
    NSData *command = [self.class servoDataPacketFromArray:@[@(self.servoID),
                                                             @(MocoJoServoSetMinSpeed),
                                                             @(minMotorSpeedAsBytes[0]),
                                                             @(minMotorSpeedAsBytes[1]),
                                                             @(minMotorSpeedAsBytes[2]),
                                                             @(minMotorSpeedAsBytes[3])]];
    ORSSerialRequest *request =
    [ORSSerialRequest requestWithDataToSend:command
                                   userInfo:@(MocoJoServoSetMinSpeed)
                            timeoutInterval:2
                          responseEvaluator:nil];
    
    return request;
    
}

-(ORSSerialRequest *)updateServoWithMaxMotorSpeedRequest{
    Byte *maxMotorSpeedAsBytes = (Byte *)[self.class fourBytesFromLongInt:self.motorMaxSpeed].bytes;
    NSData *command = [self.class servoDataPacketFromArray:@[@(self.servoID),
                                                             @(MocoJoServoSetMaxSpeed),
                                                             @(maxMotorSpeedAsBytes[0]),
                                                             @(maxMotorSpeedAsBytes[1]),
                                                             @(maxMotorSpeedAsBytes[2]),
                                                             @(maxMotorSpeedAsBytes[3])]];
    ORSSerialRequest *request =
    [ORSSerialRequest requestWithDataToSend:command
                                   userInfo:@(MocoJoServoSetMaxSpeed)
                            timeoutInterval:2
                          responseEvaluator:nil];

    return request;

}

-(void)serialPortWasOpened:(nonnull ORSSerialPort *)serialPort{
    //wait 5 seconds then talk to servo
    self.isConnecting = NO;
    [NSTimer scheduledTimerWithTimeInterval:5
                                     target:self
                                   selector:@selector(handshakeServo:)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)closeConnection{
    self.isConnecting = NO;
    self.servoState = @"Not Connected";
    [self.serialPort close];
    [self endTimedUpdate];

    self.didInitialize = NO;
    self.isInPlayback = NO;
}

-(void)serialPortWasRemovedFromSystem:(nonnull ORSSerialPort *)serialPort{
    [self closeConnection];
}

-(void)serialPort:(nonnull ORSSerialPort *)serialPort requestDidTimeout:(nonnull ORSSerialRequest *)request{
    NSLog(@"request timed out: %@", request);
    [self closeConnection];
}

-(void)serialPort:(nonnull ORSSerialPort *)serialPort didEncounterError:(nonnull NSError *)error{
    NSLog(@"serial port error: %@", error);
}

-(void)serialPort:(nonnull ORSSerialPort *)serialPort didReceiveResponse:(nonnull NSData *)responseData toRequest:(nonnull ORSSerialRequest *)request{
    NSInteger requestID = [request.userInfo integerValue];
    Byte *responseBytes = (Byte*)responseData.bytes;

    if (requestID == MocoJoServoHandshakeRequest) {
        self.servoState = @"Handshake Success";
        [self initializeServo];
    }
    else if (requestID == MocoJoServoGetCurrentPosition) {
        Byte fourbytes[4];
        fourbytes[0] = responseBytes[2];
        fourbytes[1] = responseBytes[3];
        fourbytes[2] = responseBytes[4];
        fourbytes[3] = responseBytes[5];

        self.servoCurrentPosition = [self.class longIntFromFourBytes:fourbytes];
        if (!self.didReceiveFirstPosition) {
            [VVApp endEditingInWindow:self.ownerWindow];
            self.servoTargetPosition = self.servoCurrentPosition;
            self.didReceiveFirstPosition = YES;
        }
    }
    else if (requestID == MocoJoServoGetMotorTargetSpeed){
        Byte fourbytes[4];
        fourbytes[0] = responseBytes[2];
        fourbytes[1] = responseBytes[3];
        fourbytes[2] = responseBytes[4];
        fourbytes[3] = responseBytes[5];

        self.motorTargetSpeed = [self.class longIntFromFourBytes:fourbytes];
    }
}

+(NSInteger)longIntFromFourBytes:(Byte *)fourBytes {
    return     ( (fourBytes[0] << 24)
                + (fourBytes[1] << 16)
                + (fourBytes[2] << 8)
                + (fourBytes[3] ) );
}

+ (NSData *)fourBytesFromLongInt: (NSInteger)longInt {
    unsigned char byteArray[4];

    // convert from an unsigned long int to a 4-byte array
    byteArray[0] = (int)((longInt >> 24) & 0xFF) ;
    byteArray[1] = (int)((longInt >> 16) & 0xFF) ;
    byteArray[2] = (int)((longInt >> 8) & 0XFF);
    byteArray[3] = (int)((longInt & 0XFF));

    return [NSData dataWithBytes:byteArray length:4];
}

+(NSData *)servoDataPacketFromArray:(NSArray *)array{
    char data[6];
    data[0] = array.count >= 1 ? [array[0] integerValue] : 0;
    data[1] = array.count >= 2 ? [array[1] integerValue] : 0;
    data[2] = array.count >= 3 ? [array[2] integerValue] : 0;
    data[3] = array.count >= 4 ? [array[3] integerValue] : 0;
    data[4] = array.count >= 5 ? [array[4] integerValue] : 0;
    data[5] = array.count >= 6 ? [array[5] integerValue] : 0;

    return [NSData dataWithBytes:data length:6];
}

@end
