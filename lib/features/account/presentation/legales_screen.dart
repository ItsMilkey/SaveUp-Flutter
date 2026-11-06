import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_version/presentation/app_version_controller.dart';
import '../domain/legal_documents.dart';

/// Visor de documentos legales: Términos y Condiciones y Política de
/// Privacidad, con las versiones vigentes que `GET /app/version` entregó a
/// F1 (vía [legalVersionsProvider]).
///
/// El contenido es texto provisional marcado; pendiente la fuente del
/// documento oficial (ver `domain/legal_documents.dart`).
class LegalesScreen extends ConsumerWidget {
  const LegalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final LegalVersions? versiones = ref.watch(legalVersionsProvider);

    final String versionTerminos = versiones?.versionTerminos ?? 'no disponible';
    final String versionPrivacidad = versiones?.versionPrivacidad ?? 'no disponible';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Documentos legales'),
          bottom: const TabBar(
            tabs: <Tab>[
              Tab(text: 'Términos y Condiciones'),
              Tab(text: 'Política de Privacidad'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _DocumentoLegal(
              titulo: 'Términos y Condiciones de Uso',
              version: versionTerminos,
              texto: textoProvisionalTerminos,
            ),
            _DocumentoLegal(
              titulo: 'Política de Privacidad',
              version: versionPrivacidad,
              texto: textoProvisionalPrivacidad,
            ),
          ],
        ),
        persistentFooterButtons: <Widget>[
          Text(
            'Versión de los documentos informada por el servidor: '
            'Términos $versionTerminos · Privacidad $versionPrivacidad',
            style: textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Pestaña del visor con su versión y el texto provisional.
class _DocumentoLegal extends StatelessWidget {
  const _DocumentoLegal({
    required this.titulo,
    required this.version,
    required this.texto,
  });

  final String titulo;
  final String version;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '$titulo — versión $version',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(texto),
          const SizedBox(height: 16),
          Text(
            'Versión vigente: $version',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
