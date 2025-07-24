class SoilData {
  final String title;
  final String soilType;
  final String? soilImage;
  final String soilIcon;
  final List<CropData> crops;

  SoilData({
    required this.title,
    required this.soilType,
    this.soilImage,
    required this.soilIcon,
    required this.crops,
  });
}

class CropData {
  final String icon;
  final String name;

  CropData({
    required this.icon,
    required this.name,
  });
}