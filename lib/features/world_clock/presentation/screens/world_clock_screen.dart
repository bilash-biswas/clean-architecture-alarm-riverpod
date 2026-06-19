import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bottom_nav_bar.dart';
import '../../domain/entities/city_entity.dart';
import '../controllers/world_clock_controller.dart';

class WorldClockScreen extends ConsumerStatefulWidget {
  const WorldClockScreen({super.key});

  @override
  ConsumerState<WorldClockScreen> createState() => _WorldClockScreenState();
}

class _WorldClockScreenState extends ConsumerState<WorldClockScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Standard catalog of global cities to select from
  static const List<CityEntity> _cityCatalog = [
    CityEntity(
      id: 'honolulu',
      name: 'Honolulu',
      country: 'United States',
      timezoneOffset: -10.0,
    ),
    CityEntity(
      id: 'los_angeles',
      name: 'Los Angeles',
      country: 'United States',
      timezoneOffset: -8.0,
    ),
    CityEntity(
      id: 'denver',
      name: 'Denver',
      country: 'United States',
      timezoneOffset: -7.0,
    ),
    CityEntity(
      id: 'chicago',
      name: 'Chicago',
      country: 'United States',
      timezoneOffset: -6.0,
    ),
    CityEntity(
      id: 'new_york',
      name: 'New York',
      country: 'United States',
      timezoneOffset: -5.0,
    ),
    CityEntity(
      id: 'rio_de_janeiro',
      name: 'Rio de Janeiro',
      country: 'Brazil',
      timezoneOffset: -3.0,
    ),
    CityEntity(
      id: 'london',
      name: 'London',
      country: 'United Kingdom',
      timezoneOffset: 0.0,
    ),
    CityEntity(
      id: 'paris',
      name: 'Paris',
      country: 'France',
      timezoneOffset: 1.0,
    ),
    CityEntity(
      id: 'cairo',
      name: 'Cairo',
      country: 'Egypt',
      timezoneOffset: 2.0,
    ),
    CityEntity(
      id: 'moscow',
      name: 'Moscow',
      country: 'Russia',
      timezoneOffset: 3.0,
    ),
    CityEntity(
      id: 'dubai',
      name: 'Dubai',
      country: 'United Arab Emirates',
      timezoneOffset: 4.0,
    ),
    CityEntity(
      id: 'mumbai',
      name: 'Mumbai',
      country: 'India',
      timezoneOffset: 5.5,
    ),
    CityEntity(
      id: 'dhaka',
      name: 'Dhaka',
      country: 'Bangladesh',
      timezoneOffset: 6.0,
    ),
    CityEntity(
      id: 'bangkok',
      name: 'Bangkok',
      country: 'Thailand',
      timezoneOffset: 7.0,
    ),
    CityEntity(
      id: 'singapore',
      name: 'Singapore',
      country: 'Singapore',
      timezoneOffset: 8.0,
    ),
    CityEntity(
      id: 'tokyo',
      name: 'Tokyo',
      country: 'Japan',
      timezoneOffset: 9.0,
    ),
    CityEntity(
      id: 'sydney',
      name: 'Sydney',
      country: 'Australia',
      timezoneOffset: 10.0,
    ),
    CityEntity(
      id: 'auckland',
      name: 'Auckland',
      country: 'New Zealand',
      timezoneOffset: 12.0,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Calculate local time for a city based on GMT offset
  DateTime _getLocalTime(DateTime utcTime, double offset) {
    return utcTime.add(Duration(minutes: (offset * 60).toInt()));
  }

  // Get background gradient based on city local hour
  Gradient _getGradientForHour(int hour, bool isDark) {
    if (hour >= 6 && hour < 17) {
      // Day (6 AM - 5 PM)
      return LinearGradient(
        colors: isDark
            ? [
                const Color(0xFF023E8A).withOpacity(0.12),
                const Color(0xFF0077B6).withOpacity(0.06),
              ]
            : [
                const Color(0xFF90E0EF).withOpacity(0.25),
                const Color(0xFFCAF0F8).withOpacity(0.15),
              ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if ((hour >= 5 && hour < 6) || (hour >= 17 && hour < 19)) {
      // Sunrise/Sunset (5 AM-6 AM, 5 PM-7 PM)
      return LinearGradient(
        colors: isDark
            ? [
                const Color(0xFFE2711D).withOpacity(0.18),
                const Color(0xFF6A0DAD).withOpacity(0.12),
              ]
            : [
                const Color(0xFFFFB5A7).withOpacity(0.25),
                const Color(0xFFFCD5CE).withOpacity(0.15),
              ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      // Night (7 PM - 5 AM)
      return LinearGradient(
        colors: isDark
            ? [
                const Color(0xFF0F172A).withOpacity(0.50),
                const Color(0xFF1E293B).withOpacity(0.25),
              ]
            : [
                const Color(0xFFD8B4FE).withOpacity(0.15),
                const Color(0xFFEEF2F6).withOpacity(0.35),
              ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  // Format GMT offset comparison
  String _getOffsetDiffText(double offset) {
    final homeOffset = DateTime.now().timeZoneOffset.inMinutes / 60.0;
    final diff = offset - homeOffset;

    if (diff == 0.0) return 'Same time';
    final sign = diff > 0 ? '+' : '';
    final numStr = diff % 1 == 0
        ? diff.toInt().toString()
        : diff.toStringAsFixed(1);
    return '$sign${numStr}h';
  }

  void _showAddCityBottomSheet(
    BuildContext context,
    List<CityEntity> activeCities,
    WorldClockController controller,
  ) {
    _searchController.clear();
    _searchQuery = '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF070708) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _cityCatalog
                .where(
                  (c) =>
                      !activeCities.any((ac) => ac.id == c.id) &&
                      (c.name.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          c.country.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          )),
                )
                .toList();

            final addIconColor = isDark
                ? const Color(0xFF00F5D4)
                : const Color(0xFF7B2CBF);
            final titleColor = isDark ? Colors.white : Colors.black87;
            final subtitleColor = isDark
                ? Colors.white.withOpacity(0.5)
                : Colors.black.withOpacity(0.5);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add World City',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    style: TextStyle(color: titleColor),
                    decoration: InputDecoration(
                      hintText: 'Search city or country...',
                      hintStyle: TextStyle(
                        color: isDark
                            ? Colors.white.withOpacity(0.3)
                            : Colors.black.withOpacity(0.38),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.04)
                          : Colors.black.withOpacity(0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: filtered.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text(
                                'No matching cities found',
                                style: TextStyle(color: subtitleColor),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final city = filtered[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  city.name,
                                  style: TextStyle(color: titleColor),
                                ),
                                subtitle: Text(
                                  '${city.country} (GMT ${city.timezoneOffset >= 0 ? '+' : ''}${city.timezoneOffset % 1 == 0 ? city.timezoneOffset.toInt() : city.timezoneOffset})',
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: Icon(Icons.add, color: addIconColor),
                                onTap: () {
                                  controller.addCity(city);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(worldClockControllerProvider);
    final controller = ref.read(worldClockControllerProvider.notifier);
    final utcNow = state.currentTime.toUtc();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;
    final captionColor = isDark
        ? Colors.white.withOpacity(0.4)
        : Colors.black.withOpacity(0.4);
    final emptyTextColor = isDark
        ? Colors.white.withOpacity(0.3)
        : Colors.black.withOpacity(0.38);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.getBackgroundGradient(context),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'World Clock',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.settings_outlined, color: subtitleColor),
                      onPressed: () => context.go('/settings'),
                    ),
                  ],
                ),
              ),

              // Cities display list
              Expanded(
                child: state.cities.isEmpty
                    ? Center(
                        child: Text(
                          'No cities added yet',
                          style: TextStyle(color: emptyTextColor, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 24,
                          right: 24,
                          top: 8,
                          bottom: 90,
                        ),
                        itemCount: state.cities.length,
                        itemBuilder: (context, index) {
                          final city = state.cities[index];
                          final localTime = _getLocalTime(
                            utcNow,
                            city.timezoneOffset,
                          );
                          final formatTime = DateFormat(
                            'hh:mm',
                          ).format(localTime);
                          final formatAmPm = DateFormat('a').format(localTime);
                          final formatDay = DateFormat(
                            'EEE, d MMM',
                          ).format(localTime);
                          final diffText = _getOffsetDiffText(
                            city.timezoneOffset,
                          );

                          final amPmColor = isDark
                              ? const Color(0xFF00F5D4).withOpacity(0.8)
                              : const Color(0xFF7B2CBF).withOpacity(0.8);
                          final cardBorderColor = isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              gradient: _getGradientForHour(
                                localTime.hour,
                                isDark,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: cardBorderColor,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          city.name,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: titleColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${city.country}  •  $diffText',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: captionColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.baseline,
                                            textBaseline:
                                                TextBaseline.alphabetic,
                                            children: [
                                              Text(
                                                formatTime,
                                                style: TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                  color: titleColor,
                                                  fontFeatures: const [
                                                    FontFeature.tabularFigures(),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                formatAmPm,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: amPmColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            formatDay,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: captionColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline_rounded,
                                          color: isDark
                                              ? Colors.white.withOpacity(0.2)
                                              : Colors.black.withOpacity(0.2),
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            controller.removeCity(city.id),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: FloatingActionButton(
          onPressed: () =>
              _showAddCityBottomSheet(context, state.cities, controller),
          backgroundColor: isDark
              ? const Color(0xFF00F5D4)
              : const Color(0xFF7B2CBF),
          foregroundColor: isDark ? Colors.black : Colors.white,
          shape: const CircleBorder(),
          elevation: 10,
          child: const Icon(Icons.public, size: 40),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
