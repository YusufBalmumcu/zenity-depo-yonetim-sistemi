#!/bin/bash

source ./kullanici_islemleri.sh
source ./depo_islemleri.sh
source ./program_islemleri.sh
source ./rapor_islemleri.sh

# Kaynak dosyalarının yolu
src_dir="./src"
depo_file="$src_dir/depo.csv"
kullanici_file="$src_dir/kullanici.csv"
log_file="$src_dir/log.csv"

# Kaynak dosyalarını kontrol et eğer yoklarsa oluştur
if [ ! -d "$src_dir" ]; then
	echo "Kaynak klasörü bulunamadı, kaynak klasörü oluşturuluyor..."
	mkdir "$src_dir"
	echo "Kaynak klasörü oluşturuldu!"
else
	echo "Kaynak klasörü bulundu!"
fi


if [ ! -f "$depo_file" ]; then
    echo "Depo dosyası bulunamadı, depo dosyası oluşturuluyor..."
    echo "urun_no,urun_adi,stok_miktari,birim_fiyat,kategori" > "$depo_file"
    echo "Depo dosyası oluşturuldu!"
else
    echo "Depo dosyası bulundu!"
fi


if [ ! -f "$kullanici_file" ]; then
	echo "Kullanıcı dosyası bulunamadı, kullanıcı dosyası oluşturuluyor..."
	echo "id, name, yetki, parola, blok" > "$kullanici_file"
	echo "Kullanıcı dosyası oluşturuldu!"
else
	echo "Kullanıcı dosyası bulundu!"
fi

if [ ! -f "$log_file" ]; then
	echo "Log dosyası bulunamadı, log dosyası oluşturuluyor..."
	echo "id, time, user, product, message" > "$log_file"
	echo "Log dosyası oluşturuldu!"
else
	echo "Log dosyası bulundu!"
fi



# Ana giriş menüsü fonksiyonu
function giris_menu() {
    while true; do
        # Zenity ile giriş menüsü
        local secim=$(zenity --list --title="Giriş Menüsü" \
            --column="İşlem Seç" \
            "1. Kullanıcı Girişi" \
            "2. Yeni Kullanıcı Oluştur" \
            "3. Çıkış")

        # Kullanıcının seçimine göre işlem
        case "$secim" in
            "1. Kullanıcı Girişi")
                # Kullanıcı girişini başarılı yaparsa ana menüyü çağır
                if kullanici_girisi; then
                    ana_menu
                fi
                ;;
            "2. Yeni Kullanıcı Oluştur")
                yeni_kullanici_olustur
                ;;
            "3. Çıkış")
                zenity --info --title="Çıkış" --text="Programdan çıkılıyor..."
                exit 0
                ;;
            *)
                zenity --error --title="Hata" --text="Lütfen geçerli bir seçim yapın!"
                ;;
        esac
    done
}


# Ana menü fonksiyonu
function ana_menu() {
	# Kullanıcının rolünü sorgula
    local user_role=$(grep "^$current_user_id," "$kullanici_file" | cut -d',' -f3)
    while true; do
        # Zenity ile ana menü
        local secim=$(zenity --list --title="Ana Menü | Giriş yapan kullanıcı: $current_user (Rol: $user_role)" \
            --column="Seçenekler" \
            "1. Ürün Ekle" \
            "2. Ürün Listele" \
            "3. Ürün Güncelle" \
            "4. Ürün Sil" \
            "5. Rapor Al" \
            "6. Kullanıcı Yönetimi" \
            "7. Program Yönetimi" \
            "8. Çıkış"\
			--width=400 --height=400)
        
        # Kullanıcının seçimine göre işlem
        case "$secim" in
            "1. Ürün Ekle")
                urun_ekle
                ;;
            "2. Ürün Listele")
                urunleri_listele
                ;;
            "3. Ürün Güncelle")
                urun_guncelle
                ;;
            "4. Ürün Sil")
                urun_sil
                ;;
            "5. Rapor Al")
                rapor_al
                ;;
            "6. Kullanıcı Yönetimi")
                kullanici_yonetimi
                ;;
            "7. Program Yönetimi")
                program_yonetimi
                ;;
            "8. Çıkış")
                zenity --info --title="Çıkış" --text="Ana menüden çıkılıyor..."
                break
                ;;
            *)
                zenity --error --title="Hata" --text="Lütfen geçerli bir seçim yapın!"
                ;;
        esac
    done
}


# Program başlangıcı
giris_menu
