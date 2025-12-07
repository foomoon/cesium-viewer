# Altitude constraints

Constraints for altitudes:

- min/max launch altitude
- min/max aim altitude
- min/max waypoint altitude

Constraints for range

- min/max range

Constraints for waypoints

- min/max number of waypointss

Suggested schema fragment (optional on each trajectory):

```json
"constraints": {
  "altitude": {
    "launch": { "min": 0, "max": 1000 },
    "aim": { "min": 0, "max": 12000 },
    "waypoint": { "min": 0, "max": 12000 }
  },
  "range": { "min": 0, "max": 5000 },
  "waypoints": { "min": 0, "max": 10 }
}
```
