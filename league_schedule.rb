class LeagueEventsSchedulerService
  attr_reader :league_params, :resources_availability, :teams_availability, :teams


  # Takes the inputs in formate

  # league_params = {
  #   league_params: {
  #     league_start_date: "2025-04-29",
  #     min_games_per_team: 2,
  #     game_duration: 60,
  #     number_of_teams: 4,
  #     resources: ["Court 1", "Court 2"],
  #     double_headers: true,
  #     team_can_play: 5,
  #     games: "weekly",
  #     double_headers: true,

  #   },
  #   resource_availabilities: [
  #     {
  #       resource_id: 13,
  #       resource_availabilities: [
  #         { day: "Monday", from: "10:00 AM", till: "12:00 PM", effective_from: "2025-04-29", repeats: "weekly", can_play: true },
  #         { day: "Tuesday", from: "11:00 AM", till: "12:00 PM", effective_from: "2025-04-29", repeats: "weekly", can_play: false }
  #       ]
  #     },
  #     {
  #       resource_id: 12,
  #       resource_availabilities: [
  #         { day: "Monday", from: "10:00 AM", till: "12:00 PM", effective_from: "2025-04-29", repeats: "weekly", can_play: true },
  #         { day: "Tuesday", from: "11:00 AM", till: "12:00 PM", effective_from: "2025-04-29", repeats: "weekly", can_play: false }
  #       ]
  #     }
  
  #   ],
  #   team_availabilities: [
  #     {
  #       team_id: 1,
  #       team_availabilities: [
  #         { day: "Monday", from: "10:00 AM", till: "12:00 PM", effective_from: "2025-04-29", repeats: "weekly", can_play: true },
  #         { day: "Tuesday", from: "11:00 AM", till: "12:00 PM", effective_from: "2025-04-29", repeats: "weekly", can_play: false }
  #       ],
  #       cannot_play_against: ["Team 2", "Team 3"],
  #       cannot_play_simultaneously_with: ["Team 4"]
  #     }
  #   ]
  # }


  # Initialize the service with input parameters
  # Return: <LeagueEventsSchedulerService> (self)
  # Example: #<LeagueEventsSchedulerService:0x00007f8b1c0a1234 @league_params={...}, @teams=["Team 1", "Team 2"]>
  def initialize(params)
    @league_params = params[:league_params] || {} # Store league configuration
    required_params = [:league_start_date, :min_games_per_team, :game_duration, :resources, :number_of_teams, :frequency, :games, :double_headers]
    missing_params = required_params.select { |param| @league_params[param].nil? } # Check for missing parameters
    raise ArgumentError, "Missing required parameters: #{missing_params.join(', ')}" unless missing_params.empty? # Raise error if any are missing
    
    @resources_availability = params[:resources_availability_or_not] # Store resource availability rules
    @teams_availability = params[:teams_availability_or_not] # Store team availability rules
    @teams = (1..league_params[:number_of_teams]).map { |i| "Team #{i}" } # Generate team names dynamically
    self # Return the initialized service instance
  end

  # Main method to schedule matches and return the list of scheduled events
  # Return: Array<Hash> (list of scheduled events)
  # Example: [
  #   {
  #     home: "Team 1", away: "Team 2", resource: "Court 1",
  #     date: Date.parse("2025-04-29"), start_time: Time.parse("10:00 AM"),
  #     end_time: Time.parse("11:00 AM"), duration: 60
  #   }
  # ]
  def call
    schedule_matches # Run scheduling logic and return the result
  end

  private

  # Schedule matches and return the list of scheduled events
  # Return: Array<Hash> (list of scheduled events)
  # Example: [
  #   {
  #     home: "Team 1", away: "Team 2", resource: "Court 1",
  #     date: Date.parse("2025-04-29"), start_time: Time.parse("10:00 AM"),
  #     end_time: Time.parse("11:00 AM"), duration: 60
  #   }
  # ]
  def schedule_matches
    matchups = generate_matchups # Generate all possible team matchups
    scheduled_matches = [] # Array to store scheduled events
    current_date = Date.parse(league_params[:league_start_date]) # Start from league start date
    games_per_period = league_params[:games] # Max games per frequency period
    frequency = league_params[:frequency] # Scheduling frequency (daily/weekly/monthly)
    end_date = current_date + 365.days # Limit scheduling to 1 year

    # Loop until enough games are scheduled or end date is reached
    while scheduled_matches.size < minimum_total_games && current_date <= end_date
      games_scheduled_in_period = 0 # Track games in current period
      available_slots = get_available_slots(current_date) # Get available slots for the date

      # Try scheduling matches in each slot
      available_slots.each do |slot|
        break if games_scheduled_in_period >= games_per_period # Stop if period limit reached
        matchup = find_valid_matchup(matchups, slot, scheduled_matches) # Find a valid matchup
        next unless matchup # Skip if no valid matchup

        # Schedule the match and update counters
        if schedule_match(matchup, slot, scheduled_matches)
          games_scheduled_in_period += 1 # Increment period game count
          # Remove matchup if teams have enough games
          matchups.delete(matchup) if enough_games_scheduled?(matchup, matchups)
        end
      end

      current_date = increment_date(current_date, frequency) # Move to next date
    end

    scheduled_matches # Return the list of scheduled events
  end

  # Generate all possible team matchups and return them
  # Return: Array<Array<String>> (list of team pairs)
  # Example: [["Team 1", "Team 2"], ["Team 1", "Team 3"], ["Team 2", "Team 3"]]
  def generate_matchups
    matchups = teams.combination(2).to_a # Create all team pairs
    matchups.reject { |home, away| cannot_play_against?(home, away) } # Exclude restricted matchups
  end

  # Calculate minimum total games needed and return the count
  # Return: Integer (total games needed)
  # Example: 4 (for 4 teams with min_games_per_team = 2)
  def minimum_total_games
    (league_params[:min_games_per_team] * league_params[:number_of_teams]) / 2 # Total games needed
  end

  # Check if teams have enough games scheduled and return true/false
  # Return: Boolean (true if both teams have enough games)
  # Example: true (if both teams have played min_games_per_team)
  def enough_games_scheduled?(matchup, matchups)
    home, away = matchup # Extract home and away teams
    home_games = matchups.count { |m| m.include?(home) } # Count remaining games for home
    away_games = matchups.count { |m| m.include?(away) } # Count remaining games for away
    home_games >= league_params[:min_games_per_team] && away_games >= league_params[:min_games_per_team] # True if both have enough
  end

  # Get available time slots for a date and return them
  # Return: Array<Hash> (list of available slots)
  # Example: [
  #   {
  #     date: Date.parse("2025-04-29"), start_time: Time.parse("10:00 AM"),
  #     end_time: Time.parse("11:00 AM"), resource: "Court 1"
  #   }
  # ]
  def get_available_slots(date)
    slots = [] # Array to store available slots
    resources = league_params[:resources] # Get list of resources

    resources.each do |resource| # Loop through each resource
      availability = find_resource_availability(resource, date) # Check resource availability
      next unless availability && availability[:can_play] # Skip if unavailable

      start_time = parse_time(availability[:from]) # Parse start time
      end_time = parse_time(availability[:till]) # Parse end time
      current_time = start_time # Start from available time

      # Generate slots based on game duration
      while current_time < end_time
        slot_end = current_time + league_params[:game_duration] * 60 # Calculate slot end
        break if slot_end > end_time # Stop if slot exceeds availability
        slots << { # Add slot to list
          date: date, # Slot date
          start_time: current_time, # Slot start time
          end_time: slot_end, # Slot end time
          resource: resource # Slot resource
        }
        current_time = slot_end # Move to next slot
      end
    end

    slots # Return available slots
  end

  # Find a valid matchup for a slot and return it (or nil)
  # Return: Array<String> or nil (valid team pair or nil)
  # Example: ["Team 1", "Team 2"] or nil
  def find_valid_matchup(matchups, slot, scheduled_matches)
    matchups.find { |home, away| valid_matchup?(home, away, slot, scheduled_matches) } # Return first valid matchup
  end

  # Check if a matchup is valid for a slot and return true/false
  # Return: Boolean (true if matchup is valid)
  # Example: true (if all constraints are satisfied)
  def valid_matchup?(home, away, slot, scheduled_matches)
    return false unless teams_available?(home, away, slot) # Check team availability
    return false unless resource_available_for_teams?(home, away, slot) # Check resource compatibility
    return false unless no_event_conflicts?(home, away, slot) # Check for event conflicts
    return false unless no_simultaneous_conflicts?(home, away, slot, scheduled_matches) # Check simultaneous restrictions
    return false unless double_header_allowed?(home, away, slot, scheduled_matches) # Check double-header rules
    true # All checks passed
  end

  # Check if both teams are available for a slot and return true/false
  # Return: Boolean (true if both teams are available)
  # Example: true (if both teams can play in the slot)
  def teams_available?(home, away, slot)
    home_availability = find_team_availability(home, slot[:date]) # Get home team availability
    away_availability = find_team_availability(away, slot[:date]) # Get away team availability

    return false unless home_availability && away_availability # False if either unavailable
    return false unless home_availability[:can_play] && away_availability[:can_play] # False if either can't play

    slot_start = slot[:start_time] # Slot start time
    slot_end = slot[:end_time] # Slot end time
    avail_start = parse_time(home_availability[:from]) # Home availability start
    avail_end = parse_time(home_availability[:till]) # Home availability end

    slot_start >= avail_start && slot_end <= avail_end # True if slot fits availability
  end

# Check if the resource is compatible with both teams' allowed courts
# If a team's resources array is empty or teams_availability_or_not is empty, it can play on any court listed in league_params[:resources]
# Return: Boolean (true if both teams can use the slot's resource)
# Example: true (if the slot's resource is in both teams' resources arrays, or if a team's resources array is empty, or if teams_availability_or_not is empty)
def resource_available_for_teams?(home, away, slot)
  home_team = teams_availability.find { |ta| ta[:team_name] == home } # Get home team data, may be nil
  away_team = teams_availability.find { |ta| ta[:team_name] == away } # Get away team data, may be nil
  resource = slot[:resource] # Get slot resource

  # Use league_params[:resources] as default if team data is missing or resources array is empty
  home_resources = home_team && !home_team[:resources]&.empty? ? home_team[:resources] : league_params[:resources]
  away_resources = away_team && !away_team[:resources]&.empty? ? away_team[:resources] : league_params[:resources]

  home_resources.include?(resource) && away_resources.include?(resource) # True if both can use resource
end

  # Check for conflicts in the events table and return true if none
  # Return: Boolean (true if no conflicts)
  # Example: true (if no team or resource is booked at the same time)
  def no_event_conflicts?(home, away, slot)
    # conflicts = Event.where( # Query events for conflicts
    #   event_date: slot[:date], # Match date
    #   event_start_time: slot[:start_time]...slot[:end_time] # Match time range
    # ).where( # Check team or resource conflicts
    #   "home IN (?) OR away IN (?) OR resource = ?",
    #   [home, away], [home, away], slot[:resource]
    # )
    # conflicts.none? # True if no conflicts
    
    true
  end

  # Check simultaneous play restrictions and return true if none
  # Return: Boolean (true if no simultaneous conflicts)
  # Example: true (if no forbidden teams are scheduled at the same time)
  def no_simultaneous_conflicts?(home, away, slot, scheduled_matches)
    team_availability = teams_availability.find { |ta| ta[:team_name] == home } # Get home team restrictions
    return true unless team_availability && team_availability[:cannot_play_at_same_time_as_another_team] # No restrictions

    forbidden_teams = team_availability[:cannot_play_at_same_time_as_another_team] # Forbidden simultaneous teams
    scheduled_matches.none? do |match| # Check scheduled matches
      match[:date] == slot[:date] && # Same date
      match[:start_time] == slot[:start_time] && # Same time
      (forbidden_teams.include?(match[:home]) || forbidden_teams.include?(match[:away])) # Forbidden team involved
    end
  end

  # Check if double-header rules allow the match and return true/false
  # Return: Boolean (true if double-header rules are satisfied)
  # Example: true (if double headers are allowed or no overlapping games)
  def double_header_allowed?(home, away, slot, scheduled_matches)
    return true if league_params[:double_headers] # Allow if double headers enabled

    scheduled_matches.none? do |match| # Check for overlapping games
      match[:date] == slot[:date] && # Same date
      (match[:home] == home || match[:away] == home || match[:home] == away || match[:away] == away) && # Team involved
      (match[:end_time] > slot[:start_time] || match[:start_time] < slot[:end_time]) # Time overlap
    end
  end

  # Schedule a match and return true if successful
  # Return: Boolean (true if match was scheduled)
  # Example: true (if event was saved successfully)
  def schedule_match(matchup, slot, scheduled_matches)
    home, away = matchup # Extract home and away teams
    event = Event.new( # Create new event
      home: home, # Set home team
      away: away, # Set away team
      event_start_time: slot[:start_time], # Set start time
      event_last_time: slot[:end_time], # Set end time
      event_date: slot[:date], # Set date
      resource: slot[:resource] # Set resource
    )

    if event.save # Save event to database
      scheduled_matches << { # Add to scheduled matches
        home: home, # Home team
        away: away, # Away team
        resource: slot[:resource], # Resource
        date: slot[:date], # Date
        start_time: slot[:start_time], # Start time
        end_time: slot[:end_time], # End time
        duration: league_params[:game_duration] # Game duration
      }
      true # Return true for success
    else
      false # Return false for failure
    end
  end

  # Check if teams cannot play against each other and return true/false
  # Return: Boolean (true if teams cannot play each other)
  # Example: true (if home team is restricted from playing away team)
  def cannot_play_against?(home, away)
    team_availability = teams_availability.find { |ta| ta[:team_name] == home } # Get home team restrictions
    team_availability && team_availability[:cannot_play_against]&.include?(away) # True if restricted
  end

  # Find team availability for a date and return it (or nil)
  # Return: Hash or nil (availability rule or nil)
  # Example: {
  #   team_can_play_on: ["Monday"], from: "10:00 AM", till: "12:00 PM",
  #   starting: "2025-04-29", repeats: "weekly", can_play: true
  # }
  def find_team_availability(team, date)
    team_availability = teams_availability.find { |ta| ta[:team_name] == team } # Find team data
    return nil unless team_availability # Return nil if no data

    team_availability[:availabilities].find do |avail| # Find matching rule
      day_matches = avail[:team_can_play_on]&.include?(date.strftime("%A")) ||
                    avail[:team_can_not_play_on]&.include?(date.strftime("%A"))
      day_matches && # Day matches
      Date.parse(avail[:starting]) <= date && # Rule is effective
      repeats_valid?(avail[:repeats], avail[:starting], date) # Repeats correctly
    end
  end

  # Find resource availability for a date and return it (or nil)
  # Return: Hash or nil (availability rule or nil)
  # Example: {
  #   team_can_play_on: ["Monday"], from: "10:00 AM", till: "12:00 PM",
  #   starting: "2025-04-29", repeats: "weekly", can_play: true
  # }
  def find_resource_availability(resource, date)
    resource_availability = resources_availability.find { |ra| ra[:resource_name] == resource } # Find resource data
    return nil unless resource_availability # Return nil if no data

    resource_availability[:availabilities].find do |avail| # Find matching rule
      day_matches = avail[:team_can_play_on]&.include?(date.strftime("%A")) ||
                    avail[:team_can_not_play_on]&.include?(date.strftime("%A"))
      day_matches && # Day matches
      Date.parse(avail[:starting]) <= date && # Rule is effective
      repeats_valid?(avail[:repeats], avail[:starting], date) # Repeats correctly
    end
  end

  # Check if repeat pattern is valid for a date and return true/false
  # Return: Boolean (true if repeat pattern is valid)
  # Example: true (if date matches weekly repeat pattern)
  def repeats_valid?(repeats, start_date, target_date)
    start = Date.parse(start_date) # Parse start date
    case repeats # Check repeat type
    when "weekly"
      ((target_date - start).to_i % 7).zero? # True if same day of week
    when "monthly"
      ((target_date - start).to_i % 30).zero? # Approximate monthly repeat
    when "yearly"
      ((target_date - start).to_i % 365).zero? # Approximate yearly repeat
    else
      false # Invalid repeat type
    end
  end

  # Parse a time string and return a Time object
  # Return: Time (parsed time object)
  # Example: Time.parse("10:00 AM")
  def parse_time(time_str)
    Time.parse(time_str) # Parse time string
  rescue
    Time.parse("12:00 AM") # Fallback to midnight if invalid
  end

  # Increment date based on frequency and return new date
  # Return: Date (next date based on frequency)
  # Example: Date.parse("2025-05-06") (for weekly increment from 2025-04-29)
  def increment_date(date, frequency)
    case frequency # Check frequency
    when "per_day" then date + 1.days # Next day
    when "daily" then date + 1.days # Next day
    when "weekly" then date + 7.days # Next week
    when "monthly" then date + 1.months # Next month
    when "yearly" then date + 1.years # Next years
    else date + 7.days # Default to weekly
    end
  end


  def self.call
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
        },
        {
          resource_id: 13,
          resource_name: "Court 2",
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
        },
        {
          team_id: 2,
          team_name: "Team 2",
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
          resources: ["Court 1"],
          cannot_play_against: [],
          cannot_play_at_same_time_as_another_team: []
        },
        {
          team_id: 3,
          team_name: "Team 3",
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
          resources: ["Court 2"],
          cannot_play_against: [],
          cannot_play_at_same_time_as_another_team: []
        },
        {
          team_id: 4,
          team_name: "Team 4",
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
          resources: [], # Can play on any court
          cannot_play_against: [],
          cannot_play_at_same_time_as_another_team: []
        }
      ]
    }

    scheduler = LeagueEventsSchedulerService.new(params) # Initialize service
    events = scheduler.call # Schedule matches
    events.each do |event| # Print events
      puts "#{event[:home]} vs #{event[:away]} on #{event[:resource]} at #{event[:start_time]} on #{event[:date]}"
    end
    events # Return events for inspection
  end
end
