import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as dart_image;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/theme/theme_provider.dart' as theme;
import 'package:l_breez/utils/min_font_size.dart';
import 'package:l_breez/widgets/breez_avatar.dart';
import 'package:l_breez/widgets/flushbar.dart';
import 'package:logging/logging.dart';

final _log = Logger("BreezAvatarDialog");

class BreezAvatarDialog extends StatefulWidget {
  const BreezAvatarDialog({super.key});

  @override
  BreezAvatarDialogState createState() => BreezAvatarDialogState();
}

class BreezAvatarDialogState extends State<BreezAvatarDialog> {
  late UserProfileCubit userProfileCubit;
  final nameInputController = TextEditingController();
  final AutoSizeGroup autoSizeGroup = AutoSizeGroup();
  CroppedFile? pickedImage;
  String? randomAvatarPath;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    userProfileCubit = context.read<UserProfileCubit>();
    nameInputController.text = userProfileCubit.state.profileSettings.name ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isUploading,
      child: StatefulBuilder(
        builder: (context, setState) {
          final texts = context.texts();
          final themeData = Theme.of(context);
          final navigator = Navigator.of(context);
          final queryData = MediaQuery.of(context);

          return SimpleDialog(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
            title: Stack(
              children: [
                const TitleBackground(),
                SizedBox(
                  width: queryData.size.width,
                  height: 100.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                    onSubmitted: (text) {},
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
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
    _log.fine("saveAvatarChanges");
    final navigator = Navigator.of(context);
    final texts = context.texts();
    try {
      setState(() {
        isUploading = true;
      });
      await Future.delayed(const Duration(seconds: 15));
      var userName = nameInputController.text.isNotEmpty
          ? nameInputController.text
          : userProfileCubit.state.profileSettings.name;
      userProfileCubit.updateProfile(name: userName);
      await uploadAvatar();
      setState(() {
        isUploading = false;
      });
      navigator.pop();
    } catch (e) {
      setState(() {
        isUploading = false;
        pickedImage = null;
      });
      if (!mounted) return;
      showFlushbar(
        context,
        message: texts.breez_avatar_dialog_error_upload,
      );
    }
  }

  void generateRandomProfile() {
    _log.fine("generateRandomProfile");
    final DefaultProfile randomUser = generateDefaultProfile();
    setState(() {
      nameInputController.text = "${randomUser.color} ${randomUser.animal}";
      randomAvatarPath = 'breez://profile_image?animal=${randomUser.animal}&color=${randomUser.color}';
      pickedImage = null;
    });
    // Close keyboard
    FocusScope.of(context).unfocus();
  }

  pickImageFromGallery() async {
    _log.fine("pickImageFromGallery");
    ImagePicker().pickImage(source: ImageSource.gallery).then((pickedFile) {
      final pickedFilePath = pickedFile?.path;
      _log.fine("pickedFile $pickedFilePath");
      if (pickedFilePath != null) {
        ImageCropper().cropImage(
          sourcePath: pickedFilePath,
          uiSettings: [
            AndroidUiSettings(
              cropStyle: CropStyle.circle,
              aspectRatioPresets: [CropAspectRatioPreset.square],
            ),
            IOSUiSettings(
              cropStyle: CropStyle.circle,
              aspectRatioPresets: [CropAspectRatioPreset.square],
            )
          ],
        ).then((croppedFile) {
          _log.info("croppedFile ${croppedFile?.path}");
          if (croppedFile != null) {
            setState(() {
              pickedImage = croppedFile;
              randomAvatarPath = null;
            });
          }
        }, onError: (error) {
          _log.severe("Failed to crop image", error);
        });
      }
    }, onError: (error) {
      _log.severe("Failed to pick image", error);
    });
  }

  Future<void> uploadAvatar() async {
    _log.fine("uploadAvatar ${pickedImage?.path} $randomAvatarPath");
    if (pickedImage != null) {
      String imageUrl = await userProfileCubit.uploadImage(await scaleAndFormatPNG());
      userProfileCubit.updateProfile(image: imageUrl);
    } else if (randomAvatarPath != null) {
      userProfileCubit.updateProfile(image: randomAvatarPath);
    }
  }

  Future<List<int>> scaleAndFormatPNG() async {
    _log.fine("scaleAndFormatPNG");
    const int scaledSize = 200;
    try {
      final image = dart_image.decodeImage(await pickedImage!.readAsBytes());
      final resized = dart_image.copyResize(
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
    final themeData = Theme.of(context);
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

  const RandomButton({super.key, required this.onPressed, this.autoSizeGroup});

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final minFontSize = MinFontSize(context);

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
          style: theme.whiteButtonStyle,
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
    super.key,
    required this.pickedImage,
    required this.randomAvatarPath,
    required this.isUploading,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserProfileCubit, UserProfileState>(
      builder: (context, userModel) {
        return Stack(
          children: [
            if (isUploading) ...[
              const AvatarSpinner(),
            ],
            Padding(
              padding: const EdgeInsets.only(top: 26.0),
              child: AspectRatio(
                aspectRatio: 1,
                child: BreezAvatar(
                  pickedImage?.path ?? randomAvatarPath ?? userModel.profileSettings.avatarURL,
                  radius: 36.0,
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
    final themeData = Theme.of(context);
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

  const GalleryButton({super.key, required this.onPressed, this.autoSizeGroup});

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final minFontSize = MinFontSize(context);

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
          style: theme.whiteButtonStyle,
          maxLines: 1,
          minFontSize: minFontSize.minFontSize,
          stepGranularity: 0.1,
          group: autoSizeGroup,
        ),
      ),
    );
  }
}
