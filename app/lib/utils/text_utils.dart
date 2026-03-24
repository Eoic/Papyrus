String maybePluralize(int count, String singular, {String? plural}) {
  if (count != 1) {
    return plural ?? "${singular}s";
  }

  return singular;
}
