import 'track_point.dart';

/// Serializes recorded [TrackPoint]s to GPX 1.1 with the Garmin
/// TrackPointExtension namespace (heart rate / cadence / power / speed), which
/// Strava, Garmin Connect and most ride platforms import.
class GpxWriter {
  const GpxWriter({this.creator = 'shimano_ride'});

  final String creator;

  String build(List<TrackPoint> points, {String trackName = 'Ride'}) {
    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<gpx version="1.1" creator="${_esc(creator)}"')
      ..writeln('     xmlns="http://www.topografix.com/GPX/1/1"')
      ..writeln('     xmlns:gpxtpx="http://www.garmin.com/xmlschemas/'
          'TrackPointExtension/v1">')
      ..writeln('  <trk>')
      ..writeln('    <name>${_esc(trackName)}</name>')
      ..writeln('    <trkseg>');

    for (final p in points) {
      buffer.writeln('      <trkpt lat="${p.latitude}" lon="${p.longitude}">');
      if (p.elevationMeters != null) {
        buffer.writeln('        <ele>${p.elevationMeters}</ele>');
      }
      buffer.writeln('        <time>${p.time.toUtc().toIso8601String()}</time>');
      final ext = _extensions(p);
      if (ext != null) buffer.writeln(ext);
      buffer.writeln('      </trkpt>');
    }

    buffer
      ..writeln('    </trkseg>')
      ..writeln('  </trk>')
      ..writeln('</gpx>');
    return buffer.toString();
  }

  String? _extensions(TrackPoint p) {
    if (p.heartRateBpm == null &&
        p.cadenceRpm == null &&
        p.powerWatts == null &&
        p.speedKmh == null) {
      return null;
    }
    final inner = StringBuffer();
    if (p.speedKmh != null) {
      inner.write('<gpxtpx:speed>${(p.speedKmh! / 3.6).toStringAsFixed(2)}'
          '</gpxtpx:speed>');
    }
    if (p.heartRateBpm != null) {
      inner.write('<gpxtpx:hr>${p.heartRateBpm}</gpxtpx:hr>');
    }
    if (p.cadenceRpm != null) {
      inner.write('<gpxtpx:cad>${p.cadenceRpm}</gpxtpx:cad>');
    }
    final tpx = '<gpxtpx:TrackPointExtension>$inner'
        '</gpxtpx:TrackPointExtension>';
    final power =
        p.powerWatts != null ? '<power>${p.powerWatts}</power>' : '';
    return '        <extensions>$power$tpx</extensions>';
  }

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
