// Arayüzdeki tüm Türkçe metinler burada toplanır.

class S {
  // Genel
  static const appName = 'EventApp';
  static const save = 'Kaydet';
  static const cancel = 'Vazgeç';
  static const next = 'Devam';
  static const back = 'Geri';
  static const loading = 'Yükleniyor...';
  static const errorGeneric = 'Bir hata oluştu. Tekrar dene.';

  // Auth
  static const login = 'Giriş Yap';
  static const register = 'Kayıt Ol';
  static const email = 'E-posta';
  static const password = 'Şifre';
  static const noAccount = 'Hesabın yok mu? Kayıt ol';
  static const haveAccount = 'Zaten hesabın var mı? Giriş yap';
  static const passwordTooShort = 'Şifre en az 6 karakter olmalı';
  static const invalidEmail = 'Geçerli bir e-posta gir';

  // Onboarding
  static const profileTitle = 'Profilini Oluştur';
  static const username = 'Kullanıcı adı';
  static const usernameRequired = 'Kullanıcı adı gerekli';
  static const addPhoto = 'Fotoğraf ekle (opsiyonel)';

  // Profil düzenleme
  static const editProfileTitle = 'Profili Düzenle';
  static const editProfile = 'Profili düzenle';
  static const profileSaved = 'Profil güncellendi';
  static const changePhoto = 'Fotoğrafı değiştir';

  // Görsel seçimi
  static const imageTooLarge =
      'Görsel çok büyük. Lütfen daha küçük bir fotoğraf seç.';
  static const imagePickFailed = 'Fotoğraf alınamadı. Tekrar dene.';
  static const interestsTitle = 'Hangi etkinliklerle ilgileniyorsun?';
  static const interestsSubtitle = 'Birden fazla seçebilirsin';
  static const finish = 'Bitir';

  // Ana ekran
  static const myInvites = 'Davetlerim';
  static const myEvents = 'Etkinliklerim';
  static const createEvent = 'Etkinlik Oluştur';
  static const noInvites = 'Henüz davet yok';
  static const noEvents = 'Henüz etkinlik oluşturmadın';

  // Event oluşturma
  static const chooseType = 'Etkinlik Tipi Seç';
  static const eventTitle = 'Etkinlik başlığı';
  static const eventImage = 'Etkinlik görseli';
  static const changeImage = 'Görseli değiştir';
  static const startDate = 'Başlangıç';
  static const endDate = 'Bitiş';
  static const location = 'Konum';
  static const useGps = 'Haritadan işaretle (GPS)';
  static const useText = 'Metin olarak gir';
  static const locationHint = 'Örn: Kadıköy, sahil';
  static const invitees = 'Davetliler';
  static const selectInvitees = 'Kişi seç';
  static const noShowTitle = 'Gelmeyenlere mesaj';
  static const noShowHint = 'Etkinlik bitince gelmeyenlere gidecek mesaj';
  static const noShowImage = 'Gelmeyenlere görsel (opsiyonel)';
  static const sendInvites = 'Davetleri Gönder';
  static const endMustBeAfterStart = 'Bitiş, başlangıçtan sonra olmalı';

  // RSVP
  static const willAttend = 'Katılacağım';
  static const wontAttend = 'Katılmayacağım';
  static const yourResponse = 'Cevap';

  // Event detay
  static const attending = 'Katılacaklar';
  static const notAttending = 'Katılmayacaklar';
  static const pending = 'Yanıt bekleniyor';
  static const deleteEvent = 'Etkinliği Sil';

  // Kaçırdıklarım
  static const missedTitle = 'Kaçırdıklarım';
  static const noMissed = 'Kaçırdığın etkinlik yok';
  static const missedDismiss = 'Kaldır';
  static const missedHostLabel = 'Düzenleyen';

  // Bildirim
  static const inviteNotifTitle = 'Yeni etkinlik daveti';
  static String inviteNotifBody(String host, String title) =>
      '$host seni "$title" etkinliğine davet etti';
}
