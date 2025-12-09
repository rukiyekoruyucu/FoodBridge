// foodbridge-backend/src/controllers/privateFridgeController.js (SON GÜNCELLEME)

const Product = require('../models/Product');
const { ROLES } = require('../models/User');

// --- Envanter İşlevleri (Item CRUD ve Transfer) ---

/**
 * Kullanıcının kişisel buzdolabındaki (yani kendi eklediği) tüm ürünleri listeler.
 * Korumalı Rota: Sadece 'personal' ve 'company' rolleri erişebilir.
 */
exports.getMyItems = async (req, res) => {
    const donorUserId = req.user.uid;

    try {
        // Product modelindeki getDonorItems fonksiyonunu kullan
        const myItems = await Product.getDonorItems(donorUserId);

        res.status(200).send({
            message: `${myItems.length} adet ürün bulundu.`,
            items: myItems
        });

    } catch (error) {
        console.error("Envanter listeleme hatası:", error.message);
        res.status(500).send({ message: 'Envanter listelenirken bir hata oluştu.' });
    }
};

/**
 * Kişisel buzdolabına (envantere) yeni bir ürün ekler.
 * Korumalı Rota: Sadece 'personal' ve 'company' rolleri erişebilir.
 * Not: Girdi doğrulama (validation) middleware'de yapılıyor.
 */
exports.addItem = async (req, res) => {
    const { name, quantity, expiryDate, category } = req.body;
    const donorUserId = req.user.uid;

    try {
        // Product modelindeki addItemToPrivateStash fonksiyonunu kullan
        const newItem = await Product.addItemToPrivateStash(donorUserId, name, quantity, expiryDate, category);

        res.status(201).send({ message: 'Ürün kişisel envantere başarıyla eklendi.', item: newItem });
    } catch (error) {
        console.error("Envantere ürün ekleme hatası:", error.message);
        res.status(500).send({ message: 'Ürün eklenirken bir hata oluştu.' });
    }
};

/**
 * Mevcut bir ürünü günceller (Sadece kendi envanterindeki ürünleri).
 */
exports.updateItem = async (req, res) => {
    const { itemId } = req.params;
    const donorUserId = req.user.uid;
    const updates = req.body;

    try {
        const updatedItem = await Product.updateItem(itemId, donorUserId, updates);
        res.status(200).send({ message: 'Envanter ürünü başarıyla güncellendi.', item: updatedItem });
    } catch (error) {
        console.error("Ürün güncelleme hatası:", error.message);
        res.status(403).send({ message: error.message });
    }
};

/**
 * Bir ürünü envanterden siler.
 */
exports.deleteItem = async (req, res) => {
    const { itemId } = req.params;
    const donorUserId = req.user.uid;

    try {
        await Product.deleteItem(itemId, donorUserId);
        res.status(200).send({ message: 'Ürün envanterden başarıyla silindi.' });
    } catch (error) {
        console.error("Ürün silme hatası:", error.message);
        res.status(403).send({ message: error.message });
    }
};

/**
 * Kişisel envanterdeki bir ürünü Topluluk Buzdolabına aktarır (TRANSFER İŞLEVİ).
 * Korumalı Rota: Sadece 'personal' veya 'company' (Donor) rolleri erişebilir.
 */
exports.transferItem = async (req, res) => {
    const { itemId } = req.params;
    const { targetFridgeId } = req.body; // Hangi buzdolabına taşınacak
    const donorUserId = req.user.uid;

    if (!targetFridgeId) {
        return res.status(400).send({ message: 'Hedef buzdolabı ID\'si gereklidir.' });
    }

    try {
        // Product modelindeki transferToFridge fonksiyonunu kullan
        const transferredItem = await Product.transferToFridge(itemId, donorUserId, targetFridgeId);

        res.status(200).send({
            message: 'Ürün başarıyla topluluk buzdolabına aktarıldı ve bağışa hazır.',
            item: transferredItem
        });
    } catch (error) {
        console.error("Ürün transfer hatası:", error.message);
        res.status(403).send({ message: error.message });
    }
};