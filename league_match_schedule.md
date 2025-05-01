# LeagueMatchSchedulerService Documentation
## Version: 1.0
## Date: May 01, 2025
## Purpose
This document provides a comprehensive overview of the `LeagueMatchSchedulerService`, a Ruby on Rails service designed to schedule matches for a sports league. It handles league-level configurations, team and resource availability, scheduling constraints, and saves matches to an `events` table. The service ensures fair scheduling, respects restrictions, and generates a list of scheduled events.

---

## Overview
The `LeagueMatchSchedulerService` is responsible for:
- Generating matchups between teams (e.g., Team 1 vs Team 2).
- Scheduling matches based on league rules, such as minimum games per team and frequency limits.
- Respecting team and resource availability/restrictions.
- Handling double headers (back-to-back games without gaps).
- Ensuring no conflicts in the schedule (e.g., no double-booked teams or resources).
- Saving matches to the `events` table using the `Event` model.
- Returning a list of scheduled events with details like home team, away team, resource, date, and times.

---

## Input Data Structure
The service accepts a hash with three main components: league parameters, resource availability, and team availability.

### 1. League Parameters
Provided in `params[:league_params]`:
- `league_start_date`: String, e.g., "2025-04-29" (when the league starts).
- `min_games_per_team`: Integer, e.g., 2 (minimum matches each team must play).
- `game_duration`: Integer, e.g., 60 (match duration in minutes).
- `resources`: Array of strings, e.g., ["Court 1", "Court 2"] (available fields/resources).
- `number_of_teams`: Integer, e.g., 4 (number of teams in the league).
- `teams`: Auto-generated as ["Team 1", "Team 2", ...] based on `number_of_teams`.
- `frequency`: String, e.g., "weekly" ("daily", "weekly", or "monthly"; defines scheduling interval).
- `games`: Integer, e.g., 3 (maximum matches per frequency period, e.g., 3 per week).
- `double_headers`: Boolean, e.g., true (allows back-to-back matches for a team without gaps).

### 2. Resource Availability/Restrictions
Provided in `params[:resources_availability_or_not]` as an array of hashes:
- Each hash represents one resource (e.g., "Court 1") with:
  - `resource_id`: Integer, e.g., 12 (unique ID for the resource).
  - `resource_name`: String, e.g., "Court 1" (matches `league_params[:resources]`).
  - `availabilities`: Array of availability rules, each with:
    - `team_can_play_on`: Array of strings, e.g., ["Monday"] (days when available).
    - `team_can_not_play_on`: Array of strings, e.g., ["Tuesday"] (days when unavailable).
    - `from`: String, e.g., "10:00 AM" (start time of availability/unavailability).
    - `till`: String, e.g., "12:00 PM" (end time of availability/unavailability).
    - `starting`: String, e.g., "2025-04-29" (date when rule starts).
    - `repeats`: String, e.g., "weekly" ("weekly", "monthly", "yearly"; repetition pattern).
    - `can_play`: Boolean, e.g., true (true for available, false for unavailable).

### 3. Team Availability/Restrictions
Provided in `params[:teams_availability_or_not]` as an array of hashes:
- Each hash represents one team (e.g., "Team 1") with:
  - `team_id`: Integer, e.g., 1 (1-based index of the team).
  - `team_name`: String, e.g., "Team 1" (matches generated `teams`).
  - `availabilities`: Array of availability rules (same structure as resource availability).
  - `resources`: Array of strings, e.g., ["Court 1", "Court 2"] (resources the team can use).
  - `cannot_play_against`: Array of strings, e.g., ["Team 2"] (teams this team cannot play).
  - `cannot_play_at_same_time_as_another_team`: Array of strings, e.g., ["Team 4"] (teams that cannot play simultaneously).

### Example Input
```ruby
params = {
  league_params: {
    league_start_date: "2025-04-29",
    min_games_per_team: 2,
    game_duration: 60,
    resources: ["Court 1", "Court 2"],
    number_of_teams: 4,
    frequency: "weekly",
    games: 3,
    double_headers: true
  },
  resources_availability_or_not: [
    {
      resource_id: 12,
      resource_name: "Court 1",
      availabilities: [
        {
          team_can_play_on: ["Monday"],
          from: "10:00 AM",
          till: "12:00 PM",
          starting: "2025-04-29",
          repeats: "weekly",
          can_play: true
        }
      ]
    }
  ],
  teams_availability_or_not: [
    {
      team_id: 1,
      team_name: "Team 1",
      availabilities: [
        {
          team_can_play_on: ["Monday"],
          from: "10:00 AM",
          till: "12:00 PM",
          starting: "2025-04-29",
          repeats: "weekly",
          can_play: true
        }
      ],
      resources: ["Court 1", "Court 2"],
      cannot_play_against: ["Team 2"],
      cannot_play_at_same_time_as_another_team: ["Team 4"]
    }
  ]
}
```

---

## Output
The service returns an array of hashes, each representing a scheduled match (event) saved in the `events` table. Each event includes:
- `home`: String, e.g., "Team 1" (home team).
- `away`: String, e.g., "Team 2" (away team).
- `resource`: String, e.g., "Court 1" (assigned resource).
- `date`: Date, e.g., `2025-04-29` (match date).
- `start_time`: Time, e.g., `10:00:00` (match start time).
- `end_time`: Time, e.g., `11:00:00` (match end time).
- `duration`: Integer, e.g., 60 (match duration in minutes).

### Example Output
```ruby
[
  {
    home: "Team 1",
    away: "Team 3",
    resource: "Court 1",
    date: Date.parse("2025-04-29"),
    start_time: Time.parse("10:00 AM"),
    end_time: Time.parse("11:00 AM"),
    duration: 60
  },
  {
    home: "Team 2",
    away: "Team 4",
    resource: "Court 2",
    date: Date.parse("2025-04-29"),
    start_time: Time.parse("10:00 AM"),
    end_time: Time.parse("11:00 AM"),
    duration: 60
  }
]
```

---

## League Rules and Scheduling Logic
### League-Level Rules
1. **Start Date**: Matches begin on `league_start_date` (e.g., "2025-04-29").
2. **Minimum Games**: Each team must play at least `min_games_per_team` matches. Matchups may repeat if needed.
3. **Game Duration**: Each match lasts `game_duration` minutes (e.g., 60 minutes).
4. **Resources**: Matches are scheduled on available resources (e.g., ["Court 1", "Court 2"]).
5. **Teams**: Teams are generated dynamically based on `number_of_teams` (e.g., 4 → ["Team 1", "Team 2", "Team 3", "Team 4"]).
6. **Frequency and Games**:
   - `frequency` ("daily", "weekly", "monthly") defines how often matches are scheduled.
   - `games` specifies the maximum number of matches per frequency period (e.g., 3 per week).
7. **Double Headers**:
   - If `double_headers: true`, a team can play back-to-back matches without gaps (e.g., 10:00-11:00 AM, then 11:00-12:00 PM).
   - If `double_headers: false`, matches for a team must have gaps or not be consecutive.

### Scheduling Logic
1. **Generate Matchups**:
   - Create all possible team pairs using `teams.combination(2)` (e.g., ["Team 1", "Team 2"]).
   - Exclude pairs where `cannot_play_against` applies.
2. **Ensure Minimum Games**:
   - Schedule enough matches so each team plays at least `min_games_per_team`.
   - Repeat matchups if necessary (e.g., with few teams).
3. **Assign Matches to Slots**:
   - For each date (starting from `league_start_date`):
     - Generate available time slots based on resource availability.
     - Find a valid matchup that satisfies:
       - Both teams are available (`team_can_play_on`, `from`, `till`, `can_play: true`).
       - The resource is available and allowed for both teams.
       - No conflicts in the `events` table (team or resource not booked).
       - No simultaneous play with restricted teams (`cannot_play_at_same_time_as_another_team`).
       - Double-header rules are respected.
4. **Frequency Limits**:
   - Schedule up to `games` matches per frequency period (e.g., 3 per week).
   - Move to the next period (day, week, or month) after reaching the limit.
5. **Save Matches**:
   - Save each valid match to the `events` table using the `Event` model.
   - Return the list of scheduled events.

### Team and Resource Restrictions
1. **Availability Rules**:
   - Defined by `team_can_play_on` or `team_can_not_play_on` (days like "Monday").
   - Time window (`from`, `till`, e.g., "10:00 AM" to "12:00 PM").
   - Start date (`starting`, e.g., "2025-04-29").
   - Repetition (`repeats`: "weekly", "monthly", "yearly").
   - `can_play`: true (available) or false (unavailable).
2. **Team-Specific Restrictions**:
   - `resources`: List of allowed resources (e.g., ["Court 1"]).
   - `cannot_play_against`: Teams that cannot be opponents (e.g., ["Team 2"]).
   - `cannot_play_at_same_time_as_another_team`: Teams that cannot play simultaneously (e.g., ["Team 4"]).

---

## Event Model
The service saves matches to the `events` table using the `Event` model with the following fields:
- `home`: String (home team name, e.g., "Team 1").
- `away`: String (away team name, e.g., "Team 2").
- `event_start_time`: Time (match start, e.g., "10:00 AM").
- `event_last_time`: Time (match end, e.g., "11:00 AM").
- `event_date`: Date (match date, e.g., "2025-04-29").
- `resource`: String (assigned resource, e.g., "Court 1").

---

## Usage
### Example Code
```ruby
# Initialize the service with input parameters
scheduler = LeagueMatchSchedulerService.new(params)

# Run the scheduler to get scheduled events
events = scheduler.call

# Print scheduled matches
events.each do |event|
  puts "#{event[:home]} vs #{event[:away]} on #{event[:resource]} at #{event[:start_time]}"
end
```

### Assumptions
- **Event Model**: Exists with fields as described.
- **Time Parsing**: Time strings (e.g., "10:00 AM") are parseable by `Time.parse`.
- **Repeats**: Approximates monthly (30 days) and yearly (365 days) repeats.
- **Database**: Uses Rails with ActiveRecord.
- **Team Availability**: Assumes availability data for all teams; defaults to unavailable if missing.

---

## Key Methods
1. `initialize(params)`: Sets up the service with input data.
2. `call`: Main method to schedule matches and return events.
3. `schedule_matches`: Core scheduling logic, iterates through dates and slots.
4. `generate_matchups`: Creates valid team pairs.
5. `get_available_slots(date)`: Generates time slots for a date.
6. `valid_matchup?(home, away, slot, scheduled_matches)`: Checks if a matchup is valid.
7. `schedule_match(matchup, slot, scheduled_matches)`: Saves a match to the `events` table.
8. `find_team_availability(team, date)`: Retrieves team availability rules.
9. `find_resource_availability(resource, date)`: Retrieves resource availability rules.

---

## Future Enhancements
- **Precise Repeats**: Improve monthly/yearly repeat logic for exact calendar dates.
- **Validation**: Add input validation for dates, times, and parameters.
- **Logging**: Log scheduling failures or conflicts.
- **Optimization**: Index `events` table for faster queries.
- **New Constraints**: Support additional restrictions (e.g., max games per day).

---

## Contact
For questions or modifications, refer to this document or consult the development team. The service is designed to be modular and extensible for future updates.
