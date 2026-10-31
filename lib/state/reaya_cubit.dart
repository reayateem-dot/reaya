import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../data/reaya_repository.dart';
import '../models/health_service.dart';
import '../models/medicine.dart';

enum LoadStatus { loading, loaded, error }

class ReayaState extends Equatable {
  const ReayaState({
    this.status = LoadStatus.loading,
    this.loadError,
    this.services = const [],
    this.favoriteIds = const {},
    this.medicines = const [],
  });

  final LoadStatus status;
  final Object? loadError;
  final List<HealthService> services;
  final Set<String> favoriteIds;
  final List<Medicine> medicines;

  @override
  List<Object?> get props => [status, loadError, services, favoriteIds, medicines];
}

class ReayaCubit extends Cubit<ReayaState> {
  ReayaCubit(this._repository) : super(const ReayaState());

  final ReayaRepository _repository;

  LoadStatus get status => state.status;
  Object? get loadError => state.loadError;
  List<HealthService> get services => state.services;
  Set<String> get favoriteIds => state.favoriteIds;
  List<Medicine> get medicines => state.medicines;

  Future<void> load() async {
    emit(const ReayaState(status: LoadStatus.loading));
    try {
      final results = await Future.wait<Object>([
        _repository.getServices(),
        _repository.getFavoriteIds(),
        _repository.getMedicines(),
      ]);
      emit(
        ReayaState(
          status: LoadStatus.loaded,
          services: List.unmodifiable(results[0] as List<HealthService>),
          favoriteIds:
              Set.unmodifiable(results[1] as Set<String>),
          medicines: List.unmodifiable(results[2] as List<Medicine>),
        ),
      );
    } on Exception catch (error) {
      emit(ReayaState(status: LoadStatus.error, loadError: error));
    }
  }

  Future<void> toggleFavorite(String serviceId) async {
    final updated = Set<String>.from(state.favoriteIds);
    if (!updated.add(serviceId)) updated.remove(serviceId);
    await _repository.saveFavoriteIds(updated);
    emit(
      ReayaState(
        status: state.status,
        loadError: state.loadError,
        services: state.services,
        favoriteIds: Set.unmodifiable(updated),
        medicines: state.medicines,
      ),
    );
  }

  Future<void> saveMedicine(Medicine medicine) async {
    final updated = [...state.medicines];
    final index = updated.indexWhere((item) => item.id == medicine.id);
    if (index == -1) {
      updated.add(medicine);
    } else {
      updated[index] = medicine;
    }
    await _repository.saveMedicines(updated);
    _emitMedicines(updated);
  }

  Future<void> deleteMedicine(String id) async {
    final updated =
        state.medicines.where((item) => item.id != id).toList();
    await _repository.saveMedicines(updated);
    _emitMedicines(updated);
  }

  Future<void> updateMedicine(Medicine medicine) async {
    final updated = state.medicines
        .map((item) => item.id == medicine.id ? medicine : item)
        .toList();
    await _repository.saveMedicines(updated);
    _emitMedicines(updated);
  }

  void _emitMedicines(List<Medicine> medicines) {
    emit(
      ReayaState(
        status: state.status,
        loadError: state.loadError,
        services: state.services,
        favoriteIds: state.favoriteIds,
        medicines: List.unmodifiable(medicines),
      ),
    );
  }
}
