class HistoryItem {
  final int? id;
  final String text;
  final String gifPath;
  final String timestamp;

  HistoryItem({this.id, required this.text, required this.gifPath, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'gifPath': gifPath,
      'timestamp': timestamp,
    };
  }

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      id: map['id'],
      text: map['text'],
      gifPath: map['gifPath'],
      timestamp: map['timestamp'],
    );
  }
}
