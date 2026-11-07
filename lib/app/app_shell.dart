import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design_system/design_system.dart';
import '../features/account/presentation/eliminar_cuenta_dialog.dart';
import '../features/auth/presentation/auth_controllers.dart';
import 'routes.dart';

/// Shell de navegación principal (Opción B):
/// Inicio · Deudas · Plan · Presupuesto · Más.
class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  static const List<NeoBottomDestination> _destinations =
      <NeoBottomDestination>[
        NeoBottomDestination(
          label: 'Inicio',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
        ),
        NeoBottomDestination(
          label: 'Deudas',
          icon: Icons.account_balance_wallet_outlined,
          selectedIcon: Icons.account_balance_wallet,
        ),
        NeoBottomDestination(
          label: 'Plan',
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month,
        ),
        NeoBottomDestination(
          label: 'Presupuesto',
          icon: Icons.pie_chart_outline,
          selectedIcon: Icons.pie_chart,
        ),
        NeoBottomDestination(
          label: 'Más',
          icon: Icons.grid_view_outlined,
          selectedIcon: Icons.grid_view,
        ),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NeoScaffold(
      body: child,
      bottomNavigationBar: NeoBottomNav(
        destinations: _destinations,
        selectedIndex: _indicePara(location),
        onSelected: (int index) {
          if (index == _destinations.length - 1) {
            _abrirMas(context, ref);
            return;
          }
          const List<String> rutas = <String>[
            AppRoutes.home,
            AppRoutes.deudas,
            AppRoutes.plan,
            AppRoutes.presupuestoConfiguracion,
          ];
          GoRouter.of(context).go(rutas[index]);
        },
      ),
    );
  }

  int _indicePara(String location) {
    if (location.startsWith(AppRoutes.deudas)) {
      return 1;
    }
    if (location.startsWith(AppRoutes.plan)) {
      return 2;
    }
    if (location.startsWith(AppRoutes.presupuestoConfiguracion)) {
      return 3;
    }
    return 0;
  }

  Future<void> _abrirMas(BuildContext context, WidgetRef ref) {
    return NeoMoreMenu.show(
      context,
      options: <NeoMoreOption>[
        NeoMoreOption(
          label: 'Metas',
          icon: Icons.savings_outlined,
          onTap: () => GoRouter.of(context).push(AppRoutes.metas),
        ),
        NeoMoreOption(
          label: 'Analítica',
          icon: Icons.insights_outlined,
          onTap: () => GoRouter.of(context).push(AppRoutes.analitica),
        ),
        NeoMoreOption(
          label: 'Reportes',
          icon: Icons.file_download_outlined,
          onTap: () => GoRouter.of(context).push(AppRoutes.reportes),
        ),
        NeoMoreOption(
          label: 'Cambiar contraseña',
          icon: Icons.lock_outline,
          showDividerBefore: true,
          onTap: () => GoRouter.of(context).push(AppRoutes.cambiarContrasena),
        ),
        NeoMoreOption(
          label: 'Términos y privacidad',
          icon: Icons.description_outlined,
          onTap: () => GoRouter.of(context).push(AppRoutes.legales),
        ),
        NeoMoreOption(
          label: 'Eliminar cuenta',
          icon: Icons.person_remove_outlined,
          onTap: () => EliminarCuentaDialog.show(context),
        ),
        NeoMoreOption(
          label: 'Cerrar sesión',
          icon: Icons.logout,
          onTap: () => ref.read(authSessionProvider.notifier).logout(),
        ),
        if (kDebugMode)
          NeoMoreOption(
            label: 'Design System',
            icon: Icons.palette_outlined,
            showDividerBefore: true,
            onTap: () => GoRouter.of(context).push(AppRoutes.designSystem),
          ),
      ],
    );
  }
}
