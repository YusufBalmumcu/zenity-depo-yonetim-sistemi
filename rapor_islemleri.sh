#!/bin/bash

# Rapor Alma Fonksiyonu
function rapor_al() {
    while true; do
        # Rapor menüsü
        local secim=$(zenity --list --title="Rapor Alma" \
            --column="Seçenekler" \
            "1. Stokta Azalan Ürünler" \
            "2. En Yüksek Stok Miktarına Sahip Ürünler" \
            "3. Geri Dön" \
            --width=400 --height=300)

        case "$secim" in
            "1. Stokta Azalan Ürünler")
                stokta_azalan_urunler
                ;;
            "2. En Yüksek Stok Miktarına Sahip Ürünler")
                en_yuksek_stoklu_urunler
                ;;
            "3. Geri Dön")
                return  # Ana menüye dönmek için fonksiyonu sonlandır
                ;;
            *)
                zenity --error --title="Hata" --text="Lütfen geçerli bir seçim yapın!"
                ;;
        esac
    done
}

# Stokta Azalan Ürünler Fonksiyonu
function stokta_azalan_urunler() {
    # Kullanıcıdan eşik değeri al
    local esik_deger=$(zenity --entry --title="Stokta Azalan Ürünler" --text="Lütfen bir eşik değeri girin:")
    
    # Eşik değerin geçerli sayı olup olmadığını kontrol et
    if ! [[ "$esik_deger" =~ ^[0-9]+$ ]]; then
        zenity --error --title="Hata" --text="Lütfen geçerli bir sayı girin."
        return
    fi

    # Eşik değerinden az stoğu olan ürünleri bul ve sıralı olarak listele
    local azalan_urunler=$(awk -F',' -v esik="$esik_deger" '
    NR > 1 && $3 < esik { print $2 ", Stok: " $3 }
    ' "$depo_file" | sort -t',' -k2 -n)

    # Sonuçları kullanıcıya göster
    if [ -n "$azalan_urunler" ]; then
        zenity --info --title="Stokta Azalan Ürünler" --text="Eşik değerden az stoğu olan ürünler:\n$azalan_urunler"
    else
        zenity --info --title="Stokta Azalan Ürünler" --text="Eşik değerden az stoğu olan ürün bulunamadı."
    fi
}

# En Yüksek Stok Miktarına Sahip Ürünler Fonksiyonu
function en_yuksek_stoklu_urunler() {
    # Kullanıcıdan eşik değeri al
    local esik_deger=$(zenity --entry --title="En Yüksek Stoklu Ürünler" --text="Lütfen bir eşik değeri girin:")
    
    # Eşik değerin geçerli sayı olup olmadığını kontrol et
    if ! [[ "$esik_deger" =~ ^[0-9]+$ ]]; then
        zenity --error --title="Hata" --text="Lütfen geçerli bir sayı girin."
        return
    fi

    # Eşik değerinden fazla stoğu olan ürünleri bul ve sıralı olarak listele
    local yuksek_stoklu_urunler=$(awk -F',' -v esik="$esik_deger" '
    NR > 1 && $3 > esik { print $2 ", Stok: " $3 }
    ' "$depo_file" | sort -t',' -k2 -nr)

    # Sonuçları kullanıcıya göster
    if [ -n "$yuksek_stoklu_urunler" ]; then
        zenity --info --title="En Yüksek Stoklu Ürünler" --text="Eşik değerden fazla stoğu olan ürünler:\n$yuksek_stoklu_urunler"
    else
        zenity --info --title="En Yüksek Stoklu Ürünler" --text="Eşik değerden fazla stoğu olan ürün bulunamadı."
    fi
}
