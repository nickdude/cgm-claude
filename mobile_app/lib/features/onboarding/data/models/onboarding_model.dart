class OnboardingModel {
  final int age;

  final String gender;

  final String diabetesType;

  final double height;

  final double weight;

  final bool insulinUsage;

  final int diagnosedYear;

  final String activityLevel;

  OnboardingModel({
    required this.age,
    required this.gender,
    required this.diabetesType,
    required this.height,
    required this.weight,
    required this.insulinUsage,
    required this.diagnosedYear,
    required this.activityLevel,
  });

  factory OnboardingModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return OnboardingModel(
      age: json["age"],

      gender: json["gender"],

      diabetesType:
          json["diabetesType"],

      height:
          json["height"].toDouble(),

      weight:
          json["weight"].toDouble(),

      insulinUsage:
          json["insulinUsage"],

      diagnosedYear:
          json["diagnosedYear"],

      activityLevel:
          json["activityLevel"],
    );
  }
}