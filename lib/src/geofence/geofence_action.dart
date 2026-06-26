enum GeofenceAction { enter, exit, stayed }

enum GeofenceTriggerStatus { unknown, inside, outside, stayed }

GeofenceTriggerStatus geofenceTriggerStatusFromCode(int code) {
  switch (code) {
    case 1:
      return GeofenceTriggerStatus.inside;
    case 2:
      return GeofenceTriggerStatus.outside;
    case 3:
      return GeofenceTriggerStatus.stayed;
    default:
      return GeofenceTriggerStatus.unknown;
  }
}
