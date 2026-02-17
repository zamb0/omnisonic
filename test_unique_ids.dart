import 'package:flutter/material.dart';
import 'package:omnisonic/core/di/injection_container.dart';
import 'package:omnisonic/core/repositories/music_repository.dart';
import 'package:omnisonic/core/utils/id_generator.dart';

/// Simple test script to verify unique ID generation works
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Test ID generation
  print('🧪 Testing ID generation...');
  
  final serverId = '1767560007606';
  final subsonicId = '3jNKy5fB1vQxr39XQn97jr';
  
  final uniqueId = IdGenerator.generateUniqueId(serverId, subsonicId);
  print('✅ Generated unique ID: $uniqueId');
  
  final extractedServerId = IdGenerator.extractServerId(uniqueId);
  final extractedSubsonicId = IdGenerator.extractSubsonicId(uniqueId);
  
  print('🔍 Extracted server ID: $extractedServerId');
  print('🔍 Extracted Subsonic ID: $extractedSubsonicId');
  
  assert(extractedServerId == serverId, 'Server ID extraction failed');
  assert(extractedSubsonicId == subsonicId, 'Subsonic ID extraction failed');
  
  print('✅ ID generation and extraction working correctly!');
  
  // Test with actual repository
  try {
    await configureDependencies();
    final musicRepository = getIt<MusicRepository>();
    
    print('🔍 Testing repository with unique IDs...');
    
    // Test getting all albums
    final albumsResult = await musicRepository.getAllAlbums();
    albumsResult.fold(
      (failure) => print('❌ Failed to get albums: ${failure.message}'),
      (albums) {
        print('📀 Found ${albums.length} albums in database');
        if (albums.isNotEmpty) {
          final firstAlbum = albums.first;
          print('🔍 First album ID: ${firstAlbum.id}');
          print('🔍 Is unique ID: ${IdGenerator.isUniqueId(firstAlbum.id)}');
          
          if (IdGenerator.isUniqueId(firstAlbum.id)) {
            final serverId = IdGenerator.extractServerId(firstAlbum.id);
            final subsonicId = IdGenerator.extractSubsonicId(firstAlbum.id);
            print('🔍 Album server ID: $serverId');
            print('🔍 Album Subsonic ID: $subsonicId');
          }
        }
      },
    );
    
    print('✅ Repository test completed');
  } catch (e) {
    print('❌ Repository test failed: $e');
  }
}