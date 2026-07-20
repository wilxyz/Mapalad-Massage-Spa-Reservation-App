import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.darkBrown,
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'About Us',
                        style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopImages(),
                    const SizedBox(height: 20),
                    const _FullWidthPill(text: 'Get to Know Mapalad Massage Spa!'),
                    const SizedBox(height: 16),
                    _WhiteCard(child: _buildStoryText()),
                    const SizedBox(height: 30),
                    _OverlapSection(
                      label: 'Company Vision',
                      alignLeft: true,
                      child: _buildItalicText(
                        'To be known for excellent massage services across the country, recognized for professionalism, customer satisfaction, and commitment to wellness and relaxation.',
                      ),
                    ),
                    const SizedBox(height: 34),
                    _OverlapSection(
                      label: 'Company Mission',
                      alignLeft: false,
                      child: _buildItalicText(
                        'To provide high-quality massage and spa services that promote relaxation, wellness, and overall customer well-being through skilled therapists, outstanding service, and a clean and comfortable environment. The company is committed to continuously improving its operations, expanding its reach, creating employment opportunities, and maintaining excellent customer satisfaction in every branch.',
                      ),
                    ),
                    const SizedBox(height: 26),
                    Divider(color: AppColors.brown.withOpacity(0.4), thickness: 1.2),
                    const SizedBox(height: 26),
                    const _FullWidthPill(text: 'Core Values'),
                    const SizedBox(height: 20),
                    const _CoreValueRow(label: 'Purity'),
                    const SizedBox(height: 14),
                    const _CoreValueRow(label: 'Excellence'),
                    const SizedBox(height: 14),
                    const _CoreValueRow(label: 'Compassion'),
                    const SizedBox(height: 32),
                    _buildBottomQuote(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopImages() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: _ShadowImageBox(
            child: Image.asset('assets/images/logo.jpg', height: 140, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: _ShadowImageBox(
            child: Image.asset('assets/images/mapalad_spa.jpg', height: 140, fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }

  Widget _buildStoryText() {
    final base = GoogleFonts.poppins(color: AppColors.darkBrown, fontSize: 13.5, height: 1.5);
    final bold = base.copyWith(fontWeight: FontWeight.w700);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(style: base, children: [
            TextSpan(text: 'Mapalad Massage and Spa Corporation', style: bold),
            const TextSpan(text: ' was founded in '),
            TextSpan(text: '2014', style: bold),
            const TextSpan(text: ' by '),
            TextSpan(text: 'Mark Anthony D. Loncoras', style: bold),
            const TextSpan(text: ' as a sole proprietorship, offering quality wellness and massage services.'),
          ]),
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(style: base, children: [
            const TextSpan(
                text:
                    'Over its first ten years, the business grew steadily, establishing six branches. On its 10th year, the company opened ownership opportunities to incorporators, and in '),
            TextSpan(text: 'April 2025', style: bold),
            const TextSpan(text: ', it was officially registered with the SEC as Mapalad Massage and Spa Corporation.'),
          ]),
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(style: base, children: [
            const TextSpan(text: 'Following incorporation, two additional branches were established, bringing the total to eight branches across '),
            TextSpan(text: 'Lipa City', style: bold),
            const TextSpan(text: ', '),
            TextSpan(text: 'Rosario', style: bold),
            const TextSpan(text: ', '),
            TextSpan(text: 'Santo Tomas', style: bold),
            const TextSpan(text: ', '),
            TextSpan(text: 'Batangas City', style: bold),
            const TextSpan(text: ', and '),
            TextSpan(text: 'Tagaytay', style: bold),
            const TextSpan(text: '. Among these, the '),
            TextSpan(text: 'Lipa Tambo', style: bold),
            const TextSpan(text: ' and '),
            TextSpan(text: 'Ayala Highway', style: bold),
            const TextSpan(text: ' branches serve the highest volume of customers due to their strategic locations.'),
          ]),
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(style: base, children: [
            const TextSpan(text: 'The company offers a variety of services, including '),
            TextSpan(text: 'whole body massage', style: bold),
            const TextSpan(text: ', '),
            TextSpan(text: 'Swedish massage', style: bold),
            const TextSpan(text: ', '),
            TextSpan(text: 'Thai massage', style: bold),
            const TextSpan(text: ', '),
            TextSpan(text: 'therapeutic massage', style: bold),
            const TextSpan(text: ', '),
            TextSpan(text: 'reflexology', style: bold),
            const TextSpan(text: ', '),
            TextSpan(text: 'body treatments', style: bold),
            const TextSpan(text: ', and other wellness add-ons to promote relaxation and overall well-being.'),
          ]),
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }

  Widget _buildItalicText(String text) {
    return Text(
      text,
      textAlign: TextAlign.justify,
      style: GoogleFonts.poppins(
        color: AppColors.darkBrown,
        fontStyle: FontStyle.italic,
        fontSize: 13.5,
        height: 1.5,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildBottomQuote() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ShadowImageBox(
          child: Image.asset('assets/images/logo.jpg', height: 100, width: 100, fit: BoxFit.cover),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.spa, color: AppColors.brown, size: 28),
              const SizedBox(height: 8),
              Text(
                '“Sa bawat oras ng pahinga—Mapalad Massage and Spa”',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppColors.darkBrown,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShadowImageBox extends StatelessWidget {
  final Widget child;
  const _ShadowImageBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.brown.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}

class _FullWidthPill extends StatelessWidget {
  final String text;
  const _FullWidthPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.darkBrown,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.brown.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.brown.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _OverlapSection extends StatelessWidget {
  final String label;
  final bool alignLeft;
  final Widget child;

  const _OverlapSection({
    required this.label,
    required this.alignLeft,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 18),
          padding: const EdgeInsets.fromLTRB(18, 26, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.brown.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
        Positioned(
          top: 0,
          left: alignLeft ? 20 : null,
          right: alignLeft ? null : 20,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.darkBrown,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brown.withOpacity(0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _CoreValueRow extends StatelessWidget {
  final String label;
  const _CoreValueRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.spa, color: AppColors.brown, size: 32),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brown.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: AppColors.darkBrown, fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }
}