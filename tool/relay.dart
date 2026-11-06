// Standalone "Listen together" relay for friends who are not on the same Wi-Fi.
//
//   dart run tool/relay.dart [port]        (default 47800)
//
// Run it on any PC/VPS reachable from the internet (open the TCP port), then
// everyone enters ws://<that-address>:<port>/ in Prism → Settings → Listen
// together and uses the short 4-letter session code.
import 'dart:io';

import 'package:prism/features/together/data/relay.dart';

Future<void> main(List<String> args) async {
  final port = args.isEmpty ? 47800 : int.parse(args.first);
  final relay = await ListenTogetherRelay.start(port: port);
  stdout.writeln('Prism relay listening on ws://0.0.0.0:${relay.port}/  (Ctrl+C to stop)');
  await ProcessSignal.sigint.watch().first;
  await relay.close();
}
