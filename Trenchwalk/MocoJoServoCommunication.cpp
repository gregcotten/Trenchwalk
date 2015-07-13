#include <MocoJoServoCommunication.h>
#include <MocoJoServoProtocol.h>
#include <SerialTools.h>

//SERVO to MCU
void MocoJoServoCommunication::writeHandshakeSuccessToMCU(HardwareSerial &serial, int ID){
	(&serial) -> write(ID);
	(&serial) -> write(MocoJoServoHandshakeSuccessfulResponse);
	SerialTools::writeDummyBytesToSerial(serial, 4);
}
	
void MocoJoServoCommunication::writeCurrentPositionToMCU(HardwareSerial &serial, int ID, long currentPosition){
	(&serial) -> write(ID);
	(&serial) -> write(MocoJoServoCurrentPosition);
	SerialTools::writeLongToSerial(serial, currentPosition);
}

void MocoJoServoCommunication::writePositionAtLastSyncToMCU(HardwareSerial &serial, int ID, long positionAtLastSync){
	(&serial) -> write(ID);
	(&serial) -> write(MocoJoServoPositionAtLastSync);
	SerialTools::writeLongToSerial(serial, positionAtLastSync);
}
void MocoJoServoCommunication::writeMotorTargetSpeedToMCU(HardwareSerial &serial, int ID, long motorTargetSpeed){
	(&serial) -> write(ID);
	(&serial) -> write(MocoJoServoMotorTargetSpeed);
	SerialTools::writeLongToSerial(serial, motorTargetSpeed);
}

void MocoJoServoCommunication::writeIsHoningToMCU(HardwareSerial &serial, int ID, boolean isHoning){
	(&serial) -> write(ID);
	(&serial) -> write(MocoJoServoIsHoning);
	if(isHoning){
		SerialTools::writeLongToSerial(serial, 1);
	}
	else{
		SerialTools::writeLongToSerial(serial, 0);
	}
	
}

//----------------------

//MCU to SERVO

//init
void MocoJoServoCommunication::writeHandshakeRequestToServo(HardwareSerial &serial, int ID){
	(&serial) -> write(ID);
	(&serial) -> write(MocoJoServoHandshakeRequest);
	SerialTools::writeDummyBytesToSerial(serial, 4);
}

void MocoJoServoCommunication::writeInitializeToServo(HardwareSerial &serial, int ID){
	(&serial) -> write(ID);
	(&serial) -> write(MocoJoServoInitializeRequest);
	SerialTools::writeDummyBytesToSerial(serial, 4);
}

void MocoJoServoCommunication::writeExitSafeStartToServo(HardwareSerial &serial, int ID){
	(&serial) -> write(ID);
	(&serial) -> write(MocoJoServoExitSafeStart);
	SerialTools::writeDummyBytesToSerial(serial, 4);
}



//limits
void MocoJoServoCommunication::writeSetMaxSpeedToServo(HardwareSerial &serial, int ID, long maxSpeed){
	(&serial) -> write(ID);
	(&serial) -> write(MocoJoServoSetMaxSpeed);
	SerialTools::writeLongToSerial(serial, maxSpeed);
}


//position

void MocoJoServoCommunication::writeGetCurrentPositionToServo(HardwareSerial &serial, int ID){
	(&serial) -> write(ID);
	(&serial) -> write(MocoJoServoGetCurrentPosition);
	SerialTools::writeDummyBytesToSerial(serial, 4);
}

void MocoJoServoCommunication::writeGetPositionAtLastSyncToServo(HardwareSerial &serial, int ID){
	(&serial) -> write(ID);
	(&serial) -> write(MocoJoServoGetPositionAtLastSync);
	SerialTools::writeDummyBytesToSerial(serial, 4);
}

void MocoJoServoCommunication::writeSetTargetPositionToServo(HardwareSerial &serial, int ID, long targetPosition){
	(&serial) -> write(ID);
	(&serial) -> write(MocoJoServoSetTargetPosition);
	SerialTools::writeLongToSerial(serial, targetPosition);
}

void MocoJoServoCommunication::writeAddTargetPositionToBufferToServo(HardwareSerial &serial, int ID, long targetPosition){
	(&serial) -> write(ID);
	(&serial) -> write(MocoJoServoAddTargetPositionToBuffer);
	SerialTools::writeLongToSerial(serial, targetPosition);
}


//Motor
void MocoJoServoCommunication::writeGetMotorTargetSpeedToServo(HardwareSerial &serial, int ID){
	(&serial) -> write(ID);
	(&serial) -> write(MocoJoServoGetMotorTargetSpeed);
	SerialTools::writeDummyBytesToSerial(serial, 4);
}

//playback
void MocoJoServoCommunication::writeGetIsHoningToServo(HardwareSerial &serial, int ID){
	(&serial) -> write(ID);
	(&serial) -> write(MocoJoServoGetIsHoning);
	SerialTools::writeDummyBytesToSerial(serial, 4);
}

void MocoJoServoCommunication::writeStartPlaybackToServo(HardwareSerial &serial, int ID){
	(&serial) -> write(ID);
	(&serial) -> write(MocoJoServoStartPlayback);
	SerialTools::writeDummyBytesToSerial(serial, 4);
}

void MocoJoServoCommunication::writeStopPlaybackToServo(HardwareSerial &serial, int ID){
	(&serial) -> write(ID);
	(&serial) -> write(MocoJoServoStopPlayback);
	SerialTools::writeDummyBytesToSerial(serial, 4);
}

void MocoJoServoCommunication::writeProceedToHoneToServo(HardwareSerial &serial, int ID){
	(&serial) -> write(ID);
	(&serial) -> write(MocoJoServoProceedToHone);
	SerialTools::writeDummyBytesToSerial(serial, 4);
}
//-----------------------


