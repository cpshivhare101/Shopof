# League Match Scheduling Requirements (English)

## Introduction
This document outlines the requirements for a league match scheduling system. The system aims to ensure that each team plays at least a minimum number of matches, with matches scheduled as early as possible. Users provide parameters, and default values are used for any unspecified parameters. This document is designed to be clear and understandable for both AI systems and human developers.

## Main Goals
- Ensure each team plays at least `min_games_per_team` matches.
- Schedule matches as early as possible, starting from `league_start_date` and ending by `end_date`.
- Distribute matches across resources as evenly as possible, though not mandatory.
- If only two teams are available, they can play against each other multiple times.
- Scheduling is not possible without `number_of_teams` and `resources`.

## Parameters
Below are the parameters provided by users to configure the league, along with their descriptions and default values:

| Parameter | Type | Description | Default Value |
|-----------|------|-------------|---------------|
| `league_start_date` | Date | The start date of the league (e.g., 2025-05-29) | Today's date |
| `min_games_per_team` | Number | Minimum number of games each team must play | 5 |
| `game_duration` | Number | Duration of each game in minutes (e.g., 60) | 60 |
| `number_of_teams` | Number | Total number of teams in the league (mandatory) | None (mandatory) |
| `resources` | Array | List of available resources (e.g., ['Court 1', 'Court 2']) (mandatory) | None (mandatory) |
| `frequency` | String | How often matches are scheduled (daily, weekly, monthly) | daily |
| `games` | Number | Number of games per `frequency` period | 8 |
| `double_headers` | Object | Rules for back-to-back matches `{apply: Boolean, same_resource: Boolean}` | `{apply: false, same_resource: false}` |
| `end_date` | Date | The last date for scheduling matches | `league_start_date + 90 days` |
| `team_can_play` | Number | Maximum number of games per `frequency` period (e.g., 5 weekly → 5 games weekly) | None |
| `debug` | Boolean | Enable debugging | false |
| `teams_availability_or_not` | Array | Rules for team availability/unavailability | [] (default: daily 9:00 AM to 5:00 PM) |
| `resources_availability_or_not` | Array | Rules for resource availability/unavailability | [] (default: daily 9:00 AM to 5:00 PM) |

### Note
- `team_name` (e.g., `Team 1`, `Team 2`) is unique in the database and will be used to identify teams. `team_id` is not required.
- `resource_name` (e.g., `Court 1`) is unique in the database. `resource_id` is not required.

### Double Headers
- `double_headers.apply: true` → Attempt to schedule back-to-back matches.
- `double_headers.same_resource: true` → Back-to-back matches must be on the same resource.
- This is a preference, not mandatory. If some teams are available, double headers will be scheduled for them.

### Availability Rules
`teams_availability_or_not` and `resources_availability_or_not` contain availability rules. Each rule includes:

| Field | Type | Description |
|-------|------|-------------|
| `day` | Array | Days of the week (e.g., ['Monday', 'Tuesday']) |
| `from` | Time | Start time (e.g., '10:00 AM') |
| `till` | Time | End time (e.g., '12:00 PM') |
| `effective_from` | Date | Date the rule becomes effective (e.g., '2025-05-05') |
| `repeats` | String | Repetition pattern (weekly, monthly) |
| `can_play` | Boolean | Whether the slot is playable (true/false) |

#### Repeats Behavior
- **weekly**: Attempt to schedule on the specified days every week (e.g., every Monday and Tuesday).
- **monthly**: Attempt to schedule on the first specified day of each month (e.g., first Monday). If not possible, try the second, third, or fourth occurrence. Maximum one schedule per month.

#### Additional Team Constraints
- `resources`: Resources the team can play on (e.g., ['Court 1']). If empty (`[]`), all resources are allowed.
- `cannot_play_against`: Teams the team cannot play against (e.g., ['Team 2', 'Team 3']). If empty (`[]`), no restrictions.
- `cannot_play_at_same_time_as_another_team`: Teams the team cannot play simultaneously with (e.g., ['Team 4']). If empty (`[]`), no restrictions.

### Default Behavior
- If a team is not listed in `teams_availability_or_not`, it is considered available daily from 9:00 AM to 5:00 PM, can play on any resource, and has no `cannot_play_against` or `cannot_play_at_same_time_as_another_team` restrictions.
- If a resource is not listed in `resources_availability_or_not`, it is considered available daily from 9:00 AM to 5:00 PM.
- If `game_duration`, `frequency`, or `games` are not provided, `teams_availability_or_not` and `resources_availability_or_not` are programmatically generated with default availability (9:00 AM to 5:00 PM).

### Minimum and Maximum Matches
- Each team must play at least `min_games_per_team` matches.
- Scheduling stops once all teams reach `min_games_per_team`.
- If some teams have not reached `min_games_per_team`, additional matches are scheduled, even if other teams exceed `min_games_per_team`.
- There is no maximum match limit, but extra matches are scheduled only when necessary.

### Pre-Scheduling Checks
Before scheduling any match (assigning a home team, away team, time, date, and resource), the following must be checked in the `events` table:
- **Home Team**: The home team must not have another match scheduled at the same date and time.
- **Away Team**: The away team must not have another match scheduled at the same date and time.
- **Resource**: The resource (e.g., `Court 1`) must not be booked at the same date and time.
- If all three are available, the match can be scheduled. Otherwise, the system must find the next available slot that satisfies all rules (`teams_availability_or_not`, `resources_availability_or_not`, etc.).
- This ensures no conflicts between scheduled events.

### Output Format
The scheduled matches will be output as an array, with each match containing the following information:
- `home`: Name of the home team (e.g., `Team 1`).
- `away`: Name of the away team (e.g., `Team 2`).
- `resource`: Resource used (e.g., `Court 1`).
- `date`: Date of the match (e.g., `Date.parse("2025-05-05")`).
- `start_time`: Start time of the match (e.g., `Time.parse("2025-05-05 10:00:00")`).
- `end_time`: End time of the match (e.g., `Time.parse("2025-05-05 11:00:00")`).
- `duration`: Duration of the match in minutes (e.g., `60`).

#### Example Output
```ruby
[
  { home: "Team 1", away: "Team 2", resource: "Court 1", date: Date.parse("2025-05-05"), start_time: Time.parse("2025-05-05 10:00:00"), end_time: Time.parse("2025-05-05 11:00:00"), duration: 60 },
  { home: "Team 3", away: "Team 4", resource: "Court 2", date: Date.parse("2025-05-05"), start_time: Time.parse("2025-05-05 10:00:00"), end_time: Time.parse("2025-05-05 11:00:00"), duration: 60 },
  { home: "Team 1", away: "Team 3", resource: "Court 3", date: Date.parse("2025-05-05"), start_time: Time.parse("2025-05-05 10:00:00"), end_time: Time.parse("2025-05-05 11:00:00"), duration: 60 },
  { home: "Team 2", away: "Team 4", resource: "Court 4", date: Date.parse("2025-05-05"), start_time: Time.parse("2025-05-05 10:00:00"), end_time: Time.parse("2025-05-05 11:00:00"), duration: 60 },
  { home: "Team 1", away: "Team 4", resource: "Court 1", date: Date.parse("2025-05-05"), start_time: Time.parse("2025-05-05 11:00:00"), end_time: Time.parse("2025-05-05 12:00:00"), duration: 60 }
]
```
- Alternatively, each scheduled match can be stored in the `events` table for future reference.

### Example
```ruby
league_params = {
  league_start_date: "2025-05-29",
  min_games_per_team: 2,
  game_duration: 60,
  number_of_teams: 4,
  end_date: "2025-08-27",
  resources: ["Court 1", "Court 2"],
  team_can_play: 5,
  games: "weekly",
  double_headers: {apply: true, same_resource: true},
  teams_availability_or_not: [
    {
      team_name: 'Team 1',
      availabilities: [
        {
          day: ['Monday'],
          from: '10:00 AM',
          till: '12:00 PM',
          effective_from: '2025-05-05',
          repeats: 'weekly',
          can_play: true
        }
      ],
      resources: ['Court 1'],
      cannot_play_against: [],
      cannot_play_at_same_time_as_another_team: []
    }
  ],
  resources_availability_or_not: [
    {
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
    }
  ]
}
```
- **Details**:
  - League starts on 2025-05-29 and ends on 2025-08-27.
  - 4 teams (`Team 1`, `Team 2`, `Team 3`, `Team 4`), each must play at least 2 matches.
  - Each match lasts 60 minutes.
  - Resources: `Court 1` and `Court 2`. Matches will be distributed as evenly as possible.
  - **Team 1**: Available only on Mondays from 10:00 AM to 12:00 PM, starting 2025-05-05, repeating weekly. Can only play on `Court 1`.
  - **Team 2, Team 3, Team 4**: Available daily from 9:00 AM to 5:00 PM, can play on any resource.
  - **Court 1**: Available only on Mondays from 10:00 AM to 12:00 PM, starting 2025-05-05, repeating weekly.
  - **Court 2**: Available daily from 9:00 AM to 5:00 PM.
  - Double headers are enabled, with back-to-back matches on the same resource.
  - Each team can play a maximum of 5 matches per week.
  - Before scheduling each match, the system will check the `events` table to ensure no conflicts with the home team, away team, or resource.

## Conclusion
This document clearly presents all requirements for league match scheduling. The system must account for availability rules, double headers, resource distribution, and conflict checks in the `events` table to ensure the minimum number of matches. AI or developers can use this document to build an effective scheduling solution.
