import 'package:flutter/material.dart';

// 1. DATA MODEL
class AwarenessSection {
  final String title;
  final List<String> items;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;

  AwarenessSection({
    required this.title,
    required this.items,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
  });
}

// 2. PALETTE & DATA (Moved into a container class or top level)
class AwarenessData {
  // Original Kid-Friendly Colors
  static const Color kBananaYellow = Color(0xFFFFD93D);
  static const Color kBubblegumPink = Color(0xFFFF6B6B);
  static const Color kLimeGreen = Color(0xFF6BCB77);
  static const Color kSkyBlue = Color(0xFF4CB5F9);
  static const Color kDeepNavy = Color(0xFF2C3E50);

  // NEW BACKGROUND COLORS
  static const Color kSoftLavender = Color(0xFFEFE8FF); // New main background
  static const Color kPalePinkSecondary = Color(0xFFFFECF0); // New accent for bubbles

  static final List<AwarenessSection> sections = [
    AwarenessSection(
      title: "Do This! (Thumbs Up)",
      items: [
        "Look at their eyes when signing.",
        "Wave gently to say 'Hello!'",
        "Speak normally (don't shout).",
        "Use your hands and face to help.",
        "Be patient and kind!",
      ],
      primaryColor: kLimeGreen,
      secondaryColor: const Color(0xFFE3F9E5),
      icon: Icons.check_circle_rounded,
    ),
    AwarenessSection(
      title: "Please Don't Do This",
      items: [
        "Don't shout (it doesn't help).",
        "Keep your mouth visible.",
        "Don't assume they can lip-read.",
        "Talk to the person, not the helper.",
        "Don't grab them suddenly!",
      ],
      primaryColor: kBubblegumPink,
      secondaryColor: const Color(0xFFFFEBEB),
      icon: Icons.cancel_rounded,
    ),
    AwarenessSection(
      title: "Tips for Friends",
      items: [
        "Learn A-B-C fingerspelling!",
        "Speak at a normal speed.",
        "Point to things if you need to.",
        "Repeat it if they didn't catch it.",
        "Be a respectful friend.",
      ],
      primaryColor: kBananaYellow,
      secondaryColor: const Color(0xFFFFFBE6),
      icon: Icons.lightbulb_rounded,
    ),
    AwarenessSection(
      title: "Did You Know?",
      items: [
        "Sign language has its own grammar.",
        "Faces show a lot of feelings!",
        "Good lighting helps them see signs.",
        "There are many Sign Languages.",
        "Being Deaf is a culture!",
      ],
      primaryColor: kSkyBlue,
      secondaryColor: const Color(0xFFE1F4FF),
      icon: Icons.public,
    ),
  ];
}

class AwarenessPage extends StatelessWidget {
  const AwarenessPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the colors for the decorative bubbles
    const Color bubble1Color = AwarenessData.kBubblegumPink;
    const Color bubble2Color = AwarenessData.kLimeGreen;

    return Scaffold(
      // Set the new background color
      backgroundColor: AwarenessData.kSoftLavender,

      body: Stack(
        children: [
          // ------------------------------------
          // 1. DECORATIVE BACKGROUND BUBBLES
          // ------------------------------------
          // Decorative Background Bubble 1 (Top Left - Pink)
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                // Using Pink with low opacity
                color: bubble1Color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Decorative Background Bubble 2 (Bottom Right - Green)
          Positioned(
            bottom: 100,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                // Using Green with low opacity
                color: bubble2Color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // ------------------------------------
          // 2. MAIN SCROLLABLE CONTENT
          // ------------------------------------
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Fun Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AwarenessData.kBananaYellow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black12, width: 2),
                    ),
                    child: const Text(
                      "GOOD TO KNOW",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AwarenessData.kDeepNavy,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    "Let's Be Great Friends!",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      color: AwarenessData.kDeepNavy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Here is how you can communicate better with your friends who are hard-of-hearing.",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: AwarenessData.kDeepNavy.withAlpha(150),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Awareness Sections Loop
                  ...AwarenessData.sections.map(
                        (section) => AwarenessCard(section: section),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AwarenessCard extends StatefulWidget {
  final AwarenessSection section;

  const AwarenessCard({
    super.key,
    required this.section,
  });

  @override
  State<AwarenessCard> createState() => _AwarenessCardState();
}

class _AwarenessCardState extends State<AwarenessCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: widget.section.primaryColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: widget.section.primaryColor.withOpacity(0.3),
            blurRadius: 0,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),

          initiallyExpanded: false,
          onExpansionChanged: (value) => setState(() => expanded = value),

          iconColor: widget.section.primaryColor,
          collapsedIconColor: widget.section.primaryColor,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),

          // Title Row
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.section.secondaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.section.icon,
                  color: widget.section.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.section.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AwarenessData.kDeepNavy,
                  ),
                ),
              ),
            ],
          ),

          // Items List
          children: widget.section.items.map((tip) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.section.secondaryColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 20,
                    color: widget.section.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: AwarenessData.kDeepNavy,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}