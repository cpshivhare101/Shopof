# लीग शेड्यूलिंग सर्विस दस्तावेज़

## परिचय
`LeagueEventsSchedulerService` एक शक्तिशाली सिस्टम है जो खेल लीग के लिए मैच शेड्यूलिंग को स्वचालित करता है। इसका मुख्य उद्देश्य यह सुनिश्चित करना है कि प्रत्येक टीम न्यूनतम निर्धारित मैच (`min_games_per_team`) खेले, और मैच `league_start_date` से शुरू होकर `end_date` तक यथासंभव जल्दी शेड्यूल हों। यह सिस्टम तीन इनपुट पर आधारित है: `league_params`, `resources_availability`, और `teams_availability`। यदि कुछ पैरामीटर्स अनुपस्थित हैं, तो डिफॉल्ट मान लागू किए जाते हैं। यह दस्तावेज़ AI और डेवलपर्स दोनों के लिए सरल और स्पष्ट भाषा में लिखा गया है ताकि सिस्टम की पूरी कार्यप्रणाली आसानी से समझी जा सके।

## मुख्य लक्ष्य
- प्रत्येक टीम कम से कम `min_games_per_team` मैच खेले।
- मैचों को `league_start_date` से शुरू करके `end_date` तक क्रमबद्ध और जल्द से जल्द शेड्यूल करना।
- संसाधनों (जैसे खेल के मैदान) का उपयोग यथासंभव संतुलित करना (उदाहरण: 4 मैच, 2 संसाधनों पर 2-2; 5 मैच, एक पर 3 और दूसरे पर 2), लेकिन यह अनिवार्य नहीं।
- यदि केवल दो टीमें हैं, तो वे एक-दूसरे के खिलाफ बार-बार खेल सकती हैं।
- `number_of_teams` अनिवार्य है। `resources_availability` में कम से कम एक संसाधन `{}` होना चाहिए।
- एक संसाधन एक समय में केवल एक मैच के लिए उपयोग हो सकता है।
- `teams_availability` यदि दी गई है, तो यह `resources_availability` को ओवरराइड करती है।
- यदि `availability` खाली (`[]`) है, तो डिफॉल्ट समय 9:00 AM से 5:00 PM प्रतिदिन लागू होता है।
- संसाधनों की पहचान के लिए एक अतिरिक्त यूनिक कुंजी (`unique_resource_id`) जोड़ी जाती है, क्योंकि `resource_detail_id` यूनिक होने की गारंटी नहीं है।
- समय स्लॉट्स एप्लिकेशन के टाइमज़ोन (उदाहरण: Asia/Kolkata, +0530) में प्रोसेस किए जाते हैं।

## पैरामीटर्स
### 1. `league_params`
यह हैश लीग की सामान्य सेटिंग्स को परिभाषित करता है।

| पैरामीटर                     | प्रकार       | विवरण                                                                 | डिफॉल्ट वैल्यू                           |
|------------------------------|-------------|----------------------------------------------------------------------|-----------------------------------------|
| `league_start_date`          | String      | लीग की शुरुआत की तारीख (उदाहरण: "2025-06-02")                         | आज की तारीख                             |
| `min_games_per_team`         | Number      | प्रत्येक टीम के लिए न्यूनतम मैचों की संख्या                           | 3                                       |
| `game_duration`              | Number      | प्रत्येक मैच की अवधि मिनटों में (उदाहरण: 60)                          | 60                                      |
| `number_of_teams`            | Number      | लीग में भाग लेने वाली टीमें (अनिवार्य)                              | कोई डिफॉल्ट नहीं (अनिवार्य)             |
| `resources`                  | Array       | संसाधनों की सूची (हमेशा `[]`)                                       | `[]`                                    |
| `games`                      | String      | शेड्यूलिंग आवृत्ति (daily, weekly, monthly)                         | daily                                   |
| `team_can_play`              | Number      | प्रति `games` अवधि में अधिकतम मैच प्रति टीम                          | 3                                       |
| `double_headers`             | Hash        | बैक-टू-बैक मैच नियम `{apply: Boolean, force: Boolean, same_resource: Boolean}` | `{apply: false, force: false, same_resource: false}` |
| `end_date`                   | String      | लीग की अंतिम तारीख                                                  | `league_start_date + 90 days`           |
| `debug`                      | Boolean     | डिबगिंग लॉगिंग के लिए                                              | false                                   |
| `facility_details`           | Array       | सुविधा विवरण (वर्तमान में उपयोग नहीं)                                | `[]`                                    |
| `brands_and_addresses`       | Array       | ब्रांड और पते (वर्तमान में उपयोग नहीं)                               | `[]`                                    |

**नोट**: `resources` हमेशा खाली (`[]`) होता है। वास्तविक संसाधन `resources_availability` से लिए जाते हैं।

### 2. `resources_availability`
यह एक सरणी है, जिसमें कम से कम एक संसाधन `{}` होता है। प्रत्येक तत्व एक संसाधन (जैसे खेल का मैदान) और उसकी उपलब्धता को परिभाषित करता है, जो सभी टीमों के लिए डिफॉल्ट उपलब्धता प्रदान करता है, जब तक कि `teams_availability` द्वारा ओवरराइड न हो।

**संरचना**:
```ruby
[
  {
    unique_resource_id: String, # सिस्टम द्वारा जोड़ा गया यूनिक पहचानकर्ता (उदाहरण: "resource_1")
    resource_detail_id: Number|nil, # संसाधन का पहचानकर्ता (उदाहरण: 148, या nil; यूनिक नहीं)
    product_name_of_resource_registration_id: Number|nil, # वैकल्पिक, उपयोग नहीं
    subresource_id: Number|nil, # वैकल्पिक, उपयोग नहीं
    facility_detail_id: Number|nil, # वैकल्पिक, उपयोग नहीं
    size: String|nil, # वैकल्पिक, उपयोग नहीं
    address: Hash|nil, # वैकल्पिक, उपयोग नहीं
    brand_id: Number|nil, # वैकल्पिक, उपयोग नहीं
    availability: [
      {
        day: String, # सप्ताह का दिन (उदाहरण: "Monday")
        from: String, # शुरू समय (HH:MM, उदाहरण: "10:00")
        till: String, # अंत समय (HH:MM, उदाहरण: "11:00")
        can_play: Boolean, # खेलना संभव है या नहीं
        effective_from: String, # नियम कब से लागू (उदाहरण: "2025-06-02")
        repeats: String # दोहराव पैटर्न (daily, weekly, monthly)
      }
    ]
  }
]
```

- **unique_resource_id**: सिस्टम द्वारा जनरेट किया गया यूनिक पहचानकर्ता (उदाहरण: "resource_1")। प्रत्येक संसाधन हैश के लिए जोड़ा जाता है।
- **resource_detail_id**: यदि मौजूद, तो संसाधन का पहचानकर्ता, लेकिन यूनिक होने की गारंटी नहीं। केवल रिकॉर्ड के लिए संरक्षित।
- **availability**: यदि खाली (`[]`), तो संसाधन प्रतिदिन 9:00 AM से 5:00 PM उपलब्ध।
- **can_play: false**: समय स्लॉट को ब्लॉक करता है यदि तारीख `effective_from` के बराबर या बाद की है। `repeats` अनदेखा होता है।
- **अन्य फ़ील्ड्स**: जैसे `product_name_of_resource_registration_id`, `subresource_id`, आदि, अनदेखा किए जाते हैं।
- **न्यूनतम आवश्यकता**: कम से कम एक संसाधन `{}` होना चाहिए।

### 3. `teams_availability`
यह एक सरणी है, जो विशिष्ट टीमों के लिए संसाधन और उपलब्धता को परिभाषित करती है। यदि कोई टीम यहाँ परिभाषित है, तो यह `resources_availability` को ओवरराइड करती है। सभी टीमें (उदाहरण: यदि `number_of_teams: 3`) यहाँ परिभाषित नहीं हो सकतीं।

**संरचना**:
```ruby
[
  {
    team: String, # टीम का नाम (उदाहरण: "Team 1")
    resources: [
      {
        unique_resource_id: String, # सिस्टम द्वारा जोड़ा गया यूनिक पहचानकर्ता (उदाहरण: "resource_1")
        resource_detail_id: Number|nil, # संसाधन का पहचानकर्ता (उदाहरण: 148, या nil; यूनिक नहीं)
        product_name_of_resource_registration_id: Number|nil, # वैकल्पिक, उपयोग नहीं
        subresource_id: Number|nil, # वैकल्पिक, उपयोग नहीं
        facility_detail_id: Number|nil, # वैकल्पिक, उपयोग नहीं
        size: String|nil, # वैकल्पिक, उपयोग नहीं
        address: Hash|nil, # वैकल्पिक, उपयोग नहीं
        brand_id: Number|nil, # वैकल्पिक, उपयोग नहीं
        availability: [
          {
            day: String, # सप्ताह का दिन
            from: String, # शुरू समय (HH:MM)
            till: String, # अंत समय (HH:MM)
            can_play: Boolean, # खेलना संभव है या नहीं
            effective_from: String, # नियम कब से लागू
            repeats: String # दोहराव पैटर्न
          }
        ]
      }
    ],
    availability: [], # बैकवर्ड संगतता के लिए, उपयोग नहीं
    cannot_play_against: Array, # टीमें जिनके खिलाफ नहीं खेल सकती (उदाहरण: ["Team 2"])
    cannot_play_at_same_time_as_another_team: Array # टीमें जिनके साथ एक ही समय पर नहीं खेल सकती
  }
]
```

- **unique_resource_id**: सिस्टम द्वारा जोड़ा गया यूनिक पहचानकर्ता, जो `resources_availability` के संसाधनों से मेल खाता है।
- **resources**: यदि खाली (`[]`), तो टीम `resources_availability` के सभी संसाधनों का उपयोग कर सकती है। अन्यथा, केवल निर्दिष्ट संसाधन।
- **availability (प्रति संसाधन)**: प्रत्येक संसाधन के लिए अलग-अलग उपलब्धता नियम। यदि खाली (`[]`), तो डिफॉल्ट 9:00 AM–5:00 PM प्रतिदिन।
- **availability (शीर्ष स्तर)**: बैकवर्ड संगतता के लिए; वर्तमान में अनदेखा।
- **cannot_play_against**: उन टीमों की सूची जिनके खिलाफ यह टीम नहीं खेल सकती।
- **cannot_play_at_same_time_as_another_team**: उन टीमों की सूची जिनके साथ एक ही समय पर मैच शेड्यूल नहीं हो सकता।

## उपलब्धता नियम
### डिफॉल्ट व्यवहार
- **संसाधन**:
  - यदि `resources_availability` खाली है, तो एक डिफॉल्ट संसाधन (`unique_resource_id: "default_resource"`) बनाया जाता है, जो प्रतिदिन 9:00 AM–5:00 PM उपलब्ध।
  - यदि किसी संसाधन की `availability` खाली है, तो वह प्रतिदिन 9:00 AM–5:00 PM उपलब्ध।
- **टीम**:
  - यदि कोई टीम `teams_availability` में परिभाषित नहीं है, तो वह `resources_availability` के सभी संसाधनों का उपयोग करती है।
  - यदि किसी टीम के संसाधन की `availability` खाली है, तो डिफॉल्ट 9:00 AM–5:00 PM प्रतिदिन लागू।
- **effective_from**: यदि अनुपस्थित, तो `league_start_date`।
- **repeats**: यदि अनुपस्थित, तो `"weekly"` (केवल `can_play: true` के लिए)।

### `can_play: false` नियम
- प्रत्येक निर्दिष्ट दिन (जैसे प्रत्येक सोमवार) पर समय स्लॉट (`from` से `till`) को ब्लॉक करता है, यदि तारीख `effective_from` के बराबर या बाद की है।
- `repeats` को अनदेखा किया जाता है।
- उदाहरण:
  ```ruby
  teams_availability = [
    {
      team: "Team 1",
      resources: [
        {
          unique_resource_id: "resource_1",
          resource_detail_id: 148,
          availability: [
            { day: "Monday", from: "10:00", till: "11:00", can_play: false, effective_from: "2025-06-09" }
          ]
        }
      ]
    }
  ]
  ```
  - परिणाम: Team 1 संसाधन "resource_1" पर प्रत्येक सोमवार को 10:00–11:00, 2025-06-09 या उसके बाद अनुपलब्ध।

### `repeats` व्यवहार
- **weekly**: प्रत्येक सप्ताह के निर्दिष्ट दिन पर लागू (उदाहरण: प्रत्येक सोमवार)।
- **monthly**: प्रत्येक महीने के पहले चार निर्दिष्ट दिनों पर लागू।
- **daily**: प्रतिदिन लागू।
- केवल `can_play: true` के लिए मान्य। `can_play: false` के लिए `repeats` अनदेखा।

## यूनिक संसाधन पहचानकर्ता
- `resource_detail_id` यूनिक होने की गारंटी नहीं है। सिस्टम प्रत्येक संसाधन हैश में एक नई कुंजी `unique_resource_id` जोड़ता है।
- **रणनीति**:
  - प्रत्येक संसाधन हैश (दोनों `resources_availability` और `teams_availability` में) को एक यूनिक पहचानकर्ता असाइन करें।
  - जनरेशन नियम: इंडेक्स-आधारित (उदाहरण: "resource_0", "resource_1")।
  - `teams_availability` में संसाधन `resource_detail_id` के आधार पर `resources_availability` के `unique_resource_id` से मेल खाते हैं।
  - यदि `resource_detail_id` मेल नहीं खाता, तो डिफॉल्ट `unique_resource_id` जनरेट किया जाता है।
- उदाहरण:
  ```ruby
  resources_availability = [
    { resource_detail_id: nil, availability: [...] },
    { resource_detail_id: 148, availability: [...] },
    { resource_detail_id: 148, availability: [...] }
  ]
  ```
  - परिणाम: `unique_resource_id` असाइन किए जाते हैं: `["resource_0", "resource_1", "resource_2"]`।
  - `teams_availability` में `{resource_detail_id: 148}` पहले मेल खाने वाले `unique_resource_id` (जैसे "resource_1") से जोड़ा जाता है।

## शेड्यूलिंग आवृत्ति (`games`)
### 1. **Daily**
- प्रत्येक दिन, प्रति टीम अधिकतम `team_can_play` मैच।
- समय स्लॉट्स उपलब्धता नियमों या डिफॉल्ट (9:00 AM–5:00 PM) के अनुसार।
- अगले दिन पर जाएँ यदि कोई स्लॉट उपलब्ध नहीं।

### 2. **Weekly**
- प्रत्येक सप्ताह (सोमवार से रविवार), प्रति टीम अधिकतम `team_can_play` मैच।
- मैच सप्ताह के किसी भी दिन शेड्यूल हो सकते हैं (उदाहरण: मंगलवार को 1, बुधवार को 1)।
- अगले सप्ताह पर जाएँ यदि स्लॉट्स खत्म।

### 3. **Monthly**
- प्रत्येक महीने (1 से अंतिम तारीख), प्रति टीम अधिकतम `team_can_play` मैच।
- तारीखें क्रमबद्ध चुनी जाती हैं: महीने की पहली तारीख से शुरू।
- अगले महीने पर जाएँ यदि स्लॉट्स खत्म।

## डबल हेडर्स
- **`double_headers.apply: true`**:
  - बैक-टू-बैक मैच शेड्यूल करने की कोशिश।
  - `force: true`: बैक-टू-बैक अनिवार्य; असंभव होने पर कोई मैच नहीं।
  - `force: false`: सामान्य मैच शेड्यूल हो सकते हैं।
  - `same_resource: true`: बैक-टू-बैक मैच एक ही संसाधन पर।
- **`double_headers.apply: false`**:
  - डबल हेडर नियम अनदेखा।
  - `team_can_play` के आधार पर एक दिन में कई मैच संभव।

## शेड्यूलिंग से पहले चेक
प्रत्येक मैच शेड्यूल करने से पहले:
- **होम और अवे टीम**: उस समय कोई अन्य मैच नहीं होना चाहिए।
- **संसाधन**: उस समय पहले से बुक नहीं होना चाहिए (`Events` तालिका में जाँच)।
- **cannot_play_at_same_time_as_another_team**: यदि Team 1 का मैच है, तो Team 2 का उसी समय नहीं हो सकता।
- सभी शर्तें पूरी होने पर ही मैच शेड्यूल होता है।

## संसाधन प्रबंधन
- संसाधन `unique_resource_id` द्वारा पहचाने जाते हैं।
- प्रत्येक संसाधन एक समय में केवल एक मैच के लिए उपयोग हो सकता है।
- `teams_availability` में संसाधन यदि परिभाषित हैं, तो वह टीम केवल उन संसाधनों का उपयोग कर सकती है।
- यदि `teams_availability.resources` खाली है, तो `resources_availability` के सभी संसाधन उपयोग हो सकते हैं।
- संसाधन उपयोग को संतुलित करने की कोशिश की जाती है (`@resource_usage` द्वारा ट्रैक)।

## आउटपुट फॉर्मेट
शेड्यूल किए गए मैचों की सूची एक सरणी में:
```ruby
[
  {
    home: String, # होम टीम (उदाहरण: "Team 1")
    away: String, # अवे टीम (उदाहरण: "Team 2")
    resource: String, # संसाधन (उदाहरण: "resource_1")
    date: Date, # तारीख (उदाहरण: Date.parse("2025-06-02"))
    start_time: Time, # शुरू समय (उदाहरण: Time.parse("2025-06-02 10:00:00 +0530"))
    end_time: Time, # अंत समय (उदाहरण: Time.parse("2025-06-02 11:00:00 +0530"))
    duration: Number # अवधि मिनटों में (उदाहरण: 60)
  }
]
```

## उदाहरण
**इनपुट**:
```ruby
league_params = {
  league_start_date: "2025-06-13",
  min_games_per_team: 2,
  game_duration: 60,
  number_of_teams: 3,
  resources: [],
  team_can_play: 2,
  games: "weekly",
  double_headers: { apply: false, force: false, same_resource: false },
  debug: false
}

resources_availability = [
  { resource_detail_id: nil, availability: [{ day: "Monday", from: "10:00", till: "11:00", can_play: true, effective_from: "2025-06-13", repeats: "weekly" }] },
  { resource_detail_id: 148, availability: [] }, # 9:00 AM–5:00 PM daily
  { resource_detail_id: 148, availability: [{ day: "Tuesday", from: "09:00", till: "10:00", can_play: true, effective_from: "2025-06-13", repeats: "weekly" }] }
]

teams_availability = [
  {
    team: "Team 1",
    resources: [
      {
        resource_detail_id: 148,
        availability: [
          { day: "Monday", from: "13:00", till: "14:00", can_play: true, effective_from: "2025-06-13", repeats: "weekly" }
        ]
      },
      {
        resource_detail_id: nil,
        availability: [] # 9:00 AM–5:00 PM daily
      }
    ],
    cannot_play_against: [],
    cannot_play_at_same_time_as_another_team: []
  }
]
```

**विवरण**:
- **टीमें**: Team 1, Team 2, Team 3.
- **संसाधन**:
  - `resources_availability`:
    - `{resource_detail_id: nil}` → `unique_resource_id: "resource_0"`
    - `{resource_detail_id: 148}` → `unique_resource_id: "resource_1"`
    - `{resource_detail_id: 148}` → `unique_resource_id: "resource_2"`
  - उपलब्धता:
    - "resource_0": सोमवार 10:00–11:00
    - "resource_1": 9:00 AM–5:00 PM daily
    - "resource_2": मंगलवार 09:00–10:00
- **Team 1**:
  - संसाधन:
    - `{resource_detail_id: 148}` → `unique_resource_id: "resource_1"`, सोमवार 13:00–14:00
    - `{resource_detail_id: nil}` → `unique_resource_id: "resource_0"`, 9:00 AM–5:00 PM daily
  - `resources_availability` को ओवरराइड करता है।
- **Team 2, Team 3**:
  - संसाधन: "resource_0", "resource_1", "resource_2" (`resources_availability` से)।
- **शेड्यूलिंग**:
  - प्रत्येक सप्ताह प्रति टीम 2 मैच।
  - Team 1 vs Team 2: संसाधन "resource_1" पर सोमवार, 2025-06-16, 13:00–14:00।
  - Team 2 vs Team 3: संसाधन "resource_1" पर मंगलवार, 2025-06-17, 09:00–10:00।

**आउटपुट**:
```ruby
[
  { home: "Team 1", away: "Team 2", resource: "resource_1", date: Date.parse("2025-06-16"), start_time: Time.parse("2025-06-16 13:00:00 +0530"), end_time: Time.parse("2025-06-16 14:00:00 +0530"), duration: 60 },
  { home: "Team 2", away: "Team 3", resource: "resource_1", date: Date.parse("2025-06-17"), start_time: Time.parse("2025-06-17 09:00:00 +0530"), end_time: Time.parse("2025-06-17 10:00:00 +0530"), duration: 60 }
]
```

## सामान्य समस्याएँ और समाधान
1. **खाली आउटपुट (`[]`)**:
   - **कारण**: सख्त उपलब्धता नियम, कम `team_can_play`, या `cannot_play_at_same_time_as_another_team` प्रतिबंध।
   - **समाधान**: उपलब्धता नियमों को ढीला करें, `team_can_play` बढ़ाएँ, या डिफॉल्ट उपलब्धता उपयोग करें:
     ```ruby
     resources_availability = [{}]
     teams_availability = []
     ```

2. **गलत समय स्लॉट्स**:
   - **कारण**: `teams_availability` सही ढंग से `resources_availability` को ओवरराइड नहीं कर रही।
   - **समाधान**: सुनिश्चित करें कि `team_available?` प्रति संसाधन उपलब्धता नियमों को प्राथमिकता देता है।

3. **संसाधन टकराव**:
   - **कारण**: एक ही समय में एक संसाधन पर कई मैच।
   - **समाधान**: `no_conflicts?` विधि `Events` तालिका और शेड्यूल किए गए मैचों में टकराव की जाँच करती है।

4. **संसाधन पहचान भ्रम**:
   - **कारण**: गैर-यूनिक `resource_detail_id`।
   - **समाधान**: `unique_resource_id` का उपयोग संसाधनों को एकसमान रूप से पहचानने के लिए।

## निष्कर्ष
`LeagueEventsSchedulerService` एक लचीला और मजबूत सिस्टम है जो न्यूनतम मैच सुनिश्चित करता है, उपलब्धता नियमों, डबल हेडर्स, संसाधन संतुलन, और टकरावों को ध्यान में रखता है। यह `unique_resource_id` के उपयोग से संसाधनों को यूनिक रूप से पहचानता है, और `teams_availability` प्रति संसाधन उपलब्धता को परिभाषित करके `resources_availability` को ओवरराइड करता है। यह दस्तावेज़ सिस्टम की कार्यप्रणाली को सरल और स्पष्ट रूप से प्रस्तुत करता है, जिससे AI या डेवलपर इसे आसानी से समझ और लागू कर सकते हैं।
