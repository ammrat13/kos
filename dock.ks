// PARAMETERS:
LOCAL holdDist TO 30.
LOCAL holdTol TO .3.
LOCAL speed TO 0.25.


// HELPER FUNCTIONS:
LOCAL FUNCTION translate {
	DECLARE PARAMETER v.
	IF v:MAG > 1 {
		SET v TO v:NORMALIZED.
	}

	SET SHIP:CONTROL:FORE TO VDOT(SHIP:FACING:FOREVECTOR, v).
	SET SHIP:CONTROL:STARBOARD TO VDOT(SHIP:FACING:STARVECTOR, v).
	SET SHIP:CONTROL:TOP TO VDOT(SHIP:FACING:TOPVECTOR, v).
}

LOCAL FUNCTION translateTo {
	DECLARE PARAMETER x.
	translate(x:NORMALIZED*speed - (SHIP:OBT:VELOCITY:ORBIT - TARGET:SHIP:OBT:VELOCITY:ORBIT)).
}


// Credit to CheersKevin

LOCK STEERING TO LOOKDIRUP(-1*TARGET:FACING:FOREVECTOR, TARGET:FACING:TOPVECTOR).
LOCK relPos TO TARGET:POSITION - SHIP:POSITION.

CLEARSCREEN.

IF VANG(TARGET:FACING:FOREVECTOR, relPos) < 90 {
	PRINT "Performing sideswipe.".
	IF VANG(TARGET:FACING:STARVECTOR, relPos) < 90 {
		UNTIL (relPos - TARGET:FACING:STARVECTOR*holdDist):MAG <= holdTol{
			translateTo(relPos - TARGET:FACING:STARVECTOR*holdDist).
		}
	} ELSE {
		UNTIL (relPos + TARGET:FACING:STARVECTOR*holdDist) <= holdTol{
			translateTo(relPos + TARGET:FACING:STARVECTOR*holdDist).
		}
	}
}

PRINT "Translating in front of port.".
UNTIL (relPos + TARGET:FACING:FOREVECTOR*holdDist):MAG <= holdTol {
	translateTo(relPos + TARGET:FACING:FOREVECTOR*holdDist).
}

PRINT "Docking".
UNTIL NOT HASTARGET {
	translateTo(relPos).
}

UNLOCK STEERING .
UNLOCK THROTTLE .
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
SET SHIP:CONTROL:NEUTRALIZE TO TRUE.