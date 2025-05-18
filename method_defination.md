# LeagueEventsSchedulerService Methods Documentation (Hindi)

यह दस्तावेज़ `LeagueEventsSchedulerService` क्लास के प्रत्येक मेथड के लिए विस्तृत जानकारी प्रदान करता है। प्रत्येक मेथड का विवरण शामिल करता है कि मेथड क्या करता है, इसके इनपुट पैरामीटर क्या हैं, यह किन चीजों की जाँच या प्रक्रिया करता है, और यह क्या आउटपुट देता है, साथ ही एक विस्तृत उदाहरण के साथ। सभी समय एप्लिकेशन के कॉन्फ़िगर किए गए टाइमज़ोन (उदाहरण: Asia/Kolkata) में हैं।

## 1. initialize
### यह क्या करता है
`initialize` मेथड `LeagueEventsSchedulerService` क्लास का इंस्टेंस शुरू करता है। यह लीग शेड्यूलिंग के लिए आवश्यक पैरामीटर और उपलब्धता नियम सेट करता है, इनपुट की वैधता जाँचता है, डिफॉल्ट मान लागू करता है, और शेड्यूलिंग के लिए ट्रैकिंग वेरिएबल्स शुरू करता है।

### इनपुट पैरामीटर
- **league_params** (`Hash`): लीग कॉन्फ़िगरेशन, जैसे शुरूआती तारीख, टीमों की संख्या, और संसाधन।
  - उदाहरण: `{ league_start_date: '2025-06-02', number_of_teams: 4, resources: ['Court 1', 'Court 2'] }`
- **resources_availability** (`Array<Hash>`): संसाधनों (जैसे कोर्ट) के उपलब्धता नियम।
  - उदाहरण: `[{ resource: 'Court 1', availability: [{ day: 'Monday', from: '09:00', till: '17:00', can_play: true }] }]`
- **teams_availability** (`Array<Hash>`): टीमों के उपलब्धता नियम।
  - उदाहरण: `[{ team: 'Team 1', availability: [{ day: 'Monday', from: '10:00', till: '11:00', can_play: true }] }]`

### जाँच और प्रक्रिया
1. इनपुट पैरामीटर को स्टोर करता है: `@league_params`, `@resources_availability`, `@teams_availability`।
2. `validate_params` को कॉल करके इनपुट की वैधता जाँचता है (जैसे, सकारात्मक टीम संख्या, गैर-खाली संसाधन)।
3. `set_default_params` को कॉल करके अनुपस्थित पैरामीटर के लिए डिफॉल्ट मान सेट करता है (जैसे, `league_start_date` को आज की तारीख)।
4. मुख्य कॉन्फ़िगरेशन पार्स करता है:
   - `@start_date` और `@end_date` को `Date` ऑब्जेक्ट में बदलता है।
   - `@min_games`, `@game_duration`, `@resources`, `@teams`, `@game_frequency`, `@max_games_per_period`, `@debug`, `@league_id` सेट करता है।
5. ट्रैकिंग वेरिएबल्स शुरू करता है:
   - `@games_played`: प्रत्येक टीम के खेले गए गेम्स (डिफॉल्ट 0)।
   - `@period_games`: अवधि के अनुसार गेम्स।
   - `@scheduled_matches`: शेड्यूल किए गए मैचों की सूची।
   - `@current_period_start`: वर्तमान शेड्यूलिंग अवधि की शुरुआत।
   - `@resource_usage`: संसाधन उपयोग।
   - `@current_dates`: प्रोसेस की गई तारीखें।

### आउटपुट
- `LeagueEventsSchedulerService` का एक शुरू किया हुआ इंस्टेंस।
- कोई प्रत्यक्ष रिटर्न वैल्यू नहीं; ऑब्जेक्ट की स्थिति अपडेट करता है।

### उदाहरण
**इनपुट**:
```ruby
league_params = {
  league_start_date: '2025-06-02',
  number_of_teams: 4,
  resources: ['Court 1', 'Court 2'],
  min_games_per_team: 3,
  game_duration: 60,
  games: 'daily',
  team_can_play: 3,
  debug: true
}
resources_availability = [
  { resource: 'Court 1', availability: [{ day: 'Monday', from: '09:00', till: '17:00', can_play: true }] }
]
teams_availability = [
  { team: 'Team 1', availability: [{ day: 'Monday', from: '10:00', till: '12:00', can_play: true }] }
]
scheduler = LeagueEventsSchedulerService.new(league_params, resources_availability, teams_availability)
```

**प्रक्रिया**:
- `league_params` को स्टोर करता है और `validate_params` जाँचता है कि `number_of_teams` सकारात्मक है और `resources` गैर-खाली है।
- `set_default_params` `end_date` को '2025-08-31' (90 दिन बाद) सेट करता है।
- `@start_date` को `Date.parse('2025-06-02')`, `@teams` को `['Team 1', 'Team 2', 'Team 3', 'Team 4']`, और अन्य वेरिएबल्स सेट करता है।
- `@games_played` को `{}` और `@scheduled_matches` को `[]` के रूप में शुरू करता है।

**आउटपुट**:
- `scheduler` ऑब्जेक्ट तैयार है, जिसमें `@teams = ['Team 1', 'Team 2', 'Team 3', 'Team 4']`, `@start_date = Date.parse('2025-06-02')`, आदि सेट हैं।

---

## 2. self.test
### यह क्या करता है
`test` एक क्लास मेथड है जो नमूना पैरामीटर के साथ शेड्यूलिंग का प्रदर्शन करता है। यह एक टेस्ट इंस्टेंस शुरू करता है, मैच शेड्यूल करता है, और परिणाम (मैच और प्रत्येक टीम के खेले गए गेम्स) प्रिंट करता है।

### इनपुट पैरामीटर
- कोई प्रत्यक्ष इनपुट नहीं; हार्डकोडेड `test_params` का उपयोग करता है।
  - `test_params` उदाहरण:
    ```ruby
    {
      league_start_date: '2025-06-02',
      min_games_per_team: 2,
      game_duration: 60,
      number_of_teams: 3,
      end_date: '2026-08-31',
      resources: ['Court 1', 'Court 2'],
      team_can_play: 2,
      games: 'weekly',
      double_headers: { apply: true, force: false, same_resource: false },
      debug: true
    }
    ```

### जाँच और प्रक्रिया
1. `test_params` के साथ `LeagueEventsSchedulerService` का नया इंस्टेंस बनाता है, खाली `resources_availability` और `teams_availability` के साथ।
2. `schedule_matches` को कॉल करके मैच शेड्यूल करता है।
3. निम्नलिखित प्रिंट करता है:
   - शेड्यूलर इंस्टेंस (`pp league`)।
   - शेड्यूल किए गए मैच (`pp matches`)।
   - कुल मैचों की संख्या (`pp "Total matches: #{matches.count}"`)।
   - प्रत्येक टीम के खेले गए गेम्स की गणना।
4. शेड्यूल किए गए मैचों की सूची रिटर्न करता है।

### आउटपुट
- `Array<Hash>`: शेड्यूल किए गए मैच, प्रत्येक में `home`, `away`, `resource`, `date`, `start_time`, `end_time`, `duration` शामिल।
- उदाहरण आउटपुट:
  ```ruby
  [
    { home: 'Team 1', away: 'Team 2', resource: 'Court 1', date: Date.parse('2025-06-02'), start_time: Time.parse('2025-06-02 09:00:00 +0530'), end_time: Time.parse('2025-06-02 10:00:00 +0530'), duration: 60 }
  ]
  ```

### उदाहरण
**इनपुट**:
- कोई प्रत्यक्ष इनपुट नहीं; डिफॉल्ट `test_params` का उपयोग।
- `resources_availability = []`, `teams_availability = []`।

**प्रक्रिया**:
- `new(test_params, [], [])` कॉल करता है, जो डिफॉल्ट उपलब्धता सेट करता है (09:00–17:00 सभी दिनों के लिए)।
- `schedule_matches` चलाता है, जो 3 टीमों (Team 1, Team 2, Team 3) के लिए कम से कम 2 गेम्स शेड्यूल करता है।
- मान लें यह 2 मैच शेड्यूल करता है:
  - Team 1 vs Team 2, Court 1, 2025-06-02, 09:00।
  - Team 2 vs Team 3, Court 2, 2025-06-02, 09:00।
- प्रिंट करता है:
  ```ruby
  #<LeagueEventsSchedulerService:0x...>
  [
    { home: 'Team 1', away: 'Team 2', resource: 'Court 1', date: 2025-06-02, ... },
    { home: 'Team 2', away: 'Team 3', resource: 'Court 2', date: 2025-06-02, ... }
  ]
  "Total matches: 2"
  "Team 1 played 1 games"
  "Team 2 played 2 games"
  "Team 3 played 1 games"
  ```

**आउटपुट**:
```ruby
[
  { home: 'Team 1', away: 'Team 2', resource: 'Court 1', date: Date.parse('2025-06-02'), start_time: Time.parse('2025-06-02 09:00:00 +0530'), end_time: Time.parse('2025-06-02 10:00:00 +0530'), duration: 60 },
  { home: 'Team 2', away: 'Team 3', resource: 'Court 2', date: Date.parse('2025-06-02'), start_time: Time.parse('2025-06-02 09:00:00 +0530'), end_time: Time.parse('2025-06-02 10:00:00 +0530'), duration: 60 }
]
```

---

## 3. schedule_matches
### यह क्या करता है
`schedule_matches` सभी टीमों के लिए मैच शेड्यूल करता है जब तक प्रत्येक टीम न्यूनतम गेम्स (`min_games`) नहीं खेल लेती या अंतिम तारीख (`end_date`) नहीं पहुँच जाती। यह तारीखों के माध्यम से लूप करता है, उपलब्ध स्लॉट्स जनरेट करता है, और टीम पेयर असाइन करता है।

### इनपुट पैरामीटर
- कोई प्रत्यक्ष इनपुट नहीं; इंस्टेंस वेरिएबल्स (`@start_date`, `@end_date`, `@min_games`, आदि) का उपयोग करता है।

### जाँच और प्रक्रिया
1. वर्तमान तारीख को `@start_date` पर सेट करता है और `@current_dates` को रीसेट करता है।
2. जब तक `current_date <= @end_date` और कोई टीम `@min_games` से कम गेम्स खेलती है:
   - तारीख को `@current_dates` में जोड़ता है।
   - `update_period_start` को कॉल करके अवधि शुरूआत अपडेट करता है (दैनिक, साप्ताहिक, मासिक)।
   - `generate_available_slots` से उपलब्ध स्लॉट्स प्राप्त करता है।
   - अगर कोई स्लॉट नहीं, तो `next_date` के साथ अगली तारीख पर जाता है।
   - वर्तमान अवधि के गेम्स (`period_games`) प्राप्त करता है।
   - `generate_team_pairs` से टीम पेयर जनरेट करता है, कम गेम्स वाली टीमों को प्राथमिकता देता है।
   - समय के आधार पर स्लॉट्स को समूहित करता है और प्रत्येक पेयर के लिए `schedule_match` को कॉल करता है।
   - `cannot_play_at_same_time_as_another_team` प्रतिबंधों की जाँच करता है।
   - अगली तारीख पर जाता है।
3. अंतिम शेड्यूल किए गए मैच (`@scheduled_matches`) रिटर्न करता है।

### आउटपुट
- `Array<Hash>`: शेड्यूल किए गए मैच, प्रत्येक में `home`, `away`, `resource`, `date`, `start_time`, `end_time`, `duration`।
- उदाहरण:
  ```ruby
  [
    { home: 'Team 1', away: 'Team 2', resource: 'Court 1', date: Date.parse('2025-06-02'), start_time: Time.parse('2025-06-02 09:00:00 +0530'), end_time: Time.parse('2025-06-02 10:00:00 +0530'), duration: 60 }
  ]
  ```

### उदाहरण
**इनपुट**:
- इंस्टेंस सेटअप:
  ```ruby
  @league_params = { league_start_date: '2025-06-02', end_date: '2025-06-04', number_of_teams: 4, resources: ['Court 1'], min_games_per_team: 1, game_duration: 60, games: 'daily', debug: true }
  @teams_availability = [{ team: 'Team 1', availability: [{ day: 'Monday', from: '09:00', till: '17:00', can_play: true }] }, ...]
  ```

**प्रक्रिया**:
- 2025-06-02 से शुरू करता है।
- `generate_available_slots` स्लॉट्स जनरेट करता है (मान लें 09:00–10:00, Court 1, `allowed_teams: ['Team 1', 'Team 2']`)।
- `generate_team_pairs` से पेयर: `[['Team 1', 'Team 2'], ['Team 3', 'Team 4']]`.
- `schedule_match` Team 1 vs Team 2 को 09:00 पर शेड्यूल करता है।
- `@scheduled_matches` में जोड़ता है और अगली तारीख पर जाता है।
- मान लें केवल 1 मैच शेड्यूल होता है।

**आउटपुट**:
```ruby
[
  { home: 'Team 1', away: 'Team 2', resource: 'Court 1', date: Date.parse('2025-06-02'), start_time: Time.parse('2025-06-02 09:00:00 +0530'), end_time: Time.parse('2025-06-02 10:00:00 +0530'), duration: 60 }
]
```

---

## 4. restricted_teams
### यह क्या करता है
`restricted_teams` एक सहायक मेथड है जो किसी दी गई टीम के लिए उन टीमों की सूची लौटाता है जिनके साथ वह एक ही समय में नहीं खेल सकती (`cannot_play_at_same_time_as_another_team`)।

### इनपुट पैरामीटर
- **team** (`String`): टीम का नाम।
  - उदाहरण: `'Team 1'`

### जाँच और प्रक्रिया
1. `@teams_availability` में टीम डेटा ढूँढता है।
2. `cannot_play_at_same_time_as_another_team` कुंजी से प्रतिबंधित टीमों की सूची निकालता है।
3. अगर कोई डेटा नहीं मिलता, तो खाली ऐरे (`[]`) लौटाता है।

### आउटपुट
- `Array<String>`: प्रतिबंधित टीमों की सूची।
- उदाहरण: `['Team 2', 'Team 3']`

### उदाहरण
**इनपुट**:
- `team = 'Team 1'`
- `@teams_availability = [{ team: 'Team 1', cannot_play_at_same_time_as_another_team: ['Team 2', 'Team 3'] }, { team: 'Team 2', cannot_play_at_same_time_as_another_team: [] }]`

**प्रक्रिया**:
- `Team 1` के लिए डेटा ढूँढता है।
- `cannot_play_at_same_time_as_another_team` से `['Team 2', 'Team 3']` निकालता है।

**आउटपुट**:
```ruby
['Team 2', 'Team 3']
```

---

## 5. validate_params
### यह क्या करता है
`validate_params` इनपुट पैरामीटर की वैधता जाँचता है और अगर कोई त्रुटि हो तो `ArgumentError` उठाता है। यह सुनिश्चित करता है कि शेड्यूलिंग के लिए आवश्यक सभी पैरामीटर सही और पूर्ण हैं।

### इनपुट पैरामीटर
- कोई प्रत्यक्ष इनपुट नहीं; `@league_params`, `@resources_availability`, `@teams_availability` का उपयोग करता है।

### जाँच और प्रक्रिया
1. **टीमों की संख्या**: जाँचता है कि `@league_params[:number_of_teams]` सकारात्मक है।
2. **सンスाधन**: जाँचता है कि `@league_params[:resources]` एक गैर-खाली ऐरे है।
3. **गेम फ्रीक्वेंसी**: जाँचता है कि `@league_params[:games]` `VALID_FREQUENCIES` में है या `nil`।
4. **डबल हेडर्स**: अगर `double_headers` मौजूद है, तो जाँचता है कि इसमें `apply`, `force`, `same_resource` कुंजियाँ हैं।
5. **तारीखें**: `league_start_date` और `end_date` की वैधता `valid_date?` से जाँचता है।
6. **संसाधन उपलब्धता**: प्रत्येक संसाधन में `resource` और `availability` ऐरे होना चाहिए; प्रत्येक नियम को `valid_rule?` से जाँचता है।
7. **टीम उपलब्धता**: प्रत्येक टीम में `team` और `availability` ऐरे होना चाहिए; प्रत्येक नियम को `valid_rule?` से जाँचता है।
8. अगर कोई जाँच विफल होती है, तो `ArgumentError` उठाता है।

### आउटपुट
- `void`: कोई रिटर्न वैल्यू नहीं; त्रुटि होने पर अपवाद उठाता है।

### उदाहरण
**इनपुट**:
- `@league_params = { number_of_teams: 4, resources: ['Court 1'], games: 'daily', league_start_date: '2025-06-02' }`
- `@resources_availability = [{ resource: 'Court 1', availability: [{ day: 'Monday', from: '09:00', till: '17:00', can_play: true }] }]`
- `@teams_availability = [{ team: 'Team 1', availability: [{ day: 'Monday', from: '09:00', till: '17:00', can_play: true }] }]`

**प्रक्रिया**:
- `number_of_teams` (4) सकारात्मक है।
- `resources` गैर-खाली है।
- `games` ('daily') मान्य है।
- `league_start_date` वैध तारीख है।
- संसाधन और टीम नियम `valid_rule?` पास करते हैं (मान्य दिन, समय, `can_play`)।
- कोई त्रुटि नहीं; प्रक्रिया पूरी होती है।

**आउटपुट**:
- कोई रिटर्न नहीं; प्रक्रिया सफल।

**त्रुटि उदाहरण**:
- अगर `@league_params[:number_of_teams] = 0`:
  - `ArgumentError: number_of_teams must be positive` उठाता है।

---

## 6. valid_rule?
### यह क्या करता है
`valid_rule?` जाँचता है कि उपलब्धता नियम (संसाधन या टीम के लिए) वैध है या नहीं। यह सुनिश्चित करता है कि नियम में सही दिन, समय प्रारूप, और `can_play` मान है।

### इनपुट पैरामीटर
- **rule** (`Hash`): उपलब्धता नियम।
  - उदाहरण: `{ day: 'Monday', from: '09:00', till: '17:00', can_play: true }`

### जाँच और प्रक्रिया
1. जाँचता है कि `rule[:day]` `VALID_DAYS` (`Monday`, `Tuesday`, आदि) में है।
2. जाँचता है कि `rule[:from]` और `rule[:till]` वैध समय प्रारूप (HH:MM) हैं।
3. जाँचता है कि `rule[:can_play]` बूलियन (`true` या `false`) है।
4. सभी शर्तें पूरी होने पर `true` लौटाता है, अन्यथा `false`।

### आउटपुट
- `Boolean`: `true` अगर नियम वैध है, अन्यथा `false`।
- उदाहरण: `true`

### उदाहरण
**इनपुट**:
- `rule = { day: 'Monday', from: '09:00', till: '17:00', can_play: true }`

**प्रक्रिया**:
- `day`: `'Monday'` `VALID_DAYS` में है।
- `from`: `'09:00'` वैध HH:MM प्रारूप है।
- `till`: `'17:00'` वैध HH:MM प्रारूप है।
- `can_play`: `true` बूलियन है।
- सभी जाँच पास; `true` लौटाता है।

**आउटपुट**:
```ruby
true
```

**अमान्य उदाहरण**:
- `rule = { day: 'Invalid', from: '09:00', till: '17:00', can_play: true }`
- `day` अमान्य; `false` लौटाता है।

---

## 7. set_default_params
### यह क्या करता है
`set_default_params` उपयोगकर्ता द्वारा प्रदान न किए गए पैरामीटर के लिए डिफॉल्ट मान सेट करता है। यह संसाधन और टीम उपलब्धता के लिए डिफॉल्ट नियम भी सेट करता है अगर कोई प्रदान नहीं किया गया।

### इनपुट पैरामीटर
- कोई प्रत्यक्ष इनपुट नहीं; `@league_params`, `@resources_availability`, `@teams_availability` को अपडेट करता है।

### जाँच और प्रक्रिया
1. `LeagueSchedulerConstants::DEFAULTS` से डिफॉल्ट मान लागू करता है (जैसे, `league_start_date`, `end_date`) अगर `@league_params` में अनुपस्थित हों।
2. अगर `@resources_availability` खाली है, तो प्रत्येक संसाधन के लिए डिफॉल्ट उपलब्धता सेट करता है:
   - सभी `VALID_DAYS` के लिए `can_play: true`, `from: '09:00'`, `till: '17:00'`, `repeats: 'daily'`।
3. अगर `@teams_availability` खाली है, तो प्रत्येक टीम के लिए डिफॉल्ट उपलब्धता सेट करता है:
   - सभी `VALID_DAYS` के लिए `can_play: true`, `from: '09:00'`, `till: '17:00'`, `repeats: 'daily'`।
   - `resources`, `cannot_play_against`, `cannot_play_at_same_time_as_another_team` सेट करता है।

### आउटपुट
- `void`: कोई रिटर्न वैल्यू नहीं; इंस्टेंस वेरिएबल्स अपडेट करता है।

### उदाहरण
**इनपुट**:
- `@league_params = { number_of_teams: 2, resources: ['Court 1'] }`
- `@resources_availability = []`
- `@teams_availability = []`

**प्रक्रिया**:
- `DEFAULTS` से `league_start_date` को `'2025-05-18'` (आज), `end_date` को `'2025-08-16'` (90 दिन बाद), आदि सेट करता है।
- `@resources_availability` को सेट करता है:
  ```ruby
  [{ resource: 'Court 1', availability: [
    { day: 'Monday', from: '09:00', till: '17:00', can_play: true, repeats: 'daily', effective_from: '2025-05-18' },
    ...
  ]}]
  ```
- `@teams_availability` को सेट करता है:
  ```ruby
  [
    { team: 'Team 1', availability: [...], resources: ['Court 1'], cannot_play_against: [], cannot_play_at_same_time_as_another_team: [] },
    { team: 'Team 2', availability: [...], resources: ['Court 1'], cannot_play_against: [], cannot_play_at_same_time_as_another_team: [] }
  ]
  ```

**आउटपुट**:
- कोई रिटर्न नहीं; `@league_params`, `@resources_availability`, `@teams_availability` अपडेट।

---

## 8. valid_date?
### यह क्या करता है
`valid_date?` जाँचता है कि दी गई तारीख स्ट्रिंग वैध है या नहीं। यह तारीख को पार्स करने का प्रयास करता है और अगर सफल होता है तो `true` लौटाता है।

### इनपुट पैरामीटर
- **date_str** (`String`): जाँचने के लिए तारीख स्ट्रिंग।
  - उदाहरण: `'2025-06-02'`

### जाँच और प्रक्रिया
1. `Date.parse(date_str)` का उपयोग करके तारीख को पार्स करने का प्रयास करता है।
2. अगर पार्सिंग सफल, तो `true` लौटाता है।
3. अगर `ArgumentError` (अमान्य तारीख), तो `false` लौटाता है।

### आउटपुट
- `Boolean`: `true` अगर तारीख वैध, अन्यथा `false`।
- उदाहरण: `true`

### उदाहरण
**इनपुट**:
- `date_str = '2025-06-02'`

**प्रक्रिया**:
- `Date.parse('2025-06-02')` सफल; `Date` ऑब्जेक्ट बनाता है।
- `true` लौटाता है।

**आउटपुट**:
```ruby
true
```

**अमान्य उदाहरण**:
- `date_str = 'invalid'`
- `Date.parse` विफल; `false` लौटाता है।

---

## 9. update_period_start
### यह क्या करता है
`update_period_start` गेम फ्रीक्वेंसी (दैनिक, साप्ताहिक, मासिक) के आधार पर वर्तमान शेड्यूलिंग अवधि की शुरुआत (`@current_period_start`) अपडेट करता है। यह अवधि के लिए गेम ट्रैकिंग शुरू करता है।

### इनपुट पैरामीटर
- **current_date** (`Date`): प्रोसेस की जा रही वर्तमान तारीख।
  - उदाहरण: `Date.parse('2025-06-02')`

### जाँच और प्रक्रिया
1. `@game_frequency` के आधार पर:
   - **दैनिक**: `@current_period_start` को `current_date` सेट करता है।
   - **साप्ताहिक**: सप्ताह की शुरुआत (सोमवार) की गणना करता है; अगर सप्ताह बदलता है, तो अपडेट करता है।
   - **मासिक**: महीने की शुरुआत की गणना करता है; अगर महीना बदलता है, तो अपडेट करता है।
   - **डिफॉल्ट**: दैनिक के रूप में व्यवहार करता है।
2. `@period_games[@current_period_start]` को नए गेम ट्रैकिंग हैश के साथ शुरू करता है।

### आउटपुट
- `void`: कोई रिटर्न वैल्यू नहीं; `@current_period_start` और `@period_games` अपडेट करता है।

### उदाहरण
**इनपुट**:
- `current_date = Date.parse('2025-06-03')` (मंगलवार)
- `@game_frequency = 'weekly'`
- `@current_period_start = Date.parse('2025-06-02')` (सोमवार)

**प्रक्रिया**:
- 2025-06-03 के लिए सप्ताह की शुरुआत: 2025-06-02 (सोमवार)।
- `@current_period_start` पहले से ही 2025-06-02 है; कोई बदलाव नहीं।
- `@period_games[Date.parse('2025-06-02')]` पहले से शुरू है।

**आउटपुट**:
- कोई रिटर्न नहीं; `@current_period_start` अपरिवर्तित।

**वैकल्पिक उदाहरण**:
- `current_date = Date.parse('2025-06-09')` (अगला सोमवार)
- नया `@current_period_start = Date.parse('2025-06-09')` सेट करता है।

---

## 10. generate_team_pairs
### यह क्या करता है
`generate_team_pairs` शेड्यूलिंग के लिए अद्वितीय टीम पेयर जनरेट करता है, प्रतिबंधित पेयर (`cannot_play_against`, `cannot_play_at_same_time_as_another_team`) को छोड़कर।

### इनपुट पैरामीटर
- कोई प्रत्यक्ष इनपुट नहीं; `@teams` और `@teams_availability` का उपयोग करता है।

### जाँच और प्रक्रिया
1. सभी संभावित टीम संयोजनों के माध्यम से लूप करता है।
2. छोड़ता है:
   - वही टीमें (home == away)।
   - `cannot_play_against?` द्वारा प्रतिबंधित पेयर।
   - `cannot_play_at_same_time_as_another_team` द्वारा प्रतिबंधित पेयर।
3. अगर रिवर्स पेयर (away, home) पहले से शामिल नहीं है, तो पेयर जोड़ता है।
4. पेयर की सूची लौटाता है।

### आउटपुट
- `Array<Array<String>>`: टीम पेयर की सूची।
- उदाहरण: `[['Team 1', 'Team 2'], ['Team 3', 'Team 4']]`

### उदाहरण
**इनपुट**:
- `@teams = ['Team 1', 'Team 2', 'Team 3']`
- `@teams_availability = [{ team: 'Team 1', cannot_play_against: ['Team 3'], cannot_play_at_same_time_as_another_team: [] }, ...]`

**प्रक्रिया**:
- संभावित पेयर: `Team 1 vs Team 2`, `Team 1 vs Team 3`, `Team 2 vs Team 3`।
- `Team 1 vs Team 3` छोड़ता है (`cannot_play_against`)।
- `Team 1 vs Team 2` और `Team 2 vs Team 3` जोड़ता है (रिवर्स पेयर नहीं)।

**आउटपुट**:
```ruby
[['Team 1', 'Team 2'], ['Team 2', 'Team 3']]
```

---

## 11. cannot_play_against?
### यह क्या करता है
`cannot_play_against?` जाँचता है कि दो टीमें एक-दूसरे के खिलाफ खेलने से प्रतिबंधित हैं या नहीं, `cannot_play_against` नियम के आधार पर।

### इनपुट पैरामीटर
- **home_team** (`String`): होम टीम का नाम।
  - उदाहरण: `'Team 1'`
- **away_team** (`String`): अवे टीम का नाम।
  - उदाहरण: `'Team 2'`

### जाँच और प्रक्रिया
1. `home_team` के लिए `@teams_availability` में डेटा ढूँढता है।
2. जाँचता है कि `away_team` `cannot_play_against` सूची में है।
3. अगर डेटा नहीं मिलता, तो खाली `cannot_play_against` सूची मानता है।
4. `true` लौटाता है अगर प्रतिबंधित, अन्यथा `false`।

### आउटपुट
- `Boolean`: `true` अगर टीमें नहीं खेल सकतीं, अन्यथा `false`।
- उदाहरण: `false`

### उदाहरण
**इनपुट**:
- `home_team = 'Team 1'`, `away_team = 'Team 2'`
- `@teams_availability = [{ team: 'Team 1', cannot_play_against: ['Team 2'] }, { team: 'Team 2', cannot_play_against: [] }]`

**प्रक्रिया**:
- `Team 1` के लिए `cannot_play_against: ['Team 2']`।
- `away_team` ('Team 2') सूची में है; `true` लौटाता है।

**आउटपुट**:
```ruby
true
```

---

## 12. generate_available_slots
### यह क्या करता है
`generate_available_slots` दी गई तारीख के लिए उपलब्ध समय स्लॉट्स जनरेट करता है, संसाधन और टीम उपलब्धता के आधार पर। यह केवल उन स्लॉट्स को शामिल करता है जहाँ कम से कम एक टीम उपलब्ध है।

### इनपुट पैरामीटर
- **current_date** (`Date`): स्लॉट्स जनरेट करने के लिए तारीख।
  - उदाहरण: `Date.parse('2025-06-02')`

### जाँच और प्रक्रिया
1. प्रत्येक संसाधन के लिए:
   - संसाधन उपलब्धता नियम प्राप्त करता है।
   - जाँचता है कि संसाधन `can_play: true` के साथ उपलब्ध है (`rule_applies?`)।
   - संसाधन के लिए लागू टीम नियम समूहित करता है।
2. समय रेंज निर्धारित करता है:
   - अगर टीम नियम मौजूद हैं, तो उनके `from` और `till` उपयोग करता है।
   - अगर नहीं, तो संसाधन नियम या डिफॉल्ट 09:00–17:00।
3. प्रत्येक समय रेंज के लिए:
   - समय को `@game_duration` अंतराल में विभाजित करता है।
   - `team_available?` से उपलब्ध टीमें जाँचता है।
   - अगर संसाधन ब्लॉक नहीं है (`blocked_by_resource?`) और टीमें उपलब्ध हैं, तो स्लॉट जोड़ता है।
4. स्लॉट्स की सूची लौटाता है।

### आउटपुट
- `Array<Hash>`: स्लॉट्स, प्रत्येक में `resource`, `time_slot`, `allowed_teams`।
- उदाहरण:
  ```ruby
  [{ resource: 'Court 1', time_slot: Time.parse('2025-06-02 09:00:00 +0530'), allowed_teams: ['Team 1', 'Team 2'] }]
  ```

### उदाहरण
**इनपुट**:
- `current_date = Date.parse('2025-06-02')`
- `@resources = ['Court 1']`
- `@teams_availability = [{ team: 'Team 1', availability: [{ day: 'Monday', from: '09:00', till: '11:00', can_play: true }] }, { team: 'Team 2', availability: [] }]`

**प्रक्रिया**:
- `Court 1` के लिए समय रेंज: `['09:00', '11:00']` (Team 1 से)।
- स्लॉट्स जनरेट करता है: 09:00, 10:00।
- 09:00 पर `team_available?` से `allowed_teams: ['Team 1', 'Team 2']` (Team 2 डिफॉल्ट 09:00–17:00)।
- `blocked_by_resource?` पास; स्लॉट जोड़ता है।

**आउटपुट**:
```ruby
[
  { resource: 'Court 1', time_slot: Time.parse('2025-06-02 09:00:00 +0530'), allowed_teams: ['Team 1', 'Team 2'] },
  { resource: 'Court 1', time_slot: Time.parse('2025-06-02 10:00:00 +0530'), allowed_teams: ['Team 1', 'Team 2'] }
]
```

---

## 13. blocked_by_resource?
### यह क्या करता है
`blocked_by_resource?` जाँचता है कि कोई संसाधन विशिष्ट समय और तारीख पर `can_play: false` नियमों के कारण ब्लॉक है या नहीं।

### इनपुट पैरामीटर
- **resource** (`String`): संसाधन का नाम।
  - उदाहरण: `'Court 1'`
- **time** (`Time`): जाँचने के लिए समय।
  - उदाहरण: `Time.parse('2025-06-02 10:00:00 +0530')`
- **date** (`Date`): जाँचने के लिए तारीख।
  - उदाहरण: `Date.parse('2025-06-02')`

### जाँच और प्रक्रिया
1. संसाधन के उपलब्धता नियम प्राप्त करता है।
2. `can_play: false` नियमों की जाँच करता है जो `rule_applies?` पास करते हैं।
3. अगर कोई नियम लागू है और समय नियम की रेंज में है, तो `true` लौटाता है।
4. अन्यथा `false`।

### आउटपुट
- `Boolean`: `true` अगर संसाधन ब्लॉक है, अन्यथा `false`।
- उदाहरण: `false`

### उदाहरण
**इनपुट**:
- `resource = 'Court 1'`, `time = Time.parse('2025-06-02 10:00:00 +0530')`, `date = Date.parse('2025-06-02')`
- `@resources_availability = [{ resource: 'Court 1', availability: [{ day: 'Monday', from: '09:00', till: '11:00', can_play: false }] }]`

**प्रक्रिया**:
- नियम लागू है (`rule_applies?` पास, Monday)।
- समय (10:00) 09:00–11:00 के बीच है; `true` लौटाता है।

**आउटपुट**:
```ruby
true
```

---

## 14. blocked_by_any_team?
### यह क्या करता है
`blocked_by_any_team?` जाँचता है कि कोई टीम विशिष्ट समय और संसाधन पर `can_play: false` नियमों के कारण ब्लॉक है या नहीं।

### इनपुट पैरामीटर
- **time** (`Time`): जाँचने के लिए समय।
  - उदाहरण: `Time.parse('2025-06-02 10:00:00 +0530')`
- **date** (`Date`): जाँचने के लिए तारीख।
  - उदाहरण: `Date.parse('2025-06-02')`
- **resource** (`String`): संसाधन का नाम।
  - उदाहरण: `'Court 1'`

### जाँच और प्रक्रिया
1. प्रत्येक टीम के लिए:
   - जाँचता है कि टीम संसाधन का उपयोग कर सकती है।
   - `can_play: false` नियमों की जाँच करता है जो `rule_applies?` पास करते हैं।
   - अगर समय नियम की रेंज में है, तो `true` लौटाता है।
2. अगर कोई नियम लागू नहीं, तो `false`।

### आउटपुट
- `Boolean`: `true` अगर कोई टीम ब्लॉक है, अन्यथा `false`।
- उदाहरण: `false`

### उदाहरण
**इनपुट**:
- `time = Time.parse('2025-06-02 10:00:00 +0530')`, `date = Date.parse('2025-06-02')`, `resource = 'Court 1'`
- `@teams_availability = [{ team: 'Team 1', availability: [{ day: 'Monday', from: '09:00', till: '11:00', can_play: false }], resources: ['Court 1'] }]`

**प्रक्रिया**:
- `Team 1` के लिए नियम लागू है; समय 09:00–11:00 में है।
- `true` लौटाता है।

**आउटपुट**:
```ruby
true
```

---

## 15. rule_applies?
### यह क्या करता है
`rule_applies?` जाँचता है कि उपलब्धता नियम दी गई तारीख पर लागू होता है या नहीं, दैनिक, साप्ताहिक, या मासिक दोहराव का समर्थन करता है।

### इनपुट पैरामीटर
- **rule** (`Hash`): उपलब्धता नियम।
  - उदाहरण: `{ day: 'Monday', from: '10:00', till: '11:00', can_play: true, repeats: 'weekly' }`
- **date** (`Date`): जाँचने के लिए तारीख।
  - उदाहरण: `Date.parse('2025-06-02')`

### जाँच और प्रक्रिया
1. अगर तारीख `effective_from` से पहले है, तो `false`।
2. अगर तारीख का दिन (`date.strftime('%A')`) `rule[:day]` से मेल नहीं खाता, तो `false`।
3. अगर `can_play: false`, तो तुरंत `true`।
4. `repeats` (डिफॉल्ट 'weekly') के आधार पर:
   - **दैनिक**: हमेशा `true`।
   - **साप्ताहिक**: दिन मेल खाता है।
   - **मासिक**: तारीख महीने के पहले चार दिन के उदाहरणों में है।
5. अगर `repeats` अमान्य, तो `false`।

### आउटपुट
- `Boolean`: `true` अगर नियम लागू, अन्यथा `false`।
- उदाहरण: `true`

### उदाहरण
**इनपुट**:
- `rule = { day: 'Monday', from: '10:00', till: '11:00', can_play: true, repeats: 'weekly' }`
- `date = Date.parse('2025-06-02')` (सोमवार)

**प्रक्रिया**:
- `effective_from` डिफॉल्ट `@start_date`; तारीख मान्य।
- दिन मेल खाता है ('Monday' == 'Monday')।
- `repeats = 'weekly'`; दिन फिर से मेल खाता है; `true`।

**आउटपुट**:
```ruby
true
```

---

## 16. can_schedule_pair?
### यह क्या करता है
`can_schedule_pair?` जाँचता है कि दो टीमें गेम सीमाओं और प्रतिबंधों के आधार पर शेड्यूल की जा सकती हैं।

### इनपुट पैरामीटर
- **home_team** (`String`): होम टीम।
  - उदाहरण: `'Team 1'`
- **away_team** (`String`): अवे टीम।
  - उदाहरण: `'Team 2'`
- **period_games** (`Hash`): वर्तमान अवधि में खेले गए गेम्स।
  - उदाहरण: `{ 'Team 1' => 1, 'Team 2' => 0 }`

### जाँच और प्रक्रिया
1. जाँचता है कि कोई टीम `@min_games` से कम गेम्स खेली है।
2. जाँचता है कि दोनों टीमें अवधि की गेम सीमा (`@max_games_per_period`) के भीतर हैं।
3. `cannot_play_against?` से जाँचता है कि टीमें एक-दूसरे के खिलाफ खेल सकती हैं।
4. सभी शर्तें पूरी होने पर `true`।

### आउटपुट
- `Boolean`: `true` अगर शेड्यूल कर सकते हैं, अन्यथा `false`।
- उदाहरण: `true`

### उदाहरण
**इनपुट**:
- `home_team = 'Team 1'`, `away_team = 'Team 2'`, `period_games = { 'Team 1' => 1, 'Team 2' => 0 }`
- `@min_games = 2`, `@max_games_per_period = 2`, `@games_played = { 'Team 1' => 1, 'Team 2' => 0 }`

**प्रक्रिया**:
- `Team 1` (1) और `Team 2` (0) `@min_games` (2) से कम।
- `period_games` में `Team 1` (1) और `Team 2` (0) `< 2`।
- `cannot_play_against?` `false` (कोई प्रतिबंध नहीं)।
- `true` लौटाता है।

**आउटपुट**:
```ruby
true
```

---

## 17. schedule_match
### यह क्या करता है
`schedule_match` एक उपलब्ध स्लॉट में टीम पेयर के लिए मैच शेड्यूल करने का प्रयास करता है, दोनों टीमों की उपलब्धता को प्राथमिकता देता है।

### इनपुट पैरामीटर
- **home_team** (`String`): होम टीम।
  - उदाहरण: `'Team 1'`
- **away_team** (`String`): अवे टीम।
  - उदाहरण: `'Team 2'`
- **current_date** (`Date`): शेड्यूल करने की तारीख।
  - उदाहरण: `Date.parse('2025-06-02')`
- **available_slots** (`Array<Hash>`): उपलब्ध स्लॉट्स।
  - उदाहरण: `[{ resource: 'Court 1', time_slot: Time.parse('2025-06-02 09:00:00 +0530'), allowed_teams: ['Team 1', 'Team 2'] }]`
- **period_games** (`Hash`): वर्तमान अवधि में गेम्स।
  - उदाहरण: `{ 'Team 1' => 1, 'Team 2' => 0 }`

### जाँच और प्रक्रिया
1. स्लॉट्स को संसाधन उपयोग और समय के आधार पर सॉर्ट करता है, दोनों टीमों के लिए `allowed_teams` को प्राथमिकता देता है।
2. प्रत्येक स्लॉट के लिए:
   - जाँचता है कि दोनों टीमें `allowed_teams` में हैं।
   - `resource_available?` से संसाधन उपलब्धता जाँचता है।
   - `no_conflicts?` से टकराव जाँचता है।
3. अगर वैध स्लॉट मिलता है:
   - अंत समय की गणना करता है।
   - मैच हैश बनाता है और `@scheduled_matches` में जोड़ता है।
   - `@games_played`, `period_games`, `@resource_usage` अपडेट करता है।
   - स्लॉट हटाता है और `true` लौटाता है।
4. अगर कोई स्लॉट नहीं, तो `false`।

### आउटपुट
- `Boolean`: `true` अगर शेड्यूल हुआ, अन्यथा `false`।
- उदाहरण: `true`

### उदाहरण
**इनपुट**:
- `home_team = 'Team 1'`, `away_team = 'Team 2'`, `current_date = Date.parse('2025-06-02')`
- `available_slots = [{ resource: 'Court 1', time_slot: Time.parse('2025-06-02 09:00:00 +0530'), allowed_teams: ['Team 1', 'Team 2'] }]`
- `period_games = { 'Team 1' => 0, 'Team 2' => 0 }`

**प्रक्रिया**:
- स्लॉट वैध; दोनों टीमें `allowed_teams` में।
- `resource_available?` और `no_conflicts?` पास।
- `@scheduled_matches` में जोड़ता है:
  ```ruby
  { home: 'Team 1', away: 'Team 2', resource: 'Court 1', date: Date.parse('2025-06-02'), start_time: Time.parse('2025-06-02 09:00:00 +0530'), end_time: Time.parse('2025-06-02 10:00:00 +0530'), duration: 60 }
  ```
- `@games_played`, `period_games`, `@resource_usage` अपडेट करता है।
- स्लॉट हटाता है।

**आउटपुट**:
```ruby
true
```

---

## 18. team_available?
### यह क्या करता है
`team_available?` जाँचता है कि कोई टीम विशिष्ट समय, तारीख, और संसाधन पर उपलब्ध है। यह टीम-विशिष्ट नियमों को सख्ती से लागू करता है; डिफॉल्ट 09:00–17:00 केवल तभी उपयोग करता है जब कोई नियम न हो।

### इनपुट पैरामीटर
- **team** (`String`): टीम का नाम।
  - उदाहरण: `'Team 1'`
- **time** (`Time`): जाँचने के लिए समय।
  - उदाहरण: `Time.parse('2025-06-02 10:00:00 +0530')`
- **date** (`Date`): जाँचने के लिए तारीख।
  - उदाहरण: `Date.parse('2025-06-02')`
- **resource** (`String`): संसाधन का नाम।
  - उदाहरण: `'Court 1'`

### जाँच और प्रक्रिया
1. टीम डेटा ढूँढता है; अगर नहीं, तो डिफॉल्ट (`resources: @resources`, `availability: []`)।
2. जाँचता है कि संसाधन टीम के लिए अनुमत है।
3. `can_play: false` नियमों की जाँच करता है; अगर कोई लागू है और समय रेंज में है, तो `false`।
4. `can_play: true` नियमों की जाँच करता है; अगर कोई लागू है, तो समय रेंज में होना चाहिए।
5. अगर कोई `can_play: true` नियम नहीं और नियम मौजूद हैं, तो `false`।
6. अगर कोई नियम नहीं (`rules.empty?`), तो डिफॉल्ट 09:00–17:00 जाँचता है।

### आउटपुट
- `Boolean`: `true` अगर टीम उपलब्ध, अन्यथा `false`।
- उदाहरण: `true`

### उदाहरण
**इनपुट**:
- `team = 'Team 1'`, `time = Time.parse('2025-06-02 10:00:00 +0530')`, `date = Date.parse('2025-06-02')`, `resource = 'Court 1'`
- `@teams_availability = [{ team: 'Team 1', availability: [{ day: 'Monday', from: '09:00', till: '11:00', can_play: true }], resources: ['Court 1'] }]`

**प्रक्रिया**:
- संसाधन अनुमत।
- कोई `can_play: false` नियम नहीं।
- `can_play: true` नियम लागू; समय (10:00) 09:00–11:00 में है।
- `true` लौटाता है।

**आउटपुट**:
```ruby
true
```

---

## 19. resource_available?
### यह क्या करता है
`resource_available?` जाँचता है कि कोई संसाधन विशिष्ट समय और तारीख पर उपलब्ध है।

### इनपुट पैरामीटर
- **resource** (`String`): संसाधन का नाम।
  - उदाहरण: `'Court 1'`
- **time** (`Time`): जाँचने के लिए समय।
  - उदाहरण: `Time.parse('2025-06-02 10:00:00 +0530')`
- **date** (`Date`): जाँचने के लिए तारीख।
  - उदाहरण: `Date.parse('2025-06-02')`

### जाँच और प्रक्रिया
1. `blocked_by_resource?` को कॉल करता है।
2. अगर ब्लॉक नहीं, तो `true` लौटाता है।

### आउटपुट
- `Boolean`: `true` अगर संसाधन उपलब्ध, अन्यथा `false`।
- उदाहरण: `true`

### उदाहरण
**इनपुट**:
- `resource = 'Court 1'`, `time = Time.parse('2025-06-02 10:00:00 +0530')`, `date = Date.parse('2025-06-02')`
- `@resources_availability = []`

**प्रक्रिया**:
- कोई `can_play: false` नियम नहीं; `blocked_by_resource?` `false`।
- `true` लौटाता है।

**आउटपुट**:
```ruby
true
```

---

## 20. check_scheduled_matches_collisions?
### यह क्या करता है
`check_scheduled_matches_collisions?` जाँचता है कि प्रस्तावित मैच में पहले से शेड्यूल किए गए मैचों के साथ टकराव है (टीम या संसाधन ओवरलैप, या `cannot_play_at_same_time_as_another_team`)।

### इनपुट पैरामीटर
- **home_team** (`String`): होम टीम।
  - उदाहरण: `'Team 1'`
- **away_team** (`String`): अवे टीम।
  - उदाहरण: `'Team 2'`
- **resource** (`String`): संसाधन।
  - उदाहरण: `'Court 1'`
- **time** (`Time`): प्रस्तावित मैच का समय।
  - उदाहरण: `Time.parse('2025-06-02 10:00:00 +0530')`
- **scheduled_matches** (`Array<Hash>`): पहले से शेड्यूल किए गए मैच।
  - उदाहरण: `[{ home: 'Team 3', away: 'Team 4', resource: 'Court 1', start_time: Time.parse('2025-06-02 10:00:00 +0530') }]`

### जाँच और प्रक्रिया
1. **टीम टकराव**: अगर कोई शेड्यूल किया गया मैच उसी समय पर `home_team` या `away_team` का उपयोग करता है, तो `false`।
2. **संसाधन टकराव**: अगर कोई शेड्यूल किया गया मैच उसी समय पर `resource` का उपयोग करता है, तो `false`।
3. **प्रतिबंध टकराव**: `cannot_play_at_same_time_as_another_team` के आधार पर जाँचता है कि कोई प्रतिबंधित टीमें उसी समय खेल रही हैं।
4. अगर कोई टकराव नहीं, तो `true`।

### आउटपुट
- `Boolean`: `true` अगर कोई टकराव नहीं, अन्यथा `false`।
- उदाहरण: `false`

### उदाहरण
**इनपुट**:
- `home_team = 'Team 1'`, `away_team = 'Team 2'`, `resource = 'Court 1'`, `time = Time.parse('2025-06-02 10:00:00 +0530')`
- `scheduled_matches = [{ home: 'Team 3', away: 'Team 4', resource: 'Court 1', start_time: Time.parse('2025-06-02 10:00:00 +0530') }]`
- `@teams_availability = []`

**प्रक्रिया**:
- कोई टीम टकराव नहीं (Team 1, Team 2 नहीं उपयोग हुए)।
- संसाधन टकराव: `Court 1` 10:00 पर उपयोग में; `false` लौटाता है।

**आउटपुट**:
```ruby
false
```

---

## 21. check_event_collisions
### यह क्या करता है
`check_event_collisions` `Events` टेबल में टकराव (टीम या संसाधन ओवरलैप) की जाँच करता है। वर्तमान में यह हमेशा `true` लौटाता है (कोड अक्षम)।

### इनपुट पैरामीटर
- **home_team** (`String`): होम टीम।
  - उदाहरण: `'Team 1'`
- **away_team** (`String`): अवे टीम।
  - उदाहरण: `'Team 2'`
- **resource** (`String`): संसाधन।
  - उदाहरण: `'Court 1'`
- **time** (`Time`): प्रस्तावित मैच का समय।
  - उदाहरण: `Time.parse('2025-06-02 10:00:00 +0530')`
- **date** (`Date`): प्रस्तावित तारीख।
  - उदाहरण: `Date.parse('2025-06-02')`

### जाँच और प्रक्रिया
1. वर्तमान में `return true` (कोई जाँच नहीं)।
2. अगर सक्षम होता, तो:
   - प्रस्तावित अंत समय की गणना करता।
   - `Events` टेबल में टकराव जाँचता (उसी समय पर `home_team`, `away_team`, या `resource`)।
   - अगर कोई टकराव नहीं, तो `true`।

### आउटपुट
- `Boolean`: हमेशा `true` (वर्तमान में)।
- उदाहरण: `true`

### उदाहरण
**इनपुट**:
- `home_team = 'Team 1'`, `away_team = 'Team 2'`, `resource = 'Court 1'`, `time = Time.parse('2025-06-02 10:00:00 +0530')`, `date = Date.parse('2025-06-02')`

**प्रक्रिया**:
- कोई जाँच नहीं; `true` लौटाता है।

**आउटपुट**:
```ruby
true
```

---

## 22. no_conflicts?
### यह क्या करता है
`no_conflicts?` जाँचता है कि प्रस्तावित मैच में कोई टकराव (शेड्यूल किए गए मैचों या `Events` टेबल में) नहीं है।

### इनपुट पैरामीटर
- **home_team** (`String`): होम टीम।
  - उदाहरण: `'Team 1'`
- **away_team** (`String`): अवे टीम।
  - उदाहरण: `'Team 2'`
- **resource** (`String`): संसाधन।
  - उदाहरण: `'Court 1'`
- **time** (`Time`): प्रस्तावित समय।
  - उदाहरण: `Time.parse('2025-06-02 10:00:00 +0530')`
- **current_date** (`Date`): प्रस्तावित तारीख।
  - उदाहरण: `Date.parse('2025-06-02')`

### जाँच और प्रक्रिया
1. `check_scheduled_matches_collisions?` से शेड्यूल किए गए मैचों में टकराव जाँचता है।
2. `check_event_collisions` से `Events` टेबल में टकराव जाँचता है।
3. दोनों पास होने पर `true`।

### आउटपुट
- `Boolean`: `true` अगर कोई टकराव नहीं, अन्यथा `false`।
- उदाहरण: `true`

### उदाहरण
**इनपुट**:
- `home_team = 'Team 1'`, `away_team = 'Team 2'`, `resource = 'Court 1'`, `time = Time.parse('2025-06-02 10:00:00 +0530')`, `current_date = Date.parse('2025-06-02')`
- `@scheduled_matches = []`

**प्रक्रिया**:
- `check_scheduled_matches_collisions?` `true` (कोई शेड्यूल्ड मैच नहीं)।
- `check_event_collisions` `true` (हमेशा)।
- `true` लौटाता है।

**आउटपुट**:
```ruby
true
```

---

## 23. next_date
### यह क्या करता है
`next_date` गेम फ्रीक्वेंसी के आधार पर अगली शेड्यूलिंग तारीख निर्धारित करता है।

### इनपुट पैरामीटर
- **current_date** (`Date`): वर्तमान तारीख।
  - उदाहरण: `Date.parse('2025-06-02')`

### जाँच और प्रक्रिया
1. `@game_frequency` के आधार पर:
   - **दैनिक**: अगला दिन (`current_date + 1`)।
   - **साप्ताहिक**: अगर सप्ताह के भीतर, तो अगला दिन; अन्यथा अगला सोमवार।
   - **मासिक**: अगर महीने के भीतर, तो अगला दिन; अन्यथा अगले महीने की शुरुआत।
   - **डिफॉल्ट**: अगला दिन।
2. अगली तारीख लौटाता है।

### आउटपुट
- `Date`: अगली शेड्यूलिंग तारीख।
- उदाहरण: `Date.parse('2025-06-03')`

### उदाहरण
**इनपुट**:
- `current_date = Date.parse('2025-06-02')` (सोमवार)
- `@game_frequency = 'daily'`

**प्रक्रिया**:
- दैनिक: `current_date + 1` = 2025-06-03।

**आउटपुट**:
```ruby
Date.parse('2025-06-03')
```

**साप्ताहिक उदाहरण**:
- `current_date = Date.parse('2025-06-08')` (रविवार), `@current_period_start = Date.parse('2025-06-02')`
- अगला सोमवार: 2025-06-09।
