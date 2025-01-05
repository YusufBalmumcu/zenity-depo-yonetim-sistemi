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
    # Kullanıcıları listele ve seçim yap
    local kullanici_secim=$(awk -F',' '{print $1 "," $2}' "$kullanici_file" | zenity --list --title="Kullanıcı Güncelleme" \
        --column="ID, Kullanıcı Adı" --width=400 --height=300 --separator=",")

    # Kullanıcı seçilmezse işlemi iptal et
    if [ -z "$kullanici_secim" ]; then
        zenity --error --title="Hata" --text="Lütfen bir kullanıcı seçin."
        return
    fi

    # Seçilen kullanıcının ID'sini ve adını al
    local user_id=$(echo "$kullanici_secim" | cut -d',' -f1)
    local user_name=$(echo "$kullanici_secim" | cut -d',' -f2)

    # Kullanıcı bilgilerini dosyadan al
    local user_info=$(grep -i "^$user_id," "$kullanici_file")
    local current_role=$(echo "$user_info" | cut -d',' -f3)
    local current_password=$(echo "$user_info" | cut -d',' -f4)
    local current_block_status=$(echo "$user_info" | cut -d',' -f5)

    # Kullanıcıdan yeni bilgiler al
    local yeni_bilgiler=$(zenity --forms --title="Kullanıcı Güncelleme" \
        --text="Kullanıcı bilgilerini güncelleyin:" \
        --add-entry="Yeni Kullanıcı Adı" \
        --add-entry="Yeni Yetki (admin/user)" \
        --add-password="Yeni Parola" \
        --add-entry="Yeni Blok Durumu (active/deactive)")

    # Yeni bilgiler boşsa işlem iptal edilir
    if [ -z "$yeni_bilgiler" ]; then
        zenity --error --title="Hata" --text="Yeni bilgiler boş olamaz. İşlem iptal edildi."
        return
    fi

    # Bilgileri ayrıştırma
    local yeni_user_name=$(echo "$yeni_bilgiler" | cut -d'|' -f1)
    local yeni_user_role=$(echo "$yeni_bilgiler" | cut -d'|' -f2)
    local yeni_user_password=$(echo "$yeni_bilgiler" | cut -d'|' -f3)
    local yeni_block_status=$(echo "$yeni_bilgiler" | cut -d'|' -f4)

    # Eski bilgileriyle birlikte alanları doldurmak için varsayılan değerler girme
    yeni_user_name=${yeni_user_name:-$user_name}
    yeni_user_role=${yeni_user_role:-$current_role}
    yeni_user_password=${yeni_user_password:-$current_password}
    yeni_block_status=${yeni_block_status:-$current_block_status}

    # Boş alan kontrolü
    if [[ -z "$yeni_user_name" || -z "$yeni_user_role" || -z "$yeni_user_password" || -z "$yeni_block_status" ]]; then
        zenity --error --title="Hata" --text="Tüm alanlar doldurulmalıdır."
        return
    fi

    # Güncellenen kullanıcıyı dosyaya yaz
    awk -F',' -v user_id="$user_id" -v user_name="$yeni_user_name" -v user_role="$yeni_user_role" -v user_password="$yeni_user_password" -v block_status="$yeni_block_status" -v OFS=',' '
    NR==1 { print $0; next }  # Başlık satırını olduğu gibi bırak
    NR>1 {
        if ($1 == user_id) {
            $2 = user_name;
            $3 = user_role;
            $4 = user_password;
            $5 = block_status;
        }
        print $0;
    }' "$kullanici_file" > temp_file && mv temp_file "$kullanici_file"

    # Güncelleme işlemi başarılı
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

