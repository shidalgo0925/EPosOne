/// Modificador elegido en el carrito POS (no persistido como entidad Isar).
class SelectedModifier {
  final String modifierId;
  final String groupId;
  final String groupName;
  final String name;
  final double priceDelta;

  const SelectedModifier({
    required this.modifierId,
    required this.groupId,
    required this.groupName,
    required this.name,
    this.priceDelta = 0,
  });

  Map<String, dynamic> toJson() => {
        'modifierId': modifierId,
        'groupId': groupId,
        'groupName': groupName,
        'name': name,
        'priceDelta': priceDelta,
      };

  factory SelectedModifier.fromJson(Map<String, dynamic> json) => SelectedModifier(
        modifierId: json['modifierId'] as String,
        groupId: json['groupId'] as String,
        groupName: json['groupName'] as String? ?? '',
        name: json['name'] as String,
        priceDelta: (json['priceDelta'] as num?)?.toDouble() ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedModifier && runtimeType == other.runtimeType && modifierId == other.modifierId;

  @override
  int get hashCode => modifierId.hashCode;
}
