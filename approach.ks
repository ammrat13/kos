// PARAMETERS:
LOCAL triggerDist TO 3000.
LOCAL stopDist TO 200.
LOCAL approachVel TO 5.
LOCAL stopTol TO 0.5.
LOCAL angTol TO 1.


// HELPER VARIABLES:
LOCAL prevDist TO triggerDist.


// HELPER FUNCTIONS:
LOCAL FUNCTION bTime {
	DECLARE PARAMETER dv.
	DECLARE PARAMETER pri.
	
	LOCAL thrust TO 0.
	LOCAL flow TO 0.
	FOR p IN SHIP:PARTS {
		IF p:HASMODULE("ModuleEnginesFX") AND p:ISP <> 0 {
			SET thrust TO thrust + p:AVAILABLETHRUST.
			SET flow TO flow + p:AVAILABLETHRUST / (9.80665 * p:ISP).
		}
	}
	LOCAL avgIsp TO thrust / (9.80665 * flow).

	IF pri {
		PRINT "Thrust: " + thrust.
		PRINT "Isp:    " + avgIsp.
	}

	RETURN (avgIsp*9.80665)/thrust * (SHIP:MASS - SHIP:MASS * CONSTANT:E^(-1 * dv / (9.80665 * avgIsp))).
}


IF HASTARGET {
	CLEARSCREEN.

	UNTIL TARGET:POSITION:MAG <= triggerDist {
		PRINT "State: Waiting for close approach" AT (1,1).
		PRINT "Dist:  " + (TARGET:POSITION - SHIP:POSITION):MAG AT (1,2).
	}

	UNTIL TARGET:POSITION:MAG <= stopDist {
		CLEARSCREEN.

		UNTIL (TARGET:OBT:VELOCITY:ORBIT - SHIP:OBT:VELOCITY:ORBIT):MAG <= stopTol {
			PRINT "State: Killing relative velocity" AT (1,1).
			PRINT "Dist:  " + (TARGET:POSITION - SHIP:POSITION):MAG AT (1,2).
			PRINT "Angle: " + VANG(TARGET:OBT:VELOCITY:ORBIT - SHIP:OBT:VELOCITY:ORBIT, SHIP:FACING:FOREVECTOR) AT (1,3).
			PRINT "Vel:   " + (TARGET:OBT:VELOCITY:ORBIT - SHIP:OBT:VELOCITY:ORBIT):MAG AT (1,4).
			LOCK STEERING TO TARGET:OBT:VELOCITY:ORBIT - SHIP:OBT:VELOCITY:ORBIT.
			IF VANG(TARGET:OBT:VELOCITY:ORBIT - SHIP:OBT:VELOCITY:ORBIT, SHIP:FACING:FOREVECTOR) < angTol {
				LOCK THROTTLE TO MIN(1,bTime((TARGET:OBT:VELOCITY:ORBIT - SHIP:OBT:VELOCITY:ORBIT):MAG, FALSE)).	
			} ELSE {
				LOCK THROTTLE TO 0.
			}
		}

		CLEARSCREEN.
		LOCK THROTTLE TO 0.

		IF(TARGET:POSITION - SHIP:POSITION):MAG <= stopDist {
			BREAK.
		}

		UNTIL (TARGET:OBT:VELOCITY:ORBIT - SHIP:OBT:VELOCITY:ORBIT):MAG >= approachVel OR (TARGET:POSITION - SHIP:POSITION):MAG <= stopDist OR (TARGET:POSITION - SHIP:POSITION):MAG > prevDist {
			PRINT "State: Moving towards target" AT (1,1).
			PRINT "Dist:  " + (TARGET:POSITION - SHIP:POSITION):MAG AT (1,2).
			PRINT "Angle: " + VANG(TARGET:POSITION, SHIP:FACING:FOREVECTOR) AT (1,3).
			PRINT "Vel:   " + (TARGET:OBT:VELOCITY:ORBIT - SHIP:OBT:VELOCITY:ORBIT):MAG AT (1,4).
			LOCK STEERING TO (TARGET:POSITION - SHIP:POSITION).
			IF VANG((TARGET:POSITION - SHIP:POSITION), SHIP:FACING:FOREVECTOR) < angTol {
				LOCK THROTTLE TO 1.
			} ELSE {
				LOCK THROTTLE TO 0.
			}
			SET prevDist TO (TARGET:POSITION - SHIP:POSITION):MAG.
			WAIT 0.
		}

		CLEARSCREEN.
		LOCK THROTTLE TO 0.

		UNTIL (TARGET:POSITION - SHIP:POSITION):MAG <= stopDist OR (TARGET:POSITION - SHIP:POSITION):MAG > prevDist {
			PRINT "State: Waiting" AT (1,1).
			PRINT "Dist:  " + (TARGET:POSITION - SHIP:POSITION):MAG AT (1,2).
			PRINT "Vel:   " + (TARGET:OBT:VELOCITY:ORBIT - SHIP:OBT:VELOCITY:ORBIT):MAG AT (1,3).
			SET prevDist TO (TARGET:POSITION - SHIP:POSITION):MAG.
			WAIT 0.
		}

		CLEARSCREEN.
	}

	UNTIL (TARGET:OBT:VELOCITY:ORBIT - SHIP:OBT:VELOCITY:ORBIT):MAG < stopTol {
		PRINT "State: Killing relative velocity" AT (1,1).
		PRINT "Dist:  " + (TARGET:POSITION - SHIP:POSITION):MAG AT (1,2).
		PRINT "Angle: " + VANG(TARGET:OBT:VELOCITY:ORBIT - SHIP:OBT:VELOCITY:ORBIT, SHIP:FACING:FOREVECTOR) AT (1,3).
		PRINT "Vel:   " + (TARGET:OBT:VELOCITY:ORBIT - SHIP:OBT:VELOCITY:ORBIT):MAG AT (1,4).
		LOCK STEERING TO TARGET:OBT:VELOCITY:ORBIT - SHIP:OBT:VELOCITY:ORBIT.
		IF VANG(TARGET:OBT:VELOCITY:ORBIT - SHIP:OBT:VELOCITY:ORBIT, SHIP:FACING:FOREVECTOR) < angTol {
			LOCK THROTTLE TO MIN(1,bTime((TARGET:OBT:VELOCITY:ORBIT - SHIP:OBT:VELOCITY:ORBIT):MAG, FALSE)).	
		} ELSE {
			LOCK THROTTLE TO 0.
		}
	}

	UNLOCK STEERING .
	UNLOCK THROTTLE .
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
	SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
} ELSE {
	PRINT "ERROR: Set the target ship before running this script".
}
