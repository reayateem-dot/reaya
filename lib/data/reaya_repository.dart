import '../models/health_service.dart';
import '../models/medicine.dart';

abstract interface class ReayaRepository {
  Future<List<HealthService>> getServices();
  Future<Set<String>> getFavoriteIds();
  Future<void> saveFavoriteIds(Set<String> ids);
  Future<List<Medicine>> getMedicines();
  Future<void> saveMedicines(List<Medicine> medicines);
}
