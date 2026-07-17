/// Utility for generating unique IDs across multiple servers
class IdGenerator {
  /// Generates a unique ID by combining server ID and Subsonic ID
  /// Format: {serverId}_{subsonicId}
  static String generateUniqueId(String serverId, String subsonicId) {
    return '${serverId}_$subsonicId';
  }

  /// Extracts the original Subsonic ID from a unique ID
  /// Returns the part after the first underscore
  static String extractSubsonicId(String uniqueId) {
    final parts = uniqueId.split('_');
    if (parts.length < 2) {
      return uniqueId; // Return as-is if not in expected format
    }
    return parts
        .sublist(1)
        .join('_'); // Join in case original ID had underscores
  }

  /// Extracts the server ID from a unique ID
  /// Returns the part before the first underscore
  static String extractServerId(String uniqueId) {
    final parts = uniqueId.split('_');
    return parts.first;
  }

  /// Checks if an ID is in the unique format (contains server prefix)
  static bool isUniqueId(String id) {
    return id.contains('_');
  }
}
