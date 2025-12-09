// foodbridge-backend/src/models/Product.js

const supabase = require('../config/db');
const redisClient = require('../config/redis'); // 💡 YENİ: Redis istemcisini dahil et

// Önbellek anahtar önekleri ve yaşam süresi (TTL)
const CACHE_KEY_PREFIX = 'nearby_fridges:';
const CACHE_EXPIRY_SECONDS = 300; // 5 dakika önbellekleme süresi

// --- BUZDOLABI (FRIDGE) İŞLEMLERİ ---

/**
 * Yeni bir topluluk buzdolabı kaydı oluşturur.
 */
async function createFridge(name, description, latitude, longitude, managerUserId) {
    const { data, error } = await supabase
        .from('fridges')
        .insert({
            name,
            description,
            latitude,
            longitude,
            manager_user_id: managerUserId,
            is_active: true
        })
        .select();

    if (error) {
        console.error("Veritabanına buzdolabı ekleme hatası:", error.message);
        throw new Error('Buzdolabı kaydedilemedi.');
    }
    return data[0];
}

/**
 * Konuma göre yakındaki aktif buzdolaplarını getirir (Geolocation/Spatial Query).
 * Redis Önbellekleme mantığı eklendi.
 */
async function getNearbyFridges(userLat, userLon, maxDistanceKm = 10) {
    // Sorgu parametrelerinden benzersiz bir önbellek anahtarı oluşturulur
    const cacheKey = `${CACHE_KEY_PREFIX}${userLat}:${userLon}:${maxDistanceKm}`;

    try {
        // 1. REDIS'İ KONTROL ET (CACHE CHECK)
        const cachedData = await redisClient.get(cacheKey);

        if (cachedData) {
            console.log(`✅ Redis hit: ${cacheKey}`);
            return JSON.parse(cachedData); // Önbellekte varsa doğrudan döndür
        }

        console.log(`❌ Redis miss: ${cacheKey}. Supabase'den çekiliyor...`);

        // 2. SUPABASE'DEN VERİ ÇEK (CACHE MISS)
        // Geçici çözüm: Tüm buzdolaplarını çekip mesafeye göre filtreleme
        const { data: fridges, error } = await supabase
            .from('fridges')
            .select('*, items(item_id)') // Buzdolabı bilgilerini ve içindeki item sayısını çek
            .eq('is_active', true);

        if (error) {
            console.error("Yakındaki buzdolaplarını çekme hatası:", error.message);
            // Redis bağlantısı başarısız olsa bile, Supabase'den çekilen veri hatasız gelmeli
            throw new Error('Buzdolapları listelenemedi.');
        }

        // 3. MESAFEYİ HESAPLA VE FORMATLA (ESKİ MANTIK KORUNUYOR)
        const EARTH_RADIUS_KM = 6371;
        const toRad = (value) => (value * Math.PI) / 180;

        const formattedFridges = fridges
            .map(fridge => {
                const lat1 = toRad(userLat);
                const lon1 = toRad(userLon);
                const lat2 = toRad(fridge.latitude);
                const lon2 = toRad(fridge.longitude);

                // Basit mesafe hesaplaması (yaklaşık Haversine)
                const dLat = lat2 - lat1;
                const dLon = lon2 - lon1;

                const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) * Math.sin(dLon / 2);

                const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
                const distance = EARTH_RADIUS_KM * c; // Kilometre cinsinden mesafe

                return {
                    ...fridge,
                    distance: parseFloat(distance.toFixed(2)), // 2 ondalık basamağa yuvarla
                    item_count: fridge.items.length // İçindeki item sayısını ekle
                };
            })
            .filter(fridge => fridge.distance <= maxDistanceKm)
            .sort((a, b) => a.distance - b.distance); // En yakından en uzağa sırala

        // 4. VERİYİ REDIS'E KAYDET (CACHE SET)
        // Redis bağlantısı kopuksa bu adımda hata fırlatılabilir, bu yüzden try-catch bloğu kritik.
        // Ancak Redis istemcisi, bağlanamazsa otomatik olarak hata yakalama/loglama yapar.
        await redisClient.set(cacheKey, JSON.stringify(formattedFridges), {
            EX: CACHE_EXPIRY_SECONDS,
        });

        return formattedFridges;

    } catch (error) {
        // Eğer Redis veya Supabase hatası oluşursa
        console.error("getNearbyFridges Genel Hata:", error.message);

        // 💡 ÖNEMLİ FALLBACK: Redis bağlantı hatası durumunda uygulamanın Supabase'den çekmeye devam etmesi gerekir. 
        // Ancak bu yapıda, herhangi bir hata durumunda (Redis, Supabase veya kod hatası) kullanıcıya hata döndürülür.
        throw new Error('Buzdolapları listelenirken bir hizmet hatası oluştu.');
    }
}

// --- ÜRÜN (ITEM) İŞLEMLERİ ---

/**
 * Bir buzdolabına yeni bir ürün ekler (Donör işlevi).
 */
async function addItemToFridge(fridgeId, donorUserId, name, quantity, expiryDate, category, isAvailable = true) {
    const { data, error } = await supabase
        .from('items')
        .insert({
            fridge_id: fridgeId,
            donor_user_id: donorUserId,
            name,
            quantity,
            expiry_date: expiryDate,
            category,
            is_available: isAvailable
        })
        .select();

    if (error) {
        console.error("Veritabanına ürün ekleme hatası:", error.message);
        throw new Error('Ürün kaydedilemedi.');
    }
    return data[0];
}

/**
 * Bir ürünü günceller (Donör işlevi: miktar, son kullanma tarihi vb.).
 */
async function updateItem(itemId, donorUserId, updates) {
    const { data, error } = await supabase
        .from('items')
        .update(updates)
        .eq('item_id', itemId)
        .eq('donor_user_id', donorUserId) // Yalnızca bağışçının kendi ürününü güncellemesine izin ver
        .select();

    if (error) {
        console.error("Ürün güncelleme hatası:", error.message);
        throw new Error('Ürün güncellenemedi.');
    }
    if (data.length === 0) {
        throw new Error('Ürün bulunamadı veya güncelleme yetkiniz yok.');
    }
    return data[0];
}

/**
 * Bir ürünü siler (Donör işlevi).
 */
async function deleteItem(itemId, donorUserId) {
    const { error, count } = await supabase
        .from('items')
        .delete({ count: 'exact' })
        .eq('item_id', itemId)
        .eq('donor_user_id', donorUserId); // Yalnızca bağışçının kendi ürününü silmesine izin ver

    if (error) {
        console.error("Ürün silme hatası:", error.message);
        throw new Error('Ürün silinemedi.');
    }
    if (count === 0) {
        throw new Error('Ürün bulunamadı veya silme yetkiniz yok.');
    }
    return true;
}

/**
 * Bir donörün kişisel envanterine (private stash) yeni bir ürün ekler.
 * fridge_id'si boş (null) bırakılır veya özel bir ID kullanılır.
 */
async function addItemToPrivateStash(donorUserId, name, quantity, expiryDate, category, isAvailable = false) {
    const { data, error } = await supabase
        .from('items')
        .insert({
            // fridge_id: null, // Kişisel buzdolabı olduğunu belirtmek için null/boş bırakılır
            donor_user_id: donorUserId,
            name,
            quantity,
            expiry_date: expiryDate,
            category,
            is_available: isAvailable // Başlangıçta mevcut değil olarak ayarlanır (buzdolabına eklenmediği sürece)
        })
        .select();

    if (error) {
        console.error("Kişisel envantere ürün ekleme hatası:", error.message);
        throw new Error('Ürün kişisel envantere kaydedilemedi.');
    }
    return data[0];
}


/**
 * Belirli bir donöre ait tüm kişisel envanter ürünlerini (henüz buzdolabına atanmamış olanları) getirir.
 */
async function getDonorItems(donorUserId) {
    const { data, error } = await supabase
        .from('items')
        .select('*')
        // fridge_id'si boş olan (kişisel envanterde olan) ve bu donöre ait olanları getir
        .is('fridge_id', null)
        .eq('donor_user_id', donorUserId)
        .order('expiry_date', { ascending: true }); // Son kullanma tarihine göre sırala (Önceliklendirme)

    if (error) {
        console.error("Donör envanterini çekme hatası:", error.message);
        throw new Error('Kişisel envanter listelenemedi.');
    }
    return data;
}

module.exports = {
    createFridge,
    addItemToPrivateStash,
    getDonorItems,
    getNearbyFridges,
    addItemToFridge,
    updateItem,
    deleteItem
};