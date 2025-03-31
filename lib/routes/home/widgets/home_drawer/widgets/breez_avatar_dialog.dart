import 'dart:async';
import 'dart:typed_data';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as dart_image;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/utils/a11y/min_font_size.dart';
import 'package:misty_breez/widgets/widgets.dart';

final Logger _logger = Logger('BreezAvatarDialog');

class BreezAvatarDialog extends StatefulWidget {
  const BreezAvatarDialog({super.key});

  @override
  BreezAvatarDialogState createState() => BreezAvatarDialogState();
}

class BreezAvatarDialogState extends State<BreezAvatarDialog> {
  late UserProfileCubit userProfileCubit;
  final TextEditingController nameInputController = TextEditingController();
  final AutoSizeGroup autoSizeGroup = AutoSizeGroup();
  CroppedFile? pickedImage;
  String? randomAvatarPath;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    userProfileCubit = context.read<UserProfileCubit>();
    nameInputController.text = userProfileCubit.state.profileSettings.name ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isUploading,
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          final BreezTranslations texts = context.texts();
          final ThemeData themeData = Theme.of(context);
          final NavigatorState navigator = Navigator.of(context);
          final MediaQueryData queryData = MediaQuery.of(context);

          return SimpleDialog(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
            title: Stack(
              children: <Widget>[
                const TitleBackground(),
                SizedBox(
                  width: queryData.size.width,
                  height: 100.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      RandomButton(onPressed: generateRandomProfile),
                      AvatarPreview(
                        isUploading: isUploading,
                        pickedImage: pickedImage,
                        randomAvatarPath: randomAvatarPath,
                      ),
                      GalleryButton(onPressed: pickImageFromGallery),
                    ],
                  ),
                ),
              ],
            ),
            titlePadding: const EdgeInsets.all(0.0),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(12.0),
                top: Radius.circular(13.0),
              ),
            ),
            children: <Widget>[
              SingleChildScrollView(
                child: Theme(
                  data: ThemeData(
                    primaryColor: themeData.primaryTextTheme.bodyMedium!.color,
                    hintColor: themeData.primaryTextTheme.bodyMedium!.color,
                  ),
                  child: TextField(
                    enabled: !isUploading,
                    style: themeData.primaryTextTheme.bodyMedium,
                    controller: nameInputController,
                    decoration: InputDecoration(
                      hintText: texts.breez_avatar_dialog_your_name,
                    ),
                    onSubmitted: (String text) {},
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    TextButton(
                      onPressed: isUploading ? null : () => navigator.pop(),
                      child: Text(
                        texts.breez_avatar_dialog_action_cancel,
                        style: themeData.primaryTextTheme.labelLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: isUploading
                          ? null
                          : () async {
                              await saveAvatarChanges();
                            },
                      child: Text(
                        texts.breez_avatar_dialog_action_save,
                        style: themeData.primaryTextTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> saveAvatarChanges() async {
    _logger.info('saveAvatarChanges');
    final NavigatorState navigator = Navigator.of(context);
    final BreezTranslations texts = context.texts();
    try {
      setState(() {
        isUploading = true;
      });
      final String? userName = nameInputController.text.isNotEmpty
          ? nameInputController.text
          : userProfileCubit.state.profileSettings.name;
      userProfileCubit.updateProfileSettings(name: userName);
      await saveProfileImage();
      setState(() {
        isUploading = false;
      });
      navigator.pop();
    } catch (e) {
      userProfileCubit.updateProfileSettings(name: userProfileCubit.state.profileSettings.name);
      setState(() {
        isUploading = false;
        pickedImage = null;
      });
      if (!mounted) {
        return;
      }
      showFlushbar(
        context,
        message: texts.breez_avatar_dialog_error_upload,
      );
    }
  }

  void generateRandomProfile() {
    _logger.info('generateRandomProfile');
    final DefaultProfile randomUser = generateDefaultProfile();
    setState(() {
      nameInputController.text = '${randomUser.color} ${randomUser.animal}';
      randomAvatarPath = 'breez://profile_image?animal=${randomUser.animal}&color=${randomUser.color}';
      pickedImage = null;
    });
    // Close keyboard
    FocusScope.of(context).unfocus();
  }

  void pickImageFromGallery() {
    _logger.info('pickImageFromGallery');
    ImagePicker().pickImage(source: ImageSource.gallery).then(
      (XFile? pickedFile) {
        final String? pickedFilePath = pickedFile?.path;
        _logger.info('pickedFile $pickedFilePath');
        if (pickedFilePath != null) {
          ImageCropper().cropImage(
            sourcePath: pickedFilePath,
            aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
            uiSettings: <PlatformUiSettings>[
              AndroidUiSettings(
                cropStyle: CropStyle.circle,
                aspectRatioPresets: <CropAspectRatioPresetData>[CropAspectRatioPreset.square],
              ),
              IOSUiSettings(
                cropStyle: CropStyle.circle,
                aspectRatioPresets: <CropAspectRatioPresetData>[CropAspectRatioPreset.square],
              ),
            ],
          ).then(
            (CroppedFile? croppedFile) {
              _logger.info('croppedFile ${croppedFile?.path}');
              if (croppedFile != null) {
                setState(() {
                  pickedImage = croppedFile;
                  randomAvatarPath = null;
                });
              }
            },
            onError: (Object error) {
              _logger.severe('Failed to crop image', error);
            },
          );
        }
      },
      onError: (Object error) {
        _logger.severe('Failed to pick image', error);
      },
    );
  }

  Future<void> saveProfileImage() async {
    _logger.info('saveProfileImage ${pickedImage?.path} $randomAvatarPath');
    if (pickedImage != null) {
      final String profileImageFilePath = await userProfileCubit.saveProfileImage(await scaleAndFormatPNG());
      userProfileCubit.updateProfileSettings(image: profileImageFilePath);
    } else if (randomAvatarPath != null) {
      userProfileCubit.updateProfileSettings(image: randomAvatarPath);
    }
  }

  Future<Uint8List> scaleAndFormatPNG() async {
    _logger.info('scaleAndFormatPNG');
    const int scaledSize = 200;
    try {
      final dart_image.Image? image = dart_image.decodeImage(await pickedImage!.readAsBytes());
      final dart_image.Image resized = dart_image.copyResize(
        image!,
        width: image.width < image.height ? -1 : scaledSize,
        height: image.width < image.height ? scaledSize : -1,
      );
      return dart_image.encodePng(resized);
    } catch (e) {
      rethrow;
    }
  }
}

class TitleBackground extends StatelessWidget {
  const TitleBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    return Container(
      height: 70.0,
      decoration: ShapeDecoration(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(12.0),
          ),
        ),
        color: themeData.isLightTheme ? themeData.primaryColorDark : themeData.canvasColor,
      ),
    );
  }
}

class RandomButton extends StatelessWidget {
  final Function() onPressed;
  final AutoSizeGroup? autoSizeGroup;

  const RandomButton({required this.onPressed, super.key, this.autoSizeGroup});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final MinFontSize minFontSize = MinFontSize(context);

    return Expanded(
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.only(
            bottom: 20.0,
            top: 26.0,
          ),
        ),
        onPressed: onPressed,
        child: AutoSizeText(
          texts.breez_avatar_dialog_random,
          style: whiteButtonStyle,
          maxLines: 1,
          minFontSize: minFontSize.minFontSize,
          stepGranularity: 0.1,
          group: autoSizeGroup,
        ),
      ),
    );
  }
}

class AvatarPreview extends StatelessWidget {
  final CroppedFile? pickedImage;
  final String? randomAvatarPath;
  final bool isUploading;

  const AvatarPreview({
    required this.pickedImage,
    required this.randomAvatarPath,
    required this.isUploading,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserProfileCubit, UserProfileState>(
      builder: (BuildContext context, UserProfileState userModel) {
        return Stack(
          children: <Widget>[
            if (isUploading) ...<Widget>[
              const AvatarSpinner(),
            ],
            Padding(
              padding: const EdgeInsets.only(top: 26.0),
              child: AspectRatio(
                aspectRatio: 1,
                child: BreezAvatar(
                  pickedImage?.path ?? randomAvatarPath ?? userModel.profileSettings.avatarURL,
                  radius: 36.0,
                  isPreview: pickedImage != null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class AvatarSpinner extends StatelessWidget {
  const AvatarSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 26.0),
      child: AspectRatio(
        aspectRatio: 1,
        child: CircularProgressIndicator(
          valueColor: const AlwaysStoppedAnimation<Color>(
            Colors.white,
          ),
          backgroundColor: themeData.isLightTheme ? themeData.primaryColorDark : themeData.canvasColor,
        ),
      ),
    );
  }
}

class GalleryButton extends StatelessWidget {
  final Function() onPressed;
  final AutoSizeGroup? autoSizeGroup;

  const GalleryButton({required this.onPressed, super.key, this.autoSizeGroup});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final MinFontSize minFontSize = MinFontSize(context);

    return Expanded(
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.only(
            bottom: 20.0,
            top: 26.0,
          ),
        ),
        onPressed: onPressed,
        child: AutoSizeText(
          texts.breez_avatar_dialog_gallery,
          style: whiteButtonStyle,
          maxLines: 1,
          minFontSize: minFontSize.minFontSize,
          stepGranularity: 0.1,
          group: autoSizeGroup,
        ),
      ),
    );
  }
}
