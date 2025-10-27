import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/quesgen/controller.dart';

final quesgenControllerProvider =
    NotifierProvider<QuesgenController, QuesgenState>(
      QuesgenController.new,
    );
