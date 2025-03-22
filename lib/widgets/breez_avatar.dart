import 'dart:io';
import 'dart:typed_data';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/theme/theme.dart';

class BreezAvatar extends StatelessWidget {
  final String? avatarURL;
  final double radius;
  final Color? backgroundColor;
  final bool isPreview;

  const BreezAvatar(
    this.avatarURL, {
    super.key,
    this.radius = 20.0,
    this.backgroundColor,
    this.isPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color avatarBgColor = backgroundColor ?? sessionAvatarBackgroundColor;

    if ((avatarURL ?? '').isNotEmpty) {
      if (avatarURL!.startsWith('breez://profile_image?')) {
        final Map<String, String> queryParams = Uri.parse(avatarURL!).queryParameters;
        return _GeneratedAvatar(radius, queryParams['animal'], queryParams['color'], avatarBgColor);
      }

      if (Uri.tryParse(avatarURL!)?.scheme.startsWith('http') ?? false) {
        return _NetworkImageAvatar(avatarURL!, radius);
      }

      if (Uri.tryParse(avatarURL!)?.scheme.startsWith('data') ?? false) {
        return _DataImageAvatar(avatarURL!, radius);
      }

      return _FileImageAvatar(radius, avatarURL!, isPreview: isPreview);
    }

    return _UnknownAvatar(radius, avatarBgColor);
  }
}

class _UnknownAvatar extends StatelessWidget {
  final double radius;
  final Color backgroundColor;

  const _UnknownAvatar(this.radius, this.backgroundColor);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: backgroundColor,
      radius: radius,
      child: SvgPicture.asset(
        'assets/icons/alien.svg',
        colorFilter: const ColorFilter.mode(
          Color.fromARGB(255, 0, 166, 68),
          BlendMode.srcATop,
        ),
        width: 0.70 * radius * 2,
        height: 0.70 * radius * 2,
      ),
    );
  }
}

class _GeneratedAvatar extends StatelessWidget {
  final double radius;
  final String? animal;
  final String? color;
  final Color backgroundColor;

  const _GeneratedAvatar(this.radius, this.animal, this.color, this.backgroundColor);

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    return CircleAvatar(
      radius: radius,
      backgroundColor: sessionAvatarBackgroundColor,
      child: Icon(
        profileAnimalFromName(animal, texts)!.iconData,
        size: radius * 2 * 0.75,
        color: profileColorFromName(color, texts)!.color,
      ),
    );
  }
}

class _FileImageAvatar extends StatelessWidget {
  final double radius;
  final String filePath;
  final bool isPreview;

  const _FileImageAvatar(this.radius, this.filePath, {this.isPreview = false});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: isPreview
            ? Image.file(File(filePath))
            : FutureBuilder<File?>(
                future: UserProfileImageCache().getProfileImageFile(fileName: filePath),
                builder: (BuildContext context, AsyncSnapshot<File?> snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Image.file(snapshot.data!);
                  }
                  return const SizedBox.shrink();
                },
              ),
      ),
    );
  }
}

class _NetworkImageAvatar extends StatelessWidget {
  final double radius;
  final String avatarURL;

  const _NetworkImageAvatar(this.avatarURL, this.radius);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: ExtendedImage.network(avatarURL),
      ),
    );
  }
}

class _DataImageAvatar extends StatelessWidget {
  final double radius;
  final String avatarURL;

  const _DataImageAvatar(this.avatarURL, this.radius);

  @override
  Widget build(BuildContext context) {
    final UriData uri = UriData.parse(avatarURL);
    final Uint8List bytes = uri.contentAsBytes();
    return CircleAvatar(
      backgroundColor: sessionAvatarBackgroundColor,
      radius: radius,
      child: ClipOval(
        child: Image.memory(bytes),
      ),
    );
  }
}
