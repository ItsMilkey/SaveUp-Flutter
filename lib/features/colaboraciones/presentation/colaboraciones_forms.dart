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

  static Future<DeudaGrupalDatos?> crearDeudaGrupal(
    BuildContext context, {
    required String emailPropio,
    required String nombrePropio,
  }) => showDialog<DeudaGrupalDatos>(
    context: context,
    builder: (_) => _CrearDeudaGrupalDialog(
      emailPropio: emailPropio,
      nombrePropio: nombrePropio,
    ),
  );

  static Future<PagoGrupalDatos?> registrarPagoGrupal(
    BuildContext context, {
    required DeudaGrupal deuda,
    required String emailPropio,
  }) => showDialog<PagoGrupalDatos>(
    context: context,
    builder: (_) => _PagoGrupalDialog(deuda: deuda, emailPropio: emailPropio),
  );

  static Future<RepartoDatos?> proponerCambioReparto(
    BuildContext context, {
    required DeudaGrupal deuda,
  }) => showDialog<RepartoDatos>(
    context: context,
    builder: (_) => _RepartoDialog(deuda: deuda),
  );

  static Future<SalidaDeudaDatos?> salirDeudaGrupal(
    BuildContext context, {
    required DeudaGrupal deuda,
    required String emailPropio,
  }) => showDialog<SalidaDeudaDatos>(
    context: context,
    builder: (_) => _SalidaDeudaDialog(deuda: deuda, emailPropio: emailPropio),
  );

  static Future<AdelantoFormValue?> registrarAdelanto(
    BuildContext context, {
    required OperacionColaborativa operacion,
    required String emailPropio,
  }) => showDialog<AdelantoFormValue>(
    context: context,
    builder: (_) => _AdelantoDialog(
      operacion: operacion,
      emailPropio: emailPropio,
    ),
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

class AdelantoFormValue {
  const AdelantoFormValue({required this.email, required this.monto});

  final String email;
  final Decimal monto;
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

/// Montos de una persona dentro de un formulario grupal: correo editable o
/// fijo (la persona creadora) más un campo de dinero.
class _MontoPersonaControllers {
  _MontoPersonaControllers({this.emailFijo, String? emailInicial})
    : email = TextEditingController(text: emailFijo ?? emailInicial ?? ''),
      monto = TextEditingController();

  final String? emailFijo;
  final TextEditingController email;
  final TextEditingController monto;

  void dispose() {
    email.dispose();
    monto.dispose();
  }

  bool get esPropio => emailFijo != null;
}

class _CrearDeudaGrupalDialog extends StatefulWidget {
  const _CrearDeudaGrupalDialog({
    required this.emailPropio,
    required this.nombrePropio,
  });

  final String emailPropio;
  final String nombrePropio;

  @override
  State<_CrearDeudaGrupalDialog> createState() =>
      _CrearDeudaGrupalDialogState();
}

class _CrearDeudaGrupalDialogState extends State<_CrearDeudaGrupalDialog> {
  static const int _maximoParticipantes = 10;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _acreedor = TextEditingController();
  final TextEditingController _total = TextEditingController();
  final List<_MontoPersonaControllers> _participantes =
      <_MontoPersonaControllers>[];
  final List<(TextEditingController, CalendarDate?)> _cuotas =
      <(TextEditingController, CalendarDate?)>[];
  PermisoEdicionCompartida _permiso = PermisoEdicionCompartida.soloCreador;
  String? _errorSuma;

  @override
  void initState() {
    super.initState();
    _participantes.add(
      _MontoPersonaControllers(
        emailFijo: widget.emailPropio,
        emailInicial: widget.nombrePropio,
      ),
    );
    _participantes.add(_MontoPersonaControllers());
    // Los atajos de reparto dependen del total escrito: reaccionar al texto.
    _total.addListener(_reaccionarATexto);
  }

  void _reaccionarATexto() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nombre.dispose();
    _acreedor.dispose();
    _total.dispose();
    for (final _MontoPersonaControllers participante in _participantes) {
      participante.dispose();
    }
    for (final (monto, _) in _cuotas) {
      monto.dispose();
    }
    super.dispose();
  }

  Decimal? get _totalParseado {
    if (_total.text.trim().isEmpty) return null;
    try {
      final Decimal valor = Money.parseUserInput(_total.text);
      return valor > Decimal.zero ? valor : null;
    } on FormatException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _NeoFormDialog(
      title: 'Deuda compartida con un tercero',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            NeoInput(
              controller: _nombre,
              label: 'Nombre de la deuda',
              textInputAction: TextInputAction.next,
              validator: (String? value) => value == null || value.trim().isEmpty
                  ? 'Ingresa un nombre.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            NeoInput(
              controller: _acreedor,
              label: 'Acreedor externo',
              hint: 'Tienda, financiera o persona',
              textInputAction: TextInputAction.next,
              validator: (String? value) => value == null || value.trim().isEmpty
                  ? 'Indica a quién se le debe.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            NeoInput(
              controller: _total,
              label: 'Total pendiente',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: moneyInputFormatters,
              textInputAction: TextInputAction.next,
              validator: (String? value) {
                try {
                  if (value == null ||
                      Money.parseUserInput(value) <= Decimal.zero) {
                    return 'Ingresa un monto mayor que cero.';
                  }
                } on FormatException {
                  return 'Ingresa un monto válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<PermisoEdicionCompartida>(
              initialValue: _permiso,
              decoration: const InputDecoration(
                labelText: 'Quién puede proponer cambios',
              ),
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
            const SizedBox(height: AppSpacing.md),
            NeoSectionHeader(title: 'Responsabilidades'),
            Text(
              'La suma de las responsabilidades debe coincidir con el total.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (int i = 0; i < _participantes.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: _participantes[i].esPropio
                          ? Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Text(
                                'Tú (${widget.nombrePropio})',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            )
                          : NeoInput(
                              controller: _participantes[i].email,
                              label: 'Correo',
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (String? value) =>
                                  value == null || !value.trim().contains('@')
                                  ? 'Ingresa un correo válido.'
                                  : null,
                            ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: NeoInput(
                        controller: _participantes[i].monto,
                        label: 'Responsabilidad',
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: moneyInputFormatters,
                        validator: (String? value) {
                          try {
                            if (value == null ||
                                Money.parseUserInput(value) <= Decimal.zero) {
                              return 'Mayor que cero.';
                            }
                          } on FormatException {
                            return 'Monto inválido.';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: NeoIconButton(
                          icon: Icons.remove_circle_outline,
                          tooltip: 'Quitar persona',
                          variant: NeoIconButtonVariant.ghost,
                          onPressed: () =>
                              setState(() => _participantes.removeAt(i).dispose()),
                        ),
                      ),
                  ],
                ),
              ),
            Wrap(
              spacing: AppSpacing.sm,
              children: <Widget>[
                NeoButton(
                  label: 'Agregar persona',
                  icon: Icons.person_add_alt_outlined,
                  variant: NeoButtonVariant.secondary,
                  onPressed: _participantes.length >= _maximoParticipantes
                      ? null
                      : () => setState(
                          () => _participantes.add(_MontoPersonaControllers()),
                        ),
                ),
                NeoButton(
                  label: 'Reparto equitativo',
                  icon: Icons.balance_outlined,
                  variant: NeoButtonVariant.ghost,
                  onPressed: _totalParseado == null || _participantes.isEmpty
                      ? null
                      : _repartirEquitativo,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            NeoSectionHeader(title: 'Cuotas (opcional)'),
            Text(
              'Describen pagos acordados con el acreedor; no registran pagos.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (int i = 0; i < _cuotas.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: NeoInput(
                        controller: _cuotas[i].$1,
                        label: 'Cuota ${i + 1} · monto',
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: moneyInputFormatters,
                        validator: (String? value) {
                          try {
                            if (value == null ||
                                Money.parseUserInput(value) <= Decimal.zero) {
                              return 'Mayor que cero.';
                            }
                          } on FormatException {
                            return 'Monto inválido.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _FechaLimiteSelector(
                          fecha: _cuotas[i].$2,
                          onChanged: (CalendarDate? value) => setState(() {
                            final (monto, _) = _cuotas[i];
                            _cuotas[i] = (monto, value);
                          }),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: NeoIconButton(
                        icon: Icons.remove_circle_outline,
                        tooltip: 'Quitar cuota',
                        variant: NeoIconButtonVariant.ghost,
                        onPressed: () => setState(() {
                          final (monto, _) = _cuotas.removeAt(i);
                          monto.dispose();
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            Wrap(
              spacing: AppSpacing.sm,
              children: <Widget>[
                NeoButton(
                  label: 'Agregar cuota',
                  icon: Icons.add,
                  variant: NeoButtonVariant.secondary,
                  onPressed: () => setState(
                    () => _cuotas.add((TextEditingController(), null)),
                  ),
                ),
                NeoButton(
                  label: 'Cuotas iguales',
                  icon: Icons.calendar_view_month_outlined,
                  variant: NeoButtonVariant.ghost,
                  onPressed: _totalParseado == null ? null : _generarCuotas,
                ),
              ],
            ),
            if (_errorSuma != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _errorSuma!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _repartirEquitativo() {
    final Decimal? total = _totalParseado;
    if (total == null) return;
    final List<Decimal> partes = repartirEquitativo(total, _participantes.length);
    for (int i = 0; i < _participantes.length; i++) {
      _participantes[i].monto.text = MoneyInputFormatter.format(partes[i]);
    }
    setState(() => _errorSuma = null);
  }

  Future<void> _generarCuotas() async {
    final Decimal? total = _totalParseado;
    if (total == null) return;
    final int? cantidad = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) => _CantidadCuotasDialog(),
    );
    if (cantidad == null || cantidad <= 0) return;
    final List<Decimal> partes = repartirEquitativo(total, cantidad);
    final DateTime hoy = DateTime.now();
    for (final (monto, _) in _cuotas) {
      monto.dispose();
    }
    _cuotas.clear();
    for (int i = 0; i < cantidad; i++) {
      final DateTime fecha = DateTime(hoy.year, hoy.month + i + 1, hoy.day);
      final TextEditingController monto = TextEditingController()
        ..text = MoneyInputFormatter.format(partes[i]);
      _cuotas.add(
        (monto, CalendarDate(fecha.year, fecha.month, fecha.day)),
      );
    }
    setState(() => _errorSuma = null);
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final Decimal total = Money.parseUserInput(_total.text);
    final List<ResponsabilidadParticipante> responsabilidades =
        <ResponsabilidadParticipante>[];
    final Set<String> correos = <String>{};
    for (final _MontoPersonaControllers participante in _participantes) {
      final String email = participante.esPropio
          ? widget.emailPropio
          : participante.email.text.trim();
      if (!correos.add(email.toLowerCase())) {
        setState(() => _errorSuma = 'Los correos no pueden repetirse.');
        return;
      }
      responsabilidades.add(
        ResponsabilidadParticipante(
          email: email,
          monto: Money.parseUserInput(participante.monto.text),
        ),
      );
    }
    final Decimal suma = responsabilidades
        .map((ResponsabilidadParticipante r) => r.monto)
        .reduce((Decimal a, Decimal b) => a + b);
    if (suma != total) {
      setState(
        () => _errorSuma =
            'La suma de responsabilidades ($suma) no coincide con el total ($total).',
      );
      return;
    }
    final List<CuotaGrupalDatos> cuotas = <CuotaGrupalDatos>[];
    for (final (monto, fecha) in _cuotas) {
      if (monto.text.trim().isEmpty) continue;
      if (fecha == null) {
        setState(() => _errorSuma = 'Cada cuota necesita su fecha de vencimiento.');
        return;
      }
      cuotas.add(
        CuotaGrupalDatos(
          monto: Money.parseUserInput(monto.text),
          fechaVencimiento: fecha,
        ),
      );
    }
    if (cuotas.isNotEmpty) {
      final Decimal sumaCuotas = cuotas
          .map((CuotaGrupalDatos cuota) => cuota.monto)
          .reduce((Decimal a, Decimal b) => a + b);
      if (sumaCuotas != total) {
        setState(
          () => _errorSuma =
              'La suma de las cuotas ($sumaCuotas) no coincide con el total ($total).',
        );
        return;
      }
    }
    Navigator.of(context).pop(
      DeudaGrupalDatos(
        nombre: _nombre.text.trim(),
        acreedorExterno: _acreedor.text.trim(),
        montoTotal: total,
        permisoEdicion: _permiso,
        participantes: responsabilidades,
        cuotas: cuotas,
      ),
    );
  }
}

class _CantidadCuotasDialog extends StatefulWidget {
  @override
  State<_CantidadCuotasDialog> createState() => _CantidadCuotasDialogState();
}

class _CantidadCuotasDialogState extends State<_CantidadCuotasDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _cantidad = TextEditingController();

  @override
  void dispose() {
    _cantidad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _NeoFormDialog(
    title: 'Cuotas iguales',
    actions: <Widget>[
      NeoButton(
        label: 'Cancelar',
        variant: NeoButtonVariant.secondary,
        onPressed: () => Navigator.of(context).pop(),
      ),
      NeoButton(
        label: 'Generar',
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.of(context).pop(int.parse(_cantidad.text.trim()));
        },
      ),
    ],
    child: Form(
      key: _formKey,
      child: NeoInput(
        controller: _cantidad,
        label: '¿Cuántas cuotas mensuales?',
        keyboardType: TextInputType.number,
        validator: (String? value) {
          final int? cantidad = value == null ? null : int.tryParse(value.trim());
          if (cantidad == null || cantidad < 1 || cantidad > 36) {
            return 'Ingresa entre 1 y 36 cuotas.';
          }
          return null;
        },
      ),
    ),
  );
}

class _PagoGrupalDialog extends StatefulWidget {
  const _PagoGrupalDialog({required this.deuda, required this.emailPropio});

  final DeudaGrupal deuda;
  final String emailPropio;

  @override
  State<_PagoGrupalDialog> createState() => _PagoGrupalDialogState();
}

class _PagoGrupalDialogState extends State<_PagoGrupalDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _monto = TextEditingController();
  final TextEditingController _descripcion = TextEditingController();
  final Map<String, TextEditingController> _imputaciones =
      <String, TextEditingController>{};
  String? _errorSuma;

  @override
  void initState() {
    super.initState();
    for (final ParticipanteDeudaGrupal participante in widget.deuda.activos) {
      _imputaciones[participante.email] = TextEditingController();
    }
    // Los atajos de imputación dependen del monto escrito: reaccionar al texto.
    _monto.addListener(_reaccionarATexto);
    _sugerir();
  }

  void _reaccionarATexto() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _monto.dispose();
    _descripcion.dispose();
    for (final TextEditingController controller in _imputaciones.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Decimal? get _montoParseado {
    if (_monto.text.trim().isEmpty) return null;
    try {
      final Decimal valor = Money.parseUserInput(_monto.text);
      return valor > Decimal.zero ? valor : null;
    } on FormatException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _NeoFormDialog(
      title: 'Pagar a ${widget.deuda.acreedorExterno}',
      actions: <Widget>[
        NeoButton(
          label: 'Cancelar',
          variant: NeoButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        NeoButton(label: 'Registrar pago', onPressed: _guardar),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            NeoInput(
              controller: _monto,
              label: 'Monto pagado al acreedor',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: moneyInputFormatters,
              textInputAction: TextInputAction.next,
              validator: (String? value) {
                try {
                  if (value == null ||
                      Money.parseUserInput(value) <= Decimal.zero) {
                    return 'Ingresa un monto mayor que cero.';
                  }
                  if (Money.parseUserInput(value) >
                      widget.deuda.saldoPendiente) {
                    return 'Supera lo pendiente con el acreedor.';
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
                  ? 'Describe el pago.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            NeoSectionHeader(title: 'Imputación entre participantes'),
            Text(
              'Tu parte se aplica de inmediato; la de los demás quedará '
              'pendiente hasta que confirmen.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final ParticipanteDeudaGrupal participante
                in widget.deuda.activos)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${participante.nombre}${participante.actual ? ' (tú)' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: NeoInput(
                        controller: _imputaciones[participante.email],
                        label: 'Pendiente: '
                            '${MoneyInputFormatter.format(participante.responsabilidadPendiente)}',
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: moneyInputFormatters,
                      ),
                    ),
                  ],
                ),
              ),
            Wrap(
              spacing: AppSpacing.sm,
              children: <Widget>[
                NeoButton(
                  label: 'Sugerir proporcional',
                  icon: Icons.percent_outlined,
                  variant: NeoButtonVariant.ghost,
                  onPressed: _montoParseado == null ? null : _sugerir,
                ),
                NeoButton(
                  label: 'Reparto igualitario',
                  icon: Icons.balance_outlined,
                  variant: NeoButtonVariant.ghost,
                  onPressed: _montoParseado == null
                      ? null
                      : () => _repartirIgualitario(),
                ),
              ],
            ),
            if (_errorSuma != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _errorSuma!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _sugerir() {
    final Decimal? monto = _montoParseado;
    if (monto == null) return;
    final List<ParticipanteDeudaGrupal> activos = widget.deuda.activos;
    final List<Decimal> partes = repartirProporcional(
      monto,
      activos
          .map(
            (ParticipanteDeudaGrupal p) => p.responsabilidadPendiente,
          )
          .toList(growable: false),
    );
    for (int i = 0; i < activos.length; i++) {
      _imputaciones[activos[i].email]!
          .text = MoneyInputFormatter.format(partes[i]);
    }
    setState(() => _errorSuma = null);
  }

  void _repartirIgualitario() {
    final Decimal? monto = _montoParseado;
    if (monto == null) return;
    final List<ParticipanteDeudaGrupal> activos = widget.deuda.activos;
    final List<Decimal> partes = repartirEquitativo(monto, activos.length);
    for (int i = 0; i < activos.length; i++) {
      _imputaciones[activos[i].email]!
          .text = MoneyInputFormatter.format(partes[i]);
    }
    setState(() => _errorSuma = null);
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final Decimal monto = Money.parseUserInput(_monto.text);
    final List<ImputacionPagoDatos> imputaciones = <ImputacionPagoDatos>[];
    Decimal suma = Decimal.zero;
    for (final ParticipanteDeudaGrupal participante in widget.deuda.activos) {
      final TextEditingController controller = _imputaciones[participante.email]!;
      if (controller.text.trim().isEmpty) continue;
      final Decimal parte = Money.parseUserInput(controller.text);
      if (parte <= Decimal.zero) continue;
      if (parte > participante.responsabilidadPendiente) {
        setState(
          () => _errorSuma =
              'La parte de ${participante.nombre} supera su responsabilidad pendiente.',
        );
        return;
      }
      imputaciones.add(
        ImputacionPagoDatos(email: participante.email, monto: parte),
      );
      suma += parte;
    }
    if (imputaciones.isEmpty || suma != monto) {
      setState(
        () => _errorSuma =
            'La imputación debe sumar exactamente el monto pagado.',
      );
      return;
    }
    Navigator.of(context).pop(
      PagoGrupalDatos(
        monto: monto,
        descripcion: _descripcion.text.trim(),
        imputaciones: imputaciones,
      ),
    );
  }
}

class _RepartoDialog extends StatefulWidget {
  const _RepartoDialog({required this.deuda});

  final DeudaGrupal deuda;

  @override
  State<_RepartoDialog> createState() => _RepartoDialogState();
}

class _RepartoDialogState extends State<_RepartoDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _montos = <String, TextEditingController>{};
  String? _errorSuma;

  @override
  void initState() {
    super.initState();
    for (final ParticipanteDeudaGrupal participante in widget.deuda.activos) {
      final TextEditingController controller = TextEditingController(
        text: MoneyInputFormatter.format(participante.responsabilidadPendiente),
      );
      _montos[participante.email] = controller;
    }
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _montos.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Decimal get _totalPendiente => widget.deuda.activos
      .map((ParticipanteDeudaGrupal p) => p.responsabilidadPendiente)
      .reduce((Decimal a, Decimal b) => a + b);

  @override
  Widget build(BuildContext context) {
    return _NeoFormDialog(
      title: 'Nuevo reparto de lo pendiente',
      actions: <Widget>[
        NeoButton(
          label: 'Cancelar',
          variant: NeoButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        NeoButton(label: 'Proponer reparto', onPressed: _guardar),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Solo redistribuye lo pendiente: los pagos ya hechos no cambian. '
              'Todas las personas deben confirmar.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final ParticipanteDeudaGrupal participante
                in widget.deuda.activos)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${participante.nombre}${participante.actual ? ' (tú)' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: NeoInput(
                        controller: _montos[participante.email],
                        label: 'Actual: '
                            '${MoneyInputFormatter.format(participante.responsabilidadPendiente)}',
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: moneyInputFormatters,
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Requerido.';
                          }
                          try {
                            if (Money.parseUserInput(value) < Decimal.zero) {
                              return 'No negativo.';
                            }
                          } on FormatException {
                            return 'Monto inválido.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            NeoButton(
              label: 'Reparto equitativo',
              icon: Icons.balance_outlined,
              variant: NeoButtonVariant.ghost,
              onPressed: () {
                final List<Decimal> partes =
                    repartirEquitativo(_totalPendiente, widget.deuda.activos.length);
                for (int i = 0; i < widget.deuda.activos.length; i++) {
                  _montos[widget.deuda.activos[i].email]!
                      .text = MoneyInputFormatter.format(partes[i]);
                }
                setState(() => _errorSuma = null);
              },
            ),
            if (_errorSuma != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _errorSuma!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final List<ResponsabilidadParticipante> responsabilidades =
        <ResponsabilidadParticipante>[];
    Decimal suma = Decimal.zero;
    for (final ParticipanteDeudaGrupal participante in widget.deuda.activos) {
      final Decimal monto = Money.parseUserInput(
        _montos[participante.email]!.text,
      );
      responsabilidades.add(
        ResponsabilidadParticipante(email: participante.email, monto: monto),
      );
      suma += monto;
    }
    if (suma != _totalPendiente) {
      setState(
        () => _errorSuma =
            'La suma ($suma) debe coincidir con el total pendiente ($_totalPendiente).',
      );
      return;
    }
    Navigator.of(context).pop(RepartoDatos(responsabilidades: responsabilidades));
  }
}

class _SalidaDeudaDialog extends StatefulWidget {
  const _SalidaDeudaDialog({required this.deuda, required this.emailPropio});

  final DeudaGrupal deuda;
  final String emailPropio;

  @override
  State<_SalidaDeudaDialog> createState() => _SalidaDeudaDialogState();
}

class _SalidaDeudaDialogState extends State<_SalidaDeudaDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _montos = <String, TextEditingController>{};
  String? _errorSuma;

  ParticipanteDeudaGrupal get _propio => widget.deuda.participantes
      .firstWhere((ParticipanteDeudaGrupal p) => p.actual);

  bool get _sinPendiente =>
      _propio.responsabilidadPendiente == Decimal.zero;

  @override
  void dispose() {
    for (final TextEditingController controller in _montos.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<ParticipanteDeudaGrupal> otros = widget.deuda.activos
        .where((ParticipanteDeudaGrupal p) => !p.actual)
        .toList(growable: false);
    for (final ParticipanteDeudaGrupal participante in otros) {
      _montos.putIfAbsent(
        participante.email,
        () => TextEditingController(),
      );
    }
    return _NeoFormDialog(
      title: 'Salir de la deuda',
      actions: <Widget>[
        NeoButton(
          label: 'Cancelar',
          variant: NeoButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        NeoButton(label: _sinPendiente ? 'Salir' : 'Proponer salida', onPressed: _guardar),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (_sinPendiente)
              Text(
                'No tienes responsabilidad pendiente: puedes salir sin '
                'reasignaciones. Seguirás viendo el historial.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else ...<Widget>[
              Text(
                'Tu responsabilidad pendiente es '
                '${Money.formatClp(_propio.responsabilidadPendiente)}. '
                'Reasígnala completa; quienes la reciban deberán confirmar.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final ParticipanteDeudaGrupal participante in otros)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          participante.nombre,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      SizedBox(
                        width: 170,
                        child: NeoInput(
                          controller: _montos[participante.email],
                          label: 'Actual: '
                              '${MoneyInputFormatter.format(participante.responsabilidadPendiente)}',
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: moneyInputFormatters,
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            try {
                              if (Money.parseUserInput(value) <= Decimal.zero) {
                                return 'Mayor que cero.';
                              }
                            } on FormatException {
                              return 'Monto inválido.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              if (_errorSuma != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _errorSuma!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _guardar() {
    if (!_sinPendiente && !_formKey.currentState!.validate()) return;
    final List<ResponsabilidadParticipante> reasignaciones =
        <ResponsabilidadParticipante>[];
    if (!_sinPendiente) {
      Decimal suma = Decimal.zero;
      for (final MapEntry<String, TextEditingController> entrada
          in _montos.entries) {
        if (entrada.value.text.trim().isEmpty) continue;
        final Decimal monto = Money.parseUserInput(entrada.value.text);
        if (monto <= Decimal.zero) continue;
        reasignaciones.add(
          ResponsabilidadParticipante(email: entrada.key, monto: monto),
        );
        suma += monto;
      }
      if (suma != _propio.responsabilidadPendiente) {
        setState(
          () => _errorSuma = 'Las reasignaciones deben sumar tu pendiente '
              '(${Money.formatClp(_propio.responsabilidadPendiente)}).',
        );
        return;
      }
    }
    Navigator.of(context).pop(SalidaDeudaDatos(reasignaciones: reasignaciones));
  }
}

class _AdelantoDialog extends StatelessWidget {
  const _AdelantoDialog({required this.operacion, required this.emailPropio});

  final OperacionColaborativa operacion;
  final String emailPropio;

  @override
  Widget build(BuildContext context) {
    final List<MontoParticipante> candidatos = operacion.imputacionesPago
        .where((MontoParticipante imputacion) => imputacion.email != emailPropio)
        .toList(growable: false);
    return _NeoFormDialog(
      title: 'Registrar adelanto',
      actions: <Widget>[
        NeoButton(
          label: 'Cancelar',
          variant: NeoButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Pagaste de más por estas personas. Elige de quién dejar '
            'constancia: se creará una deuda directa que deberá aceptar.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final MontoParticipante candidato in candidatos)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: NeoSurface(
                density: AppDensity.list,
                onTap: () => Navigator.of(context).pop(
                  AdelantoFormValue(
                    email: candidato.email,
                    monto: candidato.monto,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Text(candidato.nombre)),
                    Text(
                      Money.formatClp(candidato.monto),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Reparte un monto en partes iguales con precisión de centavos; los
/// centavos restantes van a las primeras filas. Solo para prellenar
/// formularios: el backend sigue siendo la fuente de verdad del reparto.
List<Decimal> repartirEquitativo(Decimal total, int partes) {
  final BigInt centavos = _aCentavos(total);
  final BigInt base = centavos ~/ BigInt.from(partes);
  BigInt resto = centavos - base * BigInt.from(partes);
  return List<Decimal>.generate(partes, (int i) {
    BigInt extra = BigInt.zero;
    if (resto > BigInt.zero) {
      extra = BigInt.one;
      resto -= BigInt.one;
    }
    return _deCentavos(base + extra);
  });
}

/// Reparte proporcional a los pesos (en centavos, redondeo medio hacia
/// arriba); la diferencia va primero al mayor peso. Solo para prellenar
/// formularios: el backend aplica la regla definitiva.
List<Decimal> repartirProporcional(Decimal total, List<Decimal> pesos) {
  final BigInt totalCentavos = _aCentavos(total);
  final List<BigInt> pesosCentavos = pesos.map(_aCentavos).toList(growable: false);
  final BigInt sumaPesos = pesosCentavos.reduce((BigInt a, BigInt b) => a + b);
  final List<int> orden = List<int>.generate(pesos.length, (int i) => i)
    ..sort((int a, int b) => pesosCentavos[b].compareTo(pesosCentavos[a]));
  final List<BigInt> partes = List<BigInt>.generate(
    pesos.length,
    (int i) => sumaPesos == BigInt.zero
        ? BigInt.zero
        : (totalCentavos * pesosCentavos[i] + sumaPesos ~/ BigInt.two) ~/
              sumaPesos,
  );
  BigInt suma = partes.reduce((BigInt a, BigInt b) => a + b);
  int indice = 0;
  final BigInt centavo = BigInt.one;
  while (suma != totalCentavos && indice < partes.length * 100) {
    final int i = orden[indice % orden.length];
    if (suma < totalCentavos) {
      partes[i] += centavo;
      suma += centavo;
    } else {
      partes[i] -= centavo;
      suma -= centavo;
    }
    indice++;
  }
  return partes.map(_deCentavos).toList(growable: false);
}

BigInt _aCentavos(Decimal monto) =>
    (monto * Decimal.fromInt(100)).toBigInt();

Decimal _deCentavos(BigInt centavos) {
  final BigInt entero = centavos ~/ BigInt.from(100);
  final BigInt resto = centavos.abs() % BigInt.from(100);
  final String signo = centavos.isNegative ? '-' : '';
  return Decimal.parse(
    '$signo$entero.${resto.toString().padLeft(2, '0')}',
  );
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
