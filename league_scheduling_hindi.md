# लीग मैच शेड्यूलिंग आवश्यकताएँ (Hindi)

## परिचय
यह दस्तावेज लीग मैच शेड्यूलिंग सिस्टम की आवश्यकताओं को वर्णन करता है। इसका उद्देश्य यह सुनिश्चित करना है कि टीमें न्यूनतम निर्धारित मैच खेलें, और मैच जल्द से जल्द शेड्यूल हों। यूजर पैरामीटर्स प्रदान करेगा, और अगर कुछ पैरामीटर्स नहीं दिए गए, तो डिफॉल्ट वैल्यूज का उपयोग होगा। यह दस्तावेज AI और डेवलपर्स दोनों के लिए स्पष्ट और समझने योग्य है।

## मुख्य लक्ष्य
- प्रत्येक टीम कम से कम `min_games_per_team` मैच खेले।
- मैचों को `league_start_date` से शुरू करके `end_date` तक जल्द से जल्द शेड्यूल करना।
- संसाधनों (resources) का उपयोग यथासंभव बराबर करना, लेकिन यह अनिवार्य नहीं।
- अगर केवल दो टीमें हैं, तो वे एक-दूसरे के खिलाफ बार-बार खेल सकती हैं।
- बिना `number_of_teams` और `resources` के शेड्यूलिंग संभव नहीं।

## पैरामीटर्स
नीचे लीग शेड्यूलिंग के लिए यूजर द्वारा प्रदान किए जाने वाले पैरामीटर्स और उनके विवरण दिए गए हैं:

| पैरामीटर | प्रकार | विवरण | डिफॉल्ट वैल्यू |
|-----------|--------|-------|----------------|
| `league_start_date` | Date | लीग की शुरुआत की तारीख (उदाहरण: 2025-05-29) | आज की तारीख |
| `min_games_per_team` | Number | प्रत्येक टीम के लिए न्यूनतम मैचों की संख्या | 5 |
| `game_duration` | Number | प्रत्येक मैच की अवधि मिनटों में (उदाहरण: 60) | 60 |
| `number_of_teams` | Number | लीग में भाग लेने वाली टीमों की संख्या (अनिवार्य) | कोई डिफॉल्ट नहीं (अनिवार्य) |
| `resources` | Array | उपलब्ध संसाधन (उदाहरण: ['Court 1', 'Court 2']) (अनिवार्य) | कोई डिफॉल्ट नहीं (अनिवार्य) |
| `frequency` | String | मैच कितनी बार शेड्यूल होंगे (daily, weekly, monthly) | daily |
| `games` | Number | प्रति `frequency` अवधि में कितने मैच | 8 |
| `double_headers` | Object | बैक-टू-बैक मैचों के लिए नियम `{apply: Boolean, force: Boolean, same_resource: Boolean}` | `{apply: false, force: false, same_resource: false}` |
| `end_date` | Date | लीग की अंतिम तारीख | `league_start_date + 90 days` |
| `team_can_play` | Number | प्रति `frequency` अवधि में अधिकतम मैच (उदाहरण: 5 weekly → 5 मैच हफ्ते में) | कोई डिफॉल्ट नहीं |
| `debug` | Boolean | डिबगिंग के लिए | false |
| `teams_availability_or_not` | Array | टीमों की उपलब्धता/अनुपलब्धता नियम | [] (डिफॉल्ट: रोज़ 9:00 AM से 5:00 PM) |
| `resources_availability_or_not` | Array | संसाधनों की उपलब्धता/अनुपलब्धता नियम | [] (डिफॉल्ट: रोज़ 9:00 AM से 5:00 PM) |

### नोट
- `team_name` (उदाहरण: `Team 1`, `Team 2`) डेटाबेस में यूनिक है और इसका उपयोग टीमें पहचानने के लिए किया जाएगा। `team_id` अनिवार्य नहीं है।
- `resource_name` (उदाहरण: `Court 1`) डेटाबेस में यूनिक है। `resource_id` अनिवार्य नहीं है।

### डबल हेडर्स
- `double_headers.apply: true` → बैक-टू-बैक मैच शेड्यूल करने की कोशिश होगी।
- `double_headers.force: true` → बैक-टू-बैक मैच अनिवार्य होंगे। प्रत्येक टीम के लिए बैक-टू-बैक मैच शेड्यूल करना होगा, और अगर यह संभव नहीं है, तो सिस्टम उस टीम के लिए कोई मैच शेड्यूल नहीं करेगा या त्रुटि देगा।
- `double_headers.force: false` → सिस्टम डबल हेडर शेड्यूल करने की कोशिश करेगा, लेकिन अगर यह संभव नहीं है, तो सामान्य मैच शेड्यूलिंग होगी।
- `double_headers.same_resource: true` → बैक-टू-बैक मैच एक ही संसाधन पर होंगे। अगर `false`, तो अलग-अलग संसाधनों पर भी हो सकते हैं।
- अगर `apply: false`, तो कोई डबल हेडर शेड्यूल नहीं होंगे, और `force` या `same_resource` का कोई प्रभाव नहीं होगा।

### उपलब्धता नियम (Availability Rules)
`teams_availability_or_not` और `resources_availability_or_not` में उपलब्धता नियम शामिल हैं। प्रत्येक नियम में निम्नलिखित शामिल हैं:

| फ़ील्ड | प्रकार | विवरण |
|--------|--------|-------|
| `day` | Array | सप्ताह के दिन (उदाहरण: ['Monday', 'Tuesday']) |
| `from` | Time | शुरू होने का समय (उदाहरण: '10:00 AM') |
| `till` | Time | खत्म होने का समय (उदाहरण: '12:00 PM') |
| `effective_from` | Date | नियम कब से लागू होगा (उदाहरण: '2025-05-05') |
| `repeats` | String | दोहराव पैटर्न (weekly, monthly) |
| `can_play` | Boolean | क्या उस समय खेलना संभव है (true/false) |

#### repeats का व्यवहार
- **weekly**: हर हफ्ते दिए गए दिनों पर शेड्यूलिंग की कोशिश होगी (उदाहरण: Monday और Tuesday)।
- **monthly**: हर महीने के पहले दिए गए दिन (उदाहरण: Monday) को शेड्यूलिंग की कोशिश होगी। अगर पहला Monday संभव न हो, तो दूसरा, तीसरा, या चौथा Monday आजमाया जाएगा। प्रत्येक महीने में अधिकतम एक बार शेड्यूलिंग।

#### अतिरिक्त नियम (टीमों के लिए)
- `resources`: टीम किन संसाधनों पर खेल सकती है (उदाहरण: ['Court 1'])। अगर खाली (`[]`), तो सभी संसाधन।
- `cannot_play_against`: वे टीमें जिनके खिलाफ नहीं खेल सकती (उदाहरण: ['Team 2', 'Team 3'])। अगर खाली (`[]`), तो कोई प्रतिबंध नहीं।
- `cannot_play_at_same_time_as_another_team`: वे टीमें जिनके साथ एक ही समय पर नहीं खेल सकती (उदाहरण: ['Team 4'])। अगर खाली (`[]`), तो कोई प्रतिबंध नहीं।

### डिफॉल्ट व्यवहार
- अगर `teams_availability_or_not` में किसी टीम का ज़िक्र नहीं है, तो वह रोज़ 9:00 AM से 5:00 PM तक उपलब्ध मानी जाएगी, सभी संसाधनों पर खेल सकती है, और कोई `cannot_play_against` या `cannot_play_at_same_time_as_another_team` प्रतिबंध नहीं होगा।
- अगर `resources_availability_or_not` में किसी संसाधन का ज़िक्र नहीं है, तो वह रोज़ 9:00 AM से 5:00 PM तक उपलब्ध माना जाएगा।
- अगर `game_duration`, `frequency`, या `games` नहीं दिए गए, तो `teams_availability_or_not` और `resources_availability_or_not` प्रोग्रामेटिकली जनरेट होंगे, और डिफॉल्ट समय 9:00 AM से 5:00 PM होगा।

### न्यूनतम और अधिकतम मैच
- प्रत्येक टीम को कम से कम `min_games_per_team` मैच खेलने हैं।
- अगर सभी टीमें `min_games_per_team` तक पहुंच गई हैं, तो शेड्यूलिंग बंद हो जाएगी।
- अगर कुछ टीमें `min_games_per_team` तक नहीं पहुंची हैं, तो उनके लिए अतिरिक्त मैच शेड्यूल होंगे, भले ही दूसरी टीमें `min_games_per_team` से ज्यादा खेल चुकी हों।
- कोई अधिकतम मैच सीमा नहीं, लेकिन अतिरिक्त मैच केवल ज़रूरी होने पर शेड्यूल होंगे।

### मैच शेड्यूलिंग से पहले चेक
किसी भी मैच को शेड्यूल करने से पहले, `events` टेबल में निम्नलिखित चेक करना अनिवार्य है:
- **होम टीम**: उस तारीख और समय पर होम टीम का कोई और मैच नहीं होना चाहिए।
- **अवे टीम**: उस तारीख और समय पर अवे टीम का कोई और मैच नहीं होना चाहिए।
- **संसाधन**: उस तारीख और समय पर संसाधन (जैसे `Court 1`) पहले से बुक नहीं होना चाहिए।
- अगर ये तीनों उपलब्ध हैं, तो मैच शेड्यूल किया जाएगा। अन्यथा, सिस्टम अगला उपलब्ध स्लॉट ढूंढेगा जो सभी नियमों (`teams_availability_or_not`, `resources_availability_or_not`, आदि) को पूरा करता हो।
- यह सुनिश्चित करता है कि शेड्यूल किए गए मैचों में कोई टकराव (conflict) न हो।

### आउटपुट फॉर्मेट
शेड्यूल किए गए मैचों का आउटपुट एक सरणी के रूप में होगा, जिसमें प्रत्येक मैच के लिए निम्नलिखित जानकारी होगी:
- `home`: होम टीम का नाम (उदाहरण: `Team 1`)।
- `away`: अवे टीम का नाम (उदाहरण: `Team 2`)।
- `resource`: उपयोग किया गया संसाधन (उदाहरण: `Court 1`)।
- `date`: मैच की तारीख (उदाहरण: `Date.parse("2025-05-29")`)।
- `start_time`: मैच शुरू होने का समय (उदाहरण: `Time.parse("2025-05-29 09:00:00")`)।
- `end_time`: मैच खत्म होने का समय (उदाहरण: `Time.parse("2025-05-29 10:00:00")`)।
- `duration`: मैच की अवधि मिनटों में (उदाहरण: `60`)।

#### उदाहरण आउटपुट
```ruby
[
  { home: "Team 1", away: "Team 2", resource: "Court 1", date: Date.parse("2025-05-29"), start_time: Time.parse("2025-05-29 09:00:00"), end_time: Time.parse("2025-05-29 10:00:00"), duration: 60 },
  { home: "Team 3", away: "Team 4", resource: "Court 2", date: Date.parse("2025-05-29"), start_time: Time.parse("2025-05-29 09:00:00"), end_time: Time.parse("2025-05-29 10:00:00"), duration: 60 },
  { home: "Team 1", away: "Team 3", resource: "Court 1", date: Date.parse("2025-05-29"), start_time: Time.parse("2025-05-29 10:00:00"), end_time: Time.parse("2025-05-29 11:00:00"), duration: 60 },
  { home: "Team 2", away: "Team 4", resource: "Court 2", date: Date.parse("2025-05-29"), start_time: Time.parse("2025-05-29 10:00:00"), end_time: Time.parse("2025-05-29 11:00:00"), duration: 60 }
]
```
- वैकल्पिक रूप से, प्रत्येक शेड्यूल किया गया मैच `events` टेबल में स्टोर किया जा सकता है।

### उदाहरण
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
  double_headers: {apply: true, force: true, same_resource: true},
  teams_availability_or_not: [],
  resources_availability_or_not: []
}
```
- **विवरण**:
  - लीग 2025-05-29 से शुरू होगी और 2025-08-27 तक चलेगी।
  - 4 टीमें (`Team 1`, `Team 2`, `Team 3`, `Team 4`), प्रत्येक को कम से कम 2 मैच खेलने हैं।
  - प्रत्येक मैच 60 मिनट का होगा।
  - संसाधन: `Court 1` और `Court 2`। मैच यथासंभव बराबर शेड्यूल होंगे।
  - **Team 1, Team 2, Team 3, Team 4**: रोज़ 9:00 AM से 5:00 PM तक उपलब्ध, किसी भी संसाधन पर खेल सकती हैं।
  - **Court 1, Court 2**: रोज़ 9:00 AM से 5:00 PM तक उपलब्ध।
  - डबल हेडर्स अनिवार्य हैं (`apply: true, force: true`), और बैक-टू-बैक मैच एक ही संसाधन पर होंगे (`same_resource: true`)।
  - प्रत्येक टीम एक हफ्ते में अधिकतम 5 मैच खेल सकती है।
  - प्रत्येक मैच को शेड्यूल करने से पहले, `events` टेबल में होम टीम, अवे टीम, और संसाधन की उपलब्धता चेक की जाएगी।

#### उदाहरण आउटपुट (डबल हेडर के साथ)
```ruby
[
  { home: "Team 1", away: "Team 2", resource: "Court 1", date: Date.parse("2025-05-29"), start_time: Time.parse("2025-05-29 09:00:00"), end_time: Time.parse("2025-05-29 10:00:00"), duration: 60 },
  { home: "Team 1", away: "Team 3", resource: "Court 1", date: Date.parse("2025-05-29"), start_time: Time.parse("2025-05-29 10:00:00"), end_time: Time.parse("2025-05-29 11:00:00"), duration: 60 },
  { home: "Team 2", away: "Team 4", resource: "Court 2", date: Date.parse("2025-05-29"), start_time: Time.parse("2025-05-29 09:00:00"), end_time: Time.parse("2025-05-29 10:00:00"), duration: 60 },
  { home: "Team 2", away: "Team 3", resource: "Court 2", date: Date.parse("2025-05-29"), start_time: Time.parse("2025-05-29 10:00:00"), end_time: Time.parse("2025-05-29 11:00:00"), duration: 60 }
]
```
- **विवरण**:
  - प्रत्येक टीम के 2 मैच बैक-टू-बैक शेड्यूल किए गए हैं:
    - `Team 1`: 9:00 AM और 10:00 AM (`Court 1` पर)।
    - `Team 2`: 9:00 AM और 10:00 AM (`Court 2` पर)।
  - `Team 3` और `Team 4` के मैच भी बैक-टू-बैक हैं, लेकिन अलग-अलग संसाधनों पर।
  - संसाधन उपयोग: `Court 1` (2 मैच), `Court 2` (2 मैच)।
  - `force: true` के कारण, सिस्टम ने सुनिश्चित किया कि प्रत्येक टीम के मैच बैक-टू-बैक हैं।

## निष्कर्ष
यह दस्तावेज लीग मैच शेड्यूलिंग की सभी आवश्यकताओं को स्पष्ट रूप से प्रस्तुत करता है। सिस्टम को उपलब्धता नियमों, डबल हेडर्स (अनिवार्य या वैकल्पिक), संसाधन उपयोग, और `events` टेबल में टकराव चेक को ध्यान में रखते हुए न्यूनतम मैच सुनिश्चित करना होगा। AI या डेवलपर इस दस्तावेज का उपयोग करके एक प्रभावी शेड्यूलिंग समाधान बना सकते हैं।




### स्यूडोकोड (Pseudocode):


# Pseudocode for League Match Scheduling

# Input: league_params (contains league_start_date, min_games_per_team, game_duration, number_of_teams, end_date, resources, team_can_play, games, frequency, double_headers, teams_availability_or_not, resources_availability_or_not)
# Output: Array of scheduled matches in format: [{home, away, resource, date, start_time, end_time, duration}]

FUNCTION ScheduleLeagueMatches(league_params)
    # Step 1: Initialize variables and defaults
    SET teams = ["Team 1", "Team 2", ..., "Team number_of_teams"] # Generate team names based on number_of_teams
    SET resources = league_params.resources
    SET start_date = league_params.league_start_date OR today
    SET end_date = league_params.end_date OR (start_date + 90 days)
    SET min_games = league_params.min_games_per_team OR 5
    SET game_duration = league_params.game_duration OR 60
    SET frequency = league_params.frequency OR "daily"
    SET max_games_per_frequency = league_params.team_can_play OR infinity
    SET double_headers = league_params.double_headers OR {apply: false, force: false, same_resource: false}
    
    # Default availability if not specified
    IF league_params.teams_availability_or_not is empty THEN
        FOR each team in teams
            SET team_availability[team] = { daily: 9:00 AM to 5:00 PM, all resources, no restrictions }
        END FOR
    ELSE
        SET team_availability = league_params.teams_availability_or_not
    END IF
    
    IF league_params.resources_availability_or_not is empty THEN
        FOR each resource in resources
            SET resource_availability[resource] = { daily: 9:00 AM to 5:00 PM }
        END FOR
    ELSE
        SET resource_availability = league_params.resources_availability_or_not
    END IF
    
    # Initialize output and tracking
    SET scheduled_matches = []
    SET games_played = { team: 0 for team in teams } # Track games per team
    SET events_table = [] # Stores scheduled matches for conflict checks (initially empty)
    
    # Step 2: Generate all possible team pairs
    SET possible_pairs = []
    FOR each team1 in teams
        FOR each team2 in teams where team2 != team1
            IF team1 cannot_play_against team2 is false THEN
                ADD (team1, team2) to possible_pairs
            END IF
        END FOR
    END FOR
    
    # Step 3: Schedule matches
    SET current_date = start_date
    WHILE current_date <= end_date AND EXISTS team with games_played[team] < min_games
        # Get available time slots for the current date
        SET available_slots = []
        FOR each resource in resources
            FOR each time_slot from 9:00 AM to 5:00 PM in game_duration increments
                IF resource is available at time_slot (based on resource_availability) THEN
                    ADD {resource, time_slot} to available_slots
                END IF
            END FOR
        END FOR
        
        # Shuffle pairs to ensure fairness
        SHUFFLE possible_pairs
        
        # Track games scheduled in this frequency period (e.g., week)
        SET games_in_frequency = { team: 0 for team in teams }
        
        FOR each pair (home_team, away_team) in possible_pairs
            # Check if both teams need more games
            IF games_played[home_team] >= min_games AND games_played[away_team] >= min_games THEN
                CONTINUE
            END IF
            
            # Check if teams can play within frequency limit
            IF games_in_frequency[home_team] >= max_games_per_frequency OR games_in_frequency[away_team] >= max_games_per_frequency THEN
                CONTINUE
            END IF
            
            # Check team availability and restrictions
            SET found_slot = false
            SET selected_slot = null
            SET selected_resource = null
            
            FOR each slot in available_slots
                SET time_slot = slot.time_slot
                SET resource = slot.resource
                
                # Check team availability
                IF home_team is available at time_slot (based on team_availability) AND
                   away_team is available at time_slot (based on team_availability) AND
                   home_team can play on resource AND
                   away_team can play on resource THEN
                   
                    # Check events table for conflicts
                    IF no conflict in events_table for home_team, away_team, resource at time_slot THEN
                        
                        # Handle double header rules
                        IF double_headers.apply THEN
                            IF double_headers.force THEN
                                # Mandatory double header: Schedule back-to-back match
                                SET next_time_slot = time_slot + game_duration
                                IF next_time_slot is within 5:00 PM AND
                                   resource is available at next_time_slot (or another resource if same_resource: false) THEN
                                    # Find another opponent for double header
                                    FOR each opponent in teams where opponent != home_team AND opponent != away_team
                                        IF opponent is available at next_time_slot AND
                                           no conflict in events_table for home_team, opponent, resource at next_time_slot THEN
                                            SET selected_slot = time_slot
                                            SET selected_resource = resource
                                            SET double_header_opponent = opponent
                                            SET found_slot = true
                                            BREAK
                                        END IF
                                    END FOR
                                END IF
                            ELSE
                                # Optional double header: Schedule if possible
                                SET selected_slot = time_slot
                                SET selected_resource = resource
                                SET found_slot = true
                                # Check for optional double header
                                SET next_time_slot = time_slot + game_duration
                                IF next_time_slot is within 5:00 PM AND
                                   resource is available at next_time_slot (or another resource if same_resource: false) THEN
                                    FOR each opponent in teams where opponent != home_team AND opponent != away_team
                                        IF opponent is available at next_time_slot AND
                                           no conflict in events_table for home_team, opponent, resource at next_time_slot THEN
                                            SET double_header_opponent = opponent
                                            BREAK
                                        END IF
                                    END FOR
                                END IF
                            END IF
                        ELSE
                            # No double headers
                            SET selected_slot = time_slot
                            SET selected_resource = resource
                            SET found_slot = true
                        END IF
                    END IF
                END IF
                
                IF found_slot THEN
                    BREAK
                END IF
            END FOR
            
            # Schedule the match if a slot was found
            IF found_slot THEN
                SET match = {
                    home: home_team,
                    away: away_team,
                    resource: selected_resource,
                    date: current_date,
                    start_time: selected_slot,
                    end_time: selected_slot + game_duration,
                    duration: game_duration
                }
                ADD match to scheduled_matches
                ADD match to events_table
                INCREMENT games_played[home_team]
                INCREMENT games_played[away_team]
                INCREMENT games_in_frequency[home_team]
                INCREMENT games_in_frequency[away_team]
                
                # Schedule double header match if applicable
                IF double_headers.apply AND double_header_opponent exists THEN
                    SET double_header_resource = selected_resource if double_headers.same_resource else any available resource
                    SET double_header_match = {
                        home: home_team,
                        away: double_header_opponent,
                        resource: double_header_resource,
                        date: current_date,
                        start_time: selected_slot + game_duration,
                        end_time: selected_slot + 2 * game_duration,
                        duration: game_duration
                    }
                    ADD double_header_match to scheduled_matches
                    ADD double_header_match to events_table
                    INCREMENT games_played[home_team]
                    INCREMENT games_played[double_header_opponent]
                    INCREMENT games_in_frequency[home_team]
                    INCREMENT games_in_frequency[double_header_opponent]
                END IF
                
                # Remove the slot from available_slots
                REMOVE {selected_resource, selected_slot} from available_slots
                IF double_headers.apply AND double_header_opponent exists THEN
                    REMOVE {double_header_resource, selected_slot + game_duration} from available_slots
                END IF
            END IF
        END FOR
        
        # Move to next date based on frequency
        IF frequency == "daily" THEN
            INCREMENT current_date by 1 day
        ELSE IF frequency == "weekly" THEN
            INCREMENT current_date by 7 days
        ELSE IF frequency == "monthly" THEN
            INCREMENT current_date by 1 month
        END IF
    END WHILE
    
    # Step 4: Validate and return
    FOR each team in teams
        IF games_played[team] < min_games THEN
            PRINT "Warning: Team " + team + " has only " + games_played[team] + " games scheduled"
        END IF
    END FOR
    
    RETURN scheduled_matches
END FUNCTION

# Helper Functions
FUNCTION IsTeamAvailable(team, time_slot, date, team_availability)
    FOR each rule in team_availability[team]
        IF rule.day includes date.day AND
           rule.from <= time_slot <= rule.till AND
           rule.effective_from <= date AND
           rule.can_play THEN
            RETURN true
        END IF
    END FOR
    RETURN false
END FUNCTION

FUNCTION IsResourceAvailable(resource, time_slot, date, resource_availability)
    FOR each rule in resource_availability[resource]
        IF rule.day includes date.day AND
           rule.from <= time_slot <= rule.till AND
           rule.effective_from <= date AND
           rule.can_play THEN
            RETURN true
        END IF
    END FOR
    RETURN false
END FUNCTION

FUNCTION HasConflict(events_table, home_team, away_team, resource, time_slot, date)
    FOR each event in events_table
        IF event.date == date AND
           event.start_time == time_slot AND
           (event.home == home_team OR event.away == home_team OR
            event.home == away_team OR event.away == away_team OR
            event.resource == resource) THEN
            RETURN true
        END IF
    END FOR
    RETURN false
END FUNCTION


---

### स्यूडोकोड का विवरण (Explanation of the Pseudocode):

#### 1. **इनिशियलाइजेशन (Initialization)**:
- पैरामीटर्स को पढ़ा जाता है और डिफॉल्ट वैल्यूज सेट की जाती हैं (उदाहरण: `min_games_per_team = 5`, `game_duration = 60`)।
- टीमें (`Team 1`, `Team 2`, आदि) और संसाधन (`Court 1`, `Court 2`) लोड किए जाते हैं।
- अगर `teams_availability_or_not` या `resources_availability_or_not` खाली हैं, तो डिफॉल्ट उपलब्धता (रोज़ 9:00 AM से 5:00 PM) लागू होती है।
- `scheduled_matches` (आउटपुट सरणी), `games_played` (प्रति टीम मैचों की गिनती), और `events_table` (टकराव जाँच के लिए) शुरू किए जाते हैं।

#### 2. **संभावित जोड़े (Possible Pairs)**:
- सभी संभावित होम-अवे जोड़े जनरेट किए जाते हैं, यह सुनिश्चित करते हुए कि `cannot_play_against` प्रतिबंधों का पालन हो।
- उदाहरण: 4 टीमें → जोड़े जैसे (`Team 1`, `Team 2`), (`Team 1`, `Team 3`), आदि।

#### 3. **मैच शेड्यूलिंग (Scheduling Matches)**:
- `start_date` से `end_date` तक लूप चलता है।
- प्रत्येक तारीख के लिए:
  - उपलब्ध समय स्लॉट्स (`available_slots`) जनरेट किए जाते हैं, जो `resource_availability` और `game_duration` पर आधारित होते हैं।
  - जोड़ों को रैंडमाइज़ किया जाता है ताकि निष्पक्षता बनी रहे।
  - प्रत्येक जोड़े के लिए:
    - **शर्तें जाँचें**:
      - दोनों टीमें न्यूनतम मैचों से कम खेल चुकी हों।
      - `team_can_play` सीमा के भीतर हों।
      - टीमें और संसाधन उस समय स्लॉट में उपलब्ध हों।
      - `events` टेबल में कोई टकराव न हो।
    - **डबल हेडर**:
      - अगर `double_headers.apply: true`:
        - `force: true` → बैक-टू-बैक मैच अनिवार्य है। अगला स्लॉट उपलब्ध होना चाहिए, और दूसरा प्रतिद्वंद्वी मिलना चाहिए।
        - `force: false` → बैक-टू-बैक मैच की कोशिश की जाती है, लेकिन अगर नहीं हो पाता, तो सामान्य मैच शेड्यूल होता है।
      - `same_resource: true` → दोनों मैच एक ही संसाधन पर होने चाहिए।
      - अगर `apply: false`, तो कोई डबल हेडर नहीं।
    - अगर स्लॉट मिलता है, तो मैच शेड्यूल किया जाता है, `scheduled_matches` और `events_table` में जोड़ा जाता है, और `games_played` अपडेट होता है।
    - डबल हेडर मैच (अगर लागू हो) भी शेड्यूल किया जाता है।

#### 4. **वैलीडेशन और रिटर्न (Validation and Return)**:
- यह जाँचा जाता है कि सभी टीमें `min_games_per_team` तक पहुँची हैं।
- अगर कोई टीम कम試合 खेलती है, तो चेतावनी दी जाती है।
- `scheduled_matches` सरणी रिटर्न की जाती है।

#### 5. **हेल्पर फंक्शन्स (Helper Functions)**:
- `IsTeamAvailable`: जाँचता है कि टीम दिए गए समय और तारीख पर उपलब्ध है।
- `IsResourceAvailable`: जाँचता है कि संसाधन उपलब्ध है।
- `HasConflict`: `events` टेबल में टकराव जाँचता है।

---

### उदाहरण के साथ प्रवाह (Flow with Example):
आपके पिछले उदाहरण (`number_of_teams: 4`, `double_headers: {apply: true, force: true, same_resource: true}`) के लिए:
1. **इनिशियलाइजेशन**:
   - टीमें: `Team 1`, `Team 2`, `Team 3`, `Team 4`
   - संसाधन: `Court 1`, `Court 2`
   - उपलब्धता: सभी टीमें और संसाधन रोज़ 9:00 AM से 5:00 PM
   - `min_games_per_team: 2`, `game_duration: 60`

2. **जोड़े**:
   - संभावित जोड़े: (`Team 1`, `Team 2`), (`Team 1`, `Team 3`), (`Team 2`, `Team 4`), आदि।

3. **शेड्यूलिंग**:
   - तारीख: 2025-05-29
   - स्लॉट्स: 9:00 AM, 10:00 AM, आदि।
   - जोड़ा (`Team 1`, `Team 2`) के लिए:
     - 9:00 AM, `Court 1` उपलब्ध → शेड्यूल।
     - `force: true` → अगला स्लॉट (10:00 AM) जाँचा जाता है।
     - `Team 3` उपलब्ध → `Team 1` vs `Team 3` 10:00 AM पर `Court 1` पर शेड्यूल।
   - जोड़ा (`Team 2`, `Team 4`) के लिए:
     - 9:00 AM, `Court 2` उपलब्ध → शेड्यूल।
     - `force: true` → `Team 2` vs `Team 3` 10:00 AM पर `Court 2` पर शेड्यूल।
   - `events` टेबल अपडेट होता है।

4. **आउटपुट**:
   - जैसा कि पिछले जवाब में प्रदान किया गया।

---

### नोट्स और मान्यताएँ (Notes and Assumptions):
1. **events टेबल**: शुरू में खाली मानी गई है।
2. **डबल हेडर विफलता**: अगर `force: true` है और बैक-टू-बैक संभव नहीं है, तो स्यूडोकोड में यह मान लिया गया है कि मैच शेड्यूल नहीं होगा। अगर आप चाहते हैं कि सिस्टम त्रुटि दे या सामान्य शेड्यूलिंग करे, तो कृपया स्पष्ट करें।
3. **संसाधन वितरण**: स्यूडोकोड संसाधनों को बराबर उपयोग करने की कोशिश करता है।
4. **लचीलापन**: स्यूडोकोड सामान्यीकृत है और किसी भी `number_of_teams`, `resources`, या नियमों के लिए काम करेगा।

---

### कोई और स्पष्टता की ज़रूरत? (Anything Else to Clarify?):
मुझे लगता है कि स्यूडोकोड सभी शर्तों और प्रवाह को कवर करता है। अगर आपके पास कोई और सवाल हैं या कुछ और चाहिए, जैसे:
- स्यूडोकोड का और विस्तार (उदाहरण के लिए, विशिष्ट शर्तों के लिए कोड स्निपेट)।
- किसी खास उदाहरण के लिए स्यूडोकोड का रन-थ्रू।
- अगर `force: true` विफल होने पर सिस्टम का व्यवहार अलग होना चाहिए।
तो कृपया बताएं।

---

### अगले कदम (Next Steps):
1. **पुष्टि**: कृपया स्यूडोकोड की समीक्षा करें और पुष्टि करें कि यह आपकी अपेक्षाओं को पूरा करता है।
2. **दस्तावेज अपडेट**: अगर आप चाहते हैं कि मैं दस्तावेजों में इस स्यूडोकोड को शामिल करूँ, तो बताएं।
3. **कोड स्निपेट**: अगर आप इस स्यूडोकोड को किसी विशिष्ट प्रोग्रामिंग भाषा (जैसे Ruby, Python) में लागू करना चाहते हैं, तो मैं एक कार्यान्वयन प्रदान कर सकता हूँ।
4. **अन्य**: अगर कोई और प्रारूप या जानकारी चाहिए, तो बताएं।

Please write service LeagueEventsSchedulerService in ruby that handle all logic and take params in input   def initialize(league_params, resources_availability_or_not, teams_availability_or_not)
and provide output.

- The service must be simple and not harder means try to make as possible as simple.
- The service  can understable by human or ai and if required it can be modify easily
- The service have each line comments that explain the logic and code. 
- each method comment describe use of method by logically. and what take in input and what would be return type and example.
like
Return Type: [Array<Hash>] List of scheduled matches, each with home, away, resource, date, start_time, end_time, duration.
  # Example:
  #   [
  #     {home: "Team 1", away: "Team 2", resource: "Court 1", date: #<Date: 2025-05-05>, start_time: 2025-05-05 10:00:00 +0530, end_time: 2025-05-05 11:00:00 +0530, duration: 60},
  #     ...
  #   ]
def ...


