import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

/// Writes the frame-timing summaries reported by integration_test/perf_test.dart
/// to `build/perf/<timestamp>.json` and prints a compact table.
Future<void> main() => integrationDriver(
      responseDataCallback: (data) async {
        if (data == null) return;
        final dir = Directory('build/perf')..createSync(recursive: true);
        final file = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.json');
        file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
        stdout.writeln('PERF written to ${file.path}');
        for (final e in data.entries) {
          final m = e.value as Map<String, dynamic>;
          double v(String k) => (m[k] as num?)?.toDouble() ?? -1;
          stdout.writeln('PERF ${e.key.padRight(14)} frames=${m['frame_count']}  '
              'build avg ${v('average_frame_build_time_millis').toStringAsFixed(2)} / p90 ${v('90th_percentile_frame_build_time_millis').toStringAsFixed(2)} / worst ${v('worst_frame_build_time_millis').toStringAsFixed(1)} ms  '
              'raster avg ${v('average_frame_rasterizer_time_millis').toStringAsFixed(2)} / p90 ${v('90th_percentile_frame_rasterizer_time_millis').toStringAsFixed(2)} / worst ${v('worst_frame_rasterizer_time_millis').toStringAsFixed(1)} ms  '
              'missed build ${m['missed_frame_build_budget_count']} raster ${m['missed_frame_rasterizer_budget_count']}');
        }
      },
    );
