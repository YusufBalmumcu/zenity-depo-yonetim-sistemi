#!/bin/bash

# Ürün ekleme fonksiyonu
function urun_ekle() {
    # Depo dosyasının var olup olmadığını kontrol et
    if [ ! -f "$depo_file" ]; then
        echo "Depo dosyası bulunamadı, depo dosyası oluşturuluyor..."
        echo "urun_no,urun_adi,stok_miktari,birim_fiyat,kategori" > "$depo_file"
        echo "Depo dosyası oluşturuldu!"
    else
        echo "Depo dosyası bulundu!"
    fi

    # Ürün bilgilerini almak için Zenity formu
    local urun_bilgileri=$(zenity --forms --title="Yeni Ürün Ekle" \
        --text="Ürün bilgilerini girin:" \
        --add-entry="Ürün Adı" \
        --add-entry="Stok Miktarı" \
        --add-entry="Birim Fiyatı" \
        --add-entry="Kategori")

    # Ürün bilgileri boşsa işlem iptal edilir
    if [ -z "$urun_bilgileri" ]; then
        zenity --error --title="Hata" --text="Ürün bilgileri boş olamaz. İşlem iptal edildi."
        return
    fi

    # Bilgileri ayrıştırma
    local urun_adi=$(echo "$urun_bilgileri" | cut -d'|' -f1)
    local stok_miktari=$(echo "$urun_bilgileri" | cut -d'|' -f2)
    local birim_fiyat=$(echo "$urun_bilgileri" | cut -d'|' -f3)
    local kategori=$(echo "$urun_bilgileri" | cut -d'|' -f4)

    # Boş alan kontrolü
    if [[ -z "$urun_adi" || -z "$stok_miktari" || -z "$birim_fiyat" || -z "$kategori" ]]; then
        zenity --error --title="Hata" --text="Tüm alanlar doldurulmalıdır."
        return
    fi

    # Ürün ismi boşluk içeriyor mu kontrolü
    if [[ "$urun_adi" =~ [[:space:]] ]]; then
        zenity --error --title="Hata" --text="Ürün adı boşluk içeremez."
        return
    fi

    # Stok miktarı ve birim fiyatının 0'dan büyük olma kontrolü
    if [ "$stok_miktari" -le 0 ] 2>/dev/null || ! [[ "$stok_miktari" =~ ^[0-9]+$ ]]; then
        zenity --error --title="Hata" --text="Stok miktarı geçerli bir pozitif sayı olmalıdır."
        return
    fi

    if [ "$birim_fiyat" -le 0 ] 2>/dev/null || ! [[ "$birim_fiyat" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        zenity --error --title="Hata" --text="Birim fiyatı geçerli bir sayı olmalıdır."
        return
    fi

    # Ürün No otomatik olarak hesaplanır
    local urun_no=$(($(tail -n +2 "$depo_file" | cut -d',' -f1 | sort -n | tail -n 1) + 1))
    if [ -z "$urun_no" ]; then
        urun_no=1
    fi

    # Ürün bilgilerini depo dosyasına ekle
    echo "$urun_no,$urun_adi,$stok_miktari,$birim_fiyat,$kategori" >> "$depo_file"

    # İşlem başarı bildirimi
    zenity --info --title="Başarılı" --text="Yeni ürün başarıyla eklendi!"
}

# Ürünleri Listele
function urunleri_listele() {
    # Depo dosyasındaki tüm ürünleri al (başlık hariç), Ürün No, Ürün Adı, Stok Miktarı, Birim Fiyat, Kategori
    local urun_listesi=$(tail -n +2 "$depo_file" | cut -d',' -f1,2,3,4,5)

    # Ürünler varsa listeyi göster
    if [ -n "$urun_listesi" ]; then
        zenity --info --title="Ürünler" --text="Ürünler:\n\nÜrün No | Ürün Adı | Stok Miktarı | Birim Fiyat | Kategori\n$urun_listesi"
    else
        zenity --info --title="Ürünler" --text="Ürün bulunmamaktadır."
    fi
}


# Ürün Silme Fonksiyonu
function urun_sil() {
    # Ürünleri listele ve seçim yap
    local urun_secim=$(awk -F',' 'NR>1 {print $1 "," $2 "," $5}' "$depo_file" | zenity --list --title="Ürünleri Listele" \
        --column="Ürün No,Ürün Adı, Kategori" --width=600 --height=400 --separator=",")

    # Ürün seçilmezse işlemi iptal et
    if [ -z "$urun_secim" ]; then
        zenity --error --title="Hata" --text="Lütfen bir ürün seçin."
        return
    fi

    # Seçilen ürünün bilgilerini al
    local urun_no=$(echo "$urun_secim" | cut -d',' -f1)
    local urun_adi=$(echo "$urun_secim" | cut -d',' -f2)
    local urun_kategori=$(echo "$urun_secim" | cut -d',' -f3)

    # Seçilen ürünü CSV dosyasından sil
    sed -i "/^$urun_no,/d" "$depo_file"

    # Silinen üründen sonra gelen ID'leri yeniden düzenle
    awk -F',' -v OFS=',' '
    NR>1 { $1=NR-1; } 
    { print $0 }
    ' "$depo_file" > temp_file && mv temp_file "$depo_file"

    # Silme işlemi başarılı
    zenity --info --title="Başarılı" --text="Ürün başarıyla silindi!\n\nÜrün No: $urun_no\nÜrün Adı: $urun_adi\nKategori: $urun_kategori"
}


# Ürün Güncelleme Fonksiyonu
function urun_guncelle() {
    # Ürünleri listele ve seçim yap
    local urun_secim=$(awk -F',' '{print $1 "," $2 "," $5}' "$depo_file" | zenity --list --title="Ürün Güncelleme" \
        --column="Ürün No, Ürün Adı, Kategori" --width=400 --height=300 --separator=",")

    # Ürün seçilmezse işlemi iptal et
    if [ -z "$urun_secim" ]; then
        zenity --error --title="Hata" --text="Lütfen bir ürün seçin."
        return
    fi

    # Seçilen ürünün ID'sini, adını ve kategorisini al
    local urun_no=$(echo "$urun_secim" | cut -d',' -f1)
    local urun_adi=$(echo "$urun_secim" | cut -d',' -f2)
    local kategori=$(echo "$urun_secim" | cut -d',' -f3)

    # Kullanıcıdan yeni stok miktarı ve birim fiyatı girmesini iste
    local yeni_bilgiler=$(zenity --forms --title="Ürün Güncelleme" \
        --text="Ürün bilgilerini güncelleyin:" \
        --add-entry="Yeni Stok Miktarı" \
        --add-entry="Yeni Birim Fiyatı")

    # Yeni bilgiler boşsa işlem iptal edilir
    if [ -z "$yeni_bilgiler" ]; then
        zenity --error --title="Hata" --text="Yeni bilgiler boş olamaz. İşlem iptal edildi."
        return
    fi

    # Bilgileri ayrıştırma
    local yeni_stok_miktari=$(echo "$yeni_bilgiler" | cut -d'|' -f1)
    local yeni_birim_fiyat=$(echo "$yeni_bilgiler" | cut -d'|' -f2)

    # Boş alan kontrolü
    if [[ -z "$yeni_stok_miktari" || -z "$yeni_birim_fiyat" ]]; then
        zenity --error --title="Hata" --text="Tüm alanlar doldurulmalıdır."
        return
    fi

    # Stok miktarı ve birim fiyatının 0'dan büyük olma kontrolü
    if [ "$yeni_stok_miktari" -le 0 ] 2>/dev/null || ! [[ "$yeni_stok_miktari" =~ ^[0-9]+$ ]]; then
        zenity --error --title="Hata" --text="Stok miktarı geçerli bir pozitif sayı olmalıdır."
        return
    fi

    if [ "$yeni_birim_fiyat" -le 0 ] 2>/dev/null || ! [[ "$yeni_birim_fiyat" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        zenity --error --title="Hata" --text="Birim fiyatı geçerli bir sayı olmalıdır."
        return
    fi

    # Ürün bilgilerini güncelle
    awk -F',' -v urun_no="$urun_no" -v stok_miktari="$yeni_stok_miktari" -v birim_fiyat="$yeni_birim_fiyat" -v OFS=',' '
    NR==1 { print $0; next }  # Başlık satırını olduğu gibi bırak
    NR>1 {
        if ($1 == urun_no) {
            $3 = stok_miktari;
            $4 = birim_fiyat;
        }
        print $0;
    }' "$depo_file" > temp_file && mv temp_file "$depo_file"

    # Güncelleme işlemi başarılı
    zenity --info --title="Başarılı" --text="Ürün başarıyla güncellendi!"
}
