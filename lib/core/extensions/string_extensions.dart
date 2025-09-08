extension StringExtensions on String {
  /// Capitalizes the first letter of the string
  String get capitalize {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  /// Capitalizes the first letter of each word
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Removes all whitespace from the string
  String get removeWhitespace {
    return replaceAll(RegExp(r'\s+'), '');
  }

  /// Checks if the string is a valid email
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Checks if the string is a valid URL
  bool get isValidUrl {
    return RegExp(
      r'^https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&=]*)$',
    ).hasMatch(this);
  }

  /// Checks if the string contains only alphabetic characters
  bool get isAlphabetic {
    return RegExp(r'^[a-zA-Z]+$').hasMatch(this);
  }

  /// Checks if the string contains only numeric characters
  bool get isNumeric {
    return RegExp(r'^[0-9]+$').hasMatch(this);
  }

  /// Checks if the string contains only alphanumeric characters
  bool get isAlphaNumeric {
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(this);
  }

  /// Truncates the string to a specified length and adds ellipsis
  String truncate(int length, {String ellipsis = '...'}) {
    if (this.length <= length) return this;
    return '${substring(0, length)}$ellipsis';
  }

  /// Converts string to snake_case
  String get toSnakeCase {
    return replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (Match match) => '${match[1]}_${match[2]}',
    ).toLowerCase();
  }

  /// Converts string to camelCase
  String get toCamelCase {
    final words = split(RegExp(r'[\s_-]+'));
    if (words.isEmpty) return this;

    final firstWord = words.first.toLowerCase();
    final capitalizedWords = words
        .skip(1)
        .map((word) => word.capitalize)
        .join();

    return firstWord + capitalizedWords;
  }

  /// Converts string to kebab-case
  String get toKebabCase {
    return replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (Match match) => '${match[1]}-${match[2]}',
    ).toLowerCase().replaceAll(' ', '-');
  }

  /// Removes HTML tags from string
  String get stripHtml {
    return replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// Checks if string is null or empty
  bool get isNullOrEmpty {
    return isEmpty;
  }

  /// Checks if string is not null and not empty
  bool get isNotNullOrEmpty {
    return isNotEmpty;
  }

  /// Reverses the string
  String get reverse {
    return split('').reversed.join('');
  }

  /// Counts the number of words in the string
  int get wordCount {
    if (trim().isEmpty) return 0;
    return trim().split(RegExp(r'\s+')).length;
  }

  /// Removes duplicate consecutive characters
  String get removeDuplicateChars {
    if (isEmpty) return this;
    final result = StringBuffer();
    String? previousChar;

    for (int i = 0; i < length; i++) {
      if (this[i] != previousChar) {
        result.write(this[i]);
        previousChar = this[i];
      }
    }

    return result.toString();
  }

  /// Converts duration string (e.g., "3:45") to Duration object
  Duration? get toDuration {
    final parts = split(':');
    if (parts.length != 2) return null;

    final minutes = int.tryParse(parts[0]);
    final seconds = int.tryParse(parts[1]);

    if (minutes == null || seconds == null) return null;

    return Duration(minutes: minutes, seconds: seconds);
  }

  /// Formats string as file size (assumes string is bytes)
  String get asFileSize {
    final bytes = int.tryParse(this);
    if (bytes == null) return this;

    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var suffixIndex = 0;

    while (size >= 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }

    return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${suffixes[suffixIndex]}';
  }
}
