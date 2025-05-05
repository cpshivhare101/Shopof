# LeagueEventsSchedulerService Documentation

## Overview
The `LeagueEventsSchedulerService` is a Ruby service designed to schedule matches for a sports league based on provided parameters. It ensures that each team plays the minimum required number of games, respects team and resource availability, handles double header rules, and avoids scheduling conflicts. The service is modular, well-commented, and easy to modify for additional requirements.

This service is particularly useful for automating the creation of match schedules while adhering to constraints such as:
- Minimum games per team.
- Team and resource availability.
- Frequency limits (e.g., maximum games per day).
- Double header rules (optional).

## Purpose
The service generates a list of scheduled matches in a structured format, ensuring fairness in resource allocation and compliance with league rules. It is designed to be:
- **Simple**: Easy to understand and use.
- **Flexible**: Supports custom availability and scheduling rules.
- **Maintainable**: Well-documented with modular methods for easy updates.

## Class Definition
The service is implemented as a Ruby class `LeagueEventsSchedulerService` in the file `league_events_scheduler_service.rb`.

```ruby
require 'date'
require 'time'

class LeagueEventsSchedulerService
  # Methods and logic as implemented
end
```

## Input Parameters
The service is initialized with three parameters:

### 1. `league_params` (Hash)
A hash containing league configuration details.

| Key                     | Type   | Description                                                                 | Required | Default Value                     |
|-------------------------|--------|-----------------------------------------------------------------------------|----------|-----------------------------------|
| `league_start_date`     | String | Start date of the league (format: "YYYY-MM-DD").                           | No       | Current date (`Date.today`)       |
| `end_date`              | String | End date of the league (format: "YYYY-MM-DD").                             | No       | Start date + 90 days             |
| `min_games_per_team`    | Integer| Minimum number of games each team must play.                               | No       | 5                                |
| `game_duration`         | Integer| Duration of each game in minutes.                                          | No       | 60                               |
| `number_of_teams`       | Integer| Number of teams in the league.                                             | Yes      | None                             |
| `resources`             | Array  | List of available resources (e.g., ["Court 1", "Court 2"]).                | Yes      | None                             |
| `games`                 | String | Frequency of games (e.g., "daily", "weekly", "monthly").                   | No       | "daily"                          |
| `team_can_play`         | Integer| Maximum number of games a team can play per frequency period.              | No       | Infinity                         |
| `double_headers`        | Hash   | Double header rules (keys: `apply`, `force`, `same_resource`).              | No       | `{ apply: false, force: false, same_resource: false }` |

#### Double Header Rules
- `apply` (Boolean): Whether double headers are allowed.
- `force` (Boolean): If `true`, double headers are mandatory (requires a back-to-back match).
- `same_resource` (Boolean): If `true`, both matches in a double header must use the same resource.

**Example**:
```ruby
league_params = {
  league_start_date: "2025-05-29",
  number_of_teams: 2,
  resources: ["Court 1", "Court 2"],
  min_games_per_team: 2,
  game_duration: 60,
  games: "daily",
  team_can_play: 2,
  double_headers: { apply: false, force: false, same_resource: false }
}
```

### 2. `resources_availability_or_not` (Array<Hash>)
An array of hashes defining resource availability rules. If empty, defaults to 9:00 AM to 5:00 PM daily for all resources.

| Key          | Type   | Description                                                       |
|--------------|--------|-------------------------------------------------------------------|
| `resource`   | String | Name of the resource (e.g., "Court 1").                           |
| `availability` | Array  | List of availability rules (each with `day`, `from`, `till`, `can_play`). |

**Availability Rule Fields**:
- `day` (String): Day of the week (e.g., "Monday").
- `from` (String): Start time (e.g., "09:00").
- `till` (String): End time (e.g., "17:00").
- `can_play` (Boolean): Whether the resource is available.

**Example**:
```ruby
resources_availability = [
  { resource: "Court 1", availability: [{ day: "Monday", from: "09:00", till: "17:00", can_play: true }] }
]
```

### 3. `teams_availability_or_not` (Array<Hash>)
An array of hashes defining team availability rules. If empty, defaults to 9:00 AM to 5:00 PM daily on all resources.

| Key                   | Type   | Description                                                       |
|-----------------------|--------|-------------------------------------------------------------------|
| `team`                | String | Name of the team (e.g., "Team 1").                               |
| `availability`        | Array  | List of availability rules (each with `day`, `from`, `till`, `can_play`). |
| `resources`           | Array  | List of allowed resources (e.g., ["Court 1"]).                    |
| `cannot_play_against` | Array  | List of teams the team cannot play against.                      |

**Example**:
```ruby
teams_availability = [
  { team: "Team 1", availability: [{ day: "Monday", from: "09:00", till: "17:00", can_play: true }], resources: ["Court 1"] }
]
```

## Output
The service returns an array of hashes, where each hash represents a scheduled match with the following fields:

| Field        | Type     | Description                                     |
|--------------|----------|-------------------------------------------------|
| `home`       | String   | Name of the home team (e.g., "Team 1").         |
| `away`       | String   | Name of the away team (e.g., "Team 2").         |
| `resource`   | String   | Resource used (e.g., "Court 1").                |
| `date`       | Date     | Date of the match.                              |
| `start_time` | Time     | Start time of the match.                        |
| `end_time`   | Time     | End time of the match.                          |
| `duration`   | Integer  | Duration of the match in minutes.               |

**Example Output**:
```ruby
[
  {
    home: "Team 1",
    away: "Team 2",
    resource: "Court 1",
    date: Date.parse("2025-05-29"),
    start_time: Time.parse("2025-05-29 09:00:00"),
    end_time: Time.parse("2025-05-29 10:00:00"),
    duration: 60
  },
  {
    home: "Team 1",
    away: "Team 2",
    resource: "Court 1",
    date: Date.parse("2025-05-29"),
    start_time: Time.parse("2025-05-29 10:00:00"),
    end_time: Time.parse("2025-05-29 11:00:00"),
    duration: 60
  }
]
```

## Scheduling Logic
The service follows a structured algorithm to schedule matches:

1. **Initialization**:
   - Loads input parameters and sets defaults.
   - Generates team names (e.g., "Team 1", "Team 2") based on `number_of_teams`.
   - Initializes an in-memory events table to track scheduled matches and avoid conflicts.

2. **Team Pair Generation**:
   - Generates unique team pairs (e.g., ["Team 1", "Team 2"]) using combinations to avoid duplicates (e.g., ["Team 2", "Team 1"]).
   - Respects `cannot_play_against` restrictions.

3. **Scheduling Loop**:
   - Iterates through dates from `league_start_date` to `end_date`.
   - Continues until all teams have played at least `min_games_per_team`.
   - For each date:
     - Generates available time slots based on resource availability (default: 9:00 AM to 5:00 PM).
     - Tracks games played per team in the current frequency period (e.g., day) using `team_can_play`.
     - Attempts to schedule matches for all possible pairs until slots or frequency limits are exhausted.

4. **Match Scheduling**:
   - For each team pair:
     - Checks if both teams need more games (`games_played < min_games_per_team`).
     - Verifies frequency limits (`team_can_play`).
     - Ensures both teams and the selected resource are available.
     - Checks for conflicts in the events table.
     - Schedules the match and updates tracking (games played, events table).
   - If `double_headers.apply: true`:
     - Attempts to schedule a back-to-back match (mandatory if `force: true`).
     - Uses the same resource if `same_resource: true`.
   - If `double_headers.apply: false`:
     - Ignores double header rules and schedules matches normally, allowing multiple matches per day if `team_can_play` permits.

5. **Output**:
   - Returns the list of scheduled matches.

## Key Rules
- **Minimum Games**: Each team must play at least `min_games_per_team` games.
- **Availability**:
  - Teams and resources must be available at the scheduled time and date.
  - Defaults to 9:00 AM to 5:00 PM daily if no rules are provided.
- **Frequency Limits**:
  - `team_can_play` limits the number of games a team can play per frequency period (e.g., 2 games per day).
- **Double Headers**:
  - If `apply: false`, double header rules are ignored, and multiple matches can be scheduled in a day if `team_can_play` allows.
  - If `apply: true`, back-to-back matches are scheduled (mandatory if `force: true`).
- **Conflicts**:
  - No team or resource can be double-booked at the same time.

## Usage Example
Below is an example of how to use the service with a test case.

```ruby
def self.call_test
  league_params = {
    league_start_date: "2025-05-29",
    number_of_teams: 2,
    resources: ["Court 1", "Court 2"],
    min_games_per_team: 2,
    game_duration: 60,
    games: "daily",
    team_can_play: 2,
    double_headers: { apply: false, force: false, same_resource: false }
  }
  resources_availability = []
  teams_availability = []
  
  service = LeagueEventsSchedulerService.new(league_params, resources_availability, teams_availability)
  matches = service.schedule_matches
  puts matches
end
```

**Expected Output**:
```ruby
[
  {
    home: "Team 1",
    away: "Team 2",
    resource: "Court 1",
    date: Date.parse("2025-05-29"),
    start_time: Time.parse("2025-05-29 09:00:00"),
    end_time: Time.parse("2025-05-29 10:00:00"),
    duration: 60
  },
  {
    home: "Team 1",
    away: "Team 2",
    resource: "Court 1",
    date: Date.parse("2025-05-29"),
    start_time: Time.parse("2025-05-29 10:00:00"),
    end_time: Time.parse("2025-05-29 11:00:00"),
    duration: 60
  }
]
```

**Explanation**:
- Two teams (`Team 1`, `Team 2`) each need 2 games.
- `team_can_play: 2` allows up to 2 games per team per day.
- `double_headers.apply: false` means double header rules are ignored, and both matches are scheduled on the same day (2025-05-29) at 9:00 AM and 10:00 AM.
- Default availability (9:00 AM to 5:00 PM) ensures slots are available.

## Common Issues and Solutions

### Issue: Empty Output (`[]`)
**Symptoms**:
- The service returns an empty array, indicating no matches were scheduled.

**Possible Causes**:
1. **Incompatible Availability**:
   - Team or resource availability rules are too restrictive (e.g., teams are never available at the same time).
   - Example: `Team 1` is only available on Monday, and `Team 2` is only available on Tuesday.
2. **Frequency Limits**:
   - `team_can_play` is set too low, preventing enough matches from being scheduled.
3. **Double Header Restrictions**:
   - If `double_headers.force: true`, and no back-to-back match is possible, matches may not be scheduled.

**Solutions**:
- Check `teams_availability` and `resources_availability` to ensure overlapping availability.
- Increase `team_can_play` or adjust `double_headers` settings.
- Use default availability (empty arrays) for testing:
  ```ruby
  resources_availability = []
  teams_availability = []
  ```

### Issue: Matches Scheduled on Different Days When They Should Be on the Same Day
**Symptoms**:
- Matches are spread across multiple days (e.g., one on 2025-05-29, another on 2025-05-30) when they should be on the same day.

**Cause**:
- The service was not fully utilizing available slots in a single day, especially when `team_can_play` allows multiple matches.

**Solution**:
- The updated service includes an inner loop in `schedule_matches` to schedule multiple matches per day until slots or frequency limits are exhausted.

### Issue: Double Header Rules Applied When `apply: false`
**Symptoms**:
- Back-to-back matches are not scheduled when `double_headers.apply: false`, even though `team_can_play` allows multiple matches.

**Solution**:
- The service ignores double header rules when `apply: false` and schedules matches normally, allowing multiple matches per day if `team_can_play` permits.

## Notes
- **Time Zone**: The service uses UTC for `Time.parse`. For specific time zones (e.g., IST), modify `Time.parse` to include the offset (e.g., `+05:30`).
- **Resource Rotation**: Currently, the first available resource is chosen. To rotate resources, modify the `schedule_match` method to prioritize less-used resources.
- **Database Integration**: The events table is in-memory. For a database, update `has_conflict?` with ActiveRecord queries.
- **Error Handling**: Basic validation is included (e.g., `number_of_teams` and `resources` are required). Add more as needed.

## Future Enhancements
- Add resource rotation for balanced usage.
- Support complex availability rules (e.g., `repeats`, `effective_from`).
- Include logging for debugging scheduling decisions.
- Add validation for input parameters to catch edge cases.

## Conclusion
The `LeagueEventsSchedulerService` provides a robust and flexible solution for scheduling league matches. It handles various constraints while remaining easy to understand and modify. For further assistance or customization, refer to the source code comments or contact the development team.
