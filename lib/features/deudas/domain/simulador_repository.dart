import 'simulacion.dart';

/// Simulador de crédito (`POST /simulaciones/credito`, sin persistencia).
abstract interface class SimuladorRepository {
  Future<SimulacionResultado> simular(SimulacionRequest request);
}
