//Initializing
enum{
	MocoJoServoBaudRate = 1000000,
	MocoJoServoBufferSize = 200,
	MocoJoServoHandshakeRequest = 0,
	MocoJoServoHandshakeSuccessfulResponse = 1,
	MocoJoServoInitializeRequest = 14

};

//Commands

enum{
	MocoJoServoStartPlayback = 2,
	MocoJoServoStopPlayback = 3,
	MocoJoServoStopEverything = 4,
	MocoJoServoExitSafeStart = 5,
	MocoJoServoProceedToHone = 15

};

//Getters

enum{
	MocoJoServoGetCurrentPosition = 6,
	MocoJoServoGetPositionAtLastSync = 7,
	MocoJoServoGetMotorTargetSpeed = 21,
	MocoJoServoGetIsHoning = 22
};

//Setters

enum{
	MocoJoServoSetTargetPosition = 9,
	MocoJoServoAddTargetPositionToBuffer = 10,
	MocoJoServoSetMaxSpeed = 11
};

// Variable IDs
enum{
	MocoJoServoCurrentPosition = 12,
	MocoJoServoPositionAtLastSync = 13,
	MocoJoServoMotorTargetSpeed = 20,
	MocoJoServoIsHoning = 23
};


