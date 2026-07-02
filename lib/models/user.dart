import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String employeeId;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? gender;
  final String? dateOfBirth;
  final String? photo;
  final String employmentType;
  final String employmentStatus;
  final String hireDate;
  final Department? department;
  final Position? position;
  final Branch? branch;
  final Company? company;

  const User({
    required this.id,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.gender,
    this.dateOfBirth,
    this.photo,
    required this.employmentType,
    required this.employmentStatus,
    required this.hireDate,
    this.department,
    this.position,
    this.branch,
    this.company,
  });

  String get fullName => '$firstName $lastName';

  String get initials => '${firstName[0]}${lastName[0]}'.toUpperCase();

  @override
  List<Object?> get props => [id, employeeId, firstName, lastName];
}

class Department extends Equatable {
  final int id;
  final String name;
  final String? code;

  const Department({required this.id, required this.name, this.code});

  @override
  List<Object?> get props => [id, name];
}

class Position extends Equatable {
  final int id;
  final String name;
  final String? code;
  final String? level;

  const Position({required this.id, required this.name, this.code, this.level});

  @override
  List<Object?> get props => [id, name];
}

class Branch extends Equatable {
  final int id;
  final String name;
  final String? code;
  final String? address;

  const Branch({required this.id, required this.name, this.code, this.address});

  @override
  List<Object?> get props => [id, name];
}

class Company extends Equatable {
  final int id;
  final String name;
  final String? logo;
  final String? slug;

  const Company({required this.id, required this.name, this.logo, this.slug});

  @override
  List<Object?> get props => [id, name];
}

class Team extends Equatable {
  final int id;
  final String name;
  final String? code;

  const Team({required this.id, required this.name, this.code});

  @override
  List<Object?> get props => [id, name];
}