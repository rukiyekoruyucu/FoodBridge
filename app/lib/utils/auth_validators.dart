class AuthValidators {
  static String? email(String email) {
    final v = email.trim();
    if (v.isEmpty) return "E-posta gerekli";

    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!regex.hasMatch(v)) return "Geçerli bir e-posta gir";

    return null;
  }

  static String? password(String password) {
    if (password.isEmpty) return "Şifre gerekli";
    if (password.length < 6) return "Şifre en az 6 karakter olmalı";
    return null;
  }

  static String? confirmPassword(String password, String confirm) {
    if (confirm.isEmpty) return "Şifre tekrar gerekli";
    if (password != confirm) return "Şifreler eşleşmiyor";
    return null;
  }

  static String? username(String username) {
    final v = username.trim();
    if (v.isEmpty) return "Kullanıcı adı gerekli";
    if (v.length < 3) return "Kullanıcı adı en az 3 karakter olmalı";

    // Şu anki kuralı koruyoruz (sende böyle). Nokta/tire istiyorsan regex’i değiştir.
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
      return "Kullanıcı adı sadece harf, rakam ve _ içerebilir";
    }
    return null;
  }

  static String? fullName(String name) {
    final v = name.trim();
    if (v.isEmpty) return "Ad Soyad gerekli";
    if (v.length < 2) return "Ad Soyad çok kısa";
    return null;
  }

  // ✅ Eksik olanlar: corporate alanlar
  static String? companyName(String v) {
    if (v.trim().isEmpty) return "Şirket adı gerekli";
    return null;
  }

  static String? location(String v) {
    if (v.trim().isEmpty) return "Konum gerekli";
    return null;
  }
}
