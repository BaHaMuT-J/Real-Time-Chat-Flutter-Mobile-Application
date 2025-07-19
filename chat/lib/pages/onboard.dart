import 'package:chat/main.dart';
import 'package:chat/userPref.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnBoardPage extends StatefulWidget {
  const OnBoardPage({super.key});

  @override
  State<OnBoardPage> createState() => _OnBoardPageState();
}

class _OnBoardPageState extends State<OnBoardPage> {
  final PageController _controller = PageController();
  bool isLastPage = false;
  final pages = [
    OnboardingContent(
      title: "Login Once, Stay Connected",
      description:
      "Secure email login with automatic sign-in. Chat seamlessly across all your devices.",
      image: Icons.lock_open,
    ),
    OnboardingContent(
      title: "Real-Time Messaging",
      description:
      "Send and receive messages instantly. Chat updates happen live—no refresh needed.",
      image: Icons.message,
    ),
    OnboardingContent(
      title: "Get Notified Instantly",
      description:
      "Receive alerts when friends send messages. Never miss an important moment.",
      image: Icons.notifications_active,
    ),
    OnboardingContent(
      title: "Build Your Social Circle",
      description:
      "Send, accept, or reject friend requests. Stay in control of your connections.",
      image: Icons.group_add,
    ),
    OnboardingContent(
      title: "Customize Your Experience",
      description:
      "Change your profile image, description, fonts, and sizes. Make the app truly yours.",
      image: Icons.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD1F8EF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (index) {
                    setState(() {
                      isLastPage = index == pages.length - 1;
                    });
                  },
                  children: pages,
                ),
              ),
              SmoothPageIndicator(
                controller: _controller,
                count: pages.length,
                effect: const WormEffect(
                  dotHeight: 12,
                  dotWidth: 12,
                  spacing: 16,
                  activeDotColor: Color(0xFF003285),
                  dotColor: Color(0xFF578FCA),
                ),
                onDotClicked: (index) async {
                  _controller.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.ease,
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => _controller.animateToPage(
                      pages.length - 1,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.ease,
                    ),
                    child: const Text("Skip", style: TextStyle(color: Color(0xFF003285))),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF003285),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      UserPrefs.saveIsOnBoard(true);
                      if (isLastPage) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const InitialPage()),
                        );
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      }
                    },
                    child: Text(isLastPage ? "Done" : "Next"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  final String title;
  final String description;
  final IconData image;

  const OnboardingContent({
    super.key,
    required this.title,
    required this.description,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(image, size: 120, color: Color(0xFF003285)),
        const SizedBox(height: 32),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF003285),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          description,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF578FCA),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
