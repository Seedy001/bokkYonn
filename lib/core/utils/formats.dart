// Petites fonctions de mise en forme en français, partagées par les écrans.

const _jours = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];
const _mois = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

// Ex : "Lundi 28 septembre"
String dateFr(DateTime d) =>
    '${_jours[d.weekday - 1]} ${d.day} ${_mois[d.month - 1]}';

// Ex : "17h45"
String heureFr(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';

// Ex : 1500 -> "1 500"
String prixFr(int prix) {
  final s = prix.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}
