// lib/features/00_app/models/background_activity.dart

sealed class BackgroundActivity {
  const BackgroundActivity();

  bool get isActive => this is! Idle;
}

class Idle extends BackgroundActivity {
  const Idle();
}

class Syncing extends BackgroundActivity {
  final int current;
  final int total;
  const Syncing(this.current, this.total);

  double get progress => total > 0 ? current / total : 0.0;
}

class Recalculating extends BackgroundActivity {
  const Recalculating();
}