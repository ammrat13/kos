CLEARSCREEN.

FUNCTION nodeChangePer {
	DECLARE PARAMETER peTarg.
	LOCAL vAp TO SQRT(SHIP:OBT:BODY:MU * (2/(SHIP:OBT:APOAPSIS + SHIP:OBT:BODY:RADIUS) - 1/SHIP:OBT:SEMIMAJORAXIS)).
	LOCAL aTarg TO ((SHIP:OBT:APOAPSIS + SHIP:OBT:BODY:RADIUS) + (peTarg + SHIP:OBT:BODY:RADIUS)) / 2.
	LOCAL vTarg TO SQRT(SHIP:OBT:BODY:MU * (2/(SHIP:OBT:APOAPSIS + SHIP:OBT:BODY:RADIUS) - 1/aTarg)).
	ADD NODE(TIME:SECONDS + ETA:APOAPSIS, 0, 0, vTarg - vAp).
}.

FUNCTION nodeChangeApo {
	DECLARE PARAMETER apTarg.
	LOCAL vPe TO SQRT(SHIP:OBT:BODY:MU * (2/(SHIP:OBT:PERIAPSIS + SHIP:OBT:BODY:RADIUS) - 1/SHIP:OBT:SEMIMAJORAXIS)).
	LOCAL aTarg TO ((apTarg + SHIP:OBT:BODY:RADIUS) + (SHIP:OBT:PERIAPSIS + SHIP:OBT:BODY:RADIUS)) / 2.
	LOCAL vTarg TO SQRT(SHIP:OBT:BODY:MU * (2/(SHIP:OBT:PERIAPSIS + SHIP:OBT:BODY:RADIUS) - 1/aTarg)).
	ADD NODE(TIME:SECONDS + ETA:PERIAPSIS, 0, 0, vTarg - vAp).
}.

FUNCTION bTime {
	DECLARE PARAMETER nd.
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

	RETURN (avgIsp*9.80665)/thrust * (SHIP:MASS - SHIP:MASS * CONSTANT:E^(-1 * nd:DELTAV:MAG / (9.80665 * avgIsp))).
}

FUNCTION execNode {
	LOCAL nd TO NEXTNODE.
	LOCAL burnDT TO bTime(nd, TRUE).

	PRINT "ETA:    " + nd:ETA.
	PRINT "Burn:   " + burnDT.

	LOCK STEERING TO LOOKDIRUP(nd:DELTAV, SHIP:FACING:TOPVECTOR).
	WAIT UNTIL VANG(SHIP:FACING:FOREVECTOR, nd:DELTAV) < 1.
	WAIT UNTIL nd:ETA <= burnDT/2.

	LOCAL dv0 TO nd:DELTAV.
	LOCK THROTTLE TO MIN(1,bTime(nd, FALSE)).
	WAIT UNTIL VDOT(dv0:NORMALIZED,nd:DELTAV) <= 0.1.

	UNLOCK STEERING .
	UNLOCK THROTTLE .
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
	SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
	REMOVE nd.
}

execNode().
