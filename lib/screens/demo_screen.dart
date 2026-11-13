import 'package:flutter/material.dart';

class DemoScreen extends StatefulWidget {
  // Route name so you can easily link it from your Main Screen
  static const String routeName = '/demo_screen';

  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  // 1. COLORS: Kept your app's design system so it looks native
  static const Color bgColor = Color(0xFF0D0B14);
  static const Color cardColor = Color(0xFF16121E);
  static const Color accentPurple = Color(0xFF9D59FF);

  // 2. STATE VARIABLE: Evaluators often ask "make this button change some text"
  String _buttonMessage = "Click a button below!";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor, // Scaffold is the base of the screen
      
      // --- APP BAR ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'UI Basics Demo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        // IconButton in the AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: accentPurple),
            onPressed: () {
              // Action when icon is pressed
              print("Info icon pressed!"); 
            },
          ),
        ],
      ),

      // --- MAIN CONTENT ---
      // SingleChildScrollView allows the screen to scroll if the content overflows
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column( // Column arranges children vertically
          crossAxisAlignment: CrossAxisAlignment.start, // Aligns items to the left
          children: [
            
            // --- TEXT ---
            const Text(
              'Text Widgets',
              style: TextStyle(
                color: accentPurple,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8), // SizedBox creates empty vertical space
            const Text(
              'This is regular text. Evaluators might ask you to change font size, color, or weight. You do all of that inside the TextStyle property.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // --- IMAGES ---
            const Text(
              'Image Widgets',
              style: TextStyle(color: accentPurple, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Center( // Center widget aligns its child in the middle horizontally
              child: ClipRRect( // ClipRRect rounds the corners of the image
                borderRadius: BorderRadius.circular(16),
                // IMPORTANT: Using Image.network so it works instantly without pubspec.yaml changes
                // If they ask for local image: Image.asset('assets/my_image.png')
                child: Image.network(
                  'https://picsum.photos/400/200', // Random placeholder image
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover, // Ensures image fills the box nicely
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- CONTAINER & ICONS ---
            const Text(
              'Containers & Icons',
              style: TextStyle(color: accentPurple, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16), // Inner spacing
              decoration: BoxDecoration( // Styling the container
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentPurple.withOpacity(0.5)),
              ),
              child: const Row( // Row arranges children horizontally
                mainAxisAlignment: MainAxisAlignment.spaceAround, // Spaces them evenly
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 32),
                  Icon(Icons.favorite, color: Colors.redAccent, size: 32),
                  Icon(Icons.thumb_up, color: Colors.blueAccent, size: 32),
                  Icon(Icons.place_outlined,color: Colors.teal,size:32),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- BUTTONS & INTERACTIVITY ---
            const Text(
              'Buttons & Interactivity',
              style: TextStyle(color: accentPurple, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Dynamic text that changes when buttons are pressed
            Center(
              child: Text(
                _buttonMessage,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 16),

            // 1. ElevatedButton (Primary Action)
            SizedBox(
              width: double.infinity, // Makes button full width
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
               onPressed: () {
                  // setState triggers the UI to rebuild with the new value
                  setState(() {
                    _buttonMessage = "Elevated Button Pressed!";
                  });
                },
                child: const Text('ELEVATED BUTTON', 
                style: TextStyle(color: Colors.white, 
                fontWeight: FontWeight.bold)
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row( // Two buttons side-by-side
              children: [
                // 2. OutlinedButton (Secondary Action)
                Expanded( // Expanded makes the button take up half the available space
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: accentPurple),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.touch_app, color: accentPurple),
                    label: const Text('Outline', style: TextStyle(color: accentPurple)),
                    onPressed: () {
                      setState(() {
                        _buttonMessage = "Outlined Button Pressed!";
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // 3. TextButton (Tertiary Action)
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: cardColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      setState(() {
                        _buttonMessage = "Text Button Pressed!";
                      }
                      );
                    },
                    child: const Text('Text Button', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}