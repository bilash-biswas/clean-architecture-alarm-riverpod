import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/providers.dart';
import '../../domain/entities/city_entity.dart';
import '../../data/models/city_model.dart';

class WorldClockState {
  final List<CityEntity> cities;
  final DateTime currentTime;

  const WorldClockState({
    this.cities = const [],
    required this.currentTime,
  });

  WorldClockState copyWith({
    List<CityEntity>? cities,
    DateTime? currentTime,
  }) {
    return WorldClockState(
      cities: cities ?? this.cities,
      currentTime: currentTime ?? this.currentTime,
    );
  }
}

class WorldClockController extends StateNotifier<WorldClockState> {
  final DatabaseService _db;
  Timer? _tickerTimer;

  WorldClockController(this._db) : super(WorldClockState(currentTime: DateTime.now())) {
    _loadCities();
    _startTicker();
  }

  void _loadCities() {
    final cityModels = _db.getCities();
    
    if (cityModels.isEmpty) {
      // Initialize with default cities
      final defaults = [
        const CityEntity(id: 'london', name: 'London', country: 'United Kingdom', timezoneOffset: 0.0),
        const CityEntity(id: 'new_york', name: 'New York', country: 'United States', timezoneOffset: -5.0),
        const CityEntity(id: 'dhaka', name: 'Dhaka', country: 'Bangladesh', timezoneOffset: 6.0),
        const CityEntity(id: 'tokyo', name: 'Tokyo', country: 'Japan', timezoneOffset: 9.0),
      ];
      
      for (var city in defaults) {
        _db.saveCity(CityModel.fromEntity(city));
      }
      state = state.copyWith(cities: defaults);
    } else {
      state = state.copyWith(
        cities: cityModels.map((m) => m.toEntity()).toList(),
      );
    }
  }

  void _startTicker() {
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        state = state.copyWith(currentTime: DateTime.now());
      }
    });
  }

  Future<void> addCity(CityEntity city) async {
    // Avoid duplicates
    if (state.cities.any((c) => c.id == city.id)) return;
    
    await _db.saveCity(CityModel.fromEntity(city));
    
    final updatedList = List<CityEntity>.from(state.cities)..add(city);
    state = state.copyWith(cities: updatedList);
  }

  Future<void> removeCity(String id) async {
    await _db.deleteCity(id);
    
    final updatedList = state.cities.where((c) => c.id != id).toList();
    state = state.copyWith(cities: updatedList);
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }
}

final worldClockControllerProvider =
    StateNotifierProvider<WorldClockController, WorldClockState>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return WorldClockController(db);
});
