# 📁 Project File Structure & Explanation

તમારા ઇન્ટરવ્યુ અને પ્રોજેક્ટને ઊંડાણપૂર્વક સમજવા માટે, અહીં એપની કઈ ફાઈલમાં કયો કોડ છે તેનું પૂરું વર્ણન (File-by-File Explanation) આપેલું છે. આ પ્રોજેક્ટ **Clean Architecture** (Core, Data, Domain, Features) પર બનેલો છે.

---

## 1. 🚀 Main Entry Point (મુખ્ય ફાઈલ)

* **`lib/main.dart`**
  - **કામ:** આખી એપ અહીથી જ શરૂ થાય છે.
  - **ડેટા/કોડ:** અહીં Supabase Database નું ઇનિશિયલાઈઝેશન (Initialization) થાય છે, `BlocProvider` દ્વારા બધી જ Cubits ને આખી એપમાં પ્રોવાઇડ કરવામાં આવે છે, અને `MaterialApp` દ્વારા એપનો મેઈન UI લોડ થાય છે.

---

## 2. ⚙️ Core Folder (મુખ્ય સેટિંગ્સ અને નેટવર્કિંગ)
આ ફોલ્ડરમાં એપના કોમન કોડ્સ હોય છે જે બધી જગ્યાએ વપરાય છે.

* **`core/config/app_config.dart`**
  - **કામ:** બધી API Keys અને Default Settings સાચવવા.
  - **ડેટા:** Groq, Gemini અને Supabase ની API Keys અહીં `String.fromEnvironment` દ્વારા વાંચવામાં આવે છે. Default મોડેલ કયું રાખવું (જેમ કે `Llama 4 Scout`) તેનું સેટિંગ પણ અહીં છે.

* **`core/network/openai_api_client.dart`**
  - **કામ:** એપનું હૃદય (Brain for APIs). 
  - **ડેટા:** AI સર્વર (Groq, Gemini) ને રિક્વેસ્ટ મોકલવાનું કામ આ ફાઈલ કરે છે. Streaming (ટુકડે-ટુકડે શબ્દો આવવા), ફોટા (Base64) મોકલવા, અને જો કોઈ સર્વર એરર આપે (404, 503) તો તેને હેન્ડલ કરવાનું જટિલ લોજીક અહીં છે.

* **`core/theme/app_theme.dart`**
  - **કામ:** એપની ડિઝાઈન અને કલર્સ.
  - **ડેટા:** ડાર્ક મોડ અને લાઈટ મોડના કલર્સ.

---

## 3. 💾 Data Folder (ડેટાબેઝ અને API ઇમ્પ્લીમેન્ટેશન)
આ ફોલ્ડર ડેટા લાવવા અને સાચવવાનું કામ કરે છે.

### 📝 Models (ડેટાનું સ્ટ્રક્ચર)
* **`data/models/chat_message.dart`** 
  - એક મેસેજ કેવો દેખાશે (તેનું લખાણ, રોલ - યુઝર કે AI, ફોટો કે ઓડિયો).
* **`data/models/conversation.dart`** 
  - આખી ચેટ હિસ્ટ્રી (એક ચેટમાં કેટલા મેસેજ છે) તેનું સ્ટ્રક્ચર. 
  *(નોંધ: જે ફાઈલોની પાછળ `.g.dart` છે, તે ઑટોમૅટિક બનેલી JSON ફાઈલો છે.)*

### 🗄️ Data Sources (ડેટા ક્યાંથી આવશે?)
* **`data/datasources/supabase_chat_data_source.dart`**
  - ચેટના મેસેજને ઓનલાઈન Supabase ડેટાબેઝમાં સેવ કરવા અને ત્યાંથી પાછા લાવવા.
* **`data/datasources/chat_cache_data_source.dart`**
  - ઓફલાઈન ચેટ સેવ કરવા માટે લોકલ કેશ (Local Cache).

### 🔄 Repositories (ડેટા મેનેજમેન્ટ)
* **`data/repositories/auth_repository.dart`**
  - યુઝરનું Login, Signup અને Logout કરવાનું Supabase લોજીક.
* **`data/repositories/chat_repository_impl.dart`**
  - લોકલ ડેટા અને ઓનલાઈન ડેટાબેઝ બંને વચ્ચે ચેટને સિંક (Sync) કરવાનું કામ.
* **`data/repositories/openai_repository_impl.dart`**
  - `openai_api_client.dart` નો ઉપયોગ કરીને મેસેજ મોકલીને જવાબ લાવવાનું વચેટિયા (Middleman) જેવું કામ.

---

## 4. 🧠 Domain Folder (નિયમો)
* **`domain/repositories/chat_repository.dart` & `openai_repository.dart`**
  - **કામ:** આ માત્ર Abstract Classes (ઈન્ટરફેસ) છે. તે નક્કી કરે છે કે કયા ફંક્શન બનવા જોઈએ (જેમ કે `sendMessage`), પણ તે ફંક્શન અંદર શું કરશે તે Data ફોલ્ડર નક્કી કરે છે.

---

## 5. 📱 Features Folder (સ્ક્રીન અને યુઝર ઇન્ટરફેસ)
અહીં એપના મેઈન પેજ અને તેની State Management ની ફાઈલો છે.

### 🔐 Auth Feature (લોગિન અને રજીસ્ટર)
* **`features/auth/view/login_page.dart` & `register_page.dart`**
  - યુઝરને દેખાતી લોગિન અને સાઈન-અપ સ્ક્રીન (UI).
* **`features/auth/cubit/auth_cubit.dart`**
  - લોગિન બટન દબાવ્યા પછી શું થશે (Loading ફરવું, એરર બતાવવી, Login સક્સેસ થાય તો પેજ બદલવું) તેનું લોજીક.

### 💬 Chat Feature (મુખ્ય ચેટિંગ સિસ્ટમ)
* **`features/chat/view/chat_page.dart`**
  - મુખ્ય ચેટ સ્ક્રીન (UI).
* **`features/chat/widgets/chat_composer.dart`**
  - નીચેનું ટાઈપિંગ બોક્સ, માઈક (Voice Record) બટન, અને ફોટો (Image Picker) સિલેક્ટ કરવાનું બટન. વોઇસ નોટનું રેકોર્ડિંગ પણ અહીં જ હેન્ડલ થાય છે.
* **`features/chat/widgets/message_list.dart`**
  - સ્ક્રીન પર દેખાતા બધા મેસેજનું લિસ્ટ (જેમાં યુઝરના અને AI ના મેસેજ હોય છે).
* **`features/chat/widgets/audio_message_bubble.dart`**
  - જ્યારે યુઝર વોઇસ નોટ મોકલે, ત્યારે તે ઓડિયોને પ્લે (Play/Pause) કરવા માટેનું કસ્ટમ UI પ્લેયર.
* **`features/chat/widgets/chat_drawer.dart`**
  - ડાબી બાજુ ખુલતું સાઈડબાર જેમાં જૂની ચેટની હિસ્ટ્રી દેખાય છે અને "New Chat" નું બટન હોય છે.
* **`features/chat/cubit/chat_cubit.dart`**
  - આ ચેટ સિસ્ટમનું **મગજ (Brain)** છે!
  - મેસેજ ટાઈપ કર્યા પછી સેન્ડ કરવું, AI નો ટુકડે-ટુકડે આવતો જવાબ (Streaming) હેન્ડલ કરવો, Whisper API થી અવાજને ટેક્સ્ટમાં કન્વર્ટ કરવો, અને જો કોઈ મોડેલ એરર (404/503) આપે તો ઑટોમૅટિક નવું મોડેલ (Fallback) ચાલુ કરવાનું બધું જ લોજીક અહીં લખેલું છે.

---
**💡 પ્રો ટીપ:** ઇન્ટરવ્યુમાં તમે કહી શકો છો કે: 
*"મેં આખો પ્રોજેક્ટ Clean Architecture મુજબ બનાવ્યો છે, જેથી UI (જે યુઝરને દેખાય) અને Logic (જે બેકગ્રાઉન્ડમાં કામ કરે - API/Database) બંને એકબીજાથી અલગ રહે. એટલે ભવિષ્યમાં જો કોઈ મોટો ફેરફાર કરવો હોય તો બહુ જ સહેલાઈથી થઈ શકે."*
