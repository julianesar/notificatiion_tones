import '../entities/tone.dart';

abstract class TonesRepository {
  Future<List<Tone>> getByCategory(String id, {int? limit, int? offset});
}
