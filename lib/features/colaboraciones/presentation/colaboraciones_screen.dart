import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/money/money.dart';
import '../../../core/money/money_input_formatter.dart';
import '../domain/colaboracion.dart';
import 'colaboraciones_controller.dart';
import 'colaboraciones_forms.dart';

enum _SeccionColaboraciones { metas, deudas, invitaciones, actividad }

class ColaboracionesScreen extends ConsumerStatefulWidget {
  const ColaboracionesScreen({super.key});

  @override
  ConsumerState<ColaboracionesScreen> createState() =>
      _ColaboracionesScreenState();
}

class _ColaboracionesScreenState extends ConsumerState<ColaboracionesScreen> {
  _SeccionColaboraciones _seccion = _SeccionColaboraciones.metas;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<SnapshotColaboraciones> data = ref.watch(
      colaboracionesProvider,
    );
    final bool enviando = ref.watch(colaboracionesAccionesProvider).isLoading;

    return NeoScaffold(
      appBar: const NeoAppBar(title: 'Colaboraciones'),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: _SeccionTabs(
              seleccion: _seccion,
              pendientes: _pendientes(data),
              onChanged: (_SeccionColaboraciones value) =>
                  setState(() => _seccion = value),
            ),
          ),
          Expanded(
            child: data.when(
              loading: () => const NeoLoading(rows: 3),
              error: (Object error, StackTrace stack) => NeoErrorState(
                message: error is AppFailure
                    ? failureMessage(error)
                    : 'No se pudieron cargar las colaboraciones.',
                onRetry: () =>
                    ref.read(colaboracionesProvider.notifier).refrescar(),
              ),
              data: (SnapshotColaboraciones snapshot) => _contenido(
                snapshot,
                enviando: enviando,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _botonCrear(enviando),
    );
  }

  /// Contadores que se muestran sobre las pestañas: invitaciones por responder
  /// y actividad con algo pendiente (requiere respuesta o sin leer).
  Map<_SeccionColaboraciones, int> _pendientes(
    AsyncValue<SnapshotColaboraciones> data,
  ) {
    return data.maybeWhen(
      data: (SnapshotColaboraciones snapshot) => <
        _SeccionColaboraciones,
        int
      >{
        _SeccionColaboraciones.invitaciones: snapshot.invitaciones.length,
        _SeccionColaboraciones.actividad: snapshot.actividad
            .where(
              (ActividadColaborativa evento) =>
                  evento.accionRequerida || !evento.leida,
            )
            .length,
      },
      orElse: () => const <_SeccionColaboraciones, int>{},
    );
  }

  Widget? _botonCrear(bool enviando) {
    if (_seccion == _SeccionColaboraciones.metas) {
      return NeoButton(
        label: 'Nueva meta compartida',
        icon: Icons.group_add_outlined,
        onPressed: enviando ? null : _crearMeta,
      );
    }
    if (_seccion == _SeccionColaboraciones.deudas) {
      return NeoButton(
        label: 'Nueva deuda directa',
        icon: Icons.add,
        onPressed: enviando ? null : _crearDeuda,
      );
    }
    return null;
  }

  Widget _contenido(
    SnapshotColaboraciones snapshot, {
    required bool enviando,
  }) {
    final List<Widget> children = switch (_seccion) {
      _SeccionColaboraciones.metas => _metas(snapshot.metas, enviando),
      _SeccionColaboraciones.deudas => _deudas(snapshot.deudas, enviando),
      _SeccionColaboraciones.invitaciones =>
        _invitaciones(snapshot.invitaciones, enviando),
      _SeccionColaboraciones.actividad =>
        _actividad(snapshot.actividad, enviando),
    };
    return RefreshIndicator(
      onRefresh: () => ref.read(colaboracionesProvider.notifier).refrescar(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxxl * 2,
        ),
        children: children,
      ),
    );
  }

  List<Widget> _metas(List<MetaCompartida> metas, bool enviando) {
    if (metas.isEmpty) {
      return <Widget>[
        const NeoEmptyState(
          icon: Icons.savings_outlined,
          title: 'Aún no tienes metas compartidas',
          message:
              'Crea una meta e invita a quienes ahorrarán contigo. '
              'El fondo se reparte según lo que aporta cada persona.',
        ),
      ];
    }
    return <Widget>[
      for (final MetaCompartida meta in metas)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _MetaCompartidaCard(
            meta: meta,
            enviando: enviando,
            onAportar: () => _operarMeta(
              meta,
              'Aportar a ${meta.nombre}',
              (OperacionFormValue value) => ref
                  .read(colaboracionesAccionesProvider.notifier)
                  .registrarAporte(
                    meta.id,
                    monto: value.monto,
                    descripcion: value.descripcion,
                    emailAtribucion: value.emailAtribucion,
                  ),
            ),
            onGastar: () => _operarMeta(
              meta,
              'Registrar gasto de ${meta.nombre}',
              (OperacionFormValue value) => ref
                  .read(colaboracionesAccionesProvider.notifier)
                  .registrarGastoMeta(
                    meta.id,
                    monto: value.monto,
                    descripcion: value.descripcion,
                    emailAtribucion: value.emailAtribucion,
                  ),
              permiteAtribucion: true,
            ),
            onRetirar: () => _operarMeta(
              meta,
              'Retirar de ${meta.nombre}',
              (OperacionFormValue value) => ref
                  .read(colaboracionesAccionesProvider.notifier)
                  .registrarRetiroMeta(
                    meta.id,
                    monto: value.monto,
                    descripcion: value.descripcion,
                    emailAtribucion: value.emailAtribucion,
                  ),
            ),
            onCambiar: () => _cambiarMeta(meta),
            onHistorial: () => _verHistorialMeta(meta),
            onSalir: () => _salirMeta(meta),
            onCancelar: () => _cancelarMeta(meta),
            onRevocarInvitacion: _revocarInvitacion,
          ),
        ),
    ];
  }

  List<Widget> _deudas(List<DeudaDirecta> deudas, bool enviando) {
    if (deudas.isEmpty) {
      return <Widget>[
        const NeoEmptyState(
          icon: Icons.handshake_outlined,
          title: 'Aún no tienes deudas directas',
          message:
              'Registra quién debe a quién. La deuda se activa cuando la '
              'otra persona acepta los términos.',
          accent: AppColors.lavender,
        ),
      ];
    }
    return <Widget>[
      for (final DeudaDirecta deuda in deudas)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _DeudaDirectaCard(
            deuda: deuda,
            enviando: enviando,
            onPagar: deuda.estado == EstadoDeudaDirecta.activa
                ? () => _pagarDeuda(deuda)
                : null,
            onCondonar: deuda.estado == EstadoDeudaDirecta.activa
                ? () => _condonarDeuda(deuda)
                : null,
            onCambiarSaldo: deuda.estado == EstadoDeudaDirecta.activa &&
                    (deuda.permisoEdicion == PermisoEdicionCompartida.todos ||
                        deuda.creadorActual)
                ? () => _cambiarSaldoDeuda(deuda)
                : null,
            onHistorial: () => _verHistorialDeuda(deuda),
            onRevocarInvitacion: deuda.creadorActual
                ? _revocarInvitacion
                : null,
          ),
        ),
    ];
  }

  List<Widget> _invitaciones(
    List<InvitacionColaborativa> invitaciones,
    bool enviando,
  ) {
    if (invitaciones.isEmpty) {
      return <Widget>[
        NeoEmptyState(
          icon: Icons.mark_email_unread_outlined,
          title: 'Sin invitaciones pendientes',
          message:
              'Cuando alguien te invite verás aquí los términos antes de '
              'aceptar. Si te compartieron un código, ingrésalo para unirte.',
          accent: AppColors.cyan,
          action: NeoButton(
            label: 'Ingresar código',
            icon: Icons.key_outlined,
            variant: NeoButtonVariant.secondary,
            onPressed: enviando ? null : _aceptarCodigo,
          ),
        ),
      ];
    }
    return <Widget>[
      Align(
        alignment: Alignment.centerLeft,
        child: NeoButton(
          label: 'Ingresar código',
          icon: Icons.key_outlined,
          variant: NeoButtonVariant.secondary,
          onPressed: enviando ? null : _aceptarCodigo,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      for (final InvitacionColaborativa invitacion in invitaciones)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _InvitacionCard(
            invitacion: invitacion,
            enviando: enviando,
            onAceptar: () => _responderInvitacion(invitacion, aceptar: true),
            onRechazar: () => _responderInvitacion(invitacion, aceptar: false),
          ),
        ),
    ];
  }

  List<Widget> _actividad(
    List<ActividadColaborativa> eventos,
    bool enviando,
  ) {
    if (eventos.isEmpty) {
      return <Widget>[
        const NeoEmptyState(
          icon: Icons.notifications_none_outlined,
          title: 'Todavía no hay actividad',
          message:
              'Aquí verás invitaciones, movimientos y cambios que '
              'requieren tu respuesta.',
          accent: AppColors.orange,
        ),
      ];
    }
    return <Widget>[
      for (final ActividadColaborativa evento in eventos)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _ActividadCard(
            evento: evento,
            enviando: enviando,
            onDecidir: evento.accionRequerida && evento.operacion != null
                ? (bool aceptar) => _decidir(evento, aceptar: aceptar)
                : null,
            onLeida: evento.leida
                ? null
                : () => _marcarLeida(evento.id),
          ),
        ),
    ];
  }

  Future<void> _crearMeta() async {
    final MetaCompartidaDatos? datos =
        await ColaboracionesForms.crearMeta(context);
    if (datos == null || !mounted) return;
    final ColaboracionActionResult<List<InvitacionColaborativa>> result =
        await ref.read(colaboracionesAccionesProvider.notifier).crearMeta(datos);
    if (!mounted) return;
    if (result.failure != null) {
      _avisar(failureMessage(result.failure!));
      return;
    }
    _avisar(
      'Meta creada. Comparte los códigos con las personas invitadas.',
      tone: NeoSnackbarTone.success,
    );
    await _mostrarCodigos(result.value ?? const <InvitacionColaborativa>[]);
  }

  Future<void> _crearDeuda() async {
    final DeudaDirectaDatos? datos =
        await ColaboracionesForms.crearDeuda(context);
    if (datos == null || !mounted) return;
    final ColaboracionActionResult<InvitacionColaborativa> result =
        await ref.read(colaboracionesAccionesProvider.notifier).crearDeuda(datos);
    if (!mounted) return;
    if (result.failure != null) {
      _avisar(failureMessage(result.failure!));
      return;
    }
    _avisar(
      'Invitación creada. La deuda se activará cuando la acepten.',
      tone: NeoSnackbarTone.success,
    );
    final InvitacionColaborativa? invitacion = result.value;
    if (invitacion != null) {
      await _mostrarCodigos(<InvitacionColaborativa>[invitacion]);
    }
  }

  Future<void> _mostrarCodigos(List<InvitacionColaborativa> invitaciones) async {
    if (invitaciones.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => NeoDialog(
        title: 'Códigos de invitación',
        actions: <Widget>[
          NeoButton(
            label: 'Listo',
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Compártelos solo con el correo invitado. Vencen en 7 días.'),
            const SizedBox(height: AppSpacing.md),
            for (final InvitacionColaborativa invitacion in invitaciones)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: NeoSurface(
                  density: AppDensity.list,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              invitacion.emailInvitado,
                              style: Theme.of(dialogContext).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(dialogContext)
                                        .extension<SaveUpColors>()!
                                        .muted,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            SelectableText(
                              invitacion.codigo ?? '',
                              style: AppTypography.text(
                                size: 13,
                                weight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      NeoIconButton(
                        icon: Icons.copy_outlined,
                        tooltip: 'Copiar código',
                        variant: NeoIconButtonVariant.secondary,
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: invitacion.codigo ?? ''),
                          );
                          if (dialogContext.mounted) {
                            NeoSnackbar.show(
                              dialogContext,
                              'Código copiado.',
                              tone: NeoSnackbarTone.success,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _operarMeta(
    MetaCompartida meta,
    String titulo,
    Future<ColaboracionActionResult<OperacionColaborativa>> Function(
      OperacionFormValue,
    ) ejecutar, {
    bool permiteAtribucion = false,
  }) async {
    if (meta.estado != EstadoMetaCompartida.activa) {
      _avisar(
        'La meta se activa cuando aceptan la invitación.',
        tone: NeoSnackbarTone.warning,
      );
      return;
    }
    final OperacionFormValue? datos =
        await ColaboracionesForms.registrarOperacion(
          context,
          titulo: titulo,
          participantes: meta.participantes,
          mostrarAtribucion: permiteAtribucion || meta.participantes.length > 1,
        );
    if (datos == null || !mounted) return;
    final ColaboracionActionResult<OperacionColaborativa> result =
        await ejecutar(datos);
    if (!mounted) return;
    if (result.failure != null) {
      _avisar(failureMessage(result.failure!));
      return;
    }
    final OperacionColaborativa? operation = result.value;
    final bool pendiente =
        operation?.estado == EstadoColaborativo.pendiente;
    _avisar(
      pendiente
          ? 'Movimiento enviado para confirmación.'
          : 'Movimiento registrado.',
      tone: pendiente ? NeoSnackbarTone.warning : NeoSnackbarTone.success,
    );
  }

  Future<void> _pagarDeuda(DeudaDirecta deuda) async {
    final OperacionFormValue? datos =
        await ColaboracionesForms.registrarOperacion(
          context,
          titulo: 'Registrar pago: ${deuda.nombre}',
          participantes: const <ParticipanteMeta>[],
        );
    if (datos == null || !mounted) return;
    final String? atribucion = deuda.yoSoyAcreedor
        ? deuda.deudorEmail
        : null;
    final ColaboracionActionResult<OperacionColaborativa> result = await ref
        .read(colaboracionesAccionesProvider.notifier)
        .registrarPagoDeuda(
          deuda.id,
          monto: datos.monto,
          descripcion: datos.descripcion,
          emailAtribucion: atribucion,
        );
    if (!mounted) return;
    _avisarOperacion(result, 'Pago registrado.');
  }

  Future<void> _condonarDeuda(DeudaDirecta deuda) async {
    final OperacionFormValue? datos =
        await ColaboracionesForms.registrarOperacion(
          context,
          titulo: 'Proponer condonación',
          participantes: const <ParticipanteMeta>[],
        );
    if (datos == null || !mounted) return;
    final ColaboracionActionResult<OperacionColaborativa> result = await ref
        .read(colaboracionesAccionesProvider.notifier)
        .condonarDeuda(
          deuda.id,
          monto: datos.monto,
          descripcion: datos.descripcion,
        );
    if (!mounted) return;
    _avisarOperacion(result, 'Propuesta enviada para confirmación.');
  }

  Future<void> _cambiarSaldoDeuda(DeudaDirecta deuda) async {
    final Decimal? saldo = await ColaboracionesForms.cambiarSaldoDeuda(
      context,
      saldoActual: MoneyInputFormatter.format(deuda.saldoPendiente),
    );
    if (saldo == null || !mounted) return;
    final ColaboracionActionResult<OperacionColaborativa> result = await ref
        .read(colaboracionesAccionesProvider.notifier)
        .proponerCambioDeuda(deuda.id, saldoPendiente: saldo);
    if (!mounted) return;
    _avisarOperacion(result, 'Cambio enviado para confirmación.');
  }

  Future<void> _cambiarMeta(MetaCompartida meta) async {
    final CambioMetaDatos? cambio = await ColaboracionesForms.cambiarMeta(
      context,
      meta: meta,
    );
    if (cambio == null || !mounted) return;
    final ColaboracionActionResult<OperacionColaborativa> result = await ref
        .read(colaboracionesAccionesProvider.notifier)
        .proponerCambioMeta(
          meta.id,
          montoObjetivo: cambio.montoObjetivo,
          fechaLimite: cambio.fechaLimite,
        );
    if (!mounted) return;
    _avisarOperacion(result, 'Cambio enviado para aprobación.');
  }

  Future<void> _responderInvitacion(
    InvitacionColaborativa invitacion, {
    required bool aceptar,
  }) async {
    if (aceptar) {
      final bool? confirmado = await NeoConfirmDialog.show(
        context,
        title: 'Aceptar invitación',
        message: invitacion.tipoRecurso == 'DEUDA_DIRECTA'
            ? '${invitacion.nombreCreador} propone una deuda de '
                  '${Money.formatClp(invitacion.monto ?? Decimal.zero)}. '
                  '${invitacion.deudorNombre} debe a ${invitacion.acreedorNombre}. '
                  'Al aceptar, confirmas estos términos.'
            : 'Te incorporarás a «${invitacion.nombreRecurso}». '
                  'La invitación confirma tu participación.',
        confirmLabel: 'Aceptar',
      );
      if (confirmado != true || !mounted) return;
    }
    final ColaboracionActionResult<bool> result = aceptar
        ? await ref
              .read(colaboracionesAccionesProvider.notifier)
              .aceptarInvitacion(invitacion.id)
        : await ref
              .read(colaboracionesAccionesProvider.notifier)
              .rechazarInvitacion(invitacion.id);
    if (!mounted) return;
    if (result.failure != null) {
      _avisar(failureMessage(result.failure!));
    } else {
      _avisar(aceptar ? 'Invitación aceptada.' : 'Invitación rechazada.', tone: NeoSnackbarTone.success);
    }
  }

  Future<void> _revocarInvitacion(InvitacionColaborativa invitacion) async {
    final bool? confirmado = await NeoConfirmDialog.show(
      context,
      title: 'Revocar invitación',
      message: 'El código para ${invitacion.emailInvitado} dejará de ser válido.',
      confirmLabel: 'Revocar',
      destructive: true,
    );
    if (confirmado != true || !mounted) return;
    final ColaboracionActionResult<bool> result = await ref
        .read(colaboracionesAccionesProvider.notifier)
        .revocarInvitacion(invitacion.id);
    if (!mounted) return;
    if (result.failure != null) {
      _avisar(failureMessage(result.failure!));
    } else {
      _avisar('Invitación revocada.', tone: NeoSnackbarTone.success);
    }
  }

  Future<void> _aceptarCodigo() async {
    final String? codigo = await ColaboracionesForms.ingresarCodigo(context);
    if (codigo == null || !mounted) return;
    final ColaboracionActionResult<bool> result = await ref
        .read(colaboracionesAccionesProvider.notifier)
        .aceptarCodigoInvitacion(codigo);
    if (!mounted) return;
    if (result.failure != null) {
      _avisar(failureMessage(result.failure!));
    } else {
      _avisar('Invitación aceptada.', tone: NeoSnackbarTone.success);
    }
  }

  Future<void> _decidir(
    ActividadColaborativa actividad, {
    required bool aceptar,
  }) async {
    final OperacionColaborativa? operation = actividad.operacion;
    if (operation == null) return;
    final bool? confirmado = await NeoConfirmDialog.show(
      context,
      title: aceptar ? 'Confirmar movimiento' : 'Rechazar movimiento',
      message:
          '${operation.registradoPor} registró «${operation.descripcion}» por '
          '${Money.formatClp(operation.monto)}. '
          '${aceptar ? 'Al confirmar, se actualizarán los saldos correspondientes.' : 'El registro quedará en el historial y no cambiará saldos.'}',
      confirmLabel: aceptar ? 'Confirmar' : 'Rechazar',
      destructive: !aceptar,
    );
    if (confirmado != true || !mounted) return;
    final ColaboracionActionResult<OperacionColaborativa> result = await ref
        .read(colaboracionesAccionesProvider.notifier)
        .decidirOperacion(operation.id, aceptar: aceptar);
    if (!mounted) return;
    _avisarOperacion(
      result,
      aceptar ? 'Movimiento confirmado.' : 'Movimiento rechazado.',
    );
  }

  Future<void> _marcarLeida(int id) async {
    final result = await ref
        .read(colaboracionesAccionesProvider.notifier)
        .marcarActividadLeida(id);
    if (!mounted || result.failure == null) return;
    _avisar(failureMessage(result.failure!));
  }

  Future<void> _salirMeta(MetaCompartida meta) async {
    final bool? confirmado = await NeoConfirmDialog.show(
      context,
      title: 'Salir de la meta',
      message: 'Debes devolver primero tu saldo atribuible. Los movimientos anteriores seguirán en el historial.',
      confirmLabel: 'Salir',
    );
    if (confirmado != true || !mounted) return;
    final result = await ref
        .read(colaboracionesAccionesProvider.notifier)
        .salirMeta(meta.id);
    if (!mounted) return;
    if (result.failure != null) {
      _avisar(failureMessage(result.failure!));
    } else {
      _avisar('Saliste de la meta.', tone: NeoSnackbarTone.success);
    }
  }

  Future<void> _cancelarMeta(MetaCompartida meta) async {
    final bool? confirmado = await NeoConfirmDialog.show(
      context,
      title: 'Proponer cancelación',
      message: 'La meta ya no tiene saldo. Las demás personas deberán aprobar la cancelación.',
      confirmLabel: 'Proponer',
    );
    if (confirmado != true || !mounted) return;
    final result = await ref
        .read(colaboracionesAccionesProvider.notifier)
        .cancelarMeta(meta.id);
    if (!mounted) return;
    _avisarOperacion(result, 'Propuesta enviada para aprobación.');
  }

  Future<void> _verHistorialMeta(MetaCompartida meta) async {
    try {
      final List<OperacionColaborativa> history = await ref
          .read(colaboracionesAccionesProvider.notifier)
          .obtenerHistorialMeta(meta.id);
      if (!mounted) return;
      await _mostrarHistorial('Historial · ${meta.nombre}', history);
    } on AppFailure catch (failure) {
      if (mounted) _avisar(failureMessage(failure));
    }
  }

  Future<void> _verHistorialDeuda(DeudaDirecta deuda) async {
    try {
      final List<OperacionColaborativa> history = await ref
          .read(colaboracionesAccionesProvider.notifier)
          .obtenerHistorialDeuda(deuda.id);
      if (!mounted) return;
      await _mostrarHistorial('Historial · ${deuda.nombre}', history);
    } on AppFailure catch (failure) {
      if (mounted) _avisar(failureMessage(failure));
    }
  }

  Future<void> _mostrarHistorial(
    String title,
    List<OperacionColaborativa> history,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: history.isEmpty
                      ? const Center(child: Text('Todavía no hay movimientos.'))
                      : ListView.separated(
                          itemCount: history.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (_, int index) =>
                              _OperacionHistoryRow(operation: history[index]),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _avisarOperacion(
    ColaboracionActionResult<OperacionColaborativa> result,
    String success,
  ) {
    if (result.failure != null) {
      _avisar(failureMessage(result.failure!));
      return;
    }
    final EstadoColaborativo? status = result.value?.estado;
    final bool pendiente = status == EstadoColaborativo.pendiente;
    _avisar(
      pendiente ? 'Pendiente de confirmación.' : success,
      tone: pendiente ? NeoSnackbarTone.warning : NeoSnackbarTone.success,
    );
  }

  void _avisar(
    String text, {
    NeoSnackbarTone tone = NeoSnackbarTone.danger,
  }) {
    NeoSnackbar.show(context, text, tone: tone);
  }
}

class _MetaCompartidaCard extends StatelessWidget {
  const _MetaCompartidaCard({
    required this.meta,
    required this.enviando,
    required this.onAportar,
    required this.onGastar,
    required this.onRetirar,
    required this.onCambiar,
    required this.onHistorial,
    required this.onSalir,
    required this.onCancelar,
    required this.onRevocarInvitacion,
  });

  final MetaCompartida meta;
  final bool enviando;
  final VoidCallback onAportar;
  final VoidCallback onGastar;
  final VoidCallback onRetirar;
  final VoidCallback onCambiar;
  final VoidCallback onHistorial;
  final VoidCallback onSalir;
  final VoidCallback onCancelar;
  final ValueChanged<InvitacionColaborativa> onRevocarInvitacion;

  @override
  Widget build(BuildContext context) {
    final bool activa = meta.estado == EstadoMetaCompartida.activa;
    final bool soyCreador = meta.participantes.any(
      (ParticipanteMeta p) => p.actual && p.creador,
    );
    final bool puedeCancelar =
        activa &&
        meta.montoActual.compareTo(Decimal.zero) == 0 &&
        (meta.permisoEdicion == PermisoEdicionCompartida.todos || soyCreador);
    final SaveUpColors colors = Theme.of(context).extension<SaveUpColors>()!;
    return NeoSurface(
      density: AppDensity.section,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(meta.nombre, style: Theme.of(context).textTheme.titleMedium)),
              NeoBadge(
                label: _estadoMeta(meta.estado),
                color: meta.estado == EstadoMetaCompartida.activa
                    ? AppColors.green
                    : AppColors.yellow,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            meta.montoObjetivo == null
                ? 'Fondo disponible: ${Money.formatClp(meta.montoActual)}'
                : '${Money.formatClp(meta.montoActual)} de ${Money.formatClp(meta.montoObjetivo!)}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (meta.montoObjetivo != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            NeoProgress(
              value: _progreso(meta.montoActual, meta.montoObjetivo!),
              color: colors.ink,
              trackColor: colors.surfaceAlt,
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Participan: ${meta.participantes.map((ParticipanteMeta p) => p.nombre).join(', ')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (soyCreador && meta.invitacionesPendientes.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            for (final InvitacionColaborativa invitacion in meta.invitacionesPendientes)
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Invitación pendiente: ${invitacion.emailInvitado}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  NeoIconButton(
                    icon: Icons.link_off_outlined,
                    tooltip: 'Revocar invitación',
                    variant: NeoIconButtonVariant.ghost,
                    onPressed: enviando
                        ? null
                        : () => onRevocarInvitacion(invitacion),
                  ),
                ],
              ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              NeoButton(
                label: 'Aportar',
                icon: Icons.add,
                variant: NeoButtonVariant.ghost,
                onPressed: activa && !enviando ? onAportar : null,
              ),
              NeoButton(
                label: 'Gastar',
                icon: Icons.shopping_bag_outlined,
                variant: NeoButtonVariant.ghost,
                onPressed: activa && !enviando ? onGastar : null,
              ),
              NeoButton(
                label: 'Retirar',
                icon: Icons.south_west,
                variant: NeoButtonVariant.ghost,
                onPressed: activa && !enviando ? onRetirar : null,
              ),
              NeoButton(
                label: 'Proponer cambio',
                icon: Icons.edit_outlined,
                variant: NeoButtonVariant.secondary,
                onPressed: activa &&
                        !enviando &&
                        (meta.permisoEdicion == PermisoEdicionCompartida.todos ||
                            soyCreador)
                    ? onCambiar
                    : null,
              ),
              NeoButton(
                label: 'Historial',
                icon: Icons.history,
                variant: NeoButtonVariant.secondary,
                onPressed: enviando ? null : onHistorial,
              ),
              if (activa && !soyCreador)
                NeoButton(
                  label: 'Salir',
                  variant: NeoButtonVariant.secondary,
                  onPressed: enviando ? null : onSalir,
                ),
              if (puedeCancelar)
                NeoButton(
                  label: 'Cancelar meta',
                  variant: NeoButtonVariant.danger,
                  onPressed: enviando ? null : onCancelar,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _estadoMeta(EstadoMetaCompartida estado) => switch (estado) {
    EstadoMetaCompartida.pendiente => 'Pendiente de invitación',
    EstadoMetaCompartida.activa => 'Activa',
    EstadoMetaCompartida.cancelada => 'Cancelada',
  };
}

class _DeudaDirectaCard extends StatelessWidget {
  const _DeudaDirectaCard({
    required this.deuda,
    required this.enviando,
    required this.onPagar,
    required this.onCondonar,
    required this.onCambiarSaldo,
    required this.onHistorial,
    required this.onRevocarInvitacion,
  });

  final DeudaDirecta deuda;
  final bool enviando;
  final VoidCallback? onPagar;
  final VoidCallback? onCondonar;
  final VoidCallback? onCambiarSaldo;
  final VoidCallback onHistorial;
  final ValueChanged<InvitacionColaborativa>? onRevocarInvitacion;

  @override
  Widget build(BuildContext context) {
    final String ruta = deuda.yoSoyDeudor
        ? 'Debes a ${deuda.acreedorNombre ?? 'la contraparte'}'
        : 'Te debe ${deuda.deudorNombre ?? 'la contraparte'}';
    final String estado = switch (deuda.estado) {
      EstadoDeudaDirecta.pendiente => 'Esperando aceptación',
      EstadoDeudaDirecta.activa => 'Activa',
      EstadoDeudaDirecta.pagada => 'Pagada',
      EstadoDeudaDirecta.condonada => 'Condonada',
    };
    return NeoSurface(
      density: AppDensity.section,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(deuda.nombre, style: Theme.of(context).textTheme.titleMedium),
              ),
              NeoBadge(
                label: estado,
                color: deuda.estado == EstadoDeudaDirecta.activa
                    ? AppColors.yellow
                    : AppColors.lavender,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(ruta),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pendiente: ${Money.formatClp(deuda.saldoPendiente)}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (deuda.creadorActual && deuda.invitacionesPendientes.isNotEmpty)
            for (final InvitacionColaborativa invitacion in deuda.invitacionesPendientes)
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Invitación pendiente: ${invitacion.emailInvitado}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  NeoIconButton(
                    icon: Icons.link_off_outlined,
                    tooltip: 'Revocar invitación',
                    variant: NeoIconButtonVariant.ghost,
                    onPressed: enviando || onRevocarInvitacion == null
                        ? null
                        : () => onRevocarInvitacion!(invitacion),
                  ),
                ],
              ),
          const SizedBox(height: AppSpacing.sm),
          if (deuda.estado == EstadoDeudaDirecta.activa)
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                NeoButton(
                  label: deuda.yoSoyDeudor ? 'Registrar pago' : 'Informar pago',
                  icon: Icons.payments_outlined,
                  onPressed: enviando ? null : onPagar,
                ),
                NeoButton(
                  label: 'Proponer condonación',
                  variant: NeoButtonVariant.secondary,
                  onPressed: enviando ? null : onCondonar,
                ),
                if (onCambiarSaldo != null)
                  NeoButton(
                    label: 'Ajustar saldo',
                    variant: NeoButtonVariant.ghost,
                    onPressed: enviando ? null : onCambiarSaldo,
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: NeoButton(
              label: 'Ver historial',
              icon: Icons.history,
              variant: NeoButtonVariant.ghost,
              onPressed: enviando ? null : onHistorial,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvitacionCard extends StatelessWidget {
  const _InvitacionCard({
    required this.invitacion,
    required this.enviando,
    required this.onAceptar,
    required this.onRechazar,
  });

  final InvitacionColaborativa invitacion;
  final bool enviando;
  final VoidCallback onAceptar;
  final VoidCallback onRechazar;

  @override
  Widget build(BuildContext context) {
    final bool deuda = invitacion.tipoRecurso == 'DEUDA_DIRECTA';
    return NeoSurface(
      density: AppDensity.section,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(invitacion.nombreRecurso, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('Invita ${invitacion.nombreCreador} · ${invitacion.tipoRecurso == 'META' ? 'Meta compartida' : 'Deuda directa'}'),
          if (deuda) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${invitacion.deudorNombre} debe a ${invitacion.acreedorNombre}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Monto: ${Money.formatClp(invitacion.monto ?? Decimal.zero)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ] else if (invitacion.montoObjetivo != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text('Objetivo: ${Money.formatClp(invitacion.montoObjetivo!)}'),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Vence ${_fecha(invitacion.expiraEn)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            children: <Widget>[
              NeoButton(
                label: 'Aceptar',
                onPressed: enviando ? null : onAceptar,
              ),
              NeoButton(
                label: 'Rechazar',
                variant: NeoButtonVariant.secondary,
                onPressed: enviando ? null : onRechazar,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActividadCard extends StatelessWidget {
  const _ActividadCard({
    required this.evento,
    required this.enviando,
    required this.onDecidir,
    required this.onLeida,
  });

  final ActividadColaborativa evento;
  final bool enviando;
  final ValueChanged<bool>? onDecidir;
  final VoidCallback? onLeida;

  @override
  Widget build(BuildContext context) {
    final OperacionColaborativa? op = evento.operacion;
    final InvitacionColaborativa? invite = evento.invitacion;
    final String title = op?.descripcion ??
        invite?.nombreRecurso ??
        _actividadLabel(evento.tipo);
    return NeoSurface(
      density: AppDensity.section,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.titleSmall),
              ),
              if (evento.accionRequerida)
                const NeoBadge(label: 'Requiere respuesta', color: AppColors.yellow, compact: true),
              if (!evento.leida && !evento.accionRequerida)
                const NeoBadge(label: 'Nueva', color: AppColors.green, compact: true),
            ],
          ),
          if (op != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${op.registradoPor} · ${Money.formatClp(op.monto)} · ${_estadoOperacion(op.estado)}',
            ),
          ] else if (invite != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text('Invitación de ${invite.nombreCreador}'),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(_fecha(evento.creadoEn), style: Theme.of(context).textTheme.bodySmall),
          if (onDecidir != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              children: <Widget>[
                NeoButton(
                  label: 'Confirmar',
                  onPressed: enviando ? null : () => onDecidir!(true),
                ),
                NeoButton(
                  label: 'Rechazar',
                  variant: NeoButtonVariant.secondary,
                  onPressed: enviando ? null : () => onDecidir!(false),
                ),
              ],
            ),
          ] else if (onLeida != null)
            Align(
              alignment: Alignment.centerRight,
              child: NeoButton(
                label: 'Marcar como leída',
                variant: NeoButtonVariant.ghost,
                onPressed: enviando ? null : onLeida,
              ),
            ),
        ],
      ),
    );
  }
}

class _OperacionHistoryRow extends StatelessWidget {
  const _OperacionHistoryRow({required this.operation});
  final OperacionColaborativa operation;

  @override
  Widget build(BuildContext context) => NeoSurface(
    density: AppDensity.list,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(operation.descripcion)),
            NeoBadge(
              label: _estadoOperacion(operation.estado),
              color: switch (operation.estado) {
                EstadoColaborativo.confirmado => AppColors.green,
                EstadoColaborativo.pendiente => AppColors.yellow,
                EstadoColaborativo.rechazado => AppColors.lavender,
              },
              compact: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${operation.registradoPor} · ${Money.formatClp(operation.monto)} · ${_fecha(operation.creadoEn)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (operation.atribuidoA != null)
          Text('Atribuido a ${operation.atribuidoA}'),
        for (final AtribucionMeta atribucion in operation.atribuciones)
          Text('${atribucion.participante}: ${Money.formatClp(atribucion.monto)}'),
      ],
    ),
  );
}

class _SeccionTabs extends StatelessWidget {
  const _SeccionTabs({
    required this.seleccion,
    required this.pendientes,
    required this.onChanged,
  });

  final _SeccionColaboraciones seleccion;
  final Map<_SeccionColaboraciones, int> pendientes;
  final ValueChanged<_SeccionColaboraciones> onChanged;

  @override
  Widget build(BuildContext context) {
    final SaveUpColors colors = Theme.of(context).extension<SaveUpColors>()!;
    return NeoSurface(
      density: AppDensity.list,
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        children: <Widget>[
          for (final _SeccionColaboraciones seccion
              in _SeccionColaboraciones.values)
            Expanded(
              child: _tab(
                context,
                colors,
                seccion,
                activa: seccion == seleccion,
                pendientes: pendientes[seccion] ?? 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _tab(
    BuildContext context,
    SaveUpColors colors,
    _SeccionColaboraciones seccion, {
    required bool activa,
    required int pendientes,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Material(
        color: activa ? colors.primary : Colors.transparent,
        borderRadius: AppRadii.smAll,
        child: InkWell(
          borderRadius: AppRadii.smAll,
          onTap: () => onChanged(seccion),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Icon(
                      seccion.icono,
                      size: 20,
                      color: activa ? AppColors.ink : colors.ink,
                    ),
                    if (pendientes > 0)
                      Positioned(
                        top: -6,
                        right: -10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.magenta,
                            borderRadius: AppRadii.pillAll,
                            border: Border.all(
                              color: colors.border,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '$pendientes',
                            style: AppTypography.text(
                              size: 9,
                              weight: FontWeight.w700,
                              height: 1.2,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  seccion.etiqueta,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: AppTypography.text(
                    size: 11,
                    weight: activa ? FontWeight.w700 : FontWeight.w500,
                    color: activa ? AppColors.ink : colors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension on _SeccionColaboraciones {
  String get etiqueta => switch (this) {
    _SeccionColaboraciones.metas => 'Metas',
    _SeccionColaboraciones.deudas => 'Deudas',
    _SeccionColaboraciones.invitaciones => 'Invitaciones',
    _SeccionColaboraciones.actividad => 'Actividad',
  };

  IconData get icono => switch (this) {
    _SeccionColaboraciones.metas => Icons.savings_outlined,
    _SeccionColaboraciones.deudas => Icons.handshake_outlined,
    _SeccionColaboraciones.invitaciones => Icons.mark_email_unread_outlined,
    _SeccionColaboraciones.actividad => Icons.notifications_none_outlined,
  };
}

String _estadoOperacion(EstadoColaborativo estado) => switch (estado) {
  EstadoColaborativo.pendiente => 'Pendiente',
  EstadoColaborativo.confirmado => 'Confirmado',
  EstadoColaborativo.rechazado => 'Rechazado',
};

String _actividadLabel(String tipo) => switch (tipo) {
  'INVITACION' => 'Nueva invitación',
  'INVITACION_ACEPTADA' => 'Invitación aceptada',
  'INVITACION_RECHAZADA' => 'Invitación rechazada',
  'MOVIMIENTO_PENDIENTE' => 'Movimiento pendiente',
  'MOVIMIENTO_CONFIRMADO' => 'Movimiento confirmado',
  'MOVIMIENTO_RECHAZADO' => 'Movimiento rechazado',
  'CAMBIO_PENDIENTE' => 'Cambio pendiente',
  'CAMBIO_CONFIRMADO' => 'Cambio confirmado',
  _ => 'Actividad colaborativa',
};

String _fecha(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

double _progreso(Decimal actual, Decimal objetivo) {
  if (objetivo <= Decimal.zero) return 0;
  return (actual / objetivo).toDecimal(scaleOnInfinitePrecision: 4).toDouble().clamp(0, 1);
}
