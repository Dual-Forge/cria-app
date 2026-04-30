import 'package:flutter/material.dart';

/// ProfilePhotoWidget
/// 
/// Exibe a foto de perfil do bebê com fallback para ícone padrão.
/// Suporta URLs de rede com tratamento de erro.
class ProfilePhotoWidget extends StatelessWidget {
  /// URL da foto de perfil (nullable)
  final String? photoUrl;

  /// Cor do tema para o ícone fallback
  final Color themeColor;

  /// Tamanho do widget em pixels
  final double size;

  /// Callback opcional quando a imagem carrega com sucesso
  final VoidCallback? onImageLoaded;

  /// Callback opcional quando há erro ao carregar a imagem
  final Function(Object error)? onImageError;

  const ProfilePhotoWidget({
    super.key,
    this.photoUrl,
    required this.themeColor,
    this.size = 130,
    this.onImageLoaded,
    this.onImageError,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: _buildPhotoContent(),
    );
  }

  /// Constrói o conteúdo da foto (imagem ou fallback)
  Widget _buildPhotoContent() {
    // Se não houver URL, mostrar ícone fallback
    if (photoUrl == null || photoUrl!.isEmpty) {
      return _buildFallbackIcon();
    }

    // Tentar carregar a imagem da URL
    return ClipOval(
      child: Image.network(
        photoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            // Imagem carregou com sucesso
            onImageLoaded?.call();
            return child;
          }

          // Mostrar indicador de carregamento
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // Erro ao carregar a imagem
          onImageError?.call(error);
          return _buildFallbackIcon();
        },
      ),
    );
  }

  /// Constrói o ícone fallback quando não há foto
  Widget _buildFallbackIcon() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: themeColor.withOpacity(0.1),
      ),
      child: Center(
        child: Icon(
          Icons.child_care_rounded,
          color: themeColor,
          size: size * 0.4,
        ),
      ),
    );
  }
}

/// ProfilePhotoWithBorderWidget
/// 
/// Versão estendida do ProfilePhotoWidget com borda customizável.
class ProfilePhotoWithBorderWidget extends StatelessWidget {
  /// URL da foto de perfil (nullable)
  final String? photoUrl;

  /// Cor do tema para o ícone fallback
  final Color themeColor;

  /// Tamanho do widget em pixels
  final double size;

  /// Cor da borda
  final Color borderColor;

  /// Largura da borda em pixels
  final double borderWidth;

  /// Callback opcional quando a imagem carrega com sucesso
  final VoidCallback? onImageLoaded;

  /// Callback opcional quando há erro ao carregar a imagem
  final Function(Object error)? onImageError;

  const ProfilePhotoWithBorderWidget({
    super.key,
    this.photoUrl,
    required this.themeColor,
    this.size = 130,
    this.borderColor = Colors.white,
    this.borderWidth = 3,
    this.onImageLoaded,
    this.onImageError,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: ProfilePhotoWidget(
        photoUrl: photoUrl,
        themeColor: themeColor,
        size: size - (borderWidth * 2),
        onImageLoaded: onImageLoaded,
        onImageError: onImageError,
      ),
    );
  }
}

/// ProfilePhotoCircleAvatarWidget
/// 
/// Versão usando CircleAvatar para melhor integração com Material Design.
class ProfilePhotoCircleAvatarWidget extends StatelessWidget {
  /// URL da foto de perfil (nullable)
  final String? photoUrl;

  /// Cor do tema para o ícone fallback
  final Color themeColor;

  /// Raio do avatar em pixels
  final double radius;

  /// Callback opcional quando a imagem carrega com sucesso
  final VoidCallback? onImageLoaded;

  /// Callback opcional quando há erro ao carregar a imagem
  final Function(Object error)? onImageError;

  const ProfilePhotoCircleAvatarWidget({
    super.key,
    this.photoUrl,
    required this.themeColor,
    this.radius = 65,
    this.onImageLoaded,
    this.onImageError,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: themeColor.withOpacity(0.1),
      child: _buildPhotoContent(),
    );
  }

  /// Constrói o conteúdo da foto (imagem ou fallback)
  Widget _buildPhotoContent() {
    // Se não houver URL, mostrar ícone fallback
    if (photoUrl == null || photoUrl!.isEmpty) {
      return Icon(
        Icons.child_care_rounded,
        color: themeColor,
        size: radius * 0.6,
      );
    }

    // Tentar carregar a imagem da URL
    return ClipOval(
      child: Image.network(
        photoUrl!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            // Imagem carregou com sucesso
            onImageLoaded?.call();
            return child;
          }

          // Mostrar indicador de carregamento
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: AlwaysStoppedAnimation<Color>(themeColor),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // Erro ao carregar a imagem
          onImageError?.call(error);
          return Icon(
            Icons.child_care_rounded,
            color: themeColor,
            size: radius * 0.6,
          );
        },
      ),
    );
  }
}
