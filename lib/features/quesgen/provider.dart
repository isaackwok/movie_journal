import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/quesgen/api.dart';
import 'package:movie_journal/features/quesgen/controller.dart';

final quesgenControllerProvider =
    StateNotifierProvider<QuesgenController, QuesgenState>(
      (ref) => QuesgenController(QuesgenAPI()),
    );
