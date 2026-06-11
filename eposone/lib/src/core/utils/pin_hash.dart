import 'dart:convert';

/// Hash local simple para PIN (offline, no texto plano).
String hashPin(String pin) => base64Url.encode(utf8.encode('eposone_v1_$pin'));

bool verifyPin(String pin, String pinHash) => hashPin(pin) == pinHash;
