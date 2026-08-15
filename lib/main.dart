import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'voucher_ticket.dart';

// ============================================================================
// 1. ABSTRACTION & INTERFACES
// ============================================================================

/// Abstraction: Abstract base class representing any event in the fest.
abstract class FestEvent {
  final String title;
  final String venue;

  FestEvent(this.title, this.venue);

  // Abstract methods enforcing sub-class implementation
  String getEventDetails();
  IconData getIcon();

  // Concrete getter
  String get locationInfo => 'Venue: $venue';
}

/// Interface: Contracts for events that issue certificates.
abstract class Certifiable {
  void generateCertificate(String studentName);
  bool get offersCertificate;
}

// ============================================================================
// 2. MIXINS (Reusable Feature Injection)
// ============================================================================

/// Mixin adding sponsorship and budget handling to events.
mixin SponsorshipRequirement {
  double _budget = 0.0; // Encapsulated private field

  double get budget => _budget;

  void addSponsorship(double amount) {
    if (amount > 0) {
      _budget += amount;
    }
  }

  void allocateExpense(double amount) {
    if (amount <= _budget) {
      _budget -= amount;
    }
  }
}

// ============================================================================
// 3. ENCAPSULATION, INHERITANCE & POLYMORPHISM
// ============================================================================

/// Subclass 1: [TechnicalEvent] extends [FestEvent], uses mixin & interface
class TechnicalEvent extends FestEvent
    with SponsorshipRequirement
    implements Certifiable {
  // Encapsulation: Private members
  int _registrationsCount = 0;
  final int _maxCapacity;

  // Static Member: Tracks total fest registrations across all technical events
  static int totalFestRegistrations = 0;

  // Standard Constructor with super-initializer
  TechnicalEvent(super.title, super.venue, this._maxCapacity);

  // Named Constructor
  TechnicalEvent.codingCompetition(String title)
    : _maxCapacity = 50,
      super(title, 'Lab 302');

  // Factory Constructor: Creates specialized preset events
  factory TechnicalEvent.hackathon() {
    return TechnicalEvent('Ai and Machine Learning', 'Main Auditorium', 100);
  }

  // Getters & Setters for Encapsulated Fields
  int get registrationsCount => _registrationsCount;
  bool get hasCapacity => _registrationsCount < _maxCapacity;

  bool registerStudent() {
    if (_registrationsCount < _maxCapacity) {
      _registrationsCount++;
      totalFestRegistrations++;
      return true;
    }
    return false;
  }

  // Polymorphic Implementation of Abstract Methods
  @override
  String getEventDetails() {
    return 'Tech Event | Slots: $_registrationsCount/$_maxCapacity';
  }

  @override
  IconData getIcon() => Icons.code;

  // Interface Implementation
  @override
  bool get offersCertificate => true;

  @override
  void generateCertificate(String studentName) {
    debugPrint('Certificate generated for $studentName in $title');
  }
}

/// Subclass 2: [CulturalEvent] demonstrating different Polymorphic behavior
class CulturalEvent extends FestEvent implements Certifiable {
  final String category; // e.g., Dance, Music, Drama
  bool _isStageReady = false;

  CulturalEvent(super.title, super.venue, this.category);

  void prepareStage() {
    _isStageReady = true;
  }

  // Polymorphic Overriding
  @override
  String getEventDetails() {
    final status = _isStageReady ? 'Stage Ready' : 'Rehearsals Ongoing';
    return 'Cultural ($category) | Status: $status';
  }

  @override
  IconData getIcon() => Icons.music_note;

  // Interface Implementation
  @override
  bool get offersCertificate => false; // Cultural events might just give trophies

  @override
  void generateCertificate(String studentName) {
    debugPrint('Participation award generated for $studentName');
  }
}

// ============================================================================
// 4. FLUTTER UI INTEGRATION
// ============================================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Some hosted web builds do not ship a local .env file. The app should still
    // render and the registration form can fall back to compile-time values.
  }

  runApp(
    MaterialApp(
      home: const CollegeFestDashboard(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Use a generic web-safe font family to avoid remote Roboto fetch on web
        fontFamily: 'sans-serif',
      ),
    ),
  );
}

class _SocialFooter extends StatelessWidget {
  const _SocialFooter();

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final socialLinks = [
      {
        'icon': Icons.camera_alt,
        'url': 'https://www.instagram.com/',
        'label': 'Instagram',
      },
      {
        'icon': Icons.facebook,
        'url': 'https://www.facebook.com/',
        'label': 'Facebook',
      },
      {
        'icon': Icons.play_circle_fill,
        'url': 'https://www.youtube.com/',
        'label': 'YouTube',
      },
      {
        'icon': Icons.language,
        'url': 'https://www.kleuniversity.in/',
        'label': 'College Website',
      },
    ];

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Follow Us',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 10),
            ...socialLinks.map((link) {
              final icon = link['icon'] as IconData;
              final url = link['url'] as String;
              final label = link['label'] as String;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Tooltip(
                  message: label,
                  child: InkWell(
                    onTap: () => _launchUrl(url),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color.fromARGB(255, 58, 183, 177),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 16,
                        color: const Color.fromARGB(255, 58, 183, 177),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class CollegeFestDashboard extends StatefulWidget {
  const CollegeFestDashboard({super.key});

  @override
  State<CollegeFestDashboard> createState() => _CollegeFestDashboardState();
}

class _CollegeFestDashboardState extends State<CollegeFestDashboard> {
  // Polymorphic List holding base type reference [FestEvent]
  late final List<FestEvent> _festEvents;
  Map<String, dynamic>? _recentRegistration;
  final PageController _galleryController = PageController();

  // Navigation state
  String _currentNavigation = 'Home'; // Track current view
  final List<String> _navigationItems = [
    'Home',
    'Events',
    'Gallery',
    'About',
    'Contact',
  ];

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Instantiating concrete subclasses via various constructors
    _festEvents = [
      TechnicalEvent.hackathon(), // Factory Constructor
      TechnicalEvent.codingCompetition('Hacakathon'), // Named Constructor
      TechnicalEvent(
        'Flutter Workshop',
        'Class room 502',
        40,
      ), // Standard Constructor
      CulturalEvent(
        'Kannada Orchestor',
        'College Ground',
        'Music',
      ), // Subclass 2
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KLE Haveri BCA'),
        backgroundColor: const Color.fromARGB(255, 58, 183, 177),
        foregroundColor: const Color.fromARGB(255, 14, 13, 13),
        elevation: 2,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _navigationItems.map((item) {
                  final isActive = _currentNavigation == item;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentNavigation = item;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isActive
                                ? const Color.fromARGB(255, 58, 183, 177)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isActive
                              ? const Color.fromARGB(255, 58, 183, 177)
                              : Colors.black54,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
      body: _buildNavigationContent(),
      bottomNavigationBar: const _SocialFooter(),
    );
  }

  /// Build content based on current navigation selection
  Widget _buildNavigationContent() {
    switch (_currentNavigation) {
      case 'Home':
        return _buildHomeView();
      case 'Events':
        return _buildEventsView();
      case 'Gallery':
        return _buildGalleryView();
      case 'About':
        return _buildAboutView();
      case 'Contact':
        return _buildContactView();
      default:
        return _buildHomeView();
    }
  }

  /// Home View - Gallery + Recent Events
  Widget _buildHomeView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Event Gallery',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(
                                    (0.1 * 255).round(),
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _GalleryWidget(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.08 * 255).round()),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, itemConstraints) {
                      final useRow = itemConstraints.maxWidth >= 500;

                      return useRow
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildInfoItem(
                                  icon: Icons.calendar_today,
                                  iconColor: const Color.fromARGB(
                                    255,
                                    58,
                                    183,
                                    177,
                                  ),
                                  title: 'Aug 15, 2026',
                                  subtitle: 'Festival Date',
                                ),
                                Container(
                                  width: 1,
                                  height: 60,
                                  color: Colors.grey.shade300,
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    final googleMapsUrl =
                                        'https://www.google.com/maps/search/KLE+Haveri+BCA+College,+Haveri,+Karnataka';
                                    if (await canLaunchUrl(
                                      Uri.parse(googleMapsUrl),
                                    )) {
                                      await launchUrl(
                                        Uri.parse(googleMapsUrl),
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                  },
                                  child: _buildInfoItem(
                                    icon: Icons.location_on,
                                    iconColor: Colors.red.shade600,
                                    title: 'KLE Haveri BCA',
                                    subtitle: 'View Location',
                                    subtitleColor: Colors.blue,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 60,
                                  color: Colors.grey.shade300,
                                ),
                                _buildInfoItem(
                                  icon: Icons.people,
                                  iconColor: Colors.purple.shade600,
                                  title:
                                      '${TechnicalEvent.totalFestRegistrations}',
                                  subtitle: 'Participants',
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _buildInfoItem(
                                  icon: Icons.calendar_today,
                                  iconColor: const Color.fromARGB(
                                    255,
                                    58,
                                    183,
                                    177,
                                  ),
                                  title: 'Aug 15, 2026',
                                  subtitle: 'Festival Date',
                                ),
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () async {
                                    final googleMapsUrl =
                                        'https://www.google.com/maps/search/KLE+Haveri+BCA+College,+Haveri,+Karnataka';
                                    if (await canLaunchUrl(
                                      Uri.parse(googleMapsUrl),
                                    )) {
                                      await launchUrl(
                                        Uri.parse(googleMapsUrl),
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                  },
                                  child: _buildInfoItem(
                                    icon: Icons.location_on,
                                    iconColor: Colors.red.shade600,
                                    title: 'KLE Haveri BCA',
                                    subtitle: 'View Location',
                                    subtitleColor: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildInfoItem(
                                  icon: Icons.people,
                                  iconColor: Colors.purple.shade600,
                                  title:
                                      '${TechnicalEvent.totalFestRegistrations}',
                                  subtitle: 'Participants',
                                ),
                              ],
                            );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.event, size: 20),
                        label: const Text(
                          'View Events',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            58,
                            183,
                            177,
                          ),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 3,
                        ),
                        onPressed: () {
                          setState(() {
                            _currentNavigation = 'Events';
                          });
                        },
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.shade200,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.06 * 255).round()),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Text(
                        'KLE INDEPENDENCE DAY 2026',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Develop the next generation of freedom—register now to compile our rich heritage and deploy a future of endless possibilities at KLE Haveri.',
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Events View - All Events
  Widget _buildEventsView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'All Events',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Total Events: ${_festEvents.length}',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _festEvents.length,
            itemBuilder: (context, index) {
              final event = _festEvents[index];
              return _buildEventCard(event);
            },
          ),
        ),
      ],
    );
  }

  /// Gallery View - Full Screen Gallery
  Widget _buildGalleryView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.purple.shade50,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Event Gallery',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Browse all festival images and moments',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.1 * 255).round()),
                  blurRadius: 8,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: const _GalleryWidget(),
            ),
          ),
        ),
      ],
    );
  }

  /// About View - Festival Information
  Widget _buildAboutView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About KLE Haveri BCA Fest',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Learn about our college fest',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About the Festival',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'KLE Haveri BCA College Fest is one of the most anticipated events on our college calendar. '
                  'It brings together students from various departments to showcase their talents and participate in exciting competitions.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Highlights',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildAboutPoint(
                  'Technical Events',
                  'Hackathons, coding competitions, and workshops',
                ),
                _buildAboutPoint(
                  'Cultural Events',
                  'Music, dance, drama, and cultural performances',
                ),
                _buildAboutPoint(
                  'Prizes',
                  'Exciting prizes and certificates for winners',
                ),
                _buildAboutPoint(
                  'Participation',
                  'Open to all students and departments',
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Contact View - Contact Information
  Widget _buildContactView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact Us',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Get in touch with us for more information',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contact Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildContactCard(
                  icon: Icons.location_on,
                  title: 'Address',
                  content:
                      'KLE Haveri BCA Department\nKLE Institute of Technology\nHaveri, Karnataka',
                  color: Colors.red,
                ),
                const SizedBox(height: 12),
                _buildContactCard(
                  icon: Icons.phone,
                  title: 'Phone',
                  content: '+91-XXXX-XXXX-XX',
                  color: Colors.green,
                ),
                const SizedBox(height: 12),
                _buildContactCard(
                  icon: Icons.email,
                  title: 'Email',
                  content: 'fest@kle.com\nbca@kle.com',
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildContactCard(
                  icon: Icons.access_time,
                  title: 'Office Hours',
                  content: 'Monday - Friday\n9:00 AM - 5:00 PM',
                  color: Colors.purple,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Color subtitleColor = Colors.black54,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 10,
            color: subtitleColor,
            fontWeight: subtitleColor == Colors.black54
                ? FontWeight.normal
                : FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Helper widget for About page points
  Widget _buildAboutPoint(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: Color.fromARGB(255, 58, 183, 177),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget for Contact page cards
  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Renders UI polymorphically using base class contract [FestEvent]
  Widget _buildEventCard(FestEvent event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: InkWell(
        onTap: () => _openEventDetails(event),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color.fromARGB(255, 196, 232, 233),
                  child: Icon(
                    event.getIcon(),
                    color: const Color.fromARGB(255, 58, 148, 183),
                  ),
                ),
                title: Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${event.locationInfo}\n${event.getEventDetails()}',
                ),
                trailing:
                    (event is Certifiable &&
                        (event as Certifiable).offersCertificate)
                    ? ElevatedButton.icon(
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Voucher'),
                        onPressed: () async {
                          if (_recentRegistration == null ||
                              _recentRegistration!['event_title'] !=
                                  event.title) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No recent registration for this event.',
                                ),
                              ),
                            );
                            return;
                          }

                          try {
                            final pdfBytes = await buildVoucherPdf(
                              _recentRegistration!,
                            );
                            await Printing.sharePdf(
                              bytes: pdfBytes,
                              filename:
                                  '${_recentRegistration!['student_name'] ?? 'voucher'}.pdf',
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to generate voucher: $e'),
                              ),
                            );
                          }
                        },
                      )
                    : null,
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (event is TechnicalEvent) ...[
                    Text('Budget: Rs${event.budget.toInt()}'),
                    IconButton(
                      icon: const Icon(
                        Icons.attach_money,
                        color: Color.fromARGB(255, 87, 175, 76),
                      ),
                      onPressed: () {
                        setState(() {
                          event.addSponsorship(100.0);
                        });
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Register'),
                      onPressed: () {
                        _showRegistrationDialog(event);
                      },
                    ),
                  ],
                  if (event is CulturalEvent) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.mic, size: 16),
                      label: const Text('Lets start the program'),
                      onPressed: () {
                        setState(() {
                          event.prepareStage();
                        });
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEventDetails(FestEvent event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventDetailPage(
          event: event,
          recentRegistration: _recentRegistration,
        ),
      ),
    );
  }

  Future<void> _showRegistrationDialog(TechnicalEvent event) async {
    if (!event.hasCapacity) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration full for this event.')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final collegeController = TextEditingController();
    final emailController = TextEditingController();
    var isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Register for Event'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Student Name',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter student name';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter phone number';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: collegeController,
                        decoration: const InputDecoration(labelText: 'College'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter college name';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter email address';
                          }
                          if (!RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(value)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }
                          setState(() {
                            isSubmitting = true;
                          });

                          final success = await _submitRegistration(
                            event: event,
                            studentName: nameController.text,
                            phoneNumber: phoneController.text,
                            collegeName: collegeController.text,
                            emailAddress: emailController.text,
                          );

                          if (!mounted) return;
                          setState(() {
                            isSubmitting = false;
                          });

                          if (success) {
                            final registered = event.registerStudent();
                            if (registered) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Registration successful'),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Registration limit reached.'),
                                ),
                              );
                            }
                            setState(() {
                              _recentRegistration = {
                                'student_name': nameController.text.trim(),
                                'phone_number': phoneController.text.trim(),
                                'college': collegeController.text.trim(),
                                'email_address': emailController.text.trim(),
                                'event_title': event.title,
                                'event_venue': event.venue,
                                'event_type': event.runtimeType.toString(),
                                'registered_at': DateTime.now()
                                    .toUtc()
                                    .toIso8601String(),
                              };
                            });
                            Navigator.of(context).pop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to submit registration.'),
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _submitRegistration({
    required TechnicalEvent event,
    required String studentName,
    required String phoneNumber,
    required String collegeName,
    required String emailAddress,
  }) async {
    final supabaseUrl =
        dotenv.env['SUPABASE_URL'] ??
        const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    final supabaseKey =
        dotenv.env['SUPABASE_KEY'] ??
        const String.fromEnvironment('SUPABASE_KEY', defaultValue: '');

    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Supabase credentials are not configured.'),
        ),
      );
      return false;
    }

    final uri = Uri.parse('$supabaseUrl/rest/v1/registrations');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
        'Prefer': 'return=representation',
      },
      body: jsonEncode({
        'student_name': studentName.trim(),
        'phone_number': phoneNumber.trim(),
        'college': collegeName.trim(),
        'email_address': emailAddress.trim(),
        'event_title': event.title,
        'event_venue': event.venue,
        'event_type': event.runtimeType.toString(),
        'registered_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );

    return response.statusCode == 201;
  }
}

class EventDetailPage extends StatelessWidget {
  final FestEvent event;
  final Map<String, dynamic>? recentRegistration;

  const EventDetailPage({
    super.key,
    required this.event,
    this.recentRegistration,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        backgroundColor: const Color.fromARGB(255, 58, 183, 177),
        foregroundColor: const Color.fromARGB(255, 14, 13, 13),
      ),
      bottomNavigationBar: const _SocialFooter(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.locationInfo,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.getEventDetails(),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  if (event is TechnicalEvent) ...[
                    Text(
                      'Budget: Rs${(event as TechnicalEvent).budget.toInt()}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (event is CulturalEvent) ...[
                    Text(
                      'Category: ${(event as CulturalEvent).category}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Text(
                        'Certificate: ${(event is Certifiable && (event as Certifiable).offersCertificate) ? 'Available' : 'Not available'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 12),
                      if (event is Certifiable &&
                          (event as Certifiable).offersCertificate)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Download Voucher'),
                          onPressed: () async {
                            if (recentRegistration == null ||
                                recentRegistration!['event_title'] !=
                                    event.title) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'No recent registration for this event.',
                                  ),
                                ),
                              );
                              return;
                            }

                            try {
                              final pdfBytes = await buildVoucherPdf(
                                recentRegistration!,
                              );
                              await Printing.sharePdf(
                                bytes: pdfBytes,
                                filename:
                                    '${recentRegistration!['student_name'] ?? 'voucher'}.pdf',
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to generate voucher: $e',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Event Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This page shows details of the selected fest event with a preview image and a summary of what to expect. Use this screen to review the venue, status, and special notes before joining the event.',
                    style: TextStyle(fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple gallery widget that cycles through provided asset images.
class _GalleryWidget extends StatefulWidget {
  /// Optional list of image asset paths. If omitted or empty, the widget
  /// will auto-discover assets under [assetDir] using the AssetManifest.
  final List<String>? images;
  final String assetDir;

  const _GalleryWidget() : assetDir = 'assets/images/', images = null;

  @override
  State<_GalleryWidget> createState() => _GalleryWidgetState();
}

class _GalleryWidgetState extends State<_GalleryWidget> {
  int _index = 0;
  late final PageController _controller;
  List<String> _images = [];
  Timer? _autoSlideTimer;
  final Duration _autoSlideDuration = const Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: _index);
    if (widget.images != null && widget.images!.isNotEmpty) {
      _images = widget.images!;
    } else {
      _loadAssets();
    }
    _startAutoSlide();
  }

  Future<void> _loadAssets() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap =
          json.decode(manifestContent) as Map<String, dynamic>;
      final assets = manifestMap.keys
          .where(
            (String key) =>
                key.startsWith(widget.assetDir) &&
                (key.endsWith('.png') ||
                    key.endsWith('.jpg') ||
                    key.endsWith('.jpeg') ||
                    key.endsWith('.svg')),
          )
          .toList();
      assets.sort();
      if (mounted) {
        setState(() {
          _images = assets;
        });
        _startAutoSlide();
      }
    } catch (_) {
      // If manifest can't be read, use default images
      _startAutoSlide();
    }
  }

  /// Start auto-slide timer
  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    if (_images.isEmpty) return;

    _autoSlideTimer = Timer.periodic(_autoSlideDuration, (timer) {
      if (_controller.hasClients && mounted) {
        final nextPage = (_index + 1) % _images.length;
        _controller.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  /// Reset auto-slide timer
  void _resetAutoSlide() {
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_images.isEmpty) {
      // Fallback to actual images in assets/images/ with 16:9 landscape ratio
      _images = [
        'assets/images/fest.jpeg',
        'assets/images/fest2.jpeg',
        'assets/images/pic.jpeg',
      ];
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Main Image Carousel
        PageView.builder(
          controller: _controller,
          itemCount: _images.length,
          onPageChanged: (i) {
            setState(() => _index = i);
            _resetAutoSlide(); // Reset timer when user manually navigates
          },
          itemBuilder: (context, i) {
            final src = _images[i];
            return Container(
              color: Colors.grey.shade300,
              child: _buildImageWidget(src),
            );
          },
        ),
        // Image Counter and Navigation
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withAlpha((0.7 * 255).round()),
                  Colors.transparent,
                ],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image Indicators (Dots)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_images.length, (i) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: active ? 12 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.white60,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                // Image Counter
                Text(
                  'Image ${_index + 1} of ${_images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Previous/Next Navigation Buttons with Labels
        if (_images.length > 1) ...[
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha((0.3 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 32,
                  ),
                  tooltip: 'Previous Image',
                  onPressed: () {
                    _controller.previousPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                    _resetAutoSlide();
                  },
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha((0.3 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 32,
                  ),
                  tooltip: 'Next Image',
                  onPressed: () {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                    _resetAutoSlide();
                  },
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Build image widget based on file type
  Widget _buildImageWidget(String src) {
    try {
      if (src.startsWith('http')) {
        return Image.network(
          src,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          },
        );
      }
      if (src.endsWith('.svg')) {
        return SvgPicture.asset(
          src,
          fit: BoxFit.cover,
          placeholderBuilder: (context) => Center(
            child: CircularProgressIndicator(color: Colors.grey.shade400),
          ),
        );
      }
      return Image.asset(
        src,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'Image not found',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      return Center(
        child: Text('Error: $e', style: TextStyle(color: Colors.grey.shade600)),
      );
    }
  }
}
