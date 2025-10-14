// file: lib/pharma_mate_chat.dart
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class PharmaMateChat extends StatefulWidget {
  const PharmaMateChat({super.key});
  @override
  State<PharmaMateChat> createState() => _PharmaMateChatState();
}

class _PharmaMateChatState extends State<PharmaMateChat> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();

  final List<_Msg> _messages = <_Msg>[
    const _Msg.bot("👋 Welcome to Pharma Mate! Ask me anything."),
  ];

  bool _loading = false;
  bool _typing = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;

    setState(() {
      _messages.add(_Msg.user(q));
      _loading = true;
      _typing = true;
      _ctrl.clear();
    });
    await Future.delayed(const Duration(milliseconds: 16));
    _scrollToEnd();

    try {
      final ans = await MedicalApiService.askMedicalQuestion(q);
      await _streamIn(ans);
    } catch (e) {
      _pushBot("😕 I had trouble fetching an answer. ($e)");
    } finally {
      setState(() {
        _loading = false;
        _typing = false;
      });
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent + 200,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _streamIn(String text) async {
    const step = 28;
    String acc = "";
    for (int i = 0; i < text.length; i += step) {
      acc = text.substring(0, min(i + step, text.length));
      if (i == 0) {
        setState(() => _messages.add(_Msg.bot(acc)));
      } else {
        setState(() => _messages[_messages.length - 1] = _Msg.bot(acc));
      }
      _scrollToEnd();
      await Future.delayed(const Duration(milliseconds: 14));
    }
  }

  void _pushBot(String s) {
    setState(() => _messages.add(_Msg.bot(s)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("PharmaMate"),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF9FAFB), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Image.asset(
                  "assets/icons/pharma_mate_icon.png",
                  height: 120,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.4)),
                      ),
                      child: ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _messages.length + (_typing ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (_typing && i == _messages.length) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: TypingIndicator(),
                            );
                          }
                          final m = _messages[i];
                          return Align(
                            alignment: m.isBot
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: m.isBot
                                    ? Theme.of(context).colorScheme.secondary.withOpacity(0.10)
                                    : Theme.of(context).colorScheme.primary.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.5)),
                              ),
                              child: SelectableText(m.text),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            _Composer(controller: _ctrl, onSend: _send, loading: _loading),
          ],
        ),
      ),
    );
  }
}

// 🔹 Typing animation
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});
  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final offset = sin((_controller.value * 2 * pi) + (i * pi / 2)) * 4;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
              transform: Matrix4.translationValues(0, -offset, 0),
            );
          },
        );
      }),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool loading;
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.loading,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: "Ask me anything…",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: loading ? null : onSend,
            child: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Send"),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final String text;
  final bool isBot;
  const _Msg.bot(this.text) : isBot = true;
  const _Msg.user(this.text) : isBot = false;
}

/// 🔹 Offline chatbot with 30 home treatments
class MedicalApiService {
  static Future<String> askMedicalQuestion(String question) async {
    final q = question.toLowerCase();

    final Map<List<String>, String> faq = {
      // === COMMON SYMPTOMS & CONDITIONS ===
      ["back pain", "backache", "spine", "lumbar pain"]:
          "🩺 **Back Pain Management:**\n\n"
          "**Immediate Relief:**\n"
          "• Apply ice for 15-20 minutes, then heat for 20-30 minutes\n"
          "• Gentle stretching: knee-to-chest, cat-cow stretches\n"
          "• Maintain good posture: shoulders back, spine straight\n"
          "• Sleep on your side with a pillow between knees\n\n"
          "**Prevention:**\n• Strengthen core muscles (planks, bridges)\n"
          "• Lift with your legs, not your back\n"
          "• Take breaks from sitting every hour\n\n"
          "⚠️ **Seek immediate medical care if:**\n"
          "• Severe pain with numbness/weakness in legs\n"
          "• Loss of bladder/bowel control\n"
          "• Pain after trauma or accident",

      ["headache", "migraine", "tension headache"]:
          "🤕 **Headache Relief:**\n\n"
          "**Immediate Treatment:**\n"
          "• Rest in a dark, quiet room\n"
          "• Apply cold compress to forehead/temples\n"
          "• Stay hydrated (dehydration is a common cause)\n"
          "• Gentle neck and shoulder stretches\n"
          "• Over-the-counter pain relievers (ibuprofen, acetaminophen)\n\n"
          "**Prevention:**\n"
          "• Regular sleep schedule (7-9 hours)\n"
          "• Manage stress with relaxation techniques\n"
          "• Limit caffeine and alcohol\n"
          "• Regular exercise and balanced meals\n\n"
          "⚠️ **Emergency signs:**\n"
          "• Sudden, severe headache (thunderclap)\n"
          "• Headache with fever, neck stiffness, confusion\n"
          "• Headache after head injury",

      ["cold", "cough", "sore throat", "upper respiratory infection"]:
          "🤧 **Cold & Cough Management:**\n\n"
          "**Symptom Relief:**\n"
          "• Stay hydrated: warm tea, soup, water\n"
          "• Gargle with salt water for sore throat\n"
          "• Use humidifier or steam inhalation\n"
          "• Honey and lemon for cough (adults only)\n"
          "• Nasal saline spray for congestion\n\n"
          "**Rest & Recovery:**\n"
          "• Get 7-9 hours of sleep\n"
          "• Avoid smoking and secondhand smoke\n"
          "• Eat nutritious foods (fruits, vegetables)\n"
          "• Wash hands frequently to prevent spread\n\n"
          "⚠️ **See doctor if:**\n"
          "• Symptoms last >10 days\n"
          "• High fever (>101.3°F)\n"
          "• Difficulty breathing or chest pain",

      ["fever", "temperature", "high temperature"]:
          "🌡️ **Fever Management:**\n\n"
          "**Home Treatment:**\n"
          "• Stay hydrated: water, electrolyte drinks\n"
          "• Rest in cool, comfortable room\n"
          "• Light clothing, remove extra blankets\n"
          "• Lukewarm sponge bath (not cold water)\n"
          "• Acetaminophen or ibuprofen as directed\n\n"
          "**Monitor Symptoms:**\n"
          "• Take temperature every 4 hours\n"
          "• Watch for dehydration signs\n"
          "• Note any rash or stiff neck\n\n"
          "⚠️ **Seek immediate care for:**\n"
          "• Fever >103°F in adults\n"
          "• Fever >100.4°F in infants <3 months\n"
          "• Fever with severe headache, stiff neck, rash\n"
          "• Fever lasting >3 days",

      // === DIGESTIVE CONDITIONS ===
      ["stomach ache", "stomach pain", "indigestion", "gas", "bloating"]:
          "🤢 **Digestive Relief:**\n\n"
          "**Immediate Relief:**\n"
          "• Drink warm water or herbal tea\n"
          "• Apply heat pad to abdomen\n"
          "• Gentle abdominal massage in circular motions\n"
          "• Peppermint tea for gas and bloating\n"
          "• Avoid carbonated drinks and chewing gum\n\n"
          "**Dietary Changes:**\n"
          "• Eat smaller, frequent meals\n"
          "• Avoid spicy, fatty, or acidic foods\n"
          "• Include probiotics (yogurt, kefir)\n"
          "• Chew food slowly and thoroughly\n\n"
          "⚠️ **Emergency symptoms:**\n"
          "• Severe, sudden abdominal pain\n"
          "• Pain with vomiting blood\n"
          "• Black, tarry stools\n"
          "• High fever with abdominal pain",

      ["diarrhea", "loose motion", "watery stool"]:
          "💩 **Diarrhea Management:**\n\n"
          "**Hydration is Key:**\n"
          "• Oral Rehydration Solution (ORS)\n"
          "• Clear fluids: water, broth, herbal tea\n"
          "• Avoid alcohol, caffeine, dairy initially\n"
          "• Small, frequent sips if nauseous\n\n"
          "**Diet (BRAT):**\n"
          "• Bananas (potassium)\n"
          "• Rice (binding)\n"
          "• Applesauce (pectin)\n"
          "• Toast (bland carbohydrates)\n\n"
          "⚠️ **Seek medical care for:**\n"
          "• Blood in stool\n"
          "• Signs of dehydration (dry mouth, no urination)\n"
          "• Diarrhea lasting >3 days\n"
          "• High fever with diarrhea",

      ["constipation", "hard stool", "difficulty passing stool"]:
          "🚽 **Constipation Relief:**\n\n"
          "**Immediate Help:**\n"
          "• Increase water intake (8-10 glasses daily)\n"
          "• High-fiber foods: fruits, vegetables, whole grains\n"
          "• Prunes, figs, or prune juice\n"
          "• Gentle abdominal massage\n"
          "• Regular exercise and movement\n\n"
          "**Prevention:**\n"
          "• Establish regular bathroom routine\n"
          "• Don't ignore the urge to go\n"
          "• Include fiber gradually to avoid gas\n"
          "• Consider probiotics\n\n"
          "⚠️ **See doctor if:**\n"
          "• No bowel movement for >3 days\n"
          "• Severe abdominal pain\n"
          "• Blood in stool\n"
          "• Constipation with vomiting",

      // === MENTAL HEALTH & WELLNESS ===
      ["stress", "anxiety", "tension", "worried", "overwhelmed"]:
          "🧘 **Stress & Anxiety Management:**\n\n"
          "**Immediate Relief:**\n"
          "• Deep breathing: 4-7-8 technique\n"
          "• Progressive muscle relaxation\n"
          "• Grounding techniques (5-4-3-2-1 method)\n"
          "• Short walk in nature\n"
          "• Listen to calming music\n\n"
          "**Long-term Strategies:**\n"
          "• Regular exercise (30 minutes daily)\n"
          "• Adequate sleep (7-9 hours)\n"
          "• Limit caffeine and alcohol\n"
          "• Practice mindfulness or meditation\n"
          "• Maintain social connections\n\n"
          "⚠️ **Seek professional help if:**\n"
          "• Anxiety interferes with daily life\n"
          "• Panic attacks or severe worry\n"
          "• Thoughts of self-harm\n"
          "• Persistent sleep problems",

      ["depression", "sad", "low mood", "feeling down"]:
          "💙 **Depression Support:**\n\n"
          "**Self-Care Strategies:**\n"
          "• Maintain regular sleep schedule\n"
          "• Eat balanced, nutritious meals\n"
          "• Get sunlight exposure daily\n"
          "• Stay connected with loved ones\n"
          "• Engage in activities you once enjoyed\n\n"
          "**Professional Support:**\n"
          "• Consider therapy or counseling\n"
          "• Talk to your doctor about treatment options\n"
          "• Join support groups\n"
          "• Practice stress management techniques\n\n"
          "⚠️ **Crisis Resources:**\n"
          "• National Suicide Prevention Lifeline: 988\n"
          "• Crisis Text Line: Text HOME to 741741\n"
          "• Emergency services: 911\n"
          "• Seek immediate help for thoughts of self-harm",

      ["sleep", "insomnia", "tired", "can't sleep", "sleep problems"]:
          "😴 **Sleep Improvement:**\n\n"
          "**Sleep Hygiene:**\n"
          "• Consistent bedtime and wake time\n"
          "• Cool, dark, quiet bedroom\n"
          "• No screens 1 hour before bed\n"
          "• Avoid caffeine after 2 PM\n"
          "• Regular exercise (not close to bedtime)\n\n"
          "**Relaxation Techniques:**\n"
          "• Deep breathing exercises\n"
          "• Progressive muscle relaxation\n"
          "• Meditation or guided imagery\n"
          "• Warm bath before bed\n"
          "• Reading (not on devices)\n\n"
          "⚠️ **See doctor if:**\n"
          "• Sleep problems persist >3 weeks\n"
          "• Loud snoring with breathing pauses\n"
          "• Excessive daytime sleepiness\n"
          "• Sleep problems affect daily functioning",

      // === SKIN CONDITIONS ===
      ["acne", "pimples", "breakouts", "skin blemishes"]:
          "🧴 **Acne Management:**\n\n"
          "**Daily Care:**\n"
          "• Gentle cleanser twice daily\n"
          "• Non-comedogenic moisturizer\n"
          "• Don't pick or squeeze pimples\n"
          "• Use oil-free, non-acnegenic products\n"
          "• Clean makeup brushes regularly\n\n"
          "**Lifestyle Factors:**\n"
          "• Manage stress levels\n"
          "• Eat balanced diet (limit dairy if triggers acne)\n"
          "• Change pillowcases frequently\n"
          "• Avoid touching face with hands\n"
          "• Use sunscreen daily (SPF 30+)\n\n"
          "⚠️ **See dermatologist if:**\n"
          "• Severe or cystic acne\n"
          "• Acne leaves dark spots or scars\n"
          "• Over-the-counter treatments don't help\n"
          "• Acne affects self-esteem significantly",

      ["eczema", "dermatitis", "itchy skin", "skin rash"]:
          "🧴 **Eczema Care:**\n\n"
          "**Skin Care:**\n"
          "• Moisturize immediately after bathing\n"
          "• Use fragrance-free, gentle products\n"
          "• Avoid hot water and long showers\n"
          "• Pat skin dry, don't rub\n"
          "• Wear soft, breathable fabrics\n\n"
          "**Trigger Management:**\n"
          "• Identify and avoid triggers (stress, allergens)\n"
          "• Use hypoallergenic laundry detergent\n"
          "• Keep nails short to prevent scratching\n"
          "• Consider humidifier in dry climates\n"
          "• Manage stress through relaxation\n\n"
          "⚠️ **See doctor if:**\n"
          "• Rash spreads or worsens\n"
          "• Signs of infection (pus, increased redness)\n"
          "• Severe itching affecting sleep\n"
          "• Rash on face or genitals",

      // === RESPIRATORY CONDITIONS ===
      ["asthma", "wheezing", "breathless", "shortness of breath"]:
          "🫁 **Asthma Management:**\n\n"
          "**During an Attack:**\n"
          "• Sit upright, stay calm\n"
          "• Use rescue inhaler as prescribed\n"
          "• Practice pursed-lip breathing\n"
          "• Remove yourself from triggers\n"
          "• Call 1990 if severe difficulty breathing\n\n"
          "**Prevention:**\n"
          "• Take controller medications as prescribed\n"
          "• Identify and avoid triggers\n"
          "• Use peak flow meter regularly\n"
          "• Get flu and pneumonia vaccines\n"
          "• Create asthma action plan with doctor\n\n"
          "⚠️ **Emergency signs:**\n"
          "• Can't speak in full sentences\n"
          "• Lips or fingernails turn blue\n"
          "• Rescue inhaler doesn't help\n"
          "• Severe chest tightness",

      ["covid", "coronavirus", "covid-19"]:
          "🦠 **COVID-19 Management:**\n\n"
          "**If You Have COVID:**\n"
          "• Isolate for at least 5 days\n"
          "• Rest and stay hydrated\n"
          "• Monitor symptoms closely\n"
          "• Use over-the-counter fever reducers\n"
          "• Contact doctor if symptoms worsen\n\n"
          "**Prevention:**\n"
          "• Get vaccinated and boosted\n"
          "• Wear masks in crowded places\n"
          "• Wash hands frequently\n"
          "• Maintain social distance\n"
          "• Stay home when sick\n\n"
          "⚠️ **Emergency care needed for:**\n"
          "• Difficulty breathing\n"
          "• Persistent chest pain\n"
          "• Confusion or inability to wake\n"
          "• Bluish lips or face",

      // === CHRONIC CONDITIONS ===
      ["diabetes", "blood sugar", "high blood sugar", "low blood sugar"]:
          "🩸 **Diabetes Management:**\n\n"
          "**Blood Sugar Control:**\n"
          "• Monitor blood glucose regularly\n"
          "• Take medications as prescribed\n"
          "• Eat balanced meals with consistent timing\n"
          "• Regular physical activity\n"
          "• Stay hydrated\n\n"
          "**Lifestyle Management:**\n"
          "• Maintain healthy weight\n"
          "• Limit processed sugars\n"
          "• Include fiber-rich foods\n"
          "• Regular foot care and eye exams\n"
          "• Manage stress levels\n\n"
          "⚠️ **Emergency situations:**\n"
          "• Severe hypoglycemia (confusion, seizures)\n"
          "• Diabetic ketoacidosis symptoms\n"
          "• Very high blood sugar with ketones\n"
          "• Seek immediate medical attention",

      ["hypertension", "high blood pressure", "blood pressure"]:
          "❤️ **Blood Pressure Management:**\n\n"
          "**Lifestyle Changes:**\n"
          "• Reduce sodium intake (<2,300mg daily)\n"
          "• Regular aerobic exercise (150 min/week)\n"
          "• Maintain healthy weight\n"
          "• Limit alcohol (1 drink/day women, 2 men)\n"
          "• Quit smoking\n\n"
          "**Monitoring:**\n"
          "• Check blood pressure regularly\n"
          "• Take medications as prescribed\n"
          "• Manage stress through relaxation\n"
          "• Get adequate sleep\n"
          "• Regular doctor visits\n\n"
          "⚠️ **Seek immediate care for:**\n"
          "• Severe headache with high BP\n"
          "• Chest pain or shortness of breath\n"
          "• Vision changes or confusion\n"
          "• Blood pressure >180/120",

      // === EMERGENCY CONDITIONS ===
      ["heart attack", "chest pain", "cardiac", "myocardial infarction"]:
          "🚨 **HEART ATTACK - CALL 1990 IMMEDIATELY:**\n\n"
          "**Emergency Signs:**\n"
          "• Chest pain or pressure\n"
          "• Pain in arm, neck, jaw, back\n"
          "• Shortness of breath\n"
          "• Nausea, vomiting, cold sweat\n"
          "• Lightheadedness or fainting\n\n"
          "**What to Do:**\n"
          "• Call 1990 immediately\n"
          "• Chew aspirin if not allergic\n"
          "• Stay calm and rest\n"
          "• Don't drive yourself to hospital\n"
          "• Have someone stay with you\n\n"
          "⚠️ **Time is critical - every minute counts!**\n"
          "Don't delay calling emergency services.",

      ["stroke", "brain attack", "facial drooping", "speech problems"]:
          "🚨 **STROKE - CALL 1990 IMMEDIATELY:**\n\n"
          "**FAST Signs:**\n"
          "• F - Face drooping on one side\n"
          "• A - Arm weakness or numbness\n"
          "• S - Speech slurred or difficulty speaking\n"
          "• T - Time to call 1990\n\n"
          "**Other Symptoms:**\n"
          "• Sudden severe headache\n"
          "• Vision problems in one or both eyes\n"
          "• Dizziness, loss of balance\n"
          "• Confusion or difficulty understanding\n\n"
          "⚠️ **Time is brain - call 1990 immediately!**\n"
          "Treatment is most effective within 3 hours.",

      // === WOMEN'S HEALTH ===
      ["pregnancy", "pregnant", "morning sickness", "prenatal"]:
          "🤰 **Pregnancy Care:**\n\n"
          "**Prenatal Health:**\n"
          "• Take prenatal vitamins with folic acid\n"
          "• Regular prenatal checkups\n"
          "• Eat balanced, nutritious meals\n"
          "• Stay hydrated (8-10 glasses water)\n"
          "• Get adequate sleep and rest\n\n"
          "**Common Concerns:**\n"
          "• Morning sickness: eat small, frequent meals\n"
          "• Heartburn: avoid spicy foods, eat slowly\n"
          "• Back pain: use pregnancy pillow, gentle stretches\n"
          "• Swelling: elevate feet, avoid standing long periods\n\n"
          "⚠️ **Call doctor immediately for:**\n"
          "• Severe abdominal pain\n"
          "• Vaginal bleeding\n"
          "• Severe headaches or vision changes\n"
          "• Decreased fetal movement",

      ["menstrual", "period", "pms", "cramps", "menstrual pain"]:
          "🩸 **Menstrual Health:**\n\n"
          "**Cramp Relief:**\n"
          "• Heat pad on lower abdomen\n"
          "• Gentle exercise (walking, yoga)\n"
          "• Over-the-counter pain relievers\n"
          "• Magnesium supplements\n"
          "• Relaxation techniques\n\n"
          "**PMS Management:**\n"
          "• Regular exercise\n"
          "• Balanced diet with complex carbs\n"
          "• Limit caffeine and alcohol\n"
          "• Adequate sleep\n"
          "• Stress management\n\n"
          "⚠️ **See doctor if:**\n"
          "• Severe pain affecting daily life\n"
          "• Heavy bleeding (soaking pad hourly)\n"
          "• Irregular periods or missed periods\n"
          "• Severe mood changes",

      // === CHILDREN'S HEALTH ===
      ["baby", "infant", "newborn", "child health"]:
          "👶 **Child Health:**\n\n"
          "**General Care:**\n"
          "• Regular pediatric checkups\n"
          "• Keep vaccination schedule current\n"
          "• Ensure adequate sleep\n"
          "• Balanced nutrition for age\n"
          "• Childproof home environment\n\n"
          "**Common Concerns:**\n"
          "• Fever: monitor temperature, keep hydrated\n"
          "• Teething: cold teething rings, gentle massage\n"
          "• Sleep: establish bedtime routine\n"
          "• Nutrition: variety of healthy foods\n\n"
          "⚠️ **Emergency signs in children:**\n"
          "• High fever with rash\n"
          "• Difficulty breathing\n"
          "• Severe dehydration\n"
          "• Unconsciousness or seizures",

      // === ADDITIONAL CONDITIONS ===
      ["arthritis", "joint pain", "rheumatoid", "osteoarthritis"]:
          "🦴 **Arthritis Management:**\n\n"
          "**Pain Relief:**\n"
          "• Heat/cold therapy for joints\n"
          "• Gentle range-of-motion exercises\n"
          "• Over-the-counter anti-inflammatories\n"
          "• Joint protection techniques\n"
          "• Weight management\n\n"
          "**Lifestyle:**\n"
          "• Regular low-impact exercise\n"
          "• Physical therapy if needed\n"
          "• Assistive devices if helpful\n"
          "• Stress management\n"
          "• Adequate rest\n\n"
          "⚠️ **See doctor for:**\n"
          "• Severe joint swelling\n"
          "• Joint deformity\n"
          "• Severe pain limiting function\n"
          "• Signs of infection",

      ["allergy", "allergic reaction", "hives", "swelling"]:
          "🤧 **Allergy Management:**\n\n"
          "**Mild Reactions:**\n"
          "• Antihistamines (Benadryl, Claritin)\n"
          "• Cool compresses for hives\n"
          "• Avoid known allergens\n"
          "• Calamine lotion for itching\n"
          "• Stay hydrated\n\n"
          "**Prevention:**\n"
          "• Identify and avoid triggers\n"
          "• Keep epinephrine auto-injector if prescribed\n"
          "• Wear medical alert jewelry\n"
          "• Inform others about allergies\n"
          "• Regular allergy testing\n\n"
          "⚠️ **Anaphylaxis - CALL 1990:**\n"
          "• Difficulty breathing or swallowing\n"
          "• Swelling of face, lips, tongue\n"
          "• Rapid pulse, dizziness\n"
          "• Use epinephrine if available",

      ["cancer", "tumor", "chemotherapy", "radiation"]:
          "🎗️ **Cancer Support:**\n\n"
          "**During Treatment:**\n"
          "• Follow treatment plan closely\n"
          "• Manage side effects with doctor\n"
          "• Maintain nutrition as possible\n"
          "• Stay hydrated\n"
          "• Get adequate rest\n\n"
          "**Support Systems:**\n"
          "• Connect with support groups\n"
          "• Family and friend support\n"
          "• Mental health counseling\n"
          "• Palliative care if needed\n"
          "• Regular medical follow-ups\n\n"
          "⚠️ **Always consult your oncologist for:**\n"
          "• Treatment decisions\n"
          "• Side effect management\n"
          "• Emergency symptoms\n"
          "• Treatment modifications",

      // === GENERAL WELLNESS ===
      ["nutrition", "diet", "healthy eating", "vitamins"]:
          "🥗 **Nutrition & Wellness:**\n\n"
          "**Balanced Diet:**\n"
          "• Fruits and vegetables (5+ servings daily)\n"
          "• Whole grains and lean proteins\n"
          "• Healthy fats (nuts, olive oil, avocado)\n"
          "• Limit processed foods and added sugars\n"
          "• Stay hydrated (8 glasses water daily)\n\n"
          "**Key Nutrients:**\n"
          "• Vitamin D (sunlight, fortified foods)\n"
          "• Omega-3 fatty acids (fish, flaxseed)\n"
          "• Antioxidants (berries, leafy greens)\n"
          "• Probiotics (yogurt, fermented foods)\n"
          "• Iron (lean meats, spinach)\n\n"
          "⚠️ **Consult nutritionist for:**\n"
          "• Specific dietary restrictions\n"
          "• Weight management goals\n"
          "• Medical conditions affecting diet\n"
          "• Supplement recommendations",

      ["exercise", "fitness", "workout", "physical activity"]:
          "💪 **Exercise & Fitness:**\n\n"
          "**General Guidelines:**\n"
          "• 150 minutes moderate exercise weekly\n"
          "• Strength training 2x per week\n"
          "• Start slowly if new to exercise\n"
          "• Listen to your body\n"
          "• Stay hydrated during workouts\n\n"
          "**Types of Exercise:**\n"
          "• Cardio: walking, swimming, cycling\n"
          "• Strength: weights, resistance bands\n"
          "• Flexibility: yoga, stretching\n"
          "• Balance: tai chi, balance exercises\n"
          "• Mix different activities\n\n"
          "⚠️ **Stop and consult doctor if:**\n"
          "• Chest pain during exercise\n"
          "• Severe shortness of breath\n"
          "• Dizziness or fainting\n"
          "• Joint pain that worsens",

      // === EMERGENCY FIRST AID ===
      ["choking", "can't breathe", "something stuck"]:
          "🚨 **CHOKING - ACT IMMEDIATELY:**\n\n"
          "**For Conscious Person:**\n"
          "• Encourage coughing if possible\n"
          "• Perform Heimlich maneuver:\n"
          "  - Stand behind person\n"
          "  - Place hands above navel\n"
          "  - Quick upward thrusts\n"
          "• Continue until object expelled\n\n"
          "**For Unconscious Person:**\n"
          "• Call 1990 immediately\n"
          "• Begin CPR if trained\n"
          "• Check mouth for visible objects\n"
          "• Don't perform blind finger sweeps\n\n"
          "⚠️ **Call 1990 if:**\n"
          "• Person becomes unconscious\n"
          "• Heimlich doesn't work\n"
          "• Severe breathing difficulty",

      ["burn", "scald", "thermal burn"]:
          "🔥 **Burn Treatment:**\n\n"
          "**Minor Burns:**\n"
          "• Cool running water for 10-15 minutes\n"
          "• Remove jewelry/clothing if not stuck\n"
          "• Cover with clean, dry cloth\n"
          "• Don't use ice, butter, or ointments\n"
          "• Over-the-counter pain relief\n\n"
          "**Severe Burns:**\n"
          "• Call 1990 immediately\n"
          "• Don't remove stuck clothing\n"
          "• Cover with clean, dry sheet\n"
          "• Elevate burned area if possible\n"
          "• Monitor for shock\n\n"
          "⚠️ **Emergency care needed for:**\n"
          "• Burns larger than palm\n"
          "• Burns on face, hands, feet, genitals\n"
          "• Electrical or chemical burns\n"
          "• Signs of infection",

      // === MENTAL HEALTH CONDITIONS ===
      ["panic attack", "panic", "anxiety attack"]:
          "😰 **Panic Attack Management:**\n\n"
          "**During Attack:**\n"
          "• Focus on slow, deep breathing\n"
          "• Use 4-7-8 breathing technique\n"
          "• Ground yourself (5-4-3-2-1 method)\n"
          "• Remind yourself it will pass\n"
          "• Find a quiet, safe space\n\n"
          "**Prevention:**\n"
          "• Regular exercise and sleep\n"
          "• Limit caffeine and alcohol\n"
          "• Practice relaxation techniques\n"
          "• Consider therapy or counseling\n"
          "• Medication if prescribed\n\n"
          "⚠️ **Seek help if:**\n"
          "• Panic attacks are frequent\n"
          "• Fear of having more attacks\n"
          "• Avoiding activities due to anxiety\n"
          "• Panic affects daily functioning",

      ["bipolar", "mood swings", "manic", "depressive"]:
          "🔄 **Bipolar Disorder Support:**\n\n"
          "**Management:**\n"
          "• Take medications as prescribed\n"
          "• Regular therapy sessions\n"
          "• Maintain consistent sleep schedule\n"
          "• Avoid alcohol and drugs\n"
          "• Track mood changes\n\n"
          "**Support System:**\n"
          "• Family and friend support\n"
          "• Support groups\n"
          "• Crisis intervention plan\n"
          "• Regular medical checkups\n"
          "• Stress management\n\n"
          "⚠️ **Crisis situations:**\n"
          "• Thoughts of self-harm or suicide\n"
          "• Severe manic or depressive episodes\n"
          "• Inability to care for self\n"
          "• Call crisis hotline: 988",

      // === ADDITIONAL COMMON CONDITIONS ===
      ["migraine", "severe headache", "head pain"]:
          "🤕 **Migraine Management:**\n\n"
          "**During Migraine:**\n"
          "• Rest in dark, quiet room\n"
          "• Apply cold compress to head\n"
          "• Take prescribed migraine medication\n"
          "• Avoid triggers (light, noise, smells)\n"
          "• Stay hydrated\n\n"
          "**Prevention:**\n"
          "• Identify and avoid triggers\n"
          "• Regular sleep schedule\n"
          "• Stress management\n"
          "• Regular meals\n"
          "• Consider preventive medications\n\n"
          "⚠️ **Emergency care if:**\n"
          "• Sudden, severe headache\n"
          "• Headache with fever, neck stiffness\n"
          "• Vision changes or weakness\n"
          "• Headache after head injury",


 ["hi", "hello", "hey"]:
          "Hello, How can I help you today?",


      ["thyroid", "hypothyroidism", "hyperthyroidism"]:
          "🦋 **Thyroid Health:**\n\n"
          "**Management:**\n"
          "• Take thyroid medication as prescribed\n"
          "• Regular blood tests to monitor levels\n"
          "• Consistent medication timing\n"
          "• Balanced diet with adequate iodine\n"
          "• Regular doctor follow-ups\n\n"
          "**Symptoms to Monitor:**\n"
          "• Energy levels and mood\n"
          "• Weight changes\n"
          "• Heart rate and blood pressure\n"
          "• Sleep patterns\n"
          "• Temperature sensitivity\n\n"
          "⚠️ **See doctor for:**\n"
          "• Medication side effects\n"
          "• Symptoms not improving\n"
          "• New or worsening symptoms\n"
          "• Difficulty with medication compliance",

      // === GENERAL HEALTH ADVICE ===
      ["vitamins", "supplements", "nutritional"]:
          "💊 **Vitamins & Supplements:**\n\n"
          "**Essential Vitamins:**\n"
          "• Vitamin D: sunlight, fortified foods\n"
          "• B12: animal products, fortified foods\n"
          "• Folate: leafy greens, legumes\n"
          "• Vitamin C: citrus fruits, berries\n"
          "• Iron: lean meats, spinach\n\n"
          "**Supplement Guidelines:**\n"
          "• Consult doctor before starting\n"
          "• Don't exceed recommended doses\n"
          "• Choose quality, tested brands\n"
          "• Consider food sources first\n"
          "• Monitor for interactions\n\n"
          "⚠️ **Important:**\n"
          "• Some supplements interact with medications\n"
          "• More isn't always better\n"
          "• Get nutrients from food when possible\n"
          "• Regular blood tests may be needed",

      ["immunity", "immune system", "prevent illness"]:
          "🛡️ **Immune System Support:**\n\n"
          "**Lifestyle Factors:**\n"
          "• Adequate sleep (7-9 hours)\n"
          "• Regular exercise\n"
          "• Stress management\n"
          "• Don't smoke, limit alcohol\n"
          "• Maintain healthy weight\n\n"
          "**Nutrition:**\n"
          "• Colorful fruits and vegetables\n"
          "• Lean proteins\n"
          "• Whole grains\n"
          "• Probiotics (yogurt, kefir)\n"
          "• Stay hydrated\n\n"
          "⚠️ **See doctor if:**\n"
          "• Frequent infections\n"
          "• Slow wound healing\n"
          "• Persistent fatigue\n"
          "• Unexplained weight loss",

      // === ELDERLY HEALTH ===
      ["elderly", "aging", "senior health", "old age"]:
          "👴 **Senior Health:**\n\n"
          "**Preventive Care:**\n"
          "• Regular health screenings\n"
          "• Vaccinations (flu, pneumonia, shingles)\n"
          "• Bone density testing\n"
          "• Eye and hearing exams\n"
          "• Medication reviews\n\n"
          "**Safety:**\n"
          "• Fall prevention measures\n"
          "• Home safety modifications\n"
          "• Regular exercise for strength/balance\n"
          "• Social connections\n"
          "• Mental stimulation\n\n"
          "⚠️ **Watch for:**\n"
          "• Memory changes\n"
          "• Balance problems\n"
          "• Medication interactions\n"
          "• Depression or isolation",

      // === EMERGENCY CONDITIONS ===
      ["seizure", "epilepsy", "convulsions"]:
          "⚡ **Seizure Response:**\n\n"
          "**During Seizure:**\n"
          "• Stay calm and time the seizure\n"
          "• Protect person from injury\n"
          "• Don't restrain or put anything in mouth\n"
          "• Turn person on side if possible\n"
          "• Clear area of dangerous objects\n\n"
          "**After Seizure:**\n"
          "• Check breathing and pulse\n"
          "• Stay with person until alert\n"
          "• Don't give food/water until fully alert\n"
          "• Note duration and symptoms\n"
          "• Call 911 if first seizure or >5 minutes\n\n"
          "⚠️ **Call 911 for:**\n"
          "• Seizure lasting >5 minutes\n"
          "• Multiple seizures without recovery\n"
          "• Difficulty breathing\n"
          "• Injury during seizure",

      ["overdose", "poisoning", "drug overdose"]:
          "🚨 **OVERDOSE - CALL 911 IMMEDIATELY:**\n\n"
          "**Emergency Response:**\n"
          "• Call 911 immediately\n"
          "• Stay with person\n"
          "• Check breathing and pulse\n"
          "• If unconscious, turn on side\n"
          "• Don't induce vomiting unless directed\n\n"
          "**If Conscious:**\n"
          "• Keep person awake and talking\n"
          "• Don't give food or water\n"
          "• Gather information about substance\n"
          "• Stay calm and reassuring\n"
          "• Wait for emergency responders\n\n"
          "⚠️ **Time is critical - call 911 immediately!**\n"
          "Don't delay seeking emergency care.",

      // === GENERAL HEALTH QUESTIONS ===
      ["health checkup", "annual exam", "preventive care"]:
          "🏥 **Preventive Health Care:**\n\n"
          "**Regular Checkups:**\n"
          "• Annual physical exam\n"
          "• Blood pressure monitoring\n"
          "• Cholesterol screening\n"
          "• Blood glucose testing\n"
          "• Cancer screenings (age-appropriate)\n\n"
          "**Age-Specific Screenings:**\n"
          "• 20s-30s: Basic health maintenance\n"
          "• 40s: Mammograms, colonoscopy prep\n"
          "• 50s+: Colonoscopy, bone density\n"
          "• 65+: Medicare wellness visits\n"
          "• Regular vaccinations\n\n"
          "⚠️ **Don't skip:**\n"
          "• Annual flu vaccine\n"
          "• Regular dental cleanings\n"
          "• Eye exams\n"
          "• Skin cancer checks",

      ["medication", "prescription", "drug interactions"]:
          "💊 **Medication Safety:**\n\n"
          "**Safe Medication Use:**\n"
          "• Take exactly as prescribed\n"
          "• Don't share medications\n"
          "• Store properly (cool, dry place)\n"
          "• Check expiration dates\n"
          "• Use one pharmacy when possible\n\n"
          "**Prevent Interactions:**\n"
          "• Tell all doctors about all medications\n"
          "• Include OTC drugs and supplements\n"
          "• Ask about food interactions\n"
          "• Read labels carefully\n"
          "• Ask questions if unsure\n\n"
          "⚠️ **Call doctor for:**\n"
          "• Unexpected side effects\n"
          "• Allergic reactions\n"
          "• Medication not working\n"
          "• Difficulty taking medication",

      // === MENTAL HEALTH CONDITIONS ===
      ["ptsd", "trauma", "post traumatic stress"]:
          "🧠 **PTSD Support:**\n\n"
          "**Coping Strategies:**\n"
          "• Grounding techniques (5-4-3-2-1)\n"
          "• Deep breathing exercises\n"
          "• Progressive muscle relaxation\n"
          "• Mindfulness meditation\n"
          "• Regular exercise\n\n"
          "**Professional Help:**\n"
          "• Trauma-focused therapy\n"
          "• EMDR therapy\n"
          "• Cognitive behavioral therapy\n"
          "• Support groups\n"
          "• Medication if prescribed\n\n"
          "⚠️ **Crisis support:**\n"
          "• National PTSD Center: 1-800-273-8255\n"
          "• Crisis Text Line: Text HOME to 741741\n"
          "• Emergency services: 911\n"
          "• Seek immediate help for self-harm thoughts",

      ["eating disorder", "anorexia", "bulimia", "binge eating"]:
          "🍽️ **Eating Disorder Support:**\n\n"
          "**Seek Professional Help:**\n"
          "• Eating disorder specialists\n"
          "• Mental health counselors\n"
          "• Nutritionists with ED experience\n"
          "• Medical monitoring\n"
          "• Support groups\n\n"
          "**Recovery Support:**\n"
          "• Family and friend support\n"
          "• Regular medical checkups\n"
          "• Nutritional counseling\n"
          "• Therapy for underlying issues\n"
          "• Crisis intervention plan\n\n"
          "⚠️ **Emergency care needed for:**\n"
          "• Severe weight loss\n"
          "• Heart problems\n"
          "• Electrolyte imbalances\n"
          "• Thoughts of self-harm\n"
          "• Call National Eating Disorders Association: 1-800-931-2237",

      // === ADDITIONAL CONDITIONS ===
      ["fibromyalgia", "chronic pain", "muscle pain"]:
          "🦴 **Fibromyalgia Management:**\n\n"
          "**Pain Management:**\n"
          "• Gentle exercise (swimming, walking)\n"
          "• Heat/cold therapy\n"
          "• Massage therapy\n"
          "• Stress reduction techniques\n"
          "• Medication as prescribed\n\n"
          "**Lifestyle:**\n"
          "• Regular sleep schedule\n"
          "• Pacing activities\n"
          "• Support groups\n"
          "• Mental health support\n"
          "• Work with healthcare team\n\n"
          "⚠️ **See doctor for:**\n"
          "• New or worsening symptoms\n"
          "• Medication adjustments\n"
          "• Mental health concerns\n"
          "• Sleep problems",

      ["lupus", "autoimmune", "systemic lupus"]:
          "🦋 **Lupus Management:**\n\n"
          "**Daily Care:**\n"
          "• Take medications as prescribed\n"
          "• Protect skin from sun (SPF 30+)\n"
          "• Regular exercise (low-impact)\n"
          "• Stress management\n"
          "• Adequate rest\n\n"
          "**Monitoring:**\n"
          "• Regular blood tests\n"
          "• Watch for flares\n"
          "• Track symptoms\n"
          "• Regular rheumatologist visits\n"
          "• Vaccination schedule\n\n"
          "⚠️ **Seek care for:**\n"
          "• Fever with joint pain\n"
          "• Chest pain or shortness of breath\n"
          "• Severe headaches\n"
          "• Vision changes\n"
          "• Signs of infection",

      // === GENERAL HEALTH ADVICE ===
      ["weight loss", "obesity", "overweight"]:
          "⚖️ **Healthy Weight Management:**\n\n"
          "**Sustainable Approach:**\n"
          "• Gradual weight loss (1-2 lbs/week)\n"
          "• Balanced, nutritious diet\n"
          "• Regular physical activity\n"
          "• Adequate sleep (7-9 hours)\n"
          "• Stress management\n\n"
          "**Lifestyle Changes:**\n"
          "• Portion control\n"
          "• Mindful eating\n"
          "• Regular meal times\n"
          "• Limit processed foods\n"
          "• Stay hydrated\n\n"
          "⚠️ **Consult healthcare provider for:**\n"
          "• Medical weight loss programs\n"
          "• Underlying health conditions\n"
          "• Medication considerations\n"
          "• Surgical options if appropriate",

      ["smoking", "quit smoking", "tobacco", "nicotine"]:
          "🚭 **Quit Smoking Support:**\n\n"
          "**Quit Strategies:**\n"
          "• Set a quit date\n"
          "• Remove smoking triggers\n"
          "• Use nicotine replacement therapy\n"
          "• Consider prescription medications\n"
          "• Join support groups\n\n"
          "**Support Resources:**\n"
          "• National Quitline: 1-800-QUIT-NOW\n"
          "• Smokefree.gov\n"
          "• Mobile apps for quitting\n"
          "• Counseling services\n"
          "• Family and friend support\n\n"
          "⚠️ **Withdrawal symptoms are temporary:**\n"
          "• Cravings last 3-5 minutes\n"
          "• Physical symptoms peak in 2-3 days\n"
          "• Most symptoms improve in 2-4 weeks\n"
          "• Don't give up - multiple attempts are normal",

      // === FINAL CATCH-ALL ===
      ["help", "support", "advice", "guidance"]:
          "🤝 **General Health Support:**\n\n"
          "**I'm here to help with:**\n"
          "• Symptom management and relief\n"
          "• General health information\n"
          "• First aid and emergency guidance\n"
          "• Wellness and prevention tips\n"
          "• When to seek medical care\n\n"
          "**Remember:**\n"
          "• This is general health information\n"
          "• Not a substitute for medical care\n"
          "• Always consult healthcare providers\n"
          "• Emergency situations need 911\n"
          "• Your health and safety come first\n\n"
          "💡 **Ask me about specific symptoms or conditions for detailed guidance!**",
    };

    for (var entry in faq.entries) {
      for (var keyword in entry.key) {
        if (q.contains(keyword)) {
          return entry.value;
        }
      }
    }

    return "🤔 I don't have specific advice for that yet. I can help with many health topics including:\n\n"
        "**Common Symptoms:** headache, fever, cold, cough, stomach pain, back pain, fatigue\n"
        "**Chronic Conditions:** diabetes, hypertension, arthritis, asthma, depression, anxiety\n"
        "**Emergency Situations:** heart attack, stroke, choking, burns, allergic reactions\n"
        "**Mental Health:** stress, anxiety, depression, panic attacks, sleep problems\n"
        "**Women's Health:** pregnancy, menstrual issues, menopause\n"
        "**Children's Health:** fever, teething, common childhood illnesses\n"
        "**General Wellness:** nutrition, exercise, weight management, preventive care\n\n"
        "💡 **Try asking about a specific symptom or condition for detailed guidance!**\n"
        "⚠️ **Remember:** This is general health information, not medical advice. Always consult healthcare providers for medical concerns.";
  }
}
