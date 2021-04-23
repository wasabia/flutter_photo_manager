part of '../photo_manager.dart';

/// asset entity, for entity info.
class AssetPathEntity {
  /// Obtained by [AssetPathEntity.id], not recommended
  static Future<AssetPathEntity> fromId(String id,
      {FilterOptionGroup? filterOption}) async {
    filterOption ??= FilterOptionGroup();
    final entity = AssetPathEntity(id: id);
    await entity.refreshPathProperties();
    return entity;
  }

  /// id
  ///
  /// in ios is localIdentifier
  ///
  /// in android is content provider database _id column
  late String id;

  /// name
  ///
  /// in android is path name
  ///
  /// in ios is photos gallery name
  String? name;

  /// gallery asset count
  int? assetCount;

  /// In iOS: 1: album, 2: folder
  ///
  /// In android: always 1.
  late int albumType;

  /// path asset type.
  late RequestType _type;

  FilterOptionGroup? filterOption;

  /// The value used internally by the user.
  /// Used to indicate the value that should be available inside the path.
  RequestType get type => _type;

  set type(RequestType type) {
    _type = type;
    typeInt = type.index;
  }

  /// Users should not edit this value.
  ///
  /// This is a field used internally by the library.
  int get typeInt => type.value;

  /// Users should not edit this value.
  ///
  /// This is a field used internally by the library.
  set typeInt(int typeInt) {
    _type = RequestType(typeInt);
  }

  /// This path is the path that contains all the assets.
  bool isAll = false;

  AssetPathEntity({required this.id, this.name, this.filterOption});

  /// Call this method to update the property
  Future<void> refreshPathProperties({
    FilterOptionGroup? filterOptionGroup,
    bool maxDateTimeToNow = true,
  }) async {
    assert(maxDateTimeToNow != null);

    filterOptionGroup ??= this.filterOption!.copyWith();

    if (maxDateTimeToNow) {
      filterOptionGroup = filterOptionGroup.copyWith(
        createTimeCond: filterOptionGroup.createTimeCond.copyWith(
          max: DateTime.now(),
        ),
        updateTimeCond: filterOptionGroup.updateTimeCond.copyWith(
          max: DateTime.now(),
        ),
      );
    }

    final result = await PhotoManager.fetchPathProperties(
      entity: this,
      filterOptionGroup: filterOptionGroup,
    );
    if (result != null) {
      this.assetCount = result.assetCount;
      this.name = result.name;
      this.isAll = result.isAll;

      this.filterOption = filterOptionGroup;
    }
  }

  /// the image entity list with pagination
  ///
  /// Doesn't support AssetPathEntity with only(Video/Image) flag.
  /// Throws UnsupportedError
  ///
  /// [page] is starting 0.
  ///
  /// [pageSize] is item count of page.
  ///
  Future<List<AssetEntity>> getAssetListPaged(int page, int pageSize) {
    assert(this.albumType == 1, "Just album type can get asset.");
    assert(pageSize > 0, "The pageSize must better than 0.");
    return PhotoManager._getAssetListPaged(this, page, pageSize);
  }

  /// The [start] and [end] like the [String.substring].
  Future<List<AssetEntity>> getAssetListRange({required int start, required int end}) async {
    assert(this.albumType == 1, "Just album type can get asset.");
    assert(start >= 0, "The start must better than 0.");
    assert(end > start, "The end must better than start.");
    return PhotoManager._getAssetWithRange(
        entity: this, start: start, end: end);
  }

  /// all of asset, It is recommended to use the latest api (pagination) [getAssetListPaged].
  Future<List<AssetEntity>> get assetList => getAssetListPaged(0, assetCount!);

  /// In android, always return empty list.
  Future<List<AssetPathEntity>> getSubPathList() async {
    if (!(Platform.isIOS || Platform.isMacOS)) {
      return [];
    }
    return PhotoManager._getSubPath(this);
  }

  @override
  bool operator ==(other) {
    if (other is! AssetPathEntity) {
      return false;
    }
    return this.id == other.id;
  }

  @override
  int get hashCode {
    return this.id.hashCode;
  }

  @override
  String toString() {
    return "AssetPathEntity{ name: $name, id:$id, length = $assetCount }";
  }
}

/// Used to describe a picture or video
class AssetEntity {
  /// Create from [AssetEntity.id], not recommended.
  static Future<AssetEntity?> fromId(String id) async {
    final entity = AssetEntity();
    entity.id = id;
    try {
      final result = await entity.refreshProperties();
      if (result == null) {
        return null;
      }
    } catch (e) {
      return null;
    }
    return entity;
  }

  /// in android is database _id column
  ///
  /// in ios is local id
  String? id;

  /// It is title `MediaStore.MediaColumns.DISPLAY_NAME` in MediaStore on android.
  ///
  /// It is `PHAssetResource.filename` on iOS.
  ///
  /// Nullable in iOS. If you must need it, See [FilterOption.needTitle] or use [titleAsync].
  String? title;

  /// It is [title] in Android.
  ///
  /// It is [PHAsset valueForKey:@"filename"] in iOS.
  Future<String?> get titleAsync => _plugin.getTitleAsync(this);

  /// see [id]
  AssetEntity({this.id});

  /// the asset type
  ///
  /// see [AssetType]
  AssetType get type {
    switch (typeInt) {
      case 1:
        return AssetType.image;
      case 2:
        return AssetType.video;
      case 3:
        return AssetType.audio;
      default:
        return AssetType.other;
    }
  }

  /// Asset type int value.
  ///
  /// see [type]
  late int typeInt;

  /// Duration of video, unit is second.
  ///
  /// If [type] is [AssetType.image], then it's value is 0.
  ///
  /// Also see [videoDuration]
  int? duration;

  /// width of asset.
  late int width;

  /// height of asset.
  late int height;

  /// Gps information when shooting, nullable.
  ///
  /// When the device is android10 or above, always null.
  double? _latitude;

  /// Gps information when shooting, nullable.
  ///
  /// When the device is android10 or above, always null.
  double get latitude => _latitude ?? 0;

  /// Gps information when shooting, nullable.
  ///
  /// When the device is android10 or above, always null.
  set latitude(double latitude) {
    _latitude = latitude;
  }

  /// Gps information when shooting, nullable.
  ///
  /// When the device is android10 or above, always null.
  double? _longitude;

  /// Gps information when shooting, nullable.
  ///
  /// When the device is android10 or above, always null.
  double get longitude => _longitude ?? 0;

  /// Gps information when shooting, nullable.
  ///
  /// When the device is android10 or above, always null.
  set longitude(double longitude) {
    _longitude = longitude;
  }

  /// Get latitude and longitude from MediaStore(android) / Photos(iOS).
  ///
  /// except : In androidQ, the location info come from exif.
  ///
  /// [LatLng.latitude] or [LatLng.longitude] maybe zero or null.
  Future<LatLng> latlngAsync() {
    return _plugin.getLatLngAsync(this);
  }

  /// if you need upload file ,then you can use the file, nullable.
  Future<File?> get file async => PhotoManager._getFileWithId(this.id!);

  /// This contains all the EXIF information, but in contrast, `Image` widget may not be able to display pictures.
  ///
  /// Usually, you can use the [file] attribute
  Future<File?> get originFile async =>
      PhotoManager._getFileWithId(id!, isOrigin: true);

  /// The asset's bytes.
  ///
  /// Use [originBytes]
  ///
  /// The property will be remove in 0.5.0.
  @Deprecated("Use originBytes instead")
  Future<Uint8List?> get fullData => PhotoManager._getFullDataWithId(id!);

  /// The raw data stored in the device, the data may be large.
  ///
  /// This property is not recommended for video types.
  Future<Uint8List?> get originBytes => PhotoManager._getOriginBytes(this);

  /// thumb data , for display
  Future<Uint8List?> get thumbData => thumbDataWithSize(150, 150);

  /// get thumb with size
  Future<Uint8List?> thumbDataWithSize(
    int width,
    int height, {
    ThumbFormat format = ThumbFormat.jpeg,
    int quality = 100,
  }) {
    assert(width > 0 && height > 0, "The width and height must better 0.");
    assert(format != null, "The format must not be null.");
    assert(quality > 0 && quality <= 100, "The quality must between 0 and 100");

    /// Return null if asset is audio or other type, because they don't have such a thing.
    if (type == AssetType.audio || type == AssetType.other) {
      return Future.sync(() => null);
    }

    return thumbDataWithOption(
      ThumbOption(
        width: width,
        height: height,
        format: format,
        quality: quality,
      ),
    );
  }

  /// get thumb with size
  Future<Uint8List?> thumbDataWithOption(
    ThumbOption option,
  ) {
    assert(() {
      option.checkAssert();
      return true;
    }());

    /// Return null if asset is audio or other type, because they don't have such a thing.
    if (type == AssetType.audio || type == AssetType.other) {
      return Future.sync(() => null);
    }

    return PhotoManager._getThumbDataWithOption(
      id!,
      option,
    );
  }

  /// if not video ,duration is null
  Duration get videoDuration => Duration(seconds: duration ?? 0);

  /// nullable, if the manager is null.
  Size get size => Size(width.toDouble(), height.toDouble());

  /// unix timestamp of asset, milliseconds
  int? createDtSecond;

  /// create time of asset
  DateTime get createDateTime {
    final sec = (createDtSecond ?? 0);
    return DateTime.fromMillisecondsSinceEpoch(sec * 1000);
  }

  /// second of modified.
  int? modifiedDateSecond;

  DateTime get modifiedDateTime {
    final sec = modifiedDateSecond ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(sec * 1000);
  }

  /// If the asset is deleted, return false.
  Future<bool?> get exists => PhotoManager._assetExistsWithId(id!);

  /// The url is provided to some video player. Such as [flutter_ijkplayer](https://pub.dev/packages/flutter_ijkplayer)
  ///
  /// It is such as `file:///var/mobile/Media/DCIM/118APPLE/IMG_8371.MOV` in iOS.
  ///
  /// Android: `content://media/external/video/media/894857`
  Future<String?> getMediaUrl() {
    if (type == AssetType.video || type == AssetType.audio) {
      return PhotoManager._getMediaUrl(this);
    }

    return Future.sync(() => null);
  }

  /// Orientation of android MediaStore. See [ORIENTATION](https://developer.android.com/reference/android/provider/MediaStore.MediaColumns#ORIENTATION)
  /// Example values for android: 0 90 180 270
  ///
  /// The value always 0 in iOS.
  late int orientation;

  /// Android does not have this field, so it is always false.
  ///
  /// In iOS, it is consistent with PHAsset.isFavorite. to change it, Use `PhotoManager.editor.iOS.favoriteAsset`, See [IosEditor.favoriteAsset]
  late bool isFavorite;

  /// In iOS, always null.
  ///
  /// In androidQ or higher: it is `MediaStore.MediaColumns.RELATIVE_PATH`.
  ///
  /// API 28 or lower: it is `MediaStore.MediaColumns.DATA` parent path.
  late String relativePath;

  /// refreshProperties
  Future<AssetEntity?> refreshProperties() async {
    return PhotoManager.refreshAssetProperties(this);
  }

  @override
  int get hashCode {
    return id.hashCode;
  }

  @override
  bool operator ==(other) {
    if (other is! AssetEntity) {
      return false;
    }
    return this.id == other.id;
  }

  @override
  String toString() {
    return "AssetEntity{ id:$id , type: $type}";
  }
}

/// Longitude and latitude
class LatLng {
  /// longitude
  late double longitude;

  /// latitude
  late double latitude;
}
