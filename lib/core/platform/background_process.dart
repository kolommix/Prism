import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

/// What a finished process left.
class ProcessOutcome {
  const ProcessOutcome(this.exitCode, this.stdout, this.stderr);
  final int exitCode;
  final String stdout;
  final String stderr;
}

/// A process started from a background isolate.
///
/// On Windows, starting a process blocks the calling thread until Windows has
/// created it, and for a large exe that an antivirus scans first (ffmpeg.exe
/// is 105 MB) that is about half a second. From the UI isolate that froze the
/// whole app on every new song (measured with the CPU profiler:
/// `NtCreateUserProcess`). Here the wait happens on another thread.
class BackgroundProcess {
  BackgroundProcess._(this._done);

  final Future<ProcessOutcome> _done;
  SendPort? _control;
  bool _killed = false;

  /// Completes when the process has ended (or could not start: exit code -2,
  /// the reason in [ProcessOutcome.stderr]).
  Future<ProcessOutcome> get done => _done;

  /// Ends the process (also before it has fully started).
  void kill() {
    _killed = true;
    _control?.send('kill');
  }

  /// Starts [executable]. [onStderr] gets stderr as it arrives (progress);
  /// [keepStdout] collects stdout as text, otherwise it is drained. After
  /// [timeout] the process is killed and the exit code is -1.
  static Future<BackgroundProcess> start(
    String executable,
    List<String> arguments, {
    void Function(String chunk)? onStderr,
    bool keepStdout = true,
    Duration? timeout,
  }) async {
    final events = ReceivePort();
    final done = Completer<ProcessOutcome>();
    late final BackgroundProcess handle;
    handle = BackgroundProcess._(done.future);
    events.listen((m) {
      if (m is SendPort) {
        handle._control = m;
        if (handle._killed) m.send('kill');
      } else if (m is String) {
        onStderr?.call(m);
      } else if (m == null) {
        // The isolate ended without a result (should not happen): don't hang.
        if (!done.isCompleted) done.complete(const ProcessOutcome(-2, '', ''));
        events.close();
      } else if (m is List) {
        if (!done.isCompleted) done.complete(ProcessOutcome(m[0] as int, m[1] as String, m[2] as String));
        events.close();
      }
    });
    try {
      await Isolate.spawn(
        _main,
        _Job(executable, arguments, events.sendPort, onStderr != null, keepStdout, timeout?.inMilliseconds),
        errorsAreFatal: true,
        onExit: events.sendPort,
      );
    } on Object catch (e) {
      events.close();
      return BackgroundProcess._(Future.value(ProcessOutcome(-2, '', '$e')));
    }
    return handle;
  }

  /// Runs to the end and returns what it printed.
  static Future<ProcessOutcome> run(String executable, List<String> arguments, {Duration? timeout}) async =>
      (await start(executable, arguments, timeout: timeout)).done;

  static Future<void> _main(_Job job) async {
    final control = ReceivePort();
    job.reply.send(control.sendPort);
    final Process proc;
    try {
      proc = await Process.start(job.executable, job.arguments);
    } on Object catch (e) {
      job.reply.send([-2, '', '$e']);
      control.close();
      return;
    }
    var timedOut = false;
    control.listen((_) => proc.kill());
    final out = StringBuffer(), err = StringBuffer();
    final a = job.keepStdout
        ? proc.stdout.transform(const Utf8Decoder(allowMalformed: true)).listen(out.write).asFuture<void>()
        : proc.stdout.drain<void>();
    final b = proc.stderr.transform(const Utf8Decoder(allowMalformed: true)).listen((c) {
      err.write(c);
      if (job.streamStderr) job.reply.send(c);
    }).asFuture<void>();
    final timeout = job.timeoutMs;
    var code = timeout == null
        ? await proc.exitCode
        : await proc.exitCode.timeout(Duration(milliseconds: timeout), onTimeout: () {
            timedOut = true;
            proc.kill();
            return -1;
          });
    await Future.wait([a, b]).timeout(const Duration(seconds: 5), onTimeout: () => const []);
    if (timedOut) code = -1;
    job.reply.send([code, out.toString(), err.toString()]);
    control.close();
  }
}

class _Job {
  const _Job(this.executable, this.arguments, this.reply, this.streamStderr, this.keepStdout, this.timeoutMs);
  final String executable;
  final List<String> arguments;
  final SendPort reply;
  final bool streamStderr;
  final bool keepStdout;
  final int? timeoutMs;
}
