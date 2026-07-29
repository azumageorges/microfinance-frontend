/// Modèle de données de la carte membre.
///
/// Correspond au payload retourné par :
///   GET  /api/cartes/{clientId}
///   POST /api/cartes/generer/{clientId}
class CarteModel {
  final String numeroMembre;
  final String numeroClient;
  final String nomComplet;
  final String telephone;
  final String cheminPhoto;
  final String dateExpiration;
  final String donneesQr;
  final String qrCodeBase64;
  final String dateGeneration;

  const CarteModel({
    required this.numeroMembre,
    required this.numeroClient,
    required this.nomComplet,
    required this.telephone,
    required this.cheminPhoto,
    required this.dateExpiration,
    required this.donneesQr,
    required this.qrCodeBase64,
    required this.dateGeneration,
  });

  factory CarteModel.fromJson(Map<String, dynamic> json) => CarteModel(
        numeroMembre:   json['numeroMembre']   as String? ?? '',
        numeroClient:   json['numeroClient']   as String? ?? '',
        nomComplet:     json['nomComplet']      as String? ?? '',
        telephone:      json['telephone']       as String? ?? '',
        cheminPhoto:    json['cheminPhoto']     as String? ?? '',
        dateExpiration: json['dateExpiration'] as String? ?? '',
        donneesQr:      json['donneesQr']       as String? ?? '',
        qrCodeBase64:   json['qrCodeBase64']   as String? ?? '',
        dateGeneration: json['dateGeneration'] as String? ?? '',
      );
}
