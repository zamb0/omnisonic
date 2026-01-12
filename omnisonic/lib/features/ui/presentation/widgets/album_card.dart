import 'package:flutter/material.dart';

import '../../../../core/entities/album.dart';
import '../../../../core/design_system/enhanced_cards.dart';

/// A card widget for displaying album information in a grid or list
/// Now uses the enhanced card system for better visual appeal and animations
class AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? width;
  final bool showArtist;
  final bool isSelected;
  final CardLayout layout;

  const AlbumCard({
    super.key,
    required this.album,
    this.onTap,
    this.onLongPress,
    this.width,
    this.showArtist = true,
    this.isSelected = false,
    this.layout = CardLayout.grid,
  });

  @override
  Widget build(BuildContext context) {
    // Use the enhanced album card with all the new features
    return EnhancedAlbumCard(
      album: album,
      onTap: onTap,
      onLongPress: onLongPress,
      width: width,
      showArtist: showArtist,
      isSelected: isSelected,
      layout: layout,
    );
  }
}