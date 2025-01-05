#!/bin/bash

# Kullanıcı Girişi
function kullanici_girisi() {
    # Kullanıcı adı girişi
    local username=$(zenity --entry --title="Kullanıcı Girişi" --text="Kullanıcı adınızı girin:")
    
    # Kullanıcı adı boş bırakıldıysa
    if [ -z "$username" ]; then
        zenity --error --title="Hata" --text="Kullanıcı adı boş olamaz!"
        return 1
    fi

    # Kullanıcıyı CSV dosyasında arama
    local kullanici_satir=$(grep "^.*,${username},.*" "$kullanici_file")
    
    # Kullanıcı yoksa hata ver
    if [ -z "$kullanici_satir" ]; then
        zenity --error --title="Hata" --text="Kullanıcı bulunamadı!"
        return 1
    fi

    # Kullanıcı bilgilerini ayrıştırma
    current_user_id=$(echo "$kullanici_satir" | cut -d',' -f1)  # Kullanıcı ID'sini al
    local role=$(echo "$kullanici_satir" | cut -d',' -f3)
    local correct_password=$(echo "$kullanici_satir" | cut -d',' -f4)
    local blok_durumu=$(echo "$kullanici_satir" | cut -d',' -f5)

    # Hesap blokluysa giriş yapılmaz
    if [ "$blok_durumu" == "deactive" ]; then
        zenity --error --title="Hata" --text="Hesabınız bloklanmıştır. Lütfen bir yöneticiyle iletişime geçin."
        return 1
    fi

    # Şifre doğrulama
    local attempts=0
    while [ $attempts -lt 3 ]; do
        local password=$(zenity --password --title="Şifre Girişi" --text="Şifrenizi girin:")
        
        # Şifre kontrolü
        if [ "$password" == "$correct_password" ]; then
            zenity --info --title="Başarılı" --text="Giriş başarılı! Hoş geldiniz, $username."
            
            # Kullanıcı adı ve ID'si global bir değişkende saklanır
            current_user="$username"
            current_user_role="$role"
            return 0
        else
            zenity --error --title="Hata" --text="Hatalı şifre. Lütfen tekrar deneyin."
            ((attempts++))
        fi
    done

    # 3 yanlış deneme sonrasında hesap bloklanır
    if [ $attempts -ge 3 ]; then
        # Kullanıcıyı bloklama
        sed -i "s/^$current_user_id,${username},${role},${correct_password},active$/$current_user_id,${username},${role},${correct_password},deactive/" "$kullanici_file"
        zenity --error --title="Bloklandı" --text="3 kez hatalı şifre girildi. Hesabınız bloklandı!"
    fi
    
    return 1
}



# Yeni Kullanıcı Oluşturma
function yeni_kullanici_olustur() {
    # Yeni kullanıcı bilgilerini almak için Zenity formu
    local yeni_kullanici=$(zenity --forms --title="Yeni Kullanıcı Oluştur" \
        --text="Yeni kullanıcı bilgilerini girin:" \
        --add-entry="Kullanıcı Adı" \
        --add-password="Parola")

    # Kullanıcı bilgileri boşsa işlem iptal edilir
    if [ -z "$yeni_kullanici" ]; then
        zenity --error --title="Hata" --text="Kullanıcı bilgileri boş olamaz. İşlem iptal edildi."
        return
    fi

    # Bilgileri ayrıştırma
    local username=$(echo "$yeni_kullanici" | cut -d'|' -f1)
    local password=$(echo "$yeni_kullanici" | cut -d'|' -f2)

    # Boş alan kontrolü
    if [[ -z "$username" || -z "$password" ]]; then
        zenity --error --title="Hata" --text="Tüm alanlar doldurulmalıdır."
        return
    fi

    # Varsayılan rol olarak 'user' atanır
    local role="user"

    # Kullanıcı adı benzersiz mi kontrolü
    if grep -q "^.*,$username," "$kullanici_file"; then
        zenity --error --title="Hata" --text="Bu kullanıcı adı zaten alınmış. Lütfen farklı bir ad girin."
        return
    fi

    # Yeni kullanıcı ID'si oluşturma
    local new_id=$(($(tail -n +2 "$kullanici_file" | cut -d',' -f1 | sort -n | tail -n 1) + 1))
    if [ -z "$new_id" ]; then
        new_id=1
    fi

    # Kullanıcı bilgilerini dosyaya yazma
    echo "$new_id,$username,$role,$password,active" >> "$kullanici_file"

    # İşlem başarı bildirimi
    zenity --info --title="Başarılı" --text="Yeni kullanıcı başarıyla oluşturuldu!"
}

# Kullanıcıları Listele
function kullanicilari_listele() {
    # Kullanıcı dosyasındaki tüm kullanıcıları al (başlık hariç), ID, kullanıcı adı, rol ve blok durumu
    local kullanici_listesi=$(tail -n +2 "$kullanici_file" | cut -d',' -f1,2,3,5)

    # Kullanıcılar varsa listeyi göster
    if [ -n "$kullanici_listesi" ]; then
        zenity --info --title="Kullanıcılar" --text="Kullanıcılar:\n\nID | Kullanıcı Adı | Rol | Durum\n$kullanici_listesi"
    else
        zenity --info --title="Kullanıcılar" --text="Kullanıcı bulunmamaktadır."
    fi
}

# Kullanıcı Güncelleme Fonksiyonu
function kullanici_guncelle() {
    # Kullanıcı adını sor
    local kullanici_adi=$(zenity --entry --title="Kullanıcı Adı Girin" --text="Güncellemek istediğiniz kullanıcı adını girin:")

    # Kullanıcı adı boşsa işlem iptal edilir
    if [ -z "$kullanici_adi" ]; then
        zenity --error --title="Hata" --text="Kullanıcı adı boş olamaz. İşlem iptal edildi."
        return
    fi

    # Kullanıcıyı dosyada arama 
    local user_info=$(grep -i "^.*,$kullanici_adi," "$kullanici_file")

    # Eğer kullanıcı bulunamazsa işlem iptal edilir
    if [ -z "$user_info" ]; then
        zenity --error --title="Hata" --text="Kullanıcı adı bulunamadı. Lütfen geçerli bir kullanıcı adı girin."
        return
    fi

    # Kullanıcı bilgilerini ayrıştırma
    local user_id=$(echo "$user_info" | cut -d',' -f1)
    local current_role=$(echo "$user_info" | cut -d',' -f3)
    local current_password=$(echo "$user_info" | cut -d',' -f4)
    local current_block_status=$(echo "$user_info" | cut -d',' -f5)

    # Kullanıcı bilgilerini güncellemek için Zenity formu
    local updated_info=$(zenity --forms --title="Kullanıcı Güncelle" \
        --text="Kullanıcı bilgilerini güncelleyin:" \
        --add-entry="Kullanıcı Adı" --entry-text="$kullanici_adi" \
        --add-entry="Yetki (admin/user)" --entry-text="$current_role" \
        --add-password="Parola" --entry-text="$current_password" \
        --add-combo="Blok Durumu" --combo-values="active,deactive" --combo-text="$current_block_status")

    # Güncellenmiş bilgiler alınmazsa işlem iptal edilir
    if [ -z "$updated_info" ]; then
        zenity --error --title="Hata" --text="Kullanıcı bilgileri boş olamaz. İşlem iptal edildi."
        return
    fi

    # Bilgileri ayrıştırma
    local new_user_name=$(echo "$updated_info" | cut -d'|' -f1)
    local new_user_role=$(echo "$updated_info" | cut -d'|' -f2)
    local new_user_password=$(echo "$updated_info" | cut -d'|' -f3)
    local new_block_status=$(echo "$updated_info" | cut -d'|' -f4)

    # Güncellenen kullanıcıyı dosyaya yaz
    sed -i "s/^$user_id,.*$/$user_id,$new_user_name,$new_user_role,$new_user_password,$new_block_status/" "$kullanici_file"

    # Güncelleme başarılı mesajı
    zenity --info --title="Başarılı" --text="Kullanıcı başarıyla güncellendi!"
}




# Kullanıcı Silme Fonksiyonu
function kullanici_sil() {
    # Kullanıcıları listele ve seçim yap
    local kullanici_secim=$(awk -F',' '{print $1 "," $2}' "$kullanici_file" | zenity --list --title="Kullanıcıları Listele" \
        --column="ID, Kullanıcı Adı" --width=400 --height=300 --separator=",")

    # Kullanıcı seçilmezse işlemi iptal et
    if [ -z "$kullanici_secim" ]; then
        zenity --error --title="Hata" --text="Lütfen bir kullanıcı seçin."
        return
    fi

    # Seçilen kullanıcının ID'sini ve adını al
    local user_id=$(echo "$kullanici_secim" | cut -d',' -f1)
    local user_name=$(echo "$kullanici_secim" | cut -d',' -f2)

    # Seçilen kullanıcıyı CSV dosyasından sil
    sed -i "/^$user_id,/d" "$kullanici_file"

    # Silinen kullanıcıdan sonra gelen ID'leri yeniden düzenle
    awk -F',' -v OFS=',' '
    NR>1 { $1=NR-1; }
    { print $0 }
    ' "$kullanici_file" > temp_file && mv temp_file "$kullanici_file"

    # Silme işlemi başarılı
    zenity --info --title="Başarılı" --text="Kullanıcı başarıyla silindi!"
}


function kullanici_yonetimi() {
    if [ "$current_user_role" == "admin" ]; then
        while true; do
            # Admin için kullanıcı yönetimi menüsü
            local admin_secim=$(zenity --list --title="Kullanıcı Yönetimi" \
                --column="Seçenekler" \
                "1. Yeni Kullanıcı Ekle" \
                "2. Kullanıcıları Listele" \
                "3. Kullanıcıları Güncelle" \
                "4. Kullanıcı Silme" \
                "5. Geri Dön"\
			--width=400 --height=400)

            case "$admin_secim" in
                "1. Yeni Kullanıcı Ekle")
                    yeni_kullanici_olustur
                    ;;
                "2. Kullanıcıları Listele")
                    kullanicilari_listele
                    ;;
                "3. Kullanıcıları Güncelle")
                    kullanici_guncelle
                    ;;
                "4. Kullanıcı Silme")
                    kullanici_sil
                    ;;
                "5. Geri Dön")
                    return  # Ana menüye dönmek için fonksiyonu sonlandır
                    ;;
                *)
                    zenity --error --title="Hata" --text="Lütfen geçerli bir seçim yapın!"
                    ;;
            esac
        done
    else
        # "user" rolü için yetkisiz erişim
        zenity --error --title="Yetkiniz Yok" --text="Bu işlemi yapmaya yetkiniz yok."
    fi
}

