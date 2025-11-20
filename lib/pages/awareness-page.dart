import 'package:flutter/material.dart';

class AwarenessSection {
  final String title;
  final List<String> items;

  AwarenessSection({required this.title, required this.items});
}
final List<AwarenessSection> awarenessSections = [
  AwarenessSection(
    title: "Do's When Communicating With Deaf People",
    items: [
      "Maintain eye contact when signing or writing.",
      "Get their attention with a light tap on the shoulder or a wave.",
      "Speak normally and clearly without shouting.",
      "Use gestures, facial expressions, or pen & paper if needed.",
      "Be patient — communication is a two-way effort.",
    ],
  ),

  AwarenessSection(
    title: "Don'ts When Communicating With Deaf People",
    items: [
      "Don’t shout — it doesn’t make you easier to understand.",
      "Don’t cover your mouth while speaking.",
      "Don’t assume they can read lips perfectly.",
      "Don’t talk to their interpreter instead of them.",
      "Don’t grab a deaf person suddenly to get attention.",
    ],
  ),

  AwarenessSection(
    title: "Tips for Hearing People",
    items: [
      "Learn basic sign language like greetings and fingerspelling.",
      "Speak at a normal pace — no exaggeration.",
      "Use visual cues to support communication.",
      "Repeat or rephrase if they do not understand.",
      "Show respect by not treating deafness as a disability.",
    ],
  ),

  AwarenessSection(
    title: "Deaf Culture Awareness",
    items: [
      "Sign language has its own grammar and structure.",
      "Deaf people rely heavily on facial expressions.",
      "Lighting is important — it helps them see your signs clearly.",
      "Not all deaf people use the same sign language.",
      "Deaf identity is a cultural identity, not a medical problem.",
    ],
  ),
];


class AwarenessPage extends StatelessWidget {
  const AwarenessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              "Awareness",
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                height: 1.2,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Learn how to communicate better with the hard-of-hearing and nonverbal community.",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 1.4,
                color: isDark
                    ? Colors.white.withOpacity(0.65)
                    : Colors.black.withOpacity(0.65),
              ),
            ),

            const SizedBox(height: 24),

            // Awareness Sections
            ...awarenessSections.map(
                  (section) => AwarenessCard(
                title: section.title,
                items: section.items,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AwarenessCard extends StatefulWidget {
  final String title;
  final List<String> items;
  final bool isDark;

  const AwarenessCard({
    super.key,
    required this.title,
    required this.items,
    required this.isDark,
  });

  @override
  State<AwarenessCard> createState() => _AwarenessCardState();
}

class _AwarenessCardState extends State<AwarenessCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final gradient = widget.isDark
        ? [const Color(0xFF0F1C2E), const Color(0xFF122F59)]
        : [const Color(0xFFE8F0FF), const Color(0xFFD9E6FF)];

    final borderColor = widget.isDark
        ? Colors.blueAccent.withOpacity(0.2)
        : Colors.blueAccent.withOpacity(0.3);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: widget.isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.blueAccent.withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            onExpansionChanged: (value) => setState(() => expanded = value),
            iconColor: widget.isDark ? Colors.white : Colors.black87,
            collapsedIconColor: widget.isDark ? Colors.white70 : Colors.black87,

            // Title
            title: Text(
              widget.title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: widget.isDark ? Colors.white : Colors.black,
              ),
            ),

            childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

            children: widget.items.map((tip) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.bubble_chart_rounded,
                      size: 20,
                      color: widget.isDark
                          ? Colors.lightBlueAccent
                          : Colors.blueAccent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.45,
                          color: widget.isDark
                              ? Colors.white70
                              : Colors.black.withOpacity(0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}