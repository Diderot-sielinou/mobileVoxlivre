/// Message affiché pour un code d'échec (l'interface choisit son message
/// par code, jamais d'après le texte du backend).
String authMessage(String code) => switch (code) {
  'INVALID_PHONE_NUMBER' =>
    'Entrez un numéro mobile Orange ou MTN : 9 chiffres commençant par 6.',
  'INVALID_EMAIL' =>
    'Entrez une adresse e-mail valide, par exemple nom@mail.com.',
  'INVALID_OTP' => 'Code incorrect. Vérifiez les chiffres et réessayez.',
  'OTP_EXPIRED' => 'Ce code a expiré. Demandez-en un nouveau.',
  'TOO_MANY_ATTEMPTS' => 'Trop d’essais pour ce code. Demandez-en un nouveau.',
  'OTP_RATE_LIMITED' || 'RATE_LIMITED' =>
    'Trop de demandes de code. Pour votre sécurité, réessayez dans '
        'quelques minutes.',
  'GOOGLE_SIGN_IN_UNAVAILABLE' =>
    'La connexion Google n’est pas disponible sur ce téléphone. '
        'Utilisez un code par e-mail.',
  'UNAUTHORIZED' ||
  'INVALID_TOKEN' => 'Google n’a pas pu confirmer ce compte. Réessayez.',
  'NETWORK_UNAVAILABLE' =>
    'Pas de connexion internet. Vérifiez vos données mobiles ou le Wi-Fi.',
  'TIMEOUT' => 'Le réseau est trop lent. Réessayez dans un instant.',
  _ => 'Une erreur est survenue. Réessayez dans un instant.',
};

/// Codes qui concernent la saisie (affichés sous le champ) plutôt que
/// l'écran entier (bandeau).
const fieldErrorCodes = {
  'INVALID_PHONE_NUMBER',
  'INVALID_EMAIL',
  'INVALID_OTP',
  'OTP_EXPIRED',
  'TOO_MANY_ATTEMPTS',
};

/// Codes de limitation : bandeau d'avertissement.
const rateLimitCodes = {'OTP_RATE_LIMITED', 'RATE_LIMITED'};
