import 'package:flutter/material.dart';
// FIX: Use an alias to prevent conflict with internal Flutter 'CarouselController'
import 'package:carousel_slider/carousel_slider.dart' as slider;

class SlidingEventCards extends StatelessWidget {
  const SlidingEventCards({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the list of event data
    final List<Map<String, dynamic>> events = [
      {
        'title': 'Church Project',
        'details': 'Building fund drive for the new annex. Target: \$50k.',
        'icon': Icons.construction,
        'gradient': const LinearGradient(
          colors: [Colors.blue, Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
      {
        'title': 'Annual Fundraising',
        'details': 'Join us for our annual harvest appeal. Every seed counts!',
        'icon': Icons.monetization_on,
        'gradient': const LinearGradient(
          colors: [Colors.orange, Color(0xFFFFB300)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
      {
        'title': 'All-Night Vigil',
        'details': 'Prayers and intercession for the nation. Starting 10 PM.',
        'icon': Icons.nights_stay,
        'gradient': const LinearGradient(
          colors: [Colors.purple, Color(0xFF8E24AA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
      {
        'title': 'Worship Night',
        'details': 'An evening of powerful worship and deep communion.',
        'icon': Icons.music_note,
        'gradient': const LinearGradient(
          colors: [Colors.brown, Color(0xFF8D6E63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
    ];

    return slider.CarouselSlider(
      // Used 'slider.' prefix
      options: slider.CarouselOptions(
        // Used 'slider.' prefix
        autoPlay: true, // Key for auto-sliding
        autoPlayInterval: const Duration(seconds: 5), // Slide every 5 seconds
        enlargeCenterPage: true, // Makes the current card slightly larger
        viewportFraction: 0.9, // Show a fraction of the next card
        aspectRatio: 16 / 9, // Card size ratio (wider than tall)
      ),
      items: events.map((event) {
        return _buildEventCard(
          event['title'] as String,
          event['details'] as String,
          event['icon'] as IconData,
          event['gradient'] as Gradient,
        );
      }).toList(),
    );
  }

  Widget _buildEventCard(
    String title,
    String details,
    IconData icon,
    Gradient gradient,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        gradient: gradient, // Apply the gradient here
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              details,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            // A subtle call to action button
            ElevatedButton(
              onPressed: () {
                // Handle card tap/navigation here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'View Details',
                style: TextStyle(
                  color: gradient
                      .colors
                      .first, // Use the primary color of the gradient for text
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
