# Depo Yönetim Sistemi

Bu proje, bir depo yönetim sistemi oluşturmak için Bash betikleri kullanarak geliştirilmiştir. Proje, ürünlerin eklenmesi, güncellenmesi, silinmesi, kullanıcı yönetimi ve raporlama gibi temel işlemleri gerçekleştirmeyi sağlar. Ayrıca, veritabanı dosyaları (CSV formatında) kullanılarak ürün ve kullanıcı verilerini yönetir.

- Projenin Demo Videosu : https://youtu.be/gZf9GKZM3TE

## Özellikler

- **Ürün Yönetimi**
  - Ürün ekleme, güncelleme, silme
  - Ürün bilgilerini görüntüleme (Ürün No, Ürün Adı, Kategori, Stok Miktarı, Birim Fiyat)
  
- **Kullanıcı Yönetimi**
  - Kullanıcı ekleme, güncelleme, silme
  - Kullanıcı bilgilerini görüntüleme (ID, Kullanıcı Adı, Yetki, Blok Durumu)
  
- **Raporlama**
  - Stokta azalan ürünler
  - En yüksek stok miktarına sahip ürünler
  
- **Yedekleme ve Güncelleme**
  - Veritabanı yedekleme (Yedekleme sadece ürün ve kullanıcı verilerini içerir)
  - Ürün ve kullanıcı bilgilerini güncelleme
  
- **Geri Dönüşüm ve Hata Kaydı Görüntüleme**
  - Sistem loglarını görüntüleme

## Başlangıç

Bu projeyi kullanmaya başlamak için aşağıdaki adımları izleyebilirsiniz:

### Gereksinimler
- Linux işletim sistemi
- `bash` yüklü
- `zenity` yüklü (grafik arayüz için)

### Kurulum

1. Bu projeyi GitHub'dan indirin veya bir zip dosyası olarak alın:
   ```bash
   git clone https://github.com/YusufBalmumcu/zenity-depo-yonetim-sistemi.git

### Kullanım

1. **Ana Menü**:
   Program başladığında, bir ana menü açılır. Buradan istediğiniz işlemi seçebilirsiniz:
   - Ürün Yönetimi
   - Kullanıcı Yönetimi
   - Raporlar
   - Yedekleme
   - Çıkış

2. **Ürün Yönetimi**:
   Ürünleri ekleyebilir, güncelleyebilir, silebilir ve listeleyebilirsiniz.

3. **Kullanıcı Yönetimi**:
   Kullanıcıları ekleyebilir, güncelleyebilir, silebilir ve listeleyebilirsiniz.

4. **Raporlama**:
   Stokta azalan ürünleri ve en yüksek stok miktarına sahip ürünleri görüntüleyebilirsiniz.

5. **Yedekleme**:
   Depo ve kullanıcı verilerini yedekleyebilirsiniz.

6. **Güncelleme ve Yönetim**:
   Hem ürünler hem de kullanıcılar için güncellemeler yapabilirsiniz.

### Script Dosyaları

- `main.sh`: Ana program dosyası. Diğer script dosyalarını çağıran ana script'tir.
- `depo_islemleri.sh`: Ürün yönetimi ile ilgili işlemleri içerir (ekleme, silme, güncelleme, listeleme).
- `kullanici_islemleri.sh`: Kullanıcı yönetimi ile ilgili işlemleri içerir (ekleme, silme, güncelleme, listeleme).
- `rapor_islemleri.sh`: Ürün raporlama işlemleri.
- `yedekleme.sh`: Veritabanı yedekleme işlemleri.


## Lisans

Bu proje [MIT Lisansı](https://opensource.org/licenses/MIT) ile lisanslanmıştır.

