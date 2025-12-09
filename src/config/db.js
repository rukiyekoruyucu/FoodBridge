// src/config/db.js

const { createClient } = require('@supabase/supabase-js');

// Ortam değişkenlerinin doğru yüklendiğinden emin olun (dotenv veya benzeri)
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;

// 1. Supabase istemcisini oluşturma
const supabase = createClient(supabaseUrl, supabaseAnonKey);

// 2. Bağlantı Testi (Supabase'de 'bağlantı havuzu' yerine doğrudan istemci kullanılır, 
//    bu nedenle basit bir sorgu ile test edilebilir)
async function testSupabaseConnection() {
    try {
        // Hata yaratan sorgu yerine, projenizde VAR OLDUĞUNDAN emin olduğunuz
        // ve RLS (Satır Düzeyinde Güvenlik) politikasıyla Anon Key'in 
        // erişimine izin verilen bir tablo adı kullanın.

        // 💡 LÜTFEN AŞAĞIDAKİ ALANI KENDİ PROJENİZE GÖRE DÜZENLEYİN 💡
        const { data, error } = await supabase
            .from('fridges') // Örneğin: 'profiles' veya 'categories'
            .select('fridge_id') // Örneğin: 'id' veya 'name'
            .limit(1);

        if (error) {
            // Eğer RLS nedeniyle erişim hatası, tablo adı hatası vb. varsa
            throw new Error(`Supabase bağlantısı sırasında veritabanı sorgu hatası: ${error.message}`);
        }
        
        // Eğer data başarılı geldiyse
        console.log("✅ Supabase bağlantısı başarılı. Veritabanı sorgusu test edildi.");
    } catch (err) {
        console.error("❌ Supabase bağlantısı başarısız.");
        console.error("Hata Detayı:", err.message);
        console.error("Lütfen: 1) .env değerlerini kontrol edin. 2) Test sorgusundaki tablo ve sütun adlarının doğru olduğundan emin olun.");
        // Eğer uygulama kritik hata ile başlamamalıysa: process.exit(1);
    }
}

// Bağlantı testini yap
testSupabaseConnection();


// 3. İstemciyi dışa aktarma (Artık diğer dosyalar bu istemciyi kullanacak)
module.exports = supabase;