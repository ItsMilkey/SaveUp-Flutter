import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../domain/categoria.dart';

/// Icono Material asociado a una categoría.
///
/// El backend expone `iconId` (por ejemplo `ic_fastfood`) y el contrato
/// recomienda usar `codigo` como clave estable. Se intenta primero el icono
/// del catálogo y, si no está mapeado, se cae al código.
IconData iconoDeCategoria(Categoria categoria) {
  return _iconosPorId[categoria.iconId] ??
      _iconosPorCodigo[categoria.codigo] ??
      Icons.category_outlined;
}

IconData iconoDeCategoriaPorCodigo(String? codigo) {
  return _iconosPorCodigo[codigo] ?? Icons.category_outlined;
}

/// Color del catálogo para la categoría (con respaldo del sistema).
Color colorDeCategoria(Categoria categoria) {
  return _parseHex(categoria.colorHex) ?? AppColors.lavender;
}

Color? _parseHex(String? hex) {
  if (hex == null) {
    return null;
  }
  final String cleaned = hex.replaceFirst('#', '');
  if (cleaned.length != 6) {
    return null;
  }
  final int? value = int.tryParse(cleaned, radix: 16);
  if (value == null) {
    return null;
  }
  return Color(0xFF000000 | value);
}

/// Ficha cuadrada con el color de la categoría y su icono.
class IconoCategoria extends StatelessWidget {
  const IconoCategoria({
    super.key,
    required this.categoria,
    this.size = 30,
  });

  final Categoria categoria;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorDeCategoria(categoria),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: AppColors.ink,
          width: AppBorders.thin,
        ),
      ),
      child: Icon(
        iconoDeCategoria(categoria),
        size: size * 0.55,
        color: AppColors.ink,
      ),
    );
  }
}

const Map<String, IconData> _iconosPorId = <String, IconData>{
  'ic_work': Icons.work_outline,
  'ic_fastfood': Icons.fastfood,
  'ic_directions_car': Icons.directions_car,
  'ic_receipt_long': Icons.receipt_long,
  'ic_sports_esports': Icons.sports_esports,
  'ic_medical_services': Icons.medical_services,
  'ic_checkroom': Icons.checkroom,
  'ic_payment': Icons.payment,
  'ic_savings': Icons.savings,
  'ic_label': Icons.label_outline,
  'ic_school': Icons.school,
  'ic_policy': Icons.policy,
  'ic_pets': Icons.pets,
  'ic_cleaning_services': Icons.cleaning_services,
  'ic_devices': Icons.devices,
  'ic_subscriptions': Icons.subscriptions,
  'ic_restaurant': Icons.restaurant,
  'ic_card_giftcard': Icons.card_giftcard,
};

const Map<String, IconData> _iconosPorCodigo = <String, IconData>{
  'SUELDO': Icons.work_outline,
  'ALIMENTACION_BASE': Icons.fastfood,
  'TRANSPORTE_MOVILIDAD': Icons.directions_car,
  'VIVIENDA_SUMINISTROS': Icons.receipt_long,
  'OCIO_RECREACION': Icons.sports_esports,
  'SALUD_BIENESTAR': Icons.medical_services,
  'CUIDADO_PERSONAL_VESTUARIO': Icons.checkroom,
  'DEUDAS': Icons.payment,
  'AHORRO': Icons.savings,
  'OTROS': Icons.label_outline,
  'EDUCACION_FORMACION': Icons.school,
  'SEGUROS_IMPUESTOS': Icons.policy,
  'MASCOTAS': Icons.pets,
  'HOGAR_CONSUMIBLES': Icons.cleaning_services,
  'EQUIPAMIENTO_TECNOLOGIA': Icons.devices,
  'SUSCRIPCIONES_DIGITAL': Icons.subscriptions,
  'RESTAURANTES_SALIDAS': Icons.restaurant,
  'REGALOS_CELEBRACIONES': Icons.card_giftcard,
};
