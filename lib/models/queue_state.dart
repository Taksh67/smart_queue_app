import 'package:hive/hive.dart';

part 'queue_state.g.dart';

@HiveType(typeId: 1)
class QueueState extends HiveObject {
  @HiveField(0)
  int currentToken;

  @HiveField(1)
  int totalInQueue;

  QueueState({
    this.currentToken = 0,
    this.totalInQueue = 0,
  });
}
