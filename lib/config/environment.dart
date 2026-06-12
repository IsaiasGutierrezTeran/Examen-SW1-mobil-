/// Configuración de ambiente — apunta al backend Spring Boot.
///
/// Reglas según dónde corre la app:
///   • Producción AWS (EC2 + IP estática)  → http://3.233.132.212/api
///   • Android USB / dispositivo físico    → IP de la PC en la red LAN
///   • Emulador Android (AVD)              → http://10.0.2.2:8080/api
///   • Chrome / Edge / Windows desktop     → http://localhost:8080/api
///
/// Cambia `apiUrl` según el caso de uso. Para encontrar tu IP local en Windows:
///     ipconfig | findstr IPv4
class Environment {
  /// Producción AWS: backend en la EC2 con IP estática (Elastic IP).
  static const String apiUrl = 'http://3.233.132.212/api';
  static const bool isProduction = true;

  // ─── Alternativas comentadas (descomenta la que necesites para desarrollo) ─
  // Producción AWS (EC2 + IP estática): 'http://3.233.132.212/api'
  // Dispositivo físico por USB/WiFi:    'http://<IP-DE-TU-PC>:8080/api'
  // Emulador Android oficial:           'http://10.0.2.2:8080/api'
  // Web (Chrome/Edge) o Windows nativo: 'http://localhost:8080/api'
}

/// Configuración de producción (no se usa por ahora — referencia futura)
class EnvironmentProd {
  static const String apiUrl = 'https://api.ficctuagrmbolivia.online/api';
  static const bool isProduction = true;
}
