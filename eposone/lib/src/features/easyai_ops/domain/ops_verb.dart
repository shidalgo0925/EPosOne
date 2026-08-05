/// Verbos canónicos de herramientas EasyAI (ADR-017).
enum OpsVerb {
  consultar,
  analizar,
  crear,
  actualizar,
  cancelar,
  cerrar,
  abrir,
}

extension OpsVerbX on OpsVerb {
  String get id => name;

  bool get isWrite {
    switch (this) {
      case OpsVerb.consultar:
      case OpsVerb.analizar:
        return false;
      case OpsVerb.crear:
      case OpsVerb.actualizar:
      case OpsVerb.cancelar:
      case OpsVerb.cerrar:
      case OpsVerb.abrir:
        return true;
    }
  }
}
