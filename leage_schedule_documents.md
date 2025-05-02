LeagueEventsSchedulerService Documentation
Overview
The LeagueEventsSchedulerService is a Ruby-based service designed to schedule matches for a sports league based on team and resource (e.g., courts) availability, ensuring that league rules are followed. It generates a list of scheduled matches (events) and can save them to a database (e.g., events table). The service prioritizes meeting the minimum games per team requirement, allows flexibility in resource distribution, and handles duplicate matchups when necessary.
This document defines the service's functionality, input requirements, expected output, behavioral rules, constraints, and assumptions to ensure clarity for developers interacting with the service. It is intended to eliminate the need for repeated explanations in future implementations or modifications.

Purpose
The service schedules matches for a sports league with the following goals:

Ensure Minimum Games: Each team must play at least the number of games specified by min_games_per_team.
Flexible Matchups: Matchups (team pairs) should be unique where possible, but duplicates are allowed if necessary to meet min_games_per_team (e.g., when the number of teams is low or options are limited).
Resource Distribution: Matches should be distributed across available resources (courts) as evenly as possible, but this is not a strict requirement if resources are unavailable or other constraints prevent equal distribution.
Handle Constraints: Respect team and resource availability, as well as any restrictions (e.g., cannot_play_against, cannot_play_at_same_time_as_another_team).
Robustness: Handle non-predictive scenarios (e.g., database conflicts, limited slots) gracefully to avoid errors.


Input Requirements
The service accepts a hash with three main components:
{
  league_params: { ... },
  resources_availability_or_not: [ ... ],
  teams_availability_or_not: [ ... ]
}

1. league_params
A hash containing league configuration:

league_start_date (String): Start date of the league in YYYY-MM-DD format (e.g., "2025-05-05").
min_games_per_team (Integer): Minimum number of games each team must play (e.g., 2). Non-negative.
game_duration (Integer): Duration of each match in minutes (e.g., 60). Positive.
resources (Array): List of available resources (e.g., ["Court 1", "Court 2", "Court 3", "Court 4"]).
number_of_teams (Integer): Number of teams in the league (e.g., 4). Must be greater than 1.
frequency (String): Scheduling frequency ("daily", "weekly", or "monthly").
games (Integer): Maximum number of games to schedule per period (e.g., 4). Positive.
double_headers (Boolean): Whether teams can play multiple games on the same day (true or false).

Validation:

All parameters are required.
Invalid formats (e.g., non-YYYY-MM-DD date, negative min_games_per_team) raise ArgumentError.

2. resources_availability_or_not
An array of hashes defining resource availability:
[
  {
    resource_id: Integer,
    resource_name: String, # Must match a resource in league_params[:resources]
    availabilities: [
      {
        day: Array<String>, # e.g., ["Monday"]
        from: String, # Time in "HH:MM AM/PM" (e.g., "10:00 AM")
        till: String, # e.g., "12:00 PM"
        effective_from: String, # Date in "YYYY-MM-DD" (e.g., "2025-05-05")
        repeats: String, # "weekly" or "monthly"
        can_play: Boolean # true if available, false if unavailable
      }
    ]
  }
]


Validation: All can_play values in an availability array must be the same (e.g., all true or all false).
Default: If empty or no rules match, resources are assumed available.

3. teams_availability_or_not
An array of hashes defining team availability and restrictions:
[
  {
    team_id: Integer,
    team_name: String, # e.g., "Team 1"
    availabilities: [
      {
        day: Array<String>, # e.g., ["Monday"]
        from: String, # e.g., "10:00 AM"
        till: String, # e.g., "12:00 PM"
        effective_from: String, # e.g., "2025-05-05"
        repeats: String, # "weekly" or "monthly"
        can_play: Boolean # true if available, false if unavailable
      }
    ],
    resources: Array<String>, # Resources the team can play on (e.g., ["Court 1", "Court 2"]). Empty means all resources.
    cannot_play_against: Array<String>, # Teams this team cannot play against (e.g., ["Team 2"]). Empty means none.
    cannot_play_at_same_time_as_another_team: Array<String> # Teams this team cannot play simultaneously with (e.g., ["Team 3"]). Empty means none.
  }
]


Validation: All can_play values in an availability array must be the same.
Default: If empty or no rules match, teams are assumed available.


Output Specification
The service returns an array of event hashes representing scheduled matches:
[
  {
    home: String, # Home team name (e.g., "Team 1")
    away: String, # Away team name (e.g., "Team 2")
    resource: String, # Resource name (e.g., "Court 1")
    date: Date, # Match date (e.g., Date.parse("2025-05-05"))
    start_time: Time, # Start time (e.g., Time.parse("2025-05-05 10:00:00"))
    end_time: Time, # End time (e.g., Time.parse("2025-05-05 11:00:00"))
    duration: Integer # Match duration in minutes (e.g., 60)
  }
]


Behavioral Rules
1. Minimum Games Per Team

Primary Goal: Ensure each team plays at least min_games_per_team games.
Calculation: 
Minimum total games required: (number_of_teams * min_games_per_team) / 2.
Example: For 4 teams and min_games_per_team: 2, minimum total games = (4 * 2) / 2 = 4.


Flexibility: 
If min_games_per_team cannot be met for all teams (e.g., due to limited teams or availability), prioritize scheduling as many games as possible.
Some teams may play more than min_games_per_team to meet the total games requirement.
Example: For 2 teams with min_games_per_team: 5, schedule 5 matches (Team 1 vs Team 2 repeated 5 times) to meet the requirement.



2. Matchup Uniqueness

Preference: Schedule unique matchups (e.g., Team 1 vs Team 2 only once) where possible.
Exception: Allow duplicate matchups if:
There are insufficient unique matchups to meet min_games_per_team.
Example: For 2 teams with min_games_per_team: 5, repeat Team 1 vs Team 2 five times.
Availability or restrictions prevent unique matchups.


Implementation:
Generate all possible matchups using teams.combination(2).
Remove a matchup after scheduling to prefer uniqueness, but allow reuse if min_games_per_team is not met.



3. Resource Distribution

Preference: Distribute matches evenly across resources (e.g., 1 match per court for 4 courts).
Flexibility: If equal distribution is not possible (e.g., due to resource unavailability or scheduling constraints), use available resources dynamically.
Implementation:
Track resource usage with a resource_usage hash.
Sort slots by least-used resources to encourage even distribution.
Ignore equal distribution if constraints (e.g., limited slots) prevent it.



4. Team and Resource Availability

Team Availability:
A team is available if its availabilities rules match the slot's date and time, and can_play: true.
If no rules exist or none match, the team is assumed available.


Resource Availability:
A resource is available if its availabilities rules match the date and time, and can_play: true.
If no rules exist or none match, the resource is assumed available.


Team-Resource Compatibility:
A team can play on a resource if it is included in the team's resources list or if the list is empty (all resources allowed).



5. Restrictions

cannot_play_against:
Prevent scheduling matchups where one team is in the other's cannot_play_against list.


cannot_play_at_same_time_as_another_team:
Prevent scheduling matches where restricted teams play simultaneously in the same time slot.


double_headers:
If double_headers: true, allow teams to play multiple matches on the same day.
If false, prevent teams from playing multiple matches on the same day with overlapping times.


Database Conflicts:
Check for conflicts in the events table (via no_event_conflicts?) to avoid overlapping matches for the same team or resource.
Handle non-predictive conflicts gracefully (e.g., return true if database check is disabled).



6. Scheduling Process

Steps:
Generate all possible matchups, excluding cannot_play_against pairs.
Calculate minimum_total_games = (number_of_teams * min_games_per_team) / 2.
Set games_per_period = max(games, minimum_total_games) to allow sufficient scheduling.
Iterate through dates (based on frequency) until minimum_total_games are scheduled or end_date (1 year from start) is reached.
For each date:
Get available slots (based on resource availability and game_duration).
Sort slots by resource_usage (least used first) for even distribution.
For each slot, find a valid matchup prioritizing teams with fewer games.
Schedule the match and update team_games and resource_usage.
Remove the matchup to avoid duplicates, unless duplicates are needed.




Prioritization:
Prefer teams with fewer games (tracked via team_games hash) to ensure all teams approach min_games_per_team.


Termination:
Stop when scheduled_matches.size >= minimum_total_games or no more valid slots/matchups are available.




Assumptions

Full Availability: If no availability rules are provided or none match, teams and resources are assumed available.
Database Conflicts: If no_event_conflicts? is disabled (e.g., commented out), it returns true, assuming no conflicts.
Non-Predictive Scenarios: The service handles unexpected issues (e.g., limited slots, validation failures) by skipping invalid matchups and continuing scheduling.
Team Names: Teams are generated as "Team 1", "Team 2", ... based on number_of_teams.
Time Parsing: Times are parsed relative to the match date (e.g., "10:00 AM" on 2025-05-05).
End Date: Scheduling is limited to 1 year from league_start_date to prevent infinite loops.


Example Usage
Input Example
params = {
  league_params: {
    league_start_date: "2025-05-05", # Monday
    min_games_per_team: 2, # Requires 4 matches
    game_duration: 60,
    resources: ["Court 1", "Court 2", "Court 3", "Court 4"],
    number_of_teams: 4,
    frequency: "weekly",
    games: 4,
    double_headers: true
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
    # Similar entries for Court 2, Court 3, Court 4
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
      resources: ["Court 1", "Court 2", "Court 3", "Court 4"],
      cannot_play_against: [],
      cannot_play_at_same_time_as_another_team: []
    },
    # Similar entries for Team 2, Team 3, Team 4
  ]
}

Expected Output
For the above input, the service should produce 4 unique matches (if possible), distributed across 4 courts:
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


Team Games: Team 1: 2, Team 2: 2, Team 3: 2, Team 4: 2.
Resource Usage: 1 match per court.

Alternative Scenario (2 Teams, min_games_per_team: 5)
For 2 teams with min_games_per_team: 5:

Input: { league_params: { number_of_teams: 2, min_games_per_team: 5, games: 5, ... }, ... }
Minimum total games: (2 * 5) / 2 = 5.
Expected Output: 5 matches, with duplicates (e.g., Team 1 vs Team 2 repeated 5 times).

[
  { home: "Team 1", away: "Team 2", resource: "Court 1", ... },
  { home: "Team 1", away: "Team 2", resource: "Court 2", ... },
  { home: "Team 1", away: "Team 2", resource: "Court 3", ... },
  { home: "Team 1", away: "Team 2", resource: "Court 1", ... },
  { home: "Team 1", away: "Team 2", resource: "Court 2", ... }
]


Team Games: Team 1: 5, Team 2: 5.
Resource Usage: Uneven distribution (e.g., Court 1: 2, Court 2: 2, Court 3: 1) is acceptable.


Debugging and Logging
To facilitate debugging, the service includes detailed logging for:

Matchup Generation: Log all generated matchups.
Slot Processing: Log available slots and resource usage.
Matchup Validation: Log results of valid_matchup?, including sub-checks (teams_available?, no_simultaneous_conflicts?, double_header_allowed?).
Team Games: Log team_games hash to track games per team.
Scheduling Progress: Log current date, matches needed, and games scheduled per period.

Example Log Output:
Generated matchups: [["Team 1", "Team 2"], ["Team 1", "Team 3"], ...]
Scheduling for date: 2025-05-05, need 4 more matches, team_games: {}
Available slots for 2025-05-05: [{:date=>2025-05-05, :start_time=>2025-05-05 10:00:00, :resource=>"Court 1"}, ...]
Checking matchup Team 1 vs Team 2 for slot {...}: Valid
Teams available check: Team 1 (true), Team 2 (true) for slot {...}
Scheduled match, games in period: 1, resource_usage: {"Court 1"=>1}, team_games: {"Team 1"=>1, "Team 2"=>1}

Debugging Steps:

Check Generated matchups to ensure all expected pairs (e.g., Team 3 vs Team 4) are included.
Review Checking matchup ...: Invalid logs to identify why a matchup was rejected.
Verify team_games to ensure all teams approach min_games_per_team.
Inspect resource_usage to confirm resource distribution.


Implementation Notes

Language: Ruby, compatible with Rails (uses Date, Time, and optional ActiveRecord for Event model).
Validation: Input parameters are validated for type and value (e.g., league_start_date must be YYYY-MM-DD).
Database Interaction: 
Matches are saved to the events table via Event.create! (can be commented out for testing).
no_event_conflicts? checks for overlapping events (disabled in test mode).


Extensibility: The service supports additional constraints (e.g., new availability rules, custom restrictions) without major changes.
Error Handling: Raises ArgumentError for invalid inputs and handles scheduling failures gracefully.


Future Enhancements

Randomized Matchups: Add an option to randomize matchup selection for variety.
Priority Weights: Allow weighting teams or resources for scheduling priority.
Advanced Constraints: Support complex rules (e.g., preferred times, team groupings).
Performance Optimization: Optimize for large leagues (e.g., 20+ teams) with caching or pre-computation.


Contact
For questions or clarifications, contact the development team or refer to the project repository. Ensure any modifications align with this document to maintain consistency.
Last Updated: May 02, 2025
