enum AppMode { balance, apps }

class UserProfileSettings {
  final String? name;
  final String? color;
  final String? animal;
  final String? image;
  final bool hideBalance;
  final AppMode appMode;
  final bool expandPreferences;

  const UserProfileSettings._({
    this.name,
    this.color,
    this.animal,
    this.image,
    this.hideBalance = false,
    this.appMode = AppMode.balance,
    this.expandPreferences = true,
  });

  UserProfileSettings.initial() : this._();

  UserProfileSettings copyWith({
    String? name,
    String? color,
    String? animal,
    String? image,
    bool? hideBalance,
    AppMode? appMode,
    bool? expandPreferences,
  }) {
    return UserProfileSettings._(
      name: name ?? this.name,
      color: color ?? this.color,
      animal: animal ?? this.animal,
      image: image ?? this.image,
      hideBalance: hideBalance ?? this.hideBalance,
      appMode: appMode ?? this.appMode,
      expandPreferences: expandPreferences ?? this.expandPreferences,
    );
  }

  String? get avatarURL =>
      image ?? (animal != null && color != null ? 'breez://profile_image?animal=$animal&color=$color' : null);

  UserProfileSettings.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String?,
        color = json['color'] as String?,
        animal = json['animal'] as String?,
        image = json['image'] as String?,
        hideBalance = json['hideBalance'] as bool? ?? false,
        appMode = json['appMode'] != null ? AppMode.values[json['appMode'] as int] : AppMode.balance,
        expandPreferences = json['expandPreferences'] as bool? ?? true;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'color': color,
        'animal': animal,
        'image': image,
        'hideBalance': hideBalance,
        'appMode': appMode.index,
        'expandPreferences': expandPreferences,
      };
}
