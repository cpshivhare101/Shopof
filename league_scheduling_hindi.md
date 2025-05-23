# लीग मैच शेड्यूलिंग आवश्यकताएँ (Hindi)

## परिचय
यह दस्तावेज़ लीग मैच शेड्यूलिंग सिस्टम की आवश्यकताओं को वर्णन करता है। इसका उद्देश्य यह सुनिश्चित करना है कि टीमें न्यूनतम निर्धारित मैच खेलें, और मैच जल्द से जल्द शेड्यूल हों। यूज़र पैरामीटर्स प्रदान करेगा, और अगर कुछ पैरामीटर्स नहीं दिए गए, तो डिफॉल्ट वैल्यूज़ का उपयोग होगा। यह दस्तावेज़ AI और डेवलपर्स दोनों के लिए स्पष्ट और समझने योग्य है।

## मुख्य लक्ष्य
- प्रत्येक टीम कम से कम `min_games_per_team` मैच खेले।
- मैचों को `league_start_date` से शुरू करके `end_date` तक जल्द से जल्द शेड्यूल करना।
- संसाधनों (`resources`) का उपयोग यथासंभव बराबर करना, लेकिन यह अनिवार्य नहीं।
If we have 2 resources and 4 matches the 2 matches will be play on resource 1  and 2 matches will be play on resorce 2.
if we have 5 matches then 3 match with any one resource and 2 match with any sec resource.
but it is not working,
only minimum code update not whole service,  what is requird changes only
- अगर केवल दो टीमें हैं, तो वे एक-दूसरे के खिलाफ बार-बार खेल सकती हैं।
- बिना `number_of_teams` और `resources` के शेड्यूलिंग संभव नहीं।

games: "weekly":
प्रत्येक सप्ताह में, प्रति टीम अधिकतम team_can_play गेम्स शेड्यूल हो सकते हैं (उदाहरण: team_can_play: 1 → प्रति सप्ताह 1 गेम प्रति टीम)।
गेम्स सप्ताह के किसी भी दिन (सोमवार से रविवार) शेड्यूल हो सकते हैं।
तारीखों का चयन क्रमबद्ध होगा:
सप्ताह की शुरुआत सोमवार से (या league_start_date से, अगर बाद में हो)।
प्रत्येक दिन के लिए डिफॉल्ट स्लॉट्स (9:00 AM से 5:00 PM) आजमाएँ।
अगर एक दिन पर शेड्यूलिंग संभव न हो, तो अगले दिन पर जाएँ।
उदाहरण: अगर team_can_play: 3, तो 4 जून 2025 (बुधवार) को 9:00-10:00 पर पहला गेम, फिर 11:00-12:00, 13:00-14:00, आदि। अगर 4 जून पर और गेम संभव न हों, तो 5 जून 2025 को आजमाएँ।
सप्ताह के अंत (रविवार) तक team_can_play सीमा पूरी होनी चाहिए, फिर अगले सप्ताह के सोमवार से शुरू करें।

games: "monthly":
प्रति महीने, प्रति टीम अधिकतम team_can_play गेम्स।
गेम्स महीने की किसी भी तारीख (1 से आखिरी तारीख) पर शेड्यूल हो सकते हैं।
तारीखों का चयन क्रमबद्ध: महीने की पहली तारीख से शुरू, फिर अगली तारीखें।
संसाधन संतुलन:
पिछले जवाब में जोड़ा गया @resource_usage पहले से ही संसाधनों को संतुलित करता है (उदाहरण: 4 मैच → 2+2, 5 मैच → 3+2)।
क्रमबद्ध तारीख चयन:
तारीखें रैंडम नहीं चुनी जाएँगी।
weekly: सप्ताह के सोमवार से रविवार तक, क्रम में।
monthly: महीने की 1 तारीख से आखिरी तारीख तक, क्रम में।
अगर कोई स्लॉट उपलब्ध न हो, तो अगली तारीख/स्लॉट आजमाएँ।

## पैरामीटर्स
नीचे लीग शेड्यूलिंग के लिए यूज़र द्वारा प्रदान किए जाने वाले पैरामीटर्स और उनके विवरण दिए गए हैं:

| पैरामीटर                     | प्रकार       | विवरण                                                                 | डिफॉल्ट वैल्यू                           |
|------------------------------|-------------|----------------------------------------------------------------------|-----------------------------------------|
| `league_start_date`          | Date        | लीग की शुरुआत की तारीख (उदाहरण: 2025-06-02)                           | आज की तारीख                             |
| `min_games_per_team`         | Number      | प्रत्येक टीम के लिए न्यूनतम मैचों की संख्या                           | 5                                       |
| `game_duration`              | Number      | प्रत्येक मैच की अवधि मिनटों में (उदाहरण: 60)                          | 60                                      |
| `number_of_teams`            | Number      | लीग में भाग लेने वाली टीमों की संख्या (अनिवार्य)                     | कोई डिफॉल्ट नहीं (अनिवार्य)             |
| `resources`                  | Array       | उपलब्ध संसाधन (उदाहरण: ['Court 1', 'Court 2']) (अनिवार्य)             | कोई डिफॉल्ट नहीं (अनिवार्य)             |
| `frequency`                  | String      | मैच कितनी बार शेड्यूल होंगे (daily, weekly, monthly)                | daily                                   |
| `games`                      | Number      | प्रति `frequency` अवधि में कितने मैच                                 | 8                                       |
| `double_headers`             | Object      | बैक-टू-बैक मैचों के लिए नियम `{apply: Boolean, force: Boolean, same_resource: Boolean}` | `{apply: false, force: false, same_resource: false}` |
| `end_date`                   | Date        | लीग की अंतिम तारीख                                                  | `league_start_date + 90 days`           |
| `team_can_play`              | Number      | प्रति `frequency` अवधि में अधिकतम मैच (उदाहरण: 5 weekly → 5 मैच हफ्ते में) | कोई डिफॉल्ट नहीं                        |
| `debug`                      | Boolean     | डिबगिंग के लिए                                                     | false                                   |
| `teams_availability_or_not`   | Array       | टीमों की उपलब्धता/अनुपलब्धता नियम                                    | [] (डिफॉल्ट: रोज़ 9:00 AM से 5:00 PM, डेली) |
| `resources_availability_or_not` | Array     | संसाधनों की उपलब्धता/अनुपलब्धता नियम                                  | [] (डिफॉल्ट: रोज़ 9:00 AM से 5:00 PM, डेली) |

## डबल हेडर्स
डबल हेडर नियम बैक-टू-बैक मैचों को शेड्यूल करने के लिए हैं। नियम इस प्रकार हैं:
- **`double_headers.apply: true`**:
  - सिस्टम बैक-टू-बैक मैच शेड्यूल करने की कोशिश करेगा।
  - अगर `force: true`, तो बैक-टू-बैक मैच अनिवार्य हैं। अगर बैक-टू-बैक संभव नहीं है, तो उस दिन उस टीम के लिए कोई मैच शेड्यूल नहीं होगा।
  - अगर `force: false`, तो सिस्टम बैक-टू-बैक मैच की कोशिश करेगा, लेकिन अगर यह संभव नहीं है, तो सामान्य मैच शेड्यूल किए जाएँगे।
  - अगर `same_resource: true`, तो बैक-टू-बैक मैच एक ही संसाधन (जैसे Court 1) पर होंगे। अगर `same_resource: false`, तो अलग-अलग संसाधनों पर भी हो सकते हैं।
- **`double_headers.apply: false`**:
  - डबल हेडर नियमों को पूरी तरह अनदेखा किया जाता है।
  - `team_can_play` के आधार पर एक दिन में कई मैच शेड्यूल हो सकते हैं, बिना बैक-टू-बैक की आवश्यकता के।
  - `force` और `same_resource` का कोई प्रभाव नहीं होता।

## उपलब्धता नियम (Availability Rules)
`teams_availability_or_not` और `resources_availability_or_not` में उपलब्धता नियम शामिल हैं। प्रत्येक नियम में निम्नलिखित फ़ील्ड्स हैं:

| फ़ील्ड           | प्रकार   | विवरण                                                                 |
|-----------------|---------|----------------------------------------------------------------------|
| `day`           | String  | सप्ताह का दिन (उदाहरण: "Monday")                                     |
| `from`          | Time    | शुरू होने का समय (उदाहरण: "10:00")                                    |
| `till`          | Time    | खत्म होने का समय (उदाहरण: "11:00")                                    |
| `effective_from`| Date    | नियम कब से लागू होगा (उदाहरण: "2025-06-02")                           |
| `repeats`       | String  | दोहराव पैटर्न ("weekly", "monthly") (केवल `can_play: true` के लिए)    |
| `can_play`      | Boolean | क्या उस समय खेलना संभव है (true/false)                               |

### `can_play: false` कॉन्सेप्ट
- **`can_play: true`**:
  - यह समय स्लॉट्स को खेलने के लिए उपलब्ध करता है।
  - `repeats` ("weekly" या "monthly") के आधार पर स्लॉट्स जनरेट होते हैं, शुरूआत `effective_from` से।
  - अगर `effective_from` अनुपस्थित है, तो `league_start_date` उपयोग किया जाता है।
  - अगर `repeats` अनुपस्थित है, तो डिफॉल्ट `"weekly"` उपयोग किया जाता है।
  - उदाहरण:
    ```ruby
    teams_availability_or_not = [
      {
        team: "Team 1",
        availability: [
          { day: "Monday", from: "10:00", till: "11:00", can_play: true, effective_from: "2025-06-02", repeats: "weekly" }
        ],
        resources: ["Court 1"]
      }
    ]
    ```
    - परिणाम: Team 1 का मैच 2025-06-02 से शुरू होने वाले प्रत्येक सोमवार को 10:00-11:00 पर Court 1 पर शेड्यूल हो सकता है।
- **`can_play: false`**:
  - यह प्रत्येक निर्दिष्ट दिन (`day`, जैसे प्रत्येक सोमवार) पर दिए गए समय स्लॉट (`from` से `till`) को ब्लॉक करता है, बशर्ते तारीख `effective_from` के बराबर या उससे अधिक हो।
  - **महत्वपूर्ण**:
    - `repeats` फ़ील्ड को पूरी तरह अनदेखा किया जाता है।
    - `effective_from` की जाँच की जाती है:
      - अगर तारीख `effective_from` से कम है, तो समय स्लॉट उपलब्ध रहता है।
      - अगर तारीख `effective_from` के बराबर या उससे अधिक है, तो समय स्लॉट ब्लॉक हो जाता है।
  - उदाहरण:
    ```ruby
    teams_availability_or_not = [
      {
        team: "Team 1",
        availability: [
          { day: "Monday", from: "10:00", till: "11:00", can_play: false, effective_from: "2025-06-09" }
        ],
        resources: ["Court 1"]
      }
    ]
    ```
    - परिणाम:
      - 2025-06-02 को 10:00-11:00 पर Team 1 उपलब्ध है, क्योंकि यह तारीख `effective_from` (2025-06-09) से पहले है।
      - 2025-06-09, 2025-06-16, आदि (प्रत्येक सोमवार) को 10:00-11:00 पर Team 1 का कोई भी मैच Court 1 पर शेड्यूल नहीं होगा, क्योंकि ये तारीखें `effective_from` (2025-06-09) के बराबर या उससे अधिक हैं।
- **संसाधन उपलब्धता**: `resources_availability_or_not` में `can_play: false` उसी तरह काम करता है, यानी प्रत्येक निर्दिष्ट दिन पर समय स्लॉट को ब्लॉक करता है, बशर्ते तारीख `effective_from` के बराबर या उससे अधिक हो, और `repeats` को अनदेखा करता है।
- **नोट**: अगर `resources_availability_or_not` में नियम दिए गए हैं, तो केवल `can_play: true` नियमों के लिए स्लॉट्स जनरेट होंगे। `can_play: false` नियम उन स्लॉट्स को ब्लॉक करते हैं जो अन्यथा उपलब्ध होंगे।

### डिफॉल्ट व्यवहार
- अगर `teams_availability_or_not` में किसी टीम के लिए कोई `can_play: true` नियम नहीं है, तो वह रोज़ 9:00 AM से 5:00 PM तक उपलब्ध मानी जाएगी, सभी संसाधनों पर खेल सकती है, और कोई `cannot_play_against` या `cannot_play_at_same_time_as_another_team` प्रतिबंध नहीं होगा, सिवाय उन स्लॉट्स के जो `can_play: false` द्वारा ब्लॉक हैं।
- अगर `resources_availability_or_not` में किसी संसाधन के लिए कोई `can_play: true` नियम नहीं है, तो वह रोज़ 9:00 AM से 5:00 PM तक उपलब्ध माना जाएगा, सिवाय उन स्लॉट्स के जो `can_play: false` द्वारा ब्लॉक हैं।
- **डिफॉल्ट पैरामीटर्स**:
  - `effective_from`: अगर अनुपस्थित है, तो `league_start_date`।
  - `repeats`: अगर अनुपस्थित है, तो `"weekly"` (केवल `can_play: true` के लिए)।
  - उपलब्धता: 9:00 AM से 5:00 PM, डेली।
- अगर `game_duration`, `frequency`, या `games` नहीं दिए गए, तो `teams_availability_or_not` और `resources_availability_or_not` प्रोग्रामेटिकली जनरेट होंगे, और डिफॉल्ट समय 9:00 AM से 5:00 PM, डेली होगा।

### `repeats` का व्यवहार
- **`weekly`**:
  - केवल `can_play: true` के लिए: हर हफ्ते दिए गए दिन पर शेड्यूलिंग की कोशिश होगी (उदाहरण: Monday), शुरूआत `effective_from` से।
  - `can_play: false` के लिए: `repeats` को अनदेखा किया जाता है; नियम प्रत्येक निर्दिष्ट दिन पर लागू होता है, बशर्ते तारीख `effective_from` के बराबर या उससे अधिक हो।
- **`monthly`**:
  - केवल `can_play: true` के लिए: हर महीने के पहले दिए गए दिन (उदाहरण: Monday) को शेड्यूलिंग की कोशिश होगी। अगर पहला Monday संभव न हो, तो दूसरा, तीसरा, या चौथा Monday आजमाया जाएगा। प्रत्येक महीने में अधिकतम एक बार शेड्यूलिंग।
  - `can_play: false` के लिए: `repeats` को अनदेखा किया जाता है; नियम प्रत्येक निर्दिष्ट दिन पर लागू होता है, बशर्ते तारीख `effective_from` के बराबर या उससे अधिक हो।
- अगर `repeats` कोई अन्य वैल्यू (जैसे `"daily"`) है, तो उसे अनदेखा किया जाएगा, और डिफॉल्ट `"weekly"` उपयोग किया जाएगा (केवल `can_play: true` के लिए)।

### अतिरिक्त नियम (टीमों के लिए)
- **`resources`**: टीम किन संसाधनों पर खेल सकती है (उदाहरण: ["Court 1"])। अगर खाली ([]), तो सभी संसाधन।
- **`cannot_play_against`**: वे टीमें जिनके खिलाफ नहीं खेल सकती (उदाहरण: ["Team 2", "Team 3"])। अगर खाली ([]), तो कोई प्रतिबंध नहीं।
- **`cannot_play_at_same_time_as_another_team`**: वे टीमें जिनके साथ एक ही समय पर नहीं खेल सकती (उदाहरण: ["Team 2"])। अगर खाली ([]), तो कोई प्रतिबंध नहीं। उदाहरण: अगर Team 1 का मैच 2025-06-02 को 10:00 AM पर है, तो Team 2 का कोई भी मैच उसी समय पर नहीं हो सकता।

### उदाहरण
```ruby
league_params = {
  league_start_date: "2025-06-02",
  min_games_per_team: 3,
  game_duration: 60,
  number_of_teams: 2,
  end_date: "2025-08-31",
  resources: ["Court 1"],
  team_can_play: 3,
  games: "daily",
  double_headers: {apply: false, force: false, same_resource: false},
  teams_availability_or_not: [
    {
      team: "Team 1",
      availability: [
        { day: "Monday", from: "10:00", till: "11:00", can_play: false, effective_from: "2025-06-09" }
      ],
      resources: ["Court 1"],
      cannot_play_against: [],
      cannot_play_at_same_time_as_another_team: ["Team 2"]
    }
  ],
  resources_availability_or_not: [
    {
      resource: "Court 1",
      availability: [
        { day: "Monday", from: "10:00", till: "11:00", can_play: true, effective_from: "2025-06-02", repeats: "weekly" },
        { day: "Monday", from: "11:00", till: "12:00", can_play: false, effective_from: "2025-06-02" },
        { day: "Monday", from: "12:00", till: "13:00", can_play: true, effective_from: "2025-06-02", repeats: "weekly" }
      ]
    }
  ]
}
```
#### विवरण:
- लीग 2025-06-02 से शुरू होगी और 2025-08-31 तक चलेगी।
- 2 टीमें (Team 1, Team 2), प्रत्येक को कम से कम 3 मैच खेलने हैं।
- प्रत्येक मैच 60 मिनट का होगा।
- संसाधन: Court 1।
- Team 1: प्रत्येक सोमवार को 10:00-11:00 पर Court 1 पर उपलब्ध नहीं है, लेकिन केवल 2025-06-09 (`effective_from`) या उसके बाद। 2025-06-02 को 10:00-11:00 पर उपलब्ध है। डिफॉल्ट उपलब्धता (9:00 AM से 5:00 PM, डेली) लागू होगी, सिवाय ब्लॉक किए गए स्लॉट्स के।
- Team 2: डिफॉल्ट उपलब्धता (9:00 AM से 5:00 PM, डेली) के साथ सभी संसाधनों पर खेल सकती है।
- Court 1: प्रत्येक सोमवार को 10:00-11:00 और 12:00-13:00 पर उपलब्ध (`can_play: true`), लेकिन 11:00-12:00 ब्लॉक (`can_play: false`), 2025-06-02 से शुरू।
- Team 1 और Team 2 एक ही समय पर शेड्यूल नहीं हो सकते (`cannot_play_at_same_time_as_another_team`).
- डबल हेडर्स अक्षम हैं (`apply: false`)।
- प्रत्येक टीम एक दिन में अधिकतम 3 मैच खेल सकती है (`team_can_play: 3`)।
- प्रत्येक मैच को शेड्यूल करने से पहले, `events` टेबल में होम टीम, अवे टीम, और संसाधन की उपलब्धता चेक की जाएगी।
- Also one twist are here.
if weekly is three matchase can be schedule. it means. We can try each monday to sunday.
suppose we schedule tuesday 2 game and 1 is remaning then we can schedule one match wednes day. also it's for each team. 
The matches can be schedule any of day monday to sunday for week.
and for month it can be schedule 1..last date of month date any of date.
example: 
 team_can_play: 2,
      games: "weekly",
it means, each week monday to sunday can be schedule only 2 matches for each team.
example: 
 team_can_play: 2,
      games: "weekly",
it means, each ,month 1 to  last date  of month can be schedule 2  only matches for each team.





## न्यूनतम और अधिकतम मैच
- प्रत्येक टीम को कम से कम `min_games_per_team` मैच खेलने हैं।
- अगर सभी टीमें `min_games_per_team` तक पहुंच गई हैं, तो शेड्यूलिंग बंद हो जाएगी।
- अगर कुछ टीमें `min_games_per_team` तक नहीं पहुंची हैं, तो उनके लिए अतिरिक्त मैच शेड्यूल होंगे, भले ही दूसरी टीमें `min_games_per_team` से ज्यादा खेल चुकी हों।
- कोई अधिकतम मैच सीमा नहीं, लेकिन अतिरिक्त मैच केवल ज़रूरी होने पर शेड्यूल होंगे।

## मैच शेड्यूलिंग से पहले चेक
किसी भी मैच को शेड्यूल करने से पहले, `events` टेबल में निम्नलिखित चेक करना अनिवार्य है:
- **होम टीम**: उस तारीख और समय पर होम टीम का कोई और मैच नहीं होना चाहिए।
- **अवे टीम**: उस तारीख और समय पर अवे टीम का कोई और मैच नहीं होना चाहिए।
- **संसाधन**: उस तारीख और समय पर संसाधन (जैसे Court 1) पहले से बुक नहीं होना चाहिए।
- **cannot_play_at_same_time_as_another_team**: अगर Team 1 का मैच शेड्यूल है, तो Team 2 का कोई भी मैच उसी समय पर नहीं हो सकता।
- अगर ये सभी उपलब्ध हैं, तो मैच शेड्यूल किया जाएगा। अन्यथा, सिस्टम अगला उपलब्ध स्लॉट ढूंढेगा जो सभी नियमों (`teams_availability_or_not`, `resources_availability_or_not`, आदि) को पूरा करता हो।

## आउटपुट फॉर्मेट
शेड्यूल किए गए मैचों का आउटपुट एक सरणी के रूप में होगा, जिसमें प्रत्येक मैच के लिए निम्नलिखित जानकारी होगी:
- `home`: होम टीम का नाम (उदाहरण: Team 1)।
- `away`: अवे टीम का नाम (उदाहरण: Team 2)।
- `resource`: उपयोग किया गया संसाधन (उदाहरण: Court 1)।
- `date`: मैच की तारीख (उदाहरण: Date.parse("2025-06-02"))।
- `start_time`: मैच शुरू होने का समय (उदाहरण: Time.parse("2025-06-02 10:00:00 +0530"))।
- `end_time`: मैच खत्म होने का समय (उदाहरण: Time.parse("2025-06-02 11:00:00 +0530"))।
- `duration`: मैच की अवधि मिनटों में (उदाहरण: 60)।

### उदाहरण आउटपुट
```ruby
[
  { home: "Team 1", away: "Team 2", resource: "Court 1", date: Date.parse("2025-06-02"), start_time: Time.parse("2025-06-02 10:00:00 +0530"), end_time: Time.parse("2025-06-02 11:00:00 +0530"), duration: 60 },
  { home: "Team 1", away: "Team 2", resource: "Court 1", date: Date.parse("2025-06-02"), start_time: Time.parse("2025-06-02 12:00:00 +0530"), end_time: Time.parse("2025-06-02 13:00:00 +0530"), duration: 60 },
  { home: "Team 1", away: "Team 2", resource: "Court 1", date: Date.parse("2025-06-03"), start_time: Time.parse("2025-06-03 10:00:00 +0530"), end_time: Time.parse("2025-06-03 11:00:00 +0530"), duration: 60 }
]
```

## सामान्य समस्याएँ और समाधान
### समस्या: खाली आउटपुट ([])
**लक्षण**: सर्विस खाली सरणी (`[]`) लौटाती है, जिसका मतलब है कि कोई मैच शेड्यूल नहीं हुआ।
**संभावित कारण**:
- **असंगत उपलब्धता**: टीम या संसाधन उपलब्धता नियम बहुत सख्त हैं (उदाहरण: Team 1 और Team 2 के लिए कोई सामान्य उपलब्ध समय नहीं)।
- **फ्रीक्वेंसी सीमाएँ**: `team_can_play` बहुत कम सेट है, जिससे पर्याप्त मैच शेड्यूल नहीं हो पा रहे।
- **डबल हेडर प्रतिबंध**: अगर `double_headers.force: true` है और बैक-टू-बैक मैच संभव नहीं है, तो मैच शेड्यूल नहीं हो सकते।
- **`cannot_play_at_same_time_as_another_team`**: अगर Team 1 और Team 2 एक ही समय पर शेड्यूल नहीं हो सकते, और उपलब्ध स्लॉट्स सीमित हैं।
**समाधान**:
- `teams_availability_or_not` और `resources_availability_or_not` की जाँच करें ताकि ओवरलैपिंग उपलब्धता सुनिश्चित हो।
- `team_can_play` बढ़ाएँ या `double_headers` सेटिंग्स समायोजित करें।
- `cannot_play_at_same_time_as_another_team` नियमों को समायोजित करें।
- डिफॉल्ट उपलब्धता का उपयोग करें:
  ```ruby
  resources_availability_or_not = []
  teams_availability_or_not = []
  ```

### समस्या: गलत समय स्लॉट्स जनरेट हो रहे हैं (उदाहरण: 09:00 AM)
**लक्षण**: सर्विस उन समय स्लॉट्स पर मैच शेड्यूल कर रही है जो `resources_availability_or_not` में `can_play: true` के रूप में नहीं दिए गए हैं (उदाहरण: 09:00 AM, जब केवल 10:00-11:00 और 12:00-13:00 उपलब्ध हैं)।
**कारण**: `generate_available_slots` मेथड गलती से डिफॉल्ट उपलब्धता (9:00 AM से 5:00 PM) को शामिल कर रहा था, भले ही स्पष्ट नियम दिए गए हों।
**समाधान**:
- `generate_available_slots` अब केवल `can_play: true` नियमों के लिए स्लॉट्स जनरेट करता है जब नियम दिए गए हों।
- डिफॉल्ट उपलब्धता (9:00 AM से 5:00 PM, डेली) केवल तभी लागू होती है जब कोई `can_play: true` नियम न हों।
- `can_play: false` नियम उन स्लॉट्स को ब्लॉक करते हैं जो `can_play: true` स्लॉट्स या डिफॉल्ट उपलब्धता के साथ ओवरलैप करते हैं, बशर्ते तारीख `effective_from` के बराबर या उससे अधिक हो।

### समस्या: `can_play: false` नियम गलत तरीके से लागू हो रहे हैं
**लक्षण**: `can_play: false` नियम उन तारीखों पर लागू हो रहे हैं जो `effective_from` से पहले हैं।
**समाधान**:
- `can_play: false` अब प्रत्येक निर्दिष्ट दिन (जैसे प्रत्येक सोमवार) पर दिए गए समय स्लॉट (`from` से `till`) को ब्लॉक करता है, लेकिन केवल तभी जब तारीख `effective_from` के बराबर या उससे अधिक हो।
- `repeats` को पूरी तरह अनदेखा किया जाता है।
- उदाहरण:
  ```ruby
  teams_availability_or_not = [
    {
      team: "Team 1",
      availability: [
        { day: "Monday", from: "10:00", till: "11:00", can_play: false, effective_from: "2025-06-09" }
      ]
    }
  ]
  ```
  - परिणाम: Team 1 2025-06-02 को 10:00-11:00 पर उपलब्ध है (क्योंकि यह `effective_from` से पहले है), लेकिन 2025-06-09 और उसके बाद प्रत्येक सोमवार को 10:00-11:00 पर अनुपलब्ध है।

### समस्या: डिफॉल्ट उपलब्धता गलत तरीके से लागू हो रही है
**लक्षण**: डिफॉल्ट उपलब्धता (9:00 AM से 5:00 PM) तब भी लागू हो रही है जब स्पष्ट `can_play: true` नियम मौजूद हैं।
**समाधान**:
- डिफॉल्ट उपलब्धता केवल तभी लागू होती है जब कोई `can_play: true` नियम नहीं हैं।
- `can_play: false` नियम डिफॉल्ट उपलब्धता के स्लॉट्स को ब्लॉक कर सकते हैं, प्रत्येक निर्दिष्ट दिन पर, बशर्ते तारीख `effective_from` के बराबर या उससे अधिक हो।
- उदाहरण:
  ```ruby
  teams_availability_or_not = [
    {
      team: "Team 1",
      availability: [
        { day: "Monday", from: "10:00", till: "11:00", can_play: false, effective_from: "2025-06-09" }
      ]
    }
  ]
  ```
  - परिणाम: Team 1 डिफॉल्ट रूप से 9:00 AM से 5:00 PM, डेली उपलब्ध है, सिवाय प्रत्येक सोमवार को 10:00-11:00 के, 2025-06-09 या उसके बाद।

### समस्या: `cannot_play_at_same_time_as_another_team` नियम लागू नहीं हो रहा
**लक्षण**: Team 1 और Team 2 एक ही समय पर शेड्यूल हो रहे हैं, भले ही `cannot_play_at_same_time_as_another_team` नियम मौजूद हो।
**समाधान**:
- सर्विस अब यह सुनिश्चित करती है कि अगर Team 1 का मैच किसी समय पर शेड्यूल है, तो Team 2 का कोई भी मैच उसी समय पर शेड्यूल नहीं होगा।
- उदाहरण:
  ```ruby
  teams_availability_or_not = [
    {
      team: "Team 1",
      cannot_play_at_same_time_as_another_team: ["Team 2"]
    }
  ]
  ```
  - परिणाम: Team 1 और Team 2 के मैच एक ही समय पर शेड्यूल नहीं होंगे।

- Remember thesese points as well.
Resource:
- A resource can be used in only one match at a time — it cannot be shared across multiple matches simultaneously.
For example, if a match is ongoing on resource 'Court 1', no other match can be scheduled at the same time on 'Court 1'.

- Use resources as equally as possible, but it's not mandatory.
EX.
If we have 2 resources and 4 matches, then 2 matches should be played on resource 1 and 2 matches on resource 2.
If we have 5 matches, then 3 matches on any one resource and 2 on the other.
- Resource can be used only if it's available. 
Ex. Need to check availibility in Events table too. 


## निष्कर्ष
यह दस्तावेज़ लीग मैच शेड्यूलिंग की सभी आवश्यकताओं को स्पष्ट रूप से प्रस्तुत करता है। सिस्टम को उपलब्धता नियमों, डबल हेडर्स, संसाधन उपयोग, `cannot_play_at_same_time_as_another_team`, और `events` टेबल में टकराव चेक को ध्यान में रखते हुए न्यूनतम मैच सुनिश्चित करना होगा। `can_play: false` नियम अब प्रत्येक निर्दिष्ट दिन (जैसे प्रत्येक सोमवार) पर समय स्लॉट को ब्लॉक करते हैं, बशर्ते तारीख `effective_from` के बराबर या उससे अधिक हो, जिससे भ्रांति दूर होती है। डिफॉल्ट उपलब्धता (9:00 AM से 5:00 PM, डेली) सुनिश्चित करती है कि शेड्यूलिंग सटीक हो। AI या डेवलपर इस दस्तावेज़ का उपयोग करके एक प्रभावी शेड्यूलिंग समाधान बना सकते हैं।
