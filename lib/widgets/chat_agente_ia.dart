// C3 Guía 2F — Chat del Agente Conversacional de IA (CU-31)
// Uso (auto-contexto): showModalBottomSheet(context, builder: (_) => const ChatAgenteIA())
// Uso (contexto manual): ChatAgenteIA(pantallaActual: '...', tramiteIdOpcional: '...')

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/comunicacion_service.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';

class ChatAgenteIA extends StatefulWidget {
  // Si se omiten, el chat deduce el contexto desde el routing actual.
  final String? pantallaActual;
  final String? tramiteIdOpcional;

  const ChatAgenteIA({
    super.key,
    this.pantallaActual,
    this.tramiteIdOpcional,
  });

  @override
  State<ChatAgenteIA> createState() => _ChatAgenteIAState();
}

class _ChatAgenteIAState extends State<ChatAgenteIA> {
  late ComunicacionService comunicacionService;
  final List<_Mensaje> _mensajes = [];
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _esperando = false;

  late final String _modulo;
  late final String? _tramiteId;

  @override
  void initState() {
    super.initState();
    comunicacionService = Get.find<ComunicacionService>();
    _modulo = widget.pantallaActual ?? _modeloDesdeRuta(Get.currentRoute);
    _tramiteId = widget.tramiteIdOpcional ?? _extraerTramiteIdDeArgs();
    _mensajes.add(_Mensaje(
      texto:
          '¡Hola! Soy tu asistente virtual. Te guío paso a paso para hacer '
          'los trámites disponibles (conexión, internet, fibra, soporte, etc.). '
          'Contame qué necesitás o elegí una opción de abajo.',
      esCliente: false,
    ));
  }

  static const List<String> _sugerencias = [
    '¿Qué trámites puedo hacer?',
    '¿Cómo inicio un trámite?',
    'Ver mis trámites',
    'Necesito subir un documento',
  ];

  Future<void> _enviarTexto(String texto) async {
    _ctrl.text = texto;
    await _enviar();
  }

  String _modeloDesdeRuta(String ruta) {
    if (ruta.isEmpty || ruta == '/') return 'Inicio';
    return ruta;
  }

  String? _extraerTramiteIdDeArgs() {
    final args = Get.arguments;
    if (args is String && args.length >= 8) return args;
    if (args is Map) {
      final v = args['tramiteId'] ?? args['id'];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _ctrl.text.trim();
    if (texto.isEmpty || _esperando) return;

    setState(() {
      _mensajes.add(_Mensaje(texto: texto, esCliente: true));
      _ctrl.clear();
      _esperando = true;
    });
    _scrollAbajo();

    final res = await comunicacionService.consultarAgenteIA(
      texto,
      _modulo,
      tramiteIdOpcional: _tramiteId,
    );

    final accion = res['accion'];
    setState(() {
      _mensajes.add(_Mensaje(
        texto: res['respuesta'] ?? 'Sin respuesta.',
        esCliente: false,
        accionLabel: accion is Map ? accion['label'] as String? : null,
        accionRuta: accion is Map ? accion['ruta'] as String? : null,
        accionTipo: accion is Map ? accion['tipo'] as String? : null,
        accionDato: accion is Map ? accion['dato'] as String? : null,
      ));
      _esperando = false;
    });
    _scrollAbajo();
  }

  /// El agente devuelve rutas del WEB (/cliente/...). Las traducimos a las del
  /// móvil; si no hay equivalente, devolvemos null (y se oculta el botón).
  String? _rutaMovil(String? rutaWeb) {
    if (rutaWeb == null || rutaWeb.isEmpty) return null;
    final r = rutaWeb.toLowerCase();
    if (r.contains('notif')) return AppRoutes.notificaciones;
    if (r.contains('perfil') || r.contains('cuenta')) return AppRoutes.perfil;
    if (r.contains('catalogo') || r.contains('nuevo') || r.contains('iniciar')) {
      return AppRoutes.catalogoTramites;
    }
    if (r.contains('tramite') || r.contains('expediente')) {
      return AppRoutes.misTramites;
    }
    return null;
  }

  void _ejecutarAccion(_Mensaje m) {
    // Recomendación: iniciar directamente el trámite sugerido (con su id).
    if (m.accionTipo == 'iniciar' &&
        m.accionDato != null &&
        m.accionDato!.isNotEmpty) {
      Get.back();
      Get.toNamed('/tramite-nuevo', arguments: m.accionDato);
      return;
    }
    final mapeada = _rutaMovil(m.accionRuta);
    if (mapeada == null) return;
    Get.back();
    Get.toNamed(mapeada);
  }

  void _scrollAbajo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Cabecera con gradiente de marca
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.smart_toy_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 11),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Asistente virtual',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4ADE80),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'En línea · te guía con tus trámites',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
          ),

          // Mensajes
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                for (final m in _mensajes) _buildBurbuja(m),
                if (_esperando) _buildEscribiendo(),
                if (!_esperando && _mensajes.length <= 1) _buildSugerencias(),
              ],
            ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.fondo,
              border: Border(top: BorderSide(color: AppColors.borde)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'Escribe tu consulta…',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.superficie,
                    ),
                    onSubmitted: (_) => _enviar(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _esperando ? null : _enviar,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: _esperando ? null : AppColors.brandGradient,
                      color: _esperando ? AppColors.borde : null,
                      shape: BoxShape.circle,
                      boxShadow: _esperando
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBurbuja(_Mensaje m) {
    final esIniciar =
        m.accionTipo == 'iniciar' && (m.accionDato?.isNotEmpty ?? false);
    final mostrarAccion = !m.esCliente &&
        m.accionLabel != null &&
        (esIniciar || _rutaMovil(m.accionRuta) != null);
    return Align(
      alignment: m.esCliente ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            m.esCliente ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.74),
            decoration: BoxDecoration(
              gradient: m.esCliente ? AppColors.brandGradient : null,
              color: m.esCliente ? null : Colors.white,
              border: m.esCliente
                  ? null
                  : Border.all(color: AppColors.borde),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(m.esCliente ? 18 : 4),
                bottomRight: Radius.circular(m.esCliente ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: (m.esCliente ? AppColors.primary : Colors.black)
                      .withValues(alpha: m.esCliente ? 0.25 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              m.texto,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: m.esCliente ? Colors.white : const Color(0xFF1D1B23),
              ),
            ),
          ),
          if (mostrarAccion)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: Text(m.accionLabel!),
                onPressed: () => _ejecutarAccion(m),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Burbuja "escribiendo" con puntos animados.
  Widget _buildEscribiendo() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: _TypingDots(),
      ),
    );
  }

  /// Chips de sugerencia (guía) que se muestran al inicio.
  Widget _buildSugerencias() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _sugerencias.map((s) {
          return InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: _esperando ? null : () => _enviarTexto(s),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: Text(
                s,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Tres puntos que pulsan para indicar que el asistente escribe.
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borde),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t = (_c.value + i * 0.25) % 1.0;
              final escala = 0.6 + 0.4 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Transform.scale(
                  scale: escala,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                          alpha: 0.4 + 0.6 * escala),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _Mensaje {
  final String texto;
  final bool esCliente;
  final String? accionLabel;
  final String? accionRuta;
  final String? accionTipo;
  final String? accionDato;
  _Mensaje({
    required this.texto,
    required this.esCliente,
    this.accionLabel,
    this.accionRuta,
    this.accionTipo,
    this.accionDato,
  });
}
