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
    local urun_secim=$(awk -F',' '{print $1 "," $2 "," $5}' "$depo_file" | zenity --list --title="Ürünleri Listele" \
        --column="Ürün No" --column="Ürün Adı" --column="Kategori" --width=600 --height=400 --separator=",")

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
    # Kullanıcıdan güncellemek istediği ürünün adını al
    local urun_adi=$(zenity --entry --title="Ürün Güncelleme" --text="Güncellemek istediğiniz ürünün adını girin:")

    # Eğer ürün adı boşsa, işlem iptal edilir
    if [ -z "$urun_adi" ]; then
        zenity --error --title="Hata" --text="Ürün adı boş olamaz."
        return
    fi

    # Ürün adı, depo dosyasında var mı kontrol et
    local urun_var=$(grep -i "^.*,$urun_adi," "$depo_file")
    
    # Ürün bulunmazsa, hata mesajı göster
    if [ -z "$urun_var" ]; then
        zenity --error --title="Hata" --text="Geçerli bir ürün bulunamadı: $urun_adi"
        return
    fi

    # Ürün bilgilerini almak (urun_no, stok_miktari, birim_fiyat)
    local urun_no=$(echo "$urun_var" | cut -d',' -f1)
    local mevcut_stok=$(echo "$urun_var" | cut -d',' -f3)
    local mevcut_fiyat=$(echo "$urun_var" | cut -d',' -f4)

    # Kullanıcıya form ile yeni stok miktarı ve birim fiyatını güncellemesi için giriş soralım
    local yeni_birim_fiyat_yeni_stok=$(zenity --forms --title="Ürün Güncelleme" \
        --text="Ürün: $urun_adi (Ürün No: $urun_no)\nMevcut Stok Miktarı: $mevcut_stok\nMevcut Birim Fiyatı: $mevcut_fiyat" \
        --add-entry="Yeni Stok Miktarı (şu anki: $mevcut_stok)" \
        --add-entry="Yeni Birim Fiyatı (şu anki: $mevcut_fiyat)")

    # Eğer formdan boş veri dönerse, işlem iptal edilir
    if [ -z "$yeni_birim_fiyat_yeni_stok" ]; then
        zenity --error --title="Hata" --text="Tüm alanlar doldurulmalıdır."
        return
    fi

    # Bilgileri ayrıştırma
    local yeni_stok_miktari=$(echo "$yeni_birim_fiyat_yeni_stok" | cut -d'|' -f1)
    local yeni_birim_fiyat=$(echo "$yeni_birim_fiyat_yeni_stok" | cut -d'|' -f2)

    # Yeni stok miktarı ve birim fiyatının geçerli olup olmadığını kontrol et
    if ! [[ "$yeni_birim_fiyat" =~ ^[0-9]+(\.[0-9]+)?$ ]] || ! [[ "$yeni_stok_miktari" =~ ^[0-9]+$ ]]; then
        zenity --error --title="Hata" --text="Geçersiz değerler girdiniz. Lütfen geçerli bir sayı girin."
        return
    fi

    # Ürün bilgilerini güncelle
    sed -i "s/^$urun_no,.*/$urun_no,$urun_adi,$yeni_stok_miktari,$yeni_birim_fiyat,$(echo "$urun_var" | cut -d',' -f5)/" "$depo_file"

    # Güncelleme başarılı bildirimi
    zenity --info --title="Başarılı" --text="Ürün başarıyla güncellendi: $urun_adi"
}

