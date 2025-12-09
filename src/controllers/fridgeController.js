// foodbridge-backend/src/controllers/fridgeController.js

const Product = require('../models/Product');
const { ROLES } = require('../models/User'); // Rolleri kontrol etmek için

// Buzdolabı/Ürün yönetimi, CRUD işlemleri ve konum bazlı aramaları içerir.

// --- Buzdolabı İşlemleri ---

/**
 * Yakındaki buzdolaplarını listeler (Recipient/Donor işlevi).
 * Korumalı rota: Tüm kayıtlı kullanıcılar (Recipient, Personal, Company) erişebilir.
 */
exports.getFridges = async (req, res) => {
    // req.query'den konum ve mesafe parametrelerini al
    const { lat, lon, distance } = req.query;

    if (!lat || !lon) {
        return res.status(400).send({ message: 'Konum bilgileri (lat, lon) gereklidir.' });
    }

    try {
        const userLat = parseFloat(lat);
        const userLon = parseFloat(lon);
        const maxDistance = distance ? parseInt(distance) : 10; // Varsayılan 10 km

        const nearbyFridges = await Product.getNearbyFridges(userLat, userLon, maxDistance);

        res.status(200).send({
            message: `${nearbyFridges.length} adet buzdolabı bulundu.`,
            fridges: nearbyFridges
        });
    } catch (error) {
        console.error("Buzdolaplarını listeleme hatası:", error.message);
        res.status(500).send({ message: 'Buzdolapları listelenirken bir hata oluştu.' });
    }
};

/**
 * Buzdolabındaki tüm ürünleri listeler.
 * Korumalı rota: Tüm kayıtlı kullanıcılar erişebilir.
 */
exports.getFridgeItems = async (req, res) => {
    // 💡 Bu kontrolcüyü Product.js'e ekleyeceğimiz bir getItemsByFridgeId metodu ile tamamlamamız gerekecek.
    // Şimdilik sadece buzdolabı ID'sinin kontrolünü yapalım.
    res.status(501).send({ message: 'Bu işlev henüz tamamlanmadı (Product modeline getItemsByFridgeId eklenmeli).' });
};


// --- Ürün İşlemleri (Donor CRUD) ---

/**
 * Bir buzdolabına yeni ürün ekler.
 * Korumalı rota: Sadece 'personal' veya 'company' (Donor) rolleri erişebilir.
 */
exports.addItem = async (req, res) => {
    const { fridgeId } = req.params;
    const { name, quantity, expiryDate, category } = req.body;
    const donorUserId = req.user.uid; // Middleware'den gelen UID

    if (!name || !quantity || !expiryDate || !category) {
        return res.status(400).send({ message: 'Tüm alanlar (isim, miktar, son kullanma tarihi, kategori) gereklidir.' });
    }

    try {
        const newItem = await Product.addItemToFridge(fridgeId, donorUserId, name, quantity, expiryDate, category);
        res.status(201).send({ message: 'Ürün başarıyla eklendi.', item: newItem });
    } catch (error) {
        console.error("Ürün ekleme hatası:", error.message);
        res.status(500).send({ message: 'Ürün eklenirken bir hata oluştu.' });
    }
};

/**
 * Mevcut bir ürünü günceller.
 * Korumalı rota: Sadece 'personal' veya 'company' (Donor) rolleri erişebilir.
 */
exports.updateItem = async (req, res) => {
    const { itemId } = req.params;
    const donorUserId = req.user.uid;
    const updates = req.body; // Güncellenmek istenen alanlar

    try {
        const updatedItem = await Product.updateItem(itemId, donorUserId, updates);
        res.status(200).send({ message: 'Ürün başarıyla güncellendi.', item: updatedItem });
    } catch (error) {
        console.error("Ürün güncelleme hatası:", error.message);
        res.status(403).send({ message: error.message }); // 403: Yetkisiz/Bulunamadı
    }
};

/**
 * Bir ürünü siler.
 * Korumalı rota: Sadece 'personal' veya 'company' (Donor) rolleri erişebilir.
 */
exports.deleteItem = async (req, res) => {
    const { itemId } = req.params;
    const donorUserId = req.user.uid;

    try {
        await Product.deleteItem(itemId, donorUserId);
        res.status(200).send({ message: 'Ürün başarıyla silindi.' });
    } catch (error) {
        console.error("Ürün silme hatası:", error.message);
        res.status(403).send({ message: error.message });
    }
};