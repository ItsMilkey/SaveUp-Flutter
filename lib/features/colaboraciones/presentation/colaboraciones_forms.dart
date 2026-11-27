import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/money/money.dart';
import '../../../core/money/money_input_formatter.dart';
import '../../../core/time/calendar_date.dart';
import '../domain/colaboracion.dart';

abstract final class ColaboracionesForms {
  static Future<MetaCompartidaDatos?> crearMeta(BuildContext context) =>
      showDialog<MetaCompartidaDatos>(
        context: context,
        builder: (_) => const _CrearMetaDialog(),
      );

  static Future<DeudaDirectaDatos?> crearDeuda(BuildContext context) =>
      showDialog<DeudaDirectaDatos>(
        context: context,
        builder: (_) => const _CrearDeudaDialog(),
      );

  static Future<OperacionFormValue?> registrarOperacion(
    BuildContext context, {
    required String titulo,
    required List<ParticipanteMeta> participantes,
    String? emailAtribucionInicial,
    bool mostrarAtribucion = false,
  }) => showDialog<OperacionFormValue>(
    context: context,
    builder: (_) => _OperacionDialog(
      titulo: titulo,
      participantes: participantes,
      emailAtribucionInicial: emailAtribucionInicial,
      mostrarAtribucion: mostrarAtribucion,
    ),
  );

  static Future<Decimal?> cambiarSaldoDeuda(
    BuildContext context, {
    required String saldoActual,
  }) => showDialog<Decimal>(
    context: context,
    builder: (_) => _MontoDialog(
      titulo: 'Proponer saldo pendiente',
      etiqueta: 'Nuevo saldo pendiente',
      initial: saldoActual,
    ),
  );

  static Future<CambioMetaDatos?> cambiarMeta(
    BuildContext context, {
    required MetaCompartida meta,
  }) => showDialog<CambioMetaDatos>(
    context: context,
    builder: (_) => _CambiarMetaDialog(meta: meta),
  );

  static Future<String?> ingresarCodigo(BuildContext context) =>
      showDialog<String>(
        context: context,
        builder: (_) => const _CodigoInvitacionDialog(),
      );
}

class OperacionFormValue {
  const OperacionFormValue({
    required this.monto,
    required this.descripcion,
    this.emailAtribucion,
  });

  final Decimal monto;
  final String descripcion;
  final String? emailAtribucion;
}

class _CrearMetaDialog extends StatefulWidget {
  const _CrearMetaDialog();

  @override
  State<_CrearMetaDialog> createState() => _CrearMetaDialogState();
}

class _CrearMetaDialogState extends State<_CrearMetaDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _objetivo = TextEditingController();
  final TextEditingController _emails = TextEditingController();
  PermisoEdicionCompartida _permiso = PermisoEdicionCompartida.soloCreador;
  CalendarDate? _fechaLimite;

  @override
  void dispose() {
    _nombre.dispose();
    _objetivo.dispose();
    _emails.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _NeoFormDialog(
      title: 'Crear meta compartida',
      actions: <Widget>[
        NeoButton(
          label: 'Cancelar',
          variant: NeoButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        NeoButton(label: 'Crear e invitar', onPressed: _guardar),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            NeoInput(
              controller: _nombre,
              label: 'Nombre de la meta',
              textInputAction: TextInputAction.next,
              validator: (String? value) => value == null || value.trim().isEmpty
                  ? 'Ingresa un nombre.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            NeoInput(
              controller: _objetivo,
              label: 'Objetivo (opcional)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: moneyInputFormatters,
              textInputAction: TextInputAction.next,
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) return null;
                try {
                  if (Money.parseUserInput(value) <= Decimal.zero) {
                    return 'El objetivo debe ser mayor que cero.';
                  }
                } on FormatException {
                  return 'Ingresa un monto válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _FechaLimiteSelector(
              fecha: _fechaLimite,
              onChanged: (CalendarDate? value) =>
                  setState(() => _fechaLimite = value),
            ),
            const SizedBox(height: AppSpacing.md),
            NeoInput(
              controller: _emails,
              label: 'Correos de las personas invitadas',
              hint: 'persona@correo.cl, otra@correo.cl',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              helper: 'Separa varios correos con coma.',
              validator: (String? value) => value == null ||
                      value.split(',').every((String email) => email.trim().isEmpty)
                  ? 'Invita al menos a una persona.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<PermisoEdicionCompartida>(
              initialValue: _permiso,
              decoration: const InputDecoration(labelText: 'Quién puede proponer cambios'),
              items: const <DropdownMenuItem<PermisoEdicionCompartida>>[
                DropdownMenuItem(
                  value: PermisoEdicionCompartida.soloCreador,
                  child: Text('Solo yo'),
                ),
                DropdownMenuItem(
                  value: PermisoEdicionCompartida.todos,
                  child: Text('Todos los participantes'),
                ),
              ],
              onChanged: (PermisoEdicionCompartida? value) {
                if (value != null) setState(() => _permiso = value);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Los cambios financieros necesitan aprobación de todas las personas.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Decimal? objetivo;
    if (_objetivo.text.trim().isNotEmpty) {
      objetivo = Money.parseUserInput(_objetivo.text);
    }
    final List<String> emails = _emails.text
        .split(',')
        .map((String email) => email.trim())
        .where((String email) => email.isNotEmpty)
        .toList(growable: false);
    Navigator.of(context).pop(
      MetaCompartidaDatos(
        nombre: _nombre.text.trim(),
        montoObjetivo: objetivo,
        fechaLimite: _fechaLimite,
        permisoEdicion: _permiso,
        emailsInvitados: emails,
      ),
    );
  }
}

class _CrearDeudaDialog extends StatefulWidget {
  const _CrearDeudaDialog();

  @override
  State<_CrearDeudaDialog> createState() => _CrearDeudaDialogState();
}

class _CrearDeudaDialogState extends State<_CrearDeudaDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _descripcion = TextEditingController();
  final TextEditingController _monto = TextEditingController();
  final TextEditingController _email = TextEditingController();
  String _direccion = 'YO_DEBO';
  PermisoEdicionCompartida _permiso = PermisoEdicionCompartida.soloCreador;

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    _monto.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _NeoFormDialog(
      title: 'Registrar deuda directa',
      actions: <Widget>[
        NeoButton(
          label: 'Cancelar',
          variant: NeoButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        NeoButton(label: 'Crear invitación', onPressed: _guardar),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            NeoInput(
              controller: _nombre,
              label: 'Nombre',
              textInputAction: TextInputAction.next,
              validator: (String? value) => value == null || value.trim().isEmpty
                  ? 'Ingresa un nombre.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            NeoInput(
              controller: _descripcion,
              label: 'Descripción (opcional)',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            NeoInput(
              controller: _monto,
              label: 'Monto acordado',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: moneyInputFormatters,
              textInputAction: TextInputAction.next,
              validator: (String? value) {
                try {
                  if (value == null || Money.parseUserInput(value) <= Decimal.zero) {
                    return 'Ingresa un monto mayor que cero.';
                  }
                } on FormatException {
                  return 'Ingresa un monto válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _direccion,
              decoration: const InputDecoration(labelText: 'Dirección'),
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem(value: 'YO_DEBO', child: Text('Yo debo')),
                DropdownMenuItem(value: 'ME_DEBEN', child: Text('Me deben')),
              ],
              onChanged: (String? value) {
                if (value != null) setState(() => _direccion = value);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            NeoInput(
              controller: _email,
              label: 'Correo de la contraparte',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (String? value) =>
                  value == null || !value.trim().contains('@')
                  ? 'Ingresa el correo de la otra persona.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<PermisoEdicionCompartida>(
              initialValue: _permiso,
              decoration: const InputDecoration(labelText: 'Quién puede proponer cambios'),
              items: const <DropdownMenuItem<PermisoEdicionCompartida>>[
                DropdownMenuItem(
                  value: PermisoEdicionCompartida.soloCreador,
                  child: Text('Solo yo'),
                ),
                DropdownMenuItem(
                  value: PermisoEdicionCompartida.todos,
                  child: Text('Ambas personas'),
                ),
              ],
              onChanged: (PermisoEdicionCompartida? value) {
                if (value != null) setState(() => _permiso = value);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'La deuda se activa cuando la contraparte acepta el monto y quién debe.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      DeudaDirectaDatos(
        nombre: _nombre.text.trim(),
        descripcion: _descripcion.text.trim().isEmpty
            ? null
            : _descripcion.text.trim(),
        monto: Money.parseUserInput(_monto.text),
        direccion: _direccion,
        emailContraparte: _email.text.trim(),
        permisoEdicion: _permiso,
      ),
    );
  }
}

class _OperacionDialog extends StatefulWidget {
  const _OperacionDialog({
    required this.titulo,
    required this.participantes,
    required this.mostrarAtribucion,
    this.emailAtribucionInicial,
  });

  final String titulo;
  final List<ParticipanteMeta> participantes;
  final bool mostrarAtribucion;
  final String? emailAtribucionInicial;

  @override
  State<_OperacionDialog> createState() => _OperacionDialogState();
}

class _OperacionDialogState extends State<_OperacionDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _monto = TextEditingController();
  final TextEditingController _descripcion = TextEditingController();
  String? _atribucion;

  @override
  void initState() {
    super.initState();
    final Iterable<ParticipanteMeta> actuales =
        widget.participantes.where((ParticipanteMeta item) => item.actual);
    _atribucion = widget.emailAtribucionInicial ??
        (actuales.isEmpty ? null : actuales.first.email);
  }

  @override
  void dispose() {
    _monto.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _NeoFormDialog(
      title: widget.titulo,
      actions: <Widget>[
        NeoButton(
          label: 'Volver',
          variant: NeoButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        NeoButton(label: 'Registrar', onPressed: _guardar),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            NeoInput(
              controller: _monto,
              label: 'Monto',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: moneyInputFormatters,
              textInputAction: TextInputAction.next,
              validator: (String? value) {
                try {
                  if (value == null || Money.parseUserInput(value) <= Decimal.zero) {
                    return 'Ingresa un monto mayor que cero.';
                  }
                } on FormatException {
                  return 'Ingresa un monto válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            NeoInput(
              controller: _descripcion,
              label: 'Descripción',
              textInputAction: TextInputAction.done,
              validator: (String? value) => value == null || value.trim().isEmpty
                  ? 'Describe el movimiento.'
                  : null,
            ),
            if (widget.mostrarAtribucion && widget.participantes.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _atribucion,
                decoration: const InputDecoration(
                  labelText: 'Movimiento atribuido a',
                  helperText: 'Si lo registras por otra persona, quedará pendiente.',
                ),
                items: widget.participantes
                    .map(
                      (ParticipanteMeta participante) =>
                          DropdownMenuItem<String>(
                            value: participante.email,
                            child: Text(
                              '${participante.nombre}${participante.actual ? ' (tú)' : ''}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                    )
                    .toList(growable: false),
                onChanged: (String? value) => setState(() => _atribucion = value),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      OperacionFormValue(
        monto: Money.parseUserInput(_monto.text),
        descripcion: _descripcion.text.trim(),
        emailAtribucion: _atribucion,
      ),
    );
  }
}

class _MontoDialog extends StatefulWidget {
  const _MontoDialog({
    required this.titulo,
    required this.etiqueta,
    required this.initial,
  });

  final String titulo;
  final String etiqueta;
  final String initial;

  @override
  State<_MontoDialog> createState() => _MontoDialogState();
}

class _MontoDialogState extends State<_MontoDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _monto =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _NeoFormDialog(
    title: widget.titulo,
    actions: <Widget>[
      NeoButton(
        label: 'Cancelar',
        variant: NeoButtonVariant.secondary,
        onPressed: () => Navigator.of(context).pop(),
      ),
      NeoButton(label: 'Proponer', onPressed: _guardar),
    ],
    child: Form(
      key: _formKey,
      child: NeoInput(
        controller: _monto,
        label: widget.etiqueta,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: moneyInputFormatters,
        validator: (String? value) {
          try {
            if (value == null || Money.parseUserInput(value) <= Decimal.zero) {
              return 'Ingresa un monto mayor que cero.';
            }
          } on FormatException {
            return 'Ingresa un monto válido.';
          }
          return null;
        },
      ),
    ),
  );

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(Money.parseUserInput(_monto.text));
  }
}

class _CambiarMetaDialog extends StatefulWidget {
  const _CambiarMetaDialog({required this.meta});
  final MetaCompartida meta;

  @override
  State<_CambiarMetaDialog> createState() => _CambiarMetaDialogState();
}

class _CambiarMetaDialogState extends State<_CambiarMetaDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _objetivo = TextEditingController(
    text: widget.meta.montoObjetivo == null
        ? ''
        : MoneyInputFormatter.format(widget.meta.montoObjetivo!),
  );
  late CalendarDate? _fecha = widget.meta.fechaLimite;

  @override
  void dispose() {
    _objetivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _NeoFormDialog(
    title: 'Proponer cambio de meta',
    actions: <Widget>[
      NeoButton(
        label: 'Cancelar',
        variant: NeoButtonVariant.secondary,
        onPressed: () => Navigator.of(context).pop(),
      ),
      NeoButton(label: 'Enviar para aprobar', onPressed: _guardar),
    ],
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          NeoInput(
            controller: _objetivo,
            label: 'Nuevo objetivo (opcional)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: moneyInputFormatters,
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) return null;
              try {
                if (Money.parseUserInput(value) <= Decimal.zero) {
                  return 'El objetivo debe ser mayor que cero.';
                }
              } on FormatException {
                return 'Ingresa un monto válido.';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _FechaLimiteSelector(
            fecha: _fecha,
            allowClear: false,
            onChanged: (CalendarDate? value) => setState(() => _fecha = value),
          ),
        ],
      ),
    ),
  );

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    if (_objetivo.text.trim().isEmpty && _fecha == widget.meta.fechaLimite) {
      return;
    }
    Navigator.of(context).pop(
      CambioMetaDatos(
        montoObjetivo: _objetivo.text.trim().isEmpty
            ? null
            : Money.parseUserInput(_objetivo.text),
        fechaLimite: _fecha == widget.meta.fechaLimite ? null : _fecha,
      ),
    );
  }
}

class _CodigoInvitacionDialog extends StatefulWidget {
  const _CodigoInvitacionDialog();

  @override
  State<_CodigoInvitacionDialog> createState() =>
      _CodigoInvitacionDialogState();
}

class _CodigoInvitacionDialogState extends State<_CodigoInvitacionDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codigo = TextEditingController();

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _NeoFormDialog(
    title: 'Aceptar con código',
    actions: <Widget>[
      NeoButton(
        label: 'Cancelar',
        variant: NeoButtonVariant.secondary,
        onPressed: () => Navigator.of(context).pop(),
      ),
      NeoButton(label: 'Continuar', onPressed: _aceptar),
    ],
    child: Form(
      key: _formKey,
      child: NeoInput(
        controller: _codigo,
        label: 'Código de invitación',
        autocorrect: false,
        enableSuggestions: false,
        validator: (String? value) =>
            value == null || value.trim().isEmpty ? 'Ingresa el código.' : null,
      ),
    ),
  );

  void _aceptar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_codigo.text.trim());
  }
}

class _FechaLimiteSelector extends StatelessWidget {
  const _FechaLimiteSelector({
    required this.fecha,
    required this.onChanged,
    this.allowClear = true,
  });

  final CalendarDate? fecha;
  final ValueChanged<CalendarDate?> onChanged;
  final bool allowClear;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Text(
          fecha == null ? 'Sin fecha límite' : 'Fecha límite: $fecha',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      TextButton.icon(
        onPressed: () async {
          final DateTime hoy = DateTime.now();
          final DateTime hoyCalendario = DateTime(hoy.year, hoy.month, hoy.day);
          final DateTime fechaActual = fecha == null
              ? hoyCalendario.add(const Duration(days: 1))
              : DateTime(fecha!.year, fecha!.month, fecha!.day);
          final DateTime? elegida = await showDatePicker(
            context: context,
            initialDate: fechaActual.isBefore(hoyCalendario)
                ? hoyCalendario
                : fechaActual,
            firstDate: hoyCalendario,
            lastDate: DateTime(2100),
          );
          if (elegida != null) {
            onChanged(CalendarDate(elegida.year, elegida.month, elegida.day));
          }
        },
        icon: const Icon(Icons.calendar_today_outlined),
        label: Text(fecha == null ? 'Elegir' : 'Cambiar'),
      ),
      if (fecha != null && allowClear)
        IconButton(
          tooltip: 'Quitar fecha',
          onPressed: () => onChanged(null),
          icon: const Icon(Icons.close),
        ),
    ],
  );
}

class _NeoFormDialog extends StatelessWidget {
  const _NeoFormDialog({
    required this.title,
    required this.child,
    required this.actions,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.72;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: NeoSurface(
        density: AppDensity.section,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.md),
              Flexible(child: SingleChildScrollView(child: child)),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: actions,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
