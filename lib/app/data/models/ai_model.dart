import 'package:flutter/material.dart';

enum ModelStatus { available, downloading, downloaded }

enum ModelReadiness { phoneReady, heavyMemory }

class AIModel {
  final String id;
  final String name;
  final String description;
  final String version;
  final String size;
  final String quantization;
  final ModelStatus status;
  final ModelReadiness readiness;
  final double downloadProgress;
  final Color iconBackgroundColor;
  final Color iconColor;
  final IconData icon;
  final bool isFeatured;
  final String? params;
  final String? inferenceSpeed;
  final String? imageUrl;

  AIModel({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.size,
    required this.quantization,
    this.status = ModelStatus.available,
    this.readiness = ModelReadiness.phoneReady,
    this.downloadProgress = 0.0,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.icon,
    this.isFeatured = false,
    this.params,
    this.inferenceSpeed,
    this.imageUrl,
  });

  AIModel copyWith({
    String? id,
    String? name,
    String? description,
    String? version,
    String? size,
    String? quantization,
    ModelStatus? status,
    ModelReadiness? readiness,
    double? downloadProgress,
    Color? iconBackgroundColor,
    Color? iconColor,
    IconData? icon,
    bool? isFeatured,
    String? params,
    String? inferenceSpeed,
    String? imageUrl,
  }) {
    return AIModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      size: size ?? this.size,
      quantization: quantization ?? this.quantization,
      status: status ?? this.status,
      readiness: readiness ?? this.readiness,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      iconBackgroundColor: iconBackgroundColor ?? this.iconBackgroundColor,
      iconColor: iconColor ?? this.iconColor,
      icon: icon ?? this.icon,
      isFeatured: isFeatured ?? this.isFeatured,
      params: params ?? this.params,
      inferenceSpeed: inferenceSpeed ?? this.inferenceSpeed,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class FilterCategory {
  final String id;
  final String name;
  final IconData? icon;
  final Color? iconColor;
  final bool isSelected;

  FilterCategory({
    required this.id,
    required this.name,
    this.icon,
    this.iconColor,
    this.isSelected = false,
  });

  FilterCategory copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? iconColor,
    bool? isSelected,
  }) {
    return FilterCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}


