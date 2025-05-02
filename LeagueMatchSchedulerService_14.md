LeagueMatchSchedulerService Documentation
Version: 1.4
Date: May 01, 2025
Purpose
This document provides a comprehensive overview of the LeagueMatchSchedulerService, a Ruby on Rails service designed to schedule matches for a sports league. It handles league-level configurations, team and resource availability, scheduling constraints, and saves matches to an events table. The service ensures fair scheduling, respects restrictions, and generates a list of scheduled events.

Overview
The LeagueMatchSchedulerService is responsible for:

Generating matchups between teams (e.g., Team 1 vs Team 2).
Scheduling matches based on league rules, such as minimum games per team and frequency limits.
Respecting team and resource availability/restrictions.
Handling double headers (back-to-back games without gaps).
Ensuring no conflicts in the schedule (e.g., no double-booked teams or resources).
Saving matches to the events table using the Event model.
Returning a list of scheduled events with details like home team, away team, resource, date, and times.


Input Data Structure
The service accepts a hash with three main components: league parameters, resource availability, and team availability.

league_params: League-level parameters for the scheduler.
league_start_date: String, e.g., "2025-04-29" (when the league starts).
min_games_per_team: Integer, e.g., 2 (minimum matches each team must play).
game_duration: Integer, e.g., 60 (match duration in minutes).
resources: Array of strings, e.g., ["Court 1", "Court 2"] (available fields/resources).
number_of_teams: Integer, e.g., 4 (number of teams in the league).
teams: Auto-generated as ["Team 1", "Team 2", ...] based on number_of_teams.
frequency: String, e.g., "weekly" ("daily", "weekly", or "monthly"; defines scheduling interval).
games: Integer, e.g., 3 (maximum matches per frequency period, e.g., 3 per week).
double_headers: Boolean, e.g., true (allows back-to-back matches for a team without gaps).

2. Resource Availability/Restrictions
Provided in params[:resources_availability_or_not] as an array of hashes:

Each hash represents one resource (e.g., "Court 1") with:
resource_id: Integer, e.g., 12 (unique ID for the resource).
resource_name: String, e.g., "Court 1" (matches league_params[:resources]).
availabilities: Array of availability rules, each with:
day: Array of strings, e.g., ["Monday", "Tuesday"] (days when available or unavailable).
from: String, e.g., "10:00 AM" (start time of availability/unavailability).
till: String, e.g., "12:00 PM" (end time of availability/unavailability).
effective_from: String, e.g., "2025-04-29" (date when rule starts).
repeats: String, e.g., "weekly" ("weekly" or "monthly"; repetition pattern).
can_play: Boolean, e.g., true (available) or false (unavailable). All rules in the availabilities array must have the same can_play value (enforced by frontend validation).





3. Team Availability/Restrictions
Provided in params[:teams_availability_or_not] as an array of hashes:

Each hash represents one team (e.g., "Team 1") with:
team_id: Integer, e.g., 1 (1-based index of the team).
team_name: String, e.g., "Team 1" (matches generated teams).
availabilities: Array of availability rules (same structure as resource availability).
resources: Array of strings, e.g., ["Court 1", "Court 2"] (resources the team can use).
cannot_play_against: Array of strings, e.g., ["Team 2"] (teams this team cannot play).
cannot_play_at_same_time_as_another_team: Array of strings, e.g., ["Team 4"] (teams that cannot play simultaneously).



Frontend Restriction: The frontend will restrict rules to either represent availability (can_play: true) or unavailability (can_play: false), but both types cannot be present in the team_availabilities or resource_availabilities arrays for a given team or resource. This means all rules in a single availabilities array must have the same can_play value.
Example Input
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
          day: ["Monday", "Tuesday"],
          from: "10:00 AM",
          till: "12:00 PM",
          effective_from: "2025-04-29",
          repeats: "weekly",
          can_play: true
        }
      ]
    },
    {
      resource_id: 13,
      resource_name: "Court 2",
      availabilities: [
        {
          day: ["Wednesday"],
          from: "10:00 AM",
          till: "12:00 PM",
          effective_from: "2025-04-29",
          repeats: "weekly",
          can_play: false
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
          day: ["Monday"],
          from: "10:00 AM",
          till: "12:00 PM",
          effective_from: "2025-04-29",
          repeats: "weekly",
          can_play: false
        },
        {
          day: ["Tuesday"],
          from: "11:00 AM",
          till: "12:00 PM",
          effective_from: "2025-04-29",
          repeats: "weekly",
          can_play: false
        }
      ],
      resources: ["Court 1", "Court 2"],
      cannot_play_against: ["Team 2"],
      cannot_play_at_same_time_as_another_team: ["Team 4"]
    }
  ]
}


Output
The service returns an array of hashes, each representing a scheduled match (event) saved in the events table. Each event includes:

home: String, e.g., "Team 1" (home team).
away: String, e.g., "Team 2" (away team).
resource: String, e.g., "Court 1" (assigned resource).
date: Date, e.g., 2025-04-29 (match date).
start_time: Time, e.g., 10:00:00 (match start time).
end_time: Time, e.g., 11:00:00 (match end time).
duration: Integer, e.g., 60 (match duration in minutes).

Example Output
[
  {
    home: "Team 1",
    away: "Team 3",
    resource: "Court 1",
    date: Date.parse("2025-05-07"),
    start_time: Time.parse("10:00 AM"),
    end_time: Time.parse("11:00 AM"),
    duration: 60
  },
  {
    home: "Team 2",
    away: "Team 4",
    resource: "Court 1",
    date: Date.parse("2025-05-07"),
    start_time: Time.parse("11:00 AM"),
    end_time: Time.parse("12:00 PM"),
    duration: 60
  }
]


League Rules and Scheduling Logic
League-Level Rules

Start Date: Matches begin on league_start_date (e.g., "2025-04-29").
Minimum Games: Each team must play at least min_games_per_team matches. Matchups may repeat if needed.
Game Duration: Each match lasts game_duration minutes (e.g., 60 minutes).
Resources: Matches are scheduled on available resources (e.g., ["Court 1", "Court 2"]).
Teams: Teams are generated dynamically based on number_of_teams (e.g., 4 → ["Team 1", "Team 2", "Team 3", "Team 4"]).
Frequency and Games:
frequency ("daily", "weekly", "monthly") defines how often matches are scheduled.
games specifies the maximum number of matches per frequency period (e.g., 3 per week).


Double Headers:
If double_headers: true, a team can play back-to-back matches without gaps (e.g., 10:00-11:00 AM, then 11:00-12:00 PM).
If double_headers: false, matches for a team must have gaps or not be consecutive.



Scheduling Logic

Generate Matchups:
Create all possible team pairs using teams.combination(2) (e.g., ["Team 1", "Team 2"]).
Exclude pairs where cannot_play_against applies.


Ensure Minimum Games:
Schedule enough matches so each team plays at least min_games_per_team.
Repeat matchups if necessary (e.g., with few teams).


Assign Matches to Slots:
For each date (starting from league_start_date):
Generate available time slots based on resource availability.
Find a valid matchup that satisfies:
Both teams are available (no can_play: false rules apply, or can_play: true rules match).
The resource is available (no can_play: false rules apply, or can_play: true rules match).
No conflicts in the events table (team or resource not booked).
No simultaneous play with restricted teams (cannot_play_at_same_time_as_another_team).
Double-header rules are respected.






Frequency Limits:
Schedule up to games matches per frequency period (e.g., 3 per week).
Move to the next period (day, week, or month) after reaching the limit.


Save Matches:
Save each valid match to the events table using the Event model.
Return the list of scheduled events.



Team and Resource Restrictions

Availability Rules:
Defined by day (array of weekdays, e.g., ["Monday", "Tuesday"]).
Time window (from, till, e.g., "10:00 AM" to "12:00 PM").
Start date (effective_from, e.g., "2025-04-29").
Repetition (repeats: "weekly" or "monthly").
can_play: true (available for scheduling) or false (unavailable, cannot be scheduled during these times). All rules in a single availabilities array must have the same can_play value.


Team-Specific Restrictions:
resources: List of allowed resources (e.g., ["Court 1"]). If empty, team can use any resource in league_params[:resources].
cannot_play_against: Teams that cannot be opponents (e.g., ["Team 2"]).
cannot_play_at_same_time_as_another_team: Teams that cannot play simultaneously (e.g., ["Team 4"]).



Repeat Logic
The repeats logic determines when a team or resource is available or unavailable based on the day, effective_from, repeats, and can_play fields. The logic verifies if the target date's weekday is in the day array.
Weekly Repeats

Behavior: If repeats: "weekly", the rule applies to the specified days (e.g., ["Monday", "Tuesday"]) every week starting from effective_from until the scheduling end date.
can_play: true: The team/resource is available on those days at the specified times.
can_play: false: The team/resource is unavailable on those days at the specified times.
Example:
Rule: day: ["Monday", "Tuesday"], effective_from: "2025-05-08" (Thursday), repeats: "weekly", can_play: true.
Available dates: The first Monday and Tuesday after 2025-05-08 are 2025-05-12 and 2025-05-13, then 2025-05-19 and 2025-05-20, and so on every week.
If can_play: false, the team/resource cannot be scheduled on Mondays and Tuesdays at the specified times.



Monthly Repeats

Behavior: If repeats: "monthly", the rule applies to the specified days (e.g., ["Monday"]) in every month starting from effective_from. The service attempts to schedule on the first occurrence of the specified day in each month, then the second, and so on, until a valid slot is found or all options are exhausted.
can_play: true: The team/resource is available on those days in each month at the specified times.
can_play: false: The team/resource is unavailable on those days in each month at the specified times.
Example:
Rule: day: ["Monday"], effective_from: "2025-05-08" (Thursday), repeats: "monthly", can_play: true.
Available dates: In May 2025, Mondays are 2025-05-12, 2025-05-19, 2025-05-26. The service tries 2025-05-12 first, then 2025-05-19, etc. In June 2025, it tries the first Monday (2025-06-02), and so on.
If can_play: false, the team/resource cannot be scheduled on Mondays in any month at the specified times.



Availability Rule Precedence

Within availabilities for a team or resource, all matching rules apply for a given date and time. A rule matches if the target date's weekday is in the day array, the date is on or after effective_from, and the time falls within the from and till window.
All rules in a single availabilities array have the same can_play value (either all can_play: true or all can_play: false, enforced by frontend validation).
can_play: true: Indicates the team or resource is available for scheduling during the specified days and times. If any can_play: true rule matches, the team or resource is available.
can_play: false: Indicates the team or resource is unavailable for scheduling during the specified days and times. If any can_play: false rule matches, the team or resource is unavailable.
If no rules match for a given date and time:
For can_play: true arrays, the team or resource is unavailable (no availability rule applies).
For can_play: false arrays, the team or resource is available (no unavailability rule restricts it).


Example:
If a team has an availabilities array with can_play: false:
Rule 1: day: ["Monday"], from: "10:00 AM", till: "12:00 PM", repeats: "weekly", can_play: false.
Rule 2: day: ["Tuesday"], from: "11:00 AM", till: "12:00 PM", repeats: "weekly", can_play: false.
Behavior: The team is unavailable on Mondays from 10:00 AM to 12:00 PM and Tuesdays from 11:00 AM to 12:00 PM every week. The team is available on other days (e.g., Wednesday) or times (e.g., Monday at 1:00 PM).


If a resource has an availabilities array with can_play: true:
Rule 1: day: ["Monday", "Tuesday"], from: "10:00 AM", till: "12:00 PM", repeats: "weekly", can_play: true.
Rule 2: day: ["Monday"], from: "1:00 PM", till: "2:00 PM", repeats: "weekly", can_play: true.
Behavior: The resource is available on Mondays and Tuesdays from 10:00 AM to 12:00 PM and on Mondays from 1:00 PM to 2:00 PM. The resource is unavailable on other days or times (e.g., Wednesday or Monday at 3:00 PM).






Event Model
The service saves matches to the events table using the Event model with the following fields:

home: String (home team name, e.g., "Team 1").
away: String (away team name, e.g., "Team 2").
event_start_time: Time (match start, e.g., "10:00 AM").
event_last_time: Time (match end, e.g., "11:00 AM").
event_date: Date (match date, e.g., "2025-04-29").
resource: String (assigned resource, e.g., "Court 1").


Usage
Example Code
# Initialize the service with input parameters
scheduler = LeagueMatchSchedulerService.new(params)

# Run the scheduler to get scheduled events
events = scheduler.call

# Print scheduled matches
events.each do |event|
  puts "#{event[:home]} vs #{event[:away

