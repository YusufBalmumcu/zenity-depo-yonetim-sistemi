#!/bin/bash

# Diskte Kaplanan Alanı Hesaplama Fonksiyonu
function disk_kaplanan_alan() {
    local disk_alan=$(du -sh 2>/dev/null | awk '{print $1}')
    zenity --info --title="Diskte Kaplanan Alan" --text="Programın disk üzerinde kapladığı alan: $disk_alan"
}

# Diske Yedek Alma Fonksiyonu
function diske_yedek_al() {
    # Yedek dosyasının adı, tarih ve saat ile belirlenir
    local yedek_dosya="yedek_$(date +%Y%m%d%H%M%S).tar.gz"
    
    # Sadece depo.csv ve kullanici.csv dosyalarını yedekle
    tar -czf "$yedek_dosya" ./src/depo.csv ./src/kullanici.csv 2>/dev/null
    
    # Yedekleme işleminin başarılı olup olmadığını kontrol et
    if [ $? -eq 0 ]; then
        zenity --info --title="Yedekleme Başarılı" --text="Depo ve kullanıcı dosyaları başarıyla yedeklendi: $yedek_dosya"
    else
        zenity --error --title="Hata" --text="Yedekleme sırasında bir hata oluştu."
    fi
}


# Hata Kayıtlarını Görüntüleme Fonksiyonu
function hata_kayitlarini_goruntule() {
    local hata_dosya="./src/log.csv"
    if [ -f "$hata_dosya" ]; then
        local log_icerik=$(tail -n 20 "$hata_dosya")
        zenity --text-info --title="Hata Kayıtları" --filename="$hata_dosya" --width=800 --height=600
    else
        zenity --error --title="Hata" --text="Hata kayıt dosyası bulunamadı."
    fi
}

# Program Yönetimi Fonksiyonu
function program_yonetimi() {
    while true; do
        # Program yönetimi menüsü
        local secim=$(zenity --list --title="Program Yönetimi" \
            --column="Seçenekler" \
            "1. Diskte Kaplanan Alan" \
            "2. Diske Yedek Alma" \
            "3. Hata Kayıtlarını Görüntüle" \
            "4. Geri Dön" \
            --width=400 --height=300)

        case "$secim" in
            "1. Diskte Kaplanan Alan")
                disk_kaplanan_alan
                ;;
            "2. Diske Yedek Alma")
                diske_yedek_al
                ;;
            "3. Hata Kayıtlarını Görüntüle")
                hata_kayitlarini_goruntule
                ;;
            "4. Geri Dön")
                return  # Ana menüye dönmek için fonksiyonu sonlandır
                ;;
            *)
                zenity --error --title="Hata" --text="Lütfen geçerli bir seçim yapın!"
                ;;
        esac
    done
}


