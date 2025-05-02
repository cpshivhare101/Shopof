# LeagueEventsSchedulerService Documentation

This document outlines the requirements, logic, input/output specifications, constraints, and test cases for the `LeagueEventsSchedulerService`, a Ruby class designed to schedule matches for a sports league. It ensures that all teams play the required number of games, matches are distributed across available resources (courts), and scheduling rules are adhered to. This document is intended to be comprehensive, enabling both AI (e.g., Grok) and human developers to understand the logic and implement the service correctly without repeated clarifications.

## 1. Purpose
The `LeagueEventsSchedulerService` schedules matches for a sports league based on:
- League parameters (e.g., start date, number of teams, minimum games per team).
- Team and resource (court) availability.
- Scheduling rules (e.g., no duplicate matchups, double-header permissions).

The service generates a list of scheduled matches (events) stored in an array (or database in production) and ensures:
- Each team plays exactly the specified minimum number of games.
- Matches are unique (no duplicate matchups, e.g., Team 1 vs Team 2 only once).
- Matches are evenly distributed across available courts (one match per court when possible).
- All scheduling constraints (e.g., availability, conflicts) are respected.

## 2. Requirements
The service must meet the following requirements:
1. **Unique Matchups**:
   - Each matchup (e.g., Team 1 vs Team 2) must be scheduled exactly once. No duplicate matchups are allowed in the output.
2. **Team Game Distribution**:
   - Each team must play exactly `min_games_per_team` games (e.g., 2 games for 4 teams, requiring 4 matches).
   - No team should be excluded (e.g., Team 4 must not be omitted).
   - No team should play more than `min_games_per_team` games unless explicitly allowed.
3. **Resource (Court) Distribution**:
   - Matches must be distributed across available courts, with a preference for one match per court when the number of matches equals the number of courts (e.g., 4 matches on 4 courts).
   - Courts should be used as evenly as possible, tracked via `resource_usage`.
4. **Scheduling Constraints**:
   - Matches must respect team and court availability (e.g., teams and courts available on specific days/times).
   - No simultaneous conflicts (teams restricted by `cannot_play_at_same_time_as_another_team` cannot play at the same time).
   - Double-headers (multiple games per team on the same day) are allowed only if `double_headers: true`.
   - No event conflicts (matches must not overlap with existing events in the database, if enabled).
5. **Logging and Debugging**:
   - The service must include detailed logging for debugging, especially for:
     - Generated matchups.
     - Validation checks (e.g., `valid_matchup?`, `teams_available?`).
     - Team game counts (`team_games`).
     - Resource usage (`resource_usage`).
   - Logs must indicate why a matchup is rejected (e.g., team unavailable, conflict detected).
6. **Performance**:
   - The scheduler should minimize iterations by prioritizing teams with fewer games and least-used courts.
   - It should stop once the minimum required matches (`minimum_total_games`) are scheduled.

## 3. Input Specification
The service accepts a hash with three keys:
- `league_params`: League configuration.
- `resources_availability_or_not`: Court availability rules.
- `teams_availability_or_not`: Team availability and restrictions.

### Example Input
```ruby
{
  league_params: {
    league_start_date: "2025-05-05", # YYYY-MM-DD, e.g., Monday
    min_games_per_team: 2, # Each team plays 2 games
    game_duration: 60, # Minutes
    resources: ["Court 1", "Court 2", "Court 3", "Court 4"], # Available courts
    number_of_teams: 4, # Teams named "Team 1", "Team 2", etc.
    frequency: "weekly", # Scheduling period: daily, weekly, monthly
    games: 4, # Max matches per period (e.g., per week)
    double_headers: true # Allow multiple games per team per day
  },
  resources_availability_or_not: [
    {
      resource_id: 12,
      resource_name: "Court 1",
      availabilities: [
        {
          day: ["Monday"],
          from: "10:00 AM",
          till: "12:00 PM",
          effective_from: "2025-05-05",
          repeats: "weekly",
          can_play: true
        }
      ]
    },
    # Similar entries for Court 2 (resource_id: 13), Court 3 (resource_id: 14), Court 4 (resource_id: 15)
  ],
  teams_availability_or_not: [
    {
      team_id: 1,
      team_name: "Team 1",
      availabilities: [
        {
          day: ["Monday"],
          from: "10:00 AM",
          till: "12:00 PM",
          effective_from: "2025-05-05",
          repeats: "weekly",
          can_play: true
        }
      ],
      resources: ["Court 1", "Court 2", "Court 3", "Court 4"], # Can play on all courts
      cannot_play_against: [], # No restrictions
      cannot_play_at_same_time_as_another_team: [] # No simultaneous restrictions
    },
    # Similar entries for Team 2 (team_id: 2), Team 3 (team_id: 3), Team 4 (team_id: 4)
  ]
}
```

### Input Constraints
- `league_start_date`: Must be in `YYYY-MM-DD` format.
- `min_games_per_team`: Non-negative integer (e.g., 2).
- `game_duration`: Positive integer in minutes (e.g., 60).
- `resources`: Array of strings (court names).
- `number_of_teams`: Integer > 1 (e.g., 4).
- `frequency`: One of `["daily", "weekly", "monthly"]`.
- `games`: Positive integer (e.g., 4).
- `double_headers`: Boolean (`true` or `false`).
- `resources_availability_or_not`: Array of hashes with `resource_id`, `resource_name`, and `availabilities` (day, time, `can_play`).
- `teams_availability_or_not`: Array of hashes with `team_id`, `team_name`, `availabilities`, `resources`, `cannot_play_against`, and `cannot_play_at_same_time_as_another_team`.
- All `can_play` values in an availability array must be identical (all `true` or all `false`).

## 4. Output Specification
The service returns an array of event hashes, each representing a scheduled match with:
- `home`: Home team name (e.g., "Team 1").
- `away`: Away team name (e.g., "Team 2").
- `resource`: Court name (e.g., "Court 1").
- `date`: Date object (e.g., `Date.parse("2025-05-05")`).
- `start_time`: Time object (e.g., `Time.parse("2025-05-05 10:00:00")`).
- `end_time`: Time object (e.g., `Time.parse("2025-05-05 11:00:00")`).
- `duration`: Integer (e.g., 60 minutes).

### Example Output
For the input above (`min_games_per_team: 2`, `number_of_teams: 4`, `games: 4`):
```ruby
[
  {
    home: "Team 1",
    away: "Team 2",
    resource: "Court 1",
    date: Date.parse("2025-05-05"),
    start_time: Time.parse("2025-05-05 10:00:00"),
    end_time: Time.parse("2025-05-05 11:00:00"),
    duration: 60
  },
  {
    home: "Team 3",
    away: "Team 4",
    resource: "Court 2",
    date: Date.parse("2025-05-05"),
    start_time: Time.parse("2025-05-05 10:00:00"),
    end_time: Time.parse("2025-05-05 11:00:00"),
    duration: 60
  },
  {
    home: "Team 1",
    away: "Team 3",
    resource: "Court 3",
    date: Date.parse("2025-05-05"),
    start_time: Time.parse("2025-05-05 10:00:00"),
    end_time: Time.parse("2025-05-05 11:00:00"),
    duration: 60
  },
  {
    home: "Team 2",
    away: "Team 4",
    resource: "Court 4",
    date: Date.parse("2025-05-05"),
    start_time: Time.parse("2025-05-05 10:00:00"),
    end_time: Time.parse("2025-05-05 11:00:00"),
    duration: 60
  }
]
```

### Output Constraints
- **Uniqueness**: No duplicate matchups (e.g., Team 1 vs Team 2 appears only once).
- **Team Games**: Each team plays exactly `min_games_per_team` games (e.g., 2 games for 4 teams).
- **Court Distribution**: Matches are assigned to unique courts (e.g., 4 matches on 4 courts).
- **Time Slots**: Matches fit within available time slots (e.g., 10:00 AM to 12:00 PM, 60-minute duration).
- **Validation**: Matches respect all availability and conflict rules.

## 5. Core Logic
The service follows this logic to schedule matches:

### 5.1. Initialization
- Validate input parameters (e.g., `league_start_date` format, `min_games_per_team` non-negative).
- Generate team names (e.g., `["Team 1", "Team 2", "Team 3", "Team 4"]` for `number_of_teams: 4`).
- Validate availability rules (all `can_play` values in each availability array must be identical).

### 5.2. Matchup Generation
- Generate all possible team pairs using `teams.combination(2)` (e.g., `[["Team 1", "Team 2"], ["Team 1", "Team 3"], ["Team 1", "Team 4"], ["Team 2", "Team 3"], ["Team 2", "Team 4"], ["Team 3", "Team 4"]]`).
- Exclude pairs restricted by `cannot_play_against` (none in the example).

### 5.3. Minimum Total Games
- Calculate total matches needed:
  ```ruby
  minimum_total_games = (number_of_teams * min_games_per_team) / 2
  ```
  - Example: `(4 * 2) / 2 = 4` matches for 4 teams with 2 games each.

### 5.4. Available Slots
- For each date (starting from `league_start_date`), generate available slots based on `resources_availability_or_not`:
  - Each court is available from `from` to `till` (e.g., 10:00 AM to 12:00 PM).
  - With `game_duration: 60`, each court provides 2 slots (10:00-11:00, 11:00-12:00).
  - Total slots: 4 courts × 2 slots = 8 slots per day.
- Sort slots by `resource_usage` (least used courts first) and `start_time` for even distribution.

### 5.5. Scheduling Loop
- Initialize:
  - `scheduled_matches`: Empty array to store events.
  - `resource_usage`: Hash to track court usage (e.g., `{ "Court 1" => 0, ... }`).
  - `team_games`: Hash to track games per team (e.g., `{ "Team 1" => 0, ... }`).
  - `current_date`: `league_start_date` (e.g., 2025-05-05).
  - `games_per_period`: `max(games, minimum_total_games)` (e.g., `max(4, 4) = 4`).
- Loop until `scheduled_matches.size >= minimum_total_games` or `current_date > end_date` (1 year later):
  - Get available slots for `current_date`.
  - For each slot:
    - Find a valid matchup prioritizing teams with fewer games (using `team_games`).
    - Validate the matchup (`valid_matchup?`):
      - Teams are available (`teams_available?`).
      - Court is compatible (`resource_available_for_teams?`).
      - No event conflicts (`no_event_conflicts?`).
      - No simultaneous conflicts (`no_simultaneous_conflicts?`).
      - Double-header rules satisfied (`double_header_allowed?`).
    - If valid, schedule the match (`schedule_match`):
      - Add to `scheduled_matches`.
      - Update `resource_usage` and `team_games`.
      - Remove the matchup from `matchups` to prevent reuse.
    - Increment `games_scheduled_in_period` (stop at `games_per_period`).
  - Increment `current_date` based on `frequency` (e.g., `+7.days` for weekly).

### 5.6. Validation Methods
- **teams_available?**: Check if both teams are available for the slot based on `availabilities`.
- **resource_available_for_teams?**: Ensure both teams can play on the court.
- **no_event_conflicts?**: Check for overlaps with existing events (disabled in test, returns `true`).
- **no_simultaneous_conflicts?**: Ensure no forbidden teams play at the same time.
- **double_header_allowed?**: Allow multiple games per team if `double_headers: true`.
- **enough_games_scheduled?**: Check if teams have played `min_games_per_team` (used for logging).

### 5.7. Logging
- Log:
  - Generated matchups.
  - Available slots per date.
  - Validation results for each matchup (Valid/Invalid, with reasons).
  - Team games (`team_games`) and resource usage (`resource_usage`) after each match.
  - Scheduled matches with details (home, away, court, time).

## 6. Constraints and Assumptions
- **Constraints**:
  - Matches must fit within available slots (e.g., 10:00 AM to 12:00 PM, 60-minute duration).
  - Each matchup is unique (e.g., Team 1 vs Team 2 only once).
  - Each team plays exactly `min_games_per_team` games.
  - Matches are assigned to unique courts when possible.
- **Assumptions**:
  - All teams and courts are available as per `teams_availability_or_not` and `resources_availability_or_not`.
  - No `cannot_play_against` or `cannot_play_at_same_time_as_another_team` restrictions in the test data.
  - `no_event_conflicts?` returns `true` (database check disabled for testing).
  - `double_headers: true` allows multiple games per team on the same day.
  - Scheduling stops after `minimum_total_games` matches are scheduled.

## 7. Test Cases
### Test Case 1: 4 Matches, 4 Teams, 2 Games Each
- **Input**:
  ```ruby
  league_params: {
    league_start_date: "2025-05-05",
    min_games_per_team: 2,
    game_duration: 60,
    resources: ["Court 1", "Court 2", "Court 3", "Court 4"],
    number_of_teams: 4,
    frequency: "weekly",
    games: 4,
    double_headers: true
  }
  # resources_availability_or_not and teams_availability_or_not as shown in Example Input
  ```
- **Expected Output**:
  ```ruby
  [
    { home: "Team 1", away: "Team 2", resource: "Court 1", date: Date.parse("2025-05-05"), start_time: Time.parse("2025-05-05 10:00:00"), end_time: Time.parse("2025-05-05 11:00:00"), duration: 60 },
    { home: "Team 3", away: "Team 4", resource: "Court 2", date: Date.parse("2025-05-05"), start_time: Time.parse("2025-05-05 10:00:00"), end_time: Time.parse("2025-05-05 11:00:00"), duration: 60 },
    { home: "Team 1", away: "Team 3", resource: "Court 3", date: Date.parse("2025-05-05"), start_time: Time.parse("2025-05-05 10:00:00"), end_time: Time.parse("2025-05-05 11:00:00"), duration: 60 },
    { home: "Team 2", away: "Team 4", resource: "Court 4", date: Date.parse("2025-05-05"), start_time: Time.parse("2025-05-05 10:00:00"), end_time: Time.parse("2025-05-05 11:00:00"), duration: 60 }
  ]
  ```
- **Verification**:
  - 4 unique matchups.
  - Each team plays 2 games: Team 1 (vs Team 2, Team 3), Team 2 (vs Team 1, Team 4), Team 3 (vs Team 1, Team 4), Team 4 (vs Team 3, Team 2).
  - One match per court (Court 1, Court 2, Court 3, Court 4).
  - All matches on 2025-05-05, 10:00-11:00 AM.

### Test Case 2: 5 Matches, 4 Teams, 3 Games Each
- **Input**:
  ```ruby
  league_params: {
    league_start_date: "2025-05-05",
    min_games_per_team: 3,
    game_duration: 60,
    resources: ["Court 1", "Court 2", "Court 3", "Court 4"],
    number_of_teams: 4,
    frequency: "weekly",
    games: 5,
    double_headers: true
  }
  # Same resources_availability_or_not and teams_availability_or_not
  ```
- **Expected Output**:
  ```ruby
  [
    { home: "Team 1", away: "Team 2", resource: "Court 1", date: Date.parse("2025-05-05"), start_time: Time.parse("2025-05-05 10:00:00"), end_time: Time.parse("2025-05-05 11:00:00"), duration: 60 },
    { home: "Team 3", away: "Team 4", resource: "Court 2", date: Date.parse("2025-05-05"), start_time: Time.parse("2025-05-05 10:00:00"), end_time: Time.parse("2025-05-05 11:00:00"), duration: 60 },
    { home: "Team 1", away: "Team 3", resource: "Court 3", date: Date.parse("2025-05-05"), start_time: Time.parse("2025-05-05 10:00:00"), end_time: Time.parse("2025-05-05 11:00:00"), duration: 60 },
    { home: "Team 2", away: "Team 4", resource: "Court 4", date: Date.parse("2025-05-05"), start_time: Time.parse("2025-05-05 10:00:00"), end_time: Time.parse("2025-05-05 11:00:00"), duration: 60 },
    { home: "Team 1", away: "Team 4", resource: "Court 1", date: Date.parse("2025-05-05"), start_time: Time.parse("2025-05-05 11:00:00"), end_time: Time.parse("2025-05-05 12:00:00"), duration: 60 }
  ]
  ```
- **Verification**:
  - 5 unique matchups.
  - Team games: Team 1 (3 games), Team 2 (2 games), Team 3 (2 games), Team 4 (3 games).
  - Note: `min_games_per_team: 3` requires `(4 * 3) / 2 = 6` matches, but `games: 5` limits to 5 matches, so not all teams reach 3 games.
  - Courts: 2 matches on Court 1, 1 each on Court 2, Court 3, Court 4.

## 8. Debugging Guidelines
If the output deviates from expectations (e.g., duplicate matchups, missing teams):
1. **Check Logs**:
   - Verify `Generated matchups` includes all pairs (e.g., `["Team 3", "Team 4"]`).
   - Check `Checking matchup ...: Valid/Invalid` logs for rejected matchups (e.g., why Team 3 vs Team 4 is Invalid).
   - Inspect sub-method logs:
     - `Teams available check`: Ensure all teams return `true` for availability.
     - `No simultaneous conflicts check`: Verify no false positives (should be `true` with empty `cannot_play_at_same_time_as_another_team`).
     - `Double header allowed check`: Should be `true` with `double_headers: true`.
   - Monitor `team_games` to ensure all teams approach `min_games_per_team`.
2. **Verify Slots**:
   - Ensure `Available slots for <date>` lists 8 slots (4 courts × 2 slots).
3. **Share Logs**:
   - Provide full log output, especially validation logs, to identify why matchups are rejected.
4. **Test Edge Cases**:
   - Test with restricted availability (e.g., Team 4 unavailable) to ensure robustness.
   - Test with `double_headers: false` to verify double-header rules.

## 9. Implementation Notes
- **Language**: Ruby (compatible with Rails).
- **Dependencies**: `date`, `time` (for parsing).
- **Database**: `Event.create!` is commented out for testing; enable for production with proper error handling.
- **Time Zone**: Assumes server time zone (e.g., `+0530`); adjust `parse_time` for specific zones.
- **Extensibility**:
  - Add support for `cannot_play_against` and `cannot_play_at_same_time_as_another_team` restrictions.
  - Enable `no_event_conflicts?` for database checks in production.
  - Allow custom matchup selection (e.g., random, priority-based).

## 10. Future Enhancements
- **Random Matchup Selection**: Introduce randomization for matchup selection while maintaining `team_games` balance.
- **Partial Scheduling**: Handle cases where `games` limits matches below `minimum_total_games`.
- **Multi-Day Scheduling**: Distribute matches across multiple days if slots are insufficient.
- **Error Reporting**: Add detailed error messages for failed validations.
- **Performance Optimization**: Cache availability checks for faster iteration.

## 11. References
- **Previous Issues**:
  - Initial code produced duplicate matchups (e.g., Team 1 vs Team 2 twice) and omitted Team 4 due to:
    - Not removing matchups after scheduling.
    - No prioritization of teams with fewer games.
  - Fixed by:
    - Removing matchups immediately after scheduling (`matchups.delete(matchup)`).
    - Adding `team_games` tracking and prioritizing teams with fewer games in `find_valid_matchup`.
- **Test Data**: Based on provided input with 4 teams, 4 courts, and full availability on Mondays 10:00 AM-12:00 PM.

## 12. Contact
For clarifications or issues:
- Share full log output, including validation logs (`valid_matchup?`, `teams_available?`, etc.).
- Provide specific test cases or modified inputs (e.g., `min_games_per_team: 3`).
- Contact via the platform used for this document (e.g., xAI interface).

---

This document ensures that the `LeagueEventsSchedulerService` can be implemented or debugged without repeated clarifications. It captures all requirements, logic, and test cases to produce the expected output (e.g., 4 unique matches with all teams playing 2 games).
