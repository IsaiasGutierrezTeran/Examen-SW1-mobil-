// IA OFFLINE — Base de conocimiento local del asistente.
//
// Permite que el chatbot responda preguntas frecuentes SIN conexión a internet
// (avión / sin datos / backend caído). Hace coincidencia difusa (fuzzy) por lo
// que tolera errores de tipeo y frases mal escritas: normaliza acentos, parte en
// palabras y compara cada palabra del usuario contra las claves de cada entrada
// usando distancia de edición (Levenshtein).

class _Faq {
  final List<String> claves; // palabras/sinónimos que disparan esta respuesta
  final String respuesta;
  const _Faq(this.claves, this.respuesta);
}

class FaqOfflineService {
  // ── Base de conocimiento (editable / ampliable como un "seeder") ──
  static const List<_Faq> _base = [
    _Faq(['hola', 'buenas', 'saludos', 'hey', 'buenos', 'dias', 'tardes'],
        'Hola, soy tu asistente. Estoy en modo sin conexión, pero puedo ayudarte con dudas frecuentes sobre tus trámites. ¿Qué necesitas?'),
    _Faq(['gracias', 'agradecido', 'genial', 'perfecto'],
        '¡Con gusto! Si necesitas algo más sobre tus trámites, aquí estoy.'),
    _Faq(['iniciar', 'crear', 'empezar', 'nuevo', 'tramite', 'solicitar', 'comenzar'],
        'Para iniciar un trámite ve a "Iniciar trámite", describe lo que necesitas (puedes dictarlo por voz) y la IA te sugiere la política correcta. Confirma y se crea el trámite.'),
    _Faq(['subir', 'adjuntar', 'cargar', 'documento', 'archivo', 'pdf', 'foto'],
        'Para subir un documento, entra al trámite y toca "Subir documento". Puedes usar la cámara, la galería o elegir un archivo (PDF, Word, Excel). Si no tienes conexión, se encola y se envía solo cuando vuelva la red.'),
    _Faq(['estado', 'seguimiento', 'avance', 'progreso', 'donde', 'va', 'situacion'],
        'En "Mis trámites" ves el estado de cada uno: código, etapa actual y progreso. Toca un trámite para ver el detalle del flujo y los documentos.'),
    _Faq(['observado', 'observacion', 'rechazado', 'corregir', 'mal', 'error'],
        'Un documento "Observado" significa que el funcionario pidió corregirlo. Abre el trámite, revisa la observación y vuelve a subir el documento corregido para continuar.'),
    _Faq(['contrasena', 'clave', 'password', 'olvide', 'recuperar', 'restablecer'],
        'Si olvidaste tu contraseña, usa "Recuperar contraseña" en la pantalla de inicio de sesión. Recibirás un enlace temporal para crear una nueva.'),
    _Faq(['tarda', 'demora', 'tiempo', 'cuanto', 'plazo', 'dias'],
        'El tiempo depende de la política del trámite y de cada etapa. Puedes ver la etapa actual y el progreso en el detalle del trámite.'),
    _Faq(['voz', 'dictar', 'dictado', 'hablar', 'microfono', 'grabar'],
        'El dictado por voz te deja llenar el formulario hablando: toca el micrófono, dicta los datos y la IA los coloca en los campos. Revisa y confirma antes de enviar.'),
    _Faq(['cerrar', 'salir', 'logout', 'sesion', 'desconectar'],
        'Para cerrar sesión ve al menú/perfil y toca "Cerrar sesión". Tus datos quedan guardados de forma segura.'),
    _Faq(['offline', 'sin', 'conexion', 'internet', 'datos', 'red'],
        'La app funciona sin conexión para lo básico: ver tus trámites guardados, encolar subidas de documentos y consultarme estas preguntas. Cuando vuelva la red, todo se sincroniza.'),
    _Faq(['aprobar', 'aprobado', 'firmar', 'resolucion', 'finalizar'],
        'Cuando un trámite se aprueba, su estado cambia a "Aprobado" y puedes descargar la resolución desde el detalle del trámite.'),
    _Faq(['funcionario', 'revisa', 'quien', 'encargado', 'responsable'],
        'Cada etapa del trámite la atiende un funcionario del departamento correspondiente. En etapas paralelas pueden intervenir varios funcionarios a la vez.'),
    _Faq(['notificacion', 'aviso', 'alerta', 'mensaje'],
        'Recibes notificaciones cuando tu trámite avanza, requiere documentos o es observado. Míralas en la campana de notificaciones.'),
    _Faq(['documentos', 'requisitos', 'necesito', 'cuales', 'requeridos'],
        'Los documentos requeridos dependen de la política del trámite. Al iniciar o en cada etapa verás la lista de requisitos a adjuntar.'),
  ];

  static const String _sinRespuesta =
      'Estoy sin conexión y no tengo una respuesta exacta para eso. Intenta reformular tu pregunta, o vuelve a intentarlo cuando tengas internet para una respuesta más completa.';

  /// Devuelve la mejor respuesta local para la consulta (siempre devuelve algo).
  String responder(String consulta) {
    final tokens = _tokens(consulta);
    if (tokens.isEmpty) return _sinRespuesta;

    _Faq? mejor;
    double mejorPuntaje = 0;
    for (final faq in _base) {
      final p = _puntaje(tokens, faq.claves);
      if (p > mejorPuntaje) {
        mejorPuntaje = p;
        mejor = faq;
      }
    }
    // Umbral: al menos una palabra clave reconocida con buena similitud.
    if (mejor != null && mejorPuntaje >= 1.0) return mejor.respuesta;
    return _sinRespuesta;
  }

  // Suma, por cada palabra del usuario, el mejor parecido contra las claves.
  double _puntaje(List<String> tokens, List<String> claves) {
    double total = 0;
    for (final t in tokens) {
      double mejor = 0;
      for (final c in claves) {
        final s = _similitud(t, c);
        if (s > mejor) mejor = s;
      }
      if (mejor >= 0.8) total += mejor; // cuenta solo coincidencias fuertes
    }
    return total;
  }

  List<String> _tokens(String texto) {
    final limpio = _sinAcentos(texto.toLowerCase());
    return limpio
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.length >= 3) // ignora "de", "el", "la"...
        .toList();
  }

  String _sinAcentos(String s) {
    const map = {
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
    };
    final sb = StringBuffer();
    for (final ch in s.split('')) {
      sb.write(map[ch] ?? ch);
    }
    return sb.toString();
  }

  // Similitud 0..1 basada en distancia de Levenshtein (tolera errores de tipeo).
  double _similitud(String a, String b) {
    if (a == b) return 1.0;
    final dist = _levenshtein(a, b);
    final maxLen = a.length > b.length ? a.length : b.length;
    if (maxLen == 0) return 1.0;
    return 1.0 - dist / maxLen;
  }

  int _levenshtein(String a, String b) {
    final m = a.length, n = b.length;
    if (m == 0) return n;
    if (n == 0) return m;
    final prev = List<int>.generate(n + 1, (i) => i);
    final cur = List<int>.filled(n + 1, 0);
    for (var i = 1; i <= m; i++) {
      cur[0] = i;
      for (var j = 1; j <= n; j++) {
        final costo = a[i - 1] == b[j - 1] ? 0 : 1;
        cur[j] = [
          cur[j - 1] + 1,
          prev[j] + 1,
          prev[j - 1] + costo,
        ].reduce((x, y) => x < y ? x : y);
      }
      for (var j = 0; j <= n; j++) {
        prev[j] = cur[j];
      }
    }
    return prev[n];
  }
}
