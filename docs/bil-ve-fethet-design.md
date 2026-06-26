# Bil ve Fethet — Tasarım Notu (v2)

> Bu belge oyunun hedef tasarımını tutar. Kod buna göre şekillenir.
> (v1 prototip `map-mechanic` dalında; bu v2 onu yeniden çerçeveler.)

## Vizyon
**Kategori temelli bilgi yarışması (Bil Bakalım havası) × harita fethi (dünya
hakimiyeti hedefi).** Kalp = seçilen kategoriden gelen sorular; fetih = oyunu
saran hedef/koşul. v1'de mekanik ters taraftaydı (fetih ana, kategori süs);
burada kategori/quiz ana, fetih çerçeve.

## Akış (üst seviye)
1. **Lobi.** Ana ekrandan lobi kur/katıl. Lobi kurulurken **kategori** seçilir
   (spor, tarih, bilim, bitki, hayvan, karışık, …). **Tüm maç o kategoriden** sorulur.
2. **Mod.**
   - **Arkadaşla (özel):** oda kodu paylaş, arkadaşınla oyna.
   - **Hızlı maç (çevrimiçi):** rastgele yabancıyla eşleş.
   - **Offline (tek kişi):** AI'a karşı / kendini sına — ayrı bir mod.
3. **Maç — Bil ve Fethet.** Eşleşince harita üzerinde bölge seçersin. Fazlar:
   - **Genişleme turları:** harita boş; oyuncular sırayla soru bilerek **boş
     bölge** kapar. Boş arazi kalmayana dek sürer.
   - **Savaş turları:** harita dolunca oyuncular **birbirinin bölgesini** alır;
     **dünya fethi** koşuluyla biri tüm haritayı alana dek.
   - Tüm sorular **lobinin kategorisinden**.
4. **Sonuç & meta.** Kazanma oranı tutulur, XP verilir, (belki) ödüller.

## Kategoriler
Mevcut 6 (bilim/tarih/coğrafya/spor/sanat/eğlence) → genişlet: **bitki, hayvan,
karışık, …**. Soru bankası büyütülecek (lobinin kategorisi maçı doldurabilmeli).

## Eldeki (yeniden kullanılabilir)
- Gerçek harita render + dokunarak bölge seçimi
- Sıra tabanlı tur sistemi + **görünür rakip** + fetih/saldırı juice
- Soru akışı `QuestionRepository` seam'i üzerinden (SP↔MP aynı çekirdek)

## Değişecek / eklenecek
- Kategori **maç başına (lobi)**, kıta başına değil → v1'deki kıta–kategori
  eşlemesini kaldır.
- **İki faz:** genişleme → savaş + faz geçişi (şu an yalnız savaş benzeri var).
- **Lobi + kategori-seçim** giriş akışı.
- (Sonra) **Çoklu oyuncu:** oda kodu + hızlı eşleşme. Firestore'da lobi/maç
  state + Cloud Function ile **sunucu-otantik cevap doğrulama** (Hard rule #1).
  → **Blaze planı + Functions deploy gerekir** (şu an bekletiliyor).
- (Sonra) **Meta:** win-rate, XP, ödüller (kalıcı depolama / Firestore).

## Önerilen sıra (önce eğlenceyi kanıtla)
1. **Offline dikey dilim (Firebase yok):** kategori seç → AI'a karşı
   genişleme → savaş → dünya fethi. *"Eğlenceli mi?"* testini burada geç.
2. **Lobi/mod iskeleti + offline meta** (win-rate/XP yerelde).
3. **Çoklu oyuncu:** önce **oda-kodlu arkadaş** maçı, sonra **hızlı eşleşme**
   (Blaze açılır, Functions deploy edilir, Firestore maç state).

## Açık sorular (sonra netleşecek)
- Bir bölgeyi almak: tek soru mu, kısa tur (3'te 2) mu, merdiven mi?
- Genişleme/savaş tur kuralları: kaç bölge, sıra düzeni, eşitlik.
- Harita: 7 kıta mı, daha küçük/daha çok bölge mi (genişleme fazı için daha
  çok bölge daha iyi olabilir)?
- Çevrimiçi eşleşmede tur senkronu: gerçek-zamanlı mı, asenkron (sıra-sıra) mı?
