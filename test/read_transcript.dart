import 'dart:convert';
import 'dart:io';

void main() async {
  final fileFull = File(r'C:\Users\Jayasurya\.gemini\antigravity-ide\brain\bf0bf5d7-e550-4a90-9a33-26ff636a812c\.system_generated\logs\transcript_full.jsonl');
  if (!await fileFull.exists()) {
    print('No full transcript found.');
    return;
  }
  
  final lines = await fileFull.readAsLines();
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.contains('browser_subagent') || line.contains('invoke_subagent')) {
      print('Line ${i+1}: contains browser_subagent/invoke_subagent');
      try {
        final decoded = jsonDecode(line);
        print('  Step: ${decoded['step_index']}, Type: ${decoded['type']}');
        if (decoded['tool_calls'] != null) {
          print('  Tool calls: ${jsonEncode(decoded['tool_calls'])}');
        }
      } catch (e) {}
    }
  }
}
