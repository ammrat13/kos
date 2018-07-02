CLEARSCREEN.

// PARAMETERS:
LOCAL targApo TO 0.
LOCAL window TO FALSE.

LOCAL lHead TO 90.
LOCAL lLAN TO 0.
LOCAL LTol TO 0.01.
LOCAL gTurnVel TO 60.
LOCAL gTurnPitch TO 85.
LOCAL gTurnTol TO 0.2.


// HELPER VARIABLES:
LOCAL pitchPID TO PIDLOOP(3, .5, 15, -5, 30).


// HELPER FUNCTIONS:
LOCAL FUNCTION vecHead {
	DECLARE PARAMETER v.
	RETURN ARCCOS(VDOT(HEADING(0,0):FOREVECTOR, VXCL(SHIP:UP:FOREVECTOR, v):NORMALIZED)).
}

LOCAL FUNCTION vecPitch {
	DECLARE PARAMETER v.
	RETURN 90 - ARCCOS(VDOT(SHIP:UP:FOREVECTOR, v:NORMALIZED)).
}


// STATE MANAGEMENT:
LOCAL state TO 0.
LOCAL FUNCTION nextState {
	CLEARSCREEN.
	SET state TO state + 1.
}.
LOCAL states TO LIST(
	waitForWindow@,
	ascent@,
	gTurn@,
	followTraj@,
	pitchUp@,
	MECO@
).

LOCAL stag TO 0.
LOCAL stages TO LIST(
	beforeAscent@
).

UNTIL state >= states:LENGTH {
	states[state]().
	IF stag < stages:LENGTH AND stages[stag]() {
		STAGE.
		SET stag TO stag + 1.
	}
}


// STATES:

LOCAL FUNCTION waitForWindow {
	PRINT "State: Wait For Window" AT (1,1).
	PRINT "Stage: " + stag AT (1,2).
	PRINT "LAN:   " + SHIP:OBT:LAN AT (1,3).
	PRINT "Targ:  " + lLAN AT (1,4).
	LOCK THROTTLE TO 1.
	IF (NOT window) OR (ABS(SHIP:OBT:LAN - lLAN) <= LTol OR ABS(SHIP:OBT:LAN - lLAN) >= 360 - LTol) {
		nextState().
	}
}

LOCAL FUNCTION ascent {
	PRINT "State: Initial Ascent" AT (1,1).
	PRINT "Stage: " + stag AT (1,2).
	PRINT "Alt:   " + SHIP:ALTITUDE AT (1,3).
	PRINT "Vel:   " + SHIP:VELOCITY:SURFACE:MAG AT (1,4).
	PRINT "Targ:  " + gTurnVel AT (1,5).
	LOCK STEERING TO HEADING(lHead, 90).
	IF SHIP:VELOCITY:SURFACE:MAG >= gTurnVel {
		nextState().
	}
}

LOCAL FUNCTION gTurn {
	PRINT "State: Gravity Turn" AT (1,1).
	PRINT "Stage: " + stag AT (1,2).
	PRINT "Alt:   " + SHIP:ALTITUDE AT (1,3).
	PRINT "Pitch: " + vecPitch(SHIP:FACING:FOREVECTOR) AT (1,4).
	PRINT "VPit:  " + vecPitch(SHIP:VELOCITY:SURFACE) AT (1,5).
	PRINT "Targ:  " + gTurnPitch AT (1,6).
	LOCK STEERING TO HEADING(lHead, gTurnPitch).
	IF vecPitch(SHIP:VELOCITY:SURFACE) <= gTurnPitch + gTurnTol {
		nextState().
	}
}

LOCAL FUNCTION followTraj {
	PRINT "State: Follow Trajectory" AT (1,1).
	PRINT "Stage: " + stag AT (1,2).
	PRINT "Alt:   " + SHIP:ALTITUDE AT (1,3).
	PRINT "Apo:   " + SHIP:OBT:APOAPSIS AT (1,4).
	PRINT "ETA:   " + ETA:APOAPSIS AT (1,5).
	LOCK STEERING TO HEADING(lHead, vecPitch(SHIP:VELOCITY:SURFACE)).
	IF SHIP:ALTITUDE >= 45000 {
		nextState().
	}
}

LOCAL FUNCTION pitchUp {
	PRINT "State: Pitch Up" AT (1,1).
	PRINT "Stage: " + stag AT (1,2).
	PRINT "Alt:   " + SHIP:ALTITUDE AT (1,3).
	PRINT "Apo:   " + SHIP:OBT:APOAPSIS AT (1,4).
	PRINT "ETA:   " + ETA:APOAPSIS AT (1,5).
	SET pitchPID:SETPOINT TO 40.
	IF ETA:APOAPSIS > SHIP:OBT:PERIOD/2{
		pitchPID:UPDATE(TIME:SECONDS, ETA:APOAPSIS - SHIP:OBT:PERIOD).
	} ELSE {
		pitchPID:UPDATE(TIME:SECONDS, ETA:APOAPSIS).
	}
	LOCK STEERING TO HEADING(lHead, vecPitch(SHIP:VELOCITY:SURFACE) + pitchPID:OUTPUT).
	IF SHIP:OBT:APOAPSIS >= targApo {
		nextState().
	}
}

LOCAL FUNCTION MECO {
	UNLOCK STEERING .
	UNLOCK THROTTLE .
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
	SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
	nextState().
}

// STAGES:

LOCAL FUNCTION beforeAscent {
	RETURN state > 0.
}
