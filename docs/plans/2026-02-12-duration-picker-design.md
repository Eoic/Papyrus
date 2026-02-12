# Duration picker and formatted time display for reading goals

## Problem

When the goal type is reading time, users enter a raw number of minutes in a plain text field. This is unintuitive for larger values and the display is awkward — "6000 of 6000 minutes" is hard to parse at a glance. We need a proper duration picker and natural formatting like "1h 30m".

## Decisions

- **Picker style:** Stepper with preset chips (not dropdowns or free text)
- **Preset chips:** 15m, 30m, 1h, 2h
- **Display format:** Short format everywhere — "1h 30m"
- **Progress text:** "45m of 1h 30m" (both values formatted)

## Design

### Duration formatting utility

A top-level `formatDuration(int minutes)` function in `reading_goal.dart`.

Rules:
- `0` → `"0m"`
- `1-59` → `"30m"` (minutes only)
- `60` → `"1h"` (exact hours, no "0m")
- `61-119` → `"1h 5m"` (hours + minutes)
- `120` → `"2h"`
- `6000` → `"100h"` (handles large yearly values)

### Duration picker widget

Replaces the plain `TextFormField` when `GoalType.minutes` is selected. Books and pages keep the existing text field.

Two parts:

**Preset chips row:** Four `ChoiceChip` widgets in a `Wrap` — 15m, 30m, 1h, 2h. Tapping one sets the value immediately. If the user adjusts via stepper to a non-preset value, no chip is selected.

**Stepper row:** Centered formatted duration display (e.g., "1h 30m") flanked by `-` and `+` `IconButton`s.

Increment logic:
- Under 60 min: steps of 5 minutes
- 60 min and above: steps of 15 minutes
- Minimum: 5 minutes
- No hard maximum

Layout in the form:
```
[Goal type dropdown]
[Duration presets row]       ← chips: 15m, 30m, 1h, 2h
[  -    1h 30m    +  ]      ← stepper with formatted display
[Period selector]
```

State: local `int _durationMinutes` variable instead of `_targetController` for minutes goals.

### Display changes

| Location | Before | After |
|---|---|---|
| GoalCard progress | 45 of 90 minutes | 45m of 1h 30m |
| GoalCard footer | 15 minutes to go | 15m to go |
| GoalCard description | Read 90 minutes daily | Read 1h 30m daily |
| ActiveGoalDetailsSheet progress | 45 of 90 minutes | 45m of 1h 30m |
| ActiveGoalDetailsSheet target | 90 minutes | 1h 30m |
| ActiveGoalDetailsSheet edit | TextFormField | Duration stepper |
| CompletedGoalChip cards | 6000 minutes | 100h |
| CompletedGoalChip details | 6000 of 6000 minutes | 100h of 100h |
| Dashboard ReadingGoalCard | 45/90 | 45m/1h 30m |
| ReadingGoal.description | Read 90 minutes daily | Read 1h 30m daily |
| ReadingGoal.statusText | 45 minutes to go | 45m to go |

## Files to modify

| File | Change |
|---|---|
| `reading_goal.dart` | Add `formatDuration()`. Update `description` and `statusText` for minutes goals. |
| `goal_card.dart` | Use `formatDuration()` in progress values and footer for minutes goals. |
| `add_goal_sheet.dart` | Replace TextFormField with duration stepper + presets for minutes goals. Add `_durationMinutes` state. |
| `active_goal_details_sheet.dart` | Replace progress/target fields with stepper for minutes goals. Format display text. |
| `completed_goal_chip.dart` | Use `formatDuration()` for target display in all views. |
| `reading_goal_card.dart` | Use `formatDuration()` for dashboard compact display. |

## What doesn't change

- Model stores `targetValue` and `currentValue` as raw `int` minutes — no schema or serialization changes
- `GoalType.minutes`, `typeLabel`, `periodLabel` — unchanged
- Books and pages goals — untouched
- Provider, DataStore, routing — no changes

## Testing

- New test group for `formatDuration()` with edge cases: 0, 1, 59, 60, 61, 120, 6000
- Verify `description` and `statusText` getters output formatted strings for minutes goals
