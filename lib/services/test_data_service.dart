import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static Future<void> createTestStory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      // İlk test hikayesi - Fiction/A2
      final testStory1 = {
        'title': 'My First English Story',
        'content': '''Once upon a time, in a small village nestled between rolling hills and whispering woods, there lived a young girl named Emma. She had always been curious about the world beyond her village, often spending hours gazing at the distant mountains and wondering what adventures awaited there.

One sunny morning, Emma decided to pack a small bag with some bread, cheese, and water, and set off on a journey to explore the mysterious forest that bordered her village. As she walked deeper into the woods, she discovered a hidden path covered with colorful flowers and singing birds.

Following the path, Emma came across a crystal-clear stream where she met a friendly rabbit who could speak! The rabbit told her about a magical garden hidden somewhere in the forest, where wishes could come true. Excited by this discovery, Emma asked the rabbit to guide her to this enchanted place.

After walking for what seemed like hours, they finally arrived at the most beautiful garden Emma had ever seen. Flowers of every color imaginable bloomed in perfect harmony, and a gentle fountain sparkled in the center. Emma made a wish to always have the courage to explore and learn new things.

From that day forward, Emma became known in her village as the brave girl who discovered the magic within herself, and she continued to have many more wonderful adventures.''',
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Anonymous',
        'isPublished': true,
        'language': 'english',
        'level': 'A2',
        'category': 'Fiction',
        'tags': ['adventure', 'fantasy', 'short-story'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'viewCount': 0,
        'likeCount': 0,
      };

      // İkinci test hikayesi - News/B1
      final testStory2 = {
        'title': 'Technology Trends in 2025',
        'content': '''The world of technology continues to evolve at an unprecedented pace. In 2025, we are witnessing remarkable developments that are reshaping how we live, work, and interact with our environment.

Artificial Intelligence has become more integrated into our daily lives. Smart home systems now understand our preferences better than ever before. Voice assistants can predict our needs and help us manage our schedules more efficiently. Machine learning algorithms are improving medical diagnoses and helping doctors provide better treatment options for patients.

Electric vehicles are becoming the norm rather than the exception. Major car manufacturers have announced that they will stop producing gasoline-powered cars by 2030. Charging stations are now as common as gas stations in many cities. The environmental impact of transportation is decreasing significantly.

Remote work technology has advanced to new levels. Virtual reality meetings feel almost as natural as being in the same room. Collaboration tools allow teams from different continents to work together seamlessly. The traditional office concept is evolving into flexible, hybrid work environments.

Sustainable technology is at the forefront of innovation. Solar panels are more efficient and affordable than ever. Smart grids optimize energy distribution automatically. Recycling technologies can now process materials that were previously impossible to reuse.

These technological advances promise a future where life is more convenient, sustainable, and connected than we have ever imagined.''',
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Tech Reporter',
        'isPublished': true,
        'language': 'english',
        'level': 'B1',
        'category': 'News',
        'tags': ['technology', 'innovation', 'future'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'viewCount': 15,
        'likeCount': 3,
      };

      // Üçüncü test hikayesi - Academic/B2
      final testStory3 = {
        'title': 'The Science of Learning Languages',
        'content': '''Language acquisition is one of the most fascinating areas of cognitive science. Understanding how the human brain processes and learns new languages can help us develop more effective teaching methods and learning strategies.

The critical period hypothesis suggests that there is an optimal age range for language learning. Children under the age of seven typically acquire languages more naturally and with better pronunciation than older learners. However, this does not mean that adults cannot become fluent in new languages. Adult learners often have advantages such as better analytical skills and existing knowledge of grammar concepts.

Neuroplasticity plays a crucial role in language learning. The brain's ability to form new neural connections allows us to develop language skills throughout our lives. Research using brain imaging technology shows that multilingual individuals have increased gray matter density in areas associated with language processing.

Immersion versus classroom learning has been a subject of ongoing debate. While immersion provides natural context and motivation, structured classroom instruction offers systematic grammar instruction and error correction. The most effective approach often combines both methods.

Memory consolidation is essential for language retention. Sleep plays a vital role in transferring information from short-term to long-term memory. Students who get adequate sleep after language learning sessions show significantly better retention rates than those who do not.

Modern technology offers new opportunities for language learning. Spaced repetition algorithms, adaptive learning systems, and virtual reality environments are revolutionizing how we approach language education. These tools can provide personalized learning experiences that adapt to individual learning styles and progress rates.

Understanding these scientific principles can help language learners optimize their study methods and achieve better results in shorter time periods.''',
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Dr. Language Expert',
        'isPublished': true,
        'language': 'english',
        'level': 'B2',
        'category': 'Academic',
        'tags': ['science', 'education', 'psychology'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'viewCount': 28,
        'likeCount': 7,
      };
      
      // Hikayeleri kaydet
      final stories = [testStory1, testStory2, testStory3];
      for (final story in stories) {
        // Public stories koleksiyonuna ekle
        final docRef = await _firestore
            .collection('stories')
            .doc('english')
            .collection('stories')
            .add(story);
        
        // Author stories koleksiyonuna da ekle
        await _firestore
            .collection('stories_by_author')
            .doc(user.uid)
            .collection('stories')
            .doc(docRef.id)
            .set({
          'storyId': docRef.id,
          'language': story['language'],
          'title': story['title'],
          'isPublished': story['isPublished'],
          'createdAt': story['createdAt'],
        });
        
        print('✅ Test story created successfully with ID: ${docRef.id}');
      }
      
    } catch (e) {
      print('❌ Error creating test stories: $e');
    }
  }
  
  static Future<void> createTurkishTestStory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      // İlk Türkçe hikaye - Literature/B1
      final testStory1 = {
        'title': 'Küçük Prens ve Yıldızlar',
        'content': '''Küçük bir gezegende yaşayan Küçük Prens, her gece yıldızlara bakarak hayaller kurardı. Onun gezegeni o kadar küçüktü ki, günde kırk dört gün batımı izleyebilirdi.

Bir gün, gezegene tuhaf bir tohum düştü. Küçük Prens bu tohumu özenle suladı ve büyümesini bekledi. Tohum büyüdükçe, güzel bir gül çiçeği haline geldi. Ama bu gül çok kibirliydi ve sürekli övgü istiyordu.

Küçük Prens, gülün kibriyle başa çıkamayınca, gezegeni terk etmeye karar verdi. Gökyüzündeki kuşlara binip farklı gezegenleri ziyaret etmeye başladı.

İlk ziyaret ettiği gezegende yalnız bir kral yaşıyordu. Kral, Küçük Prens'ten kendisine itaat etmesini istedi, ama Küçük Prens özgürlüğünü daha çok seviyordu.

İkinci gezegende kibirli bir adam vardı. Bu adam, sürekle kendisini övüyordu ve başkalarından alkış bekliyordu. Küçük Prens bu davranışı çok tuhaf buldu.

Üçüncü gezegende ise içki içen bir adam vardı. Adam, içki içtiği için utandığını, utandığı için de içki içtiğini söylüyordu. Bu durum Küçük Prens'i çok üzdü.

En sonunda Dünya'ya geldi ve burada bir pilot ile arkadaş oldu. Pilot ona çok güzel bir koyun çizdi ve Küçük Prens çok mutlu oldu.''',
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Anonim',
        'isPublished': true,
        'language': 'turkish',
        'level': 'B1',
        'category': 'Literature',
        'tags': ['klasik', 'felsefe', 'çocuk'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'viewCount': 12,
        'likeCount': 4,
      };

      // İkinci Türkçe hikaye - Culture/A2
      final testStory2 = {
        'title': 'Türk Kahvesi Geleneği',
        'content': '''Türk kahvesi, Türk kültürünün en önemli sembollerinden biridir. UNESCO tarafından İnsanlığın Somut Olmayan Kültürel Mirası listesine alınmıştır.

Kahve, 16. yüzyılda Osmanlı İmparatorluğu'na geldi. İlk kahvehane 1554 yılında İstanbul'da açıldı. O zamandan beri Türk kahvesi, sosyal hayatın vazgeçilmez bir parçası oldu.

Türk kahvesi yapımı özel bir sanattır. Kahve çekirdekleri çok ince öğütülür. Cezve adı verilen özel bir katta pişirilir. Su, kahve ve şeker bir arada kaynatılır. Köpüğü çok önemlidir.

Geleneksel olarak, kahve en büyük kişiden başlayarak ikram edilir. Misafire kahve ikram etmek, misafirperverliğin bir göstergesidir. Kahve ile birlikte genellikle lokum veya çikolata sunulur.

Evlilik geleneklerinde de önemli bir yeri vardır. Kız isteme merasiminde, kızın demlediği kahve erkek tarafına sunulur. Bu, kızın ev hanımlığı becerilerini gösterme fırsatıdır.

Günümüzde modern kahve çeşitleri yaygınlaşsa da, Türk kahvesi hala sevilerek içilmektedir. Özellikle özel günlerde ve misafir ağırlamalarında tercih edilir.

Bu güzel gelenek, kuşaktan kuşağa aktarılarak yaşatılmaktadır.''',
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Kültür Yazarı',
        'isPublished': true,
        'language': 'turkish',
        'level': 'A2',
        'category': 'Culture',
        'tags': ['kültür', 'gelenek', 'tarih'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'viewCount': 8,
        'likeCount': 2,
      };

      // Üçüncü Türkçe hikaye - News/B2
      final testStory3 = {
        'title': 'Türkiye\'de Dijital Dönüşüm',
        'content': '''Türkiye, son yıllarda dijital dönüşüm alanında önemli adımlar atmaktadır. Hem kamu hem de özel sektörde teknolojik yenilikler hayatımızı kolaylaştırmaktadır.

E-Devlet uygulamaları sayesinde birçok işlemimizi artık evden yapabiliyoruz. Nüfus cüzdanından vergi dairesine, SGK'dan emlak işlemlerine kadar pek çok hizmet dijital ortamda sunulmaktadır. Bu durum, hem vatandaşların zamanını koruyor hem de bürokrasiyi azaltıyor.

Bankacılık sektöründe mobil uygulamalar büyük gelişim gösterdi. Para transferleri, fatura ödemeleri ve yatırım işlemleri artık telefonlarımızdan kolayca yapılabiliyor. QR kod ile ödeme sistemi de yaygınlaştı.

Eğitim alanında uzaktan öğretim teknolojileri pandemi döneminde büyük önem kazandı. Üniversiteler ve okullar, online eğitim platformlarını geliştirdi. Öğrenciler evlerinden derslerine katılabilir hale geldi.

E-ticaret sektörü çok hızlı büyüyor. Küçük işletmeler bile artık internet üzerinden satış yapabiliyor. Kargo ve lojistik sistemleri de bu gelişmelere uyum sağladı.

Sağlık alanında telemedicine uygulamaları yaygınlaşıyor. Hastalar, doktorlarıyla video konferans ile görüşebiliyor. Reçeteler elektronik ortamda düzenleniyor.

Bu dijital dönüşüm süreci, Türkiye'yi teknoloji konusunda daha rekabetçi bir konuma getirmektedir. Geleceğe hazırlık açısından büyük önem taşımaktadır.''',
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Teknoloji Editörü',
        'isPublished': true,
        'language': 'turkish',
        'level': 'B2',
        'category': 'News',
        'tags': ['teknoloji', 'dijital', 'gelişim'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'viewCount': 22,
        'likeCount': 6,
      };
      
      // Hikayeleri kaydet
      final stories = [testStory1, testStory2, testStory3];
      for (final story in stories) {
        // Public stories koleksiyonuna ekle
        final docRef = await _firestore
            .collection('stories')
            .doc('turkish')
            .collection('stories')
            .add(story);
        
        // Author stories koleksiyonuna da ekle
        await _firestore
            .collection('stories_by_author')
            .doc(user.uid)
            .collection('stories')
            .doc(docRef.id)
            .set({
          'storyId': docRef.id,
          'language': story['language'],
          'title': story['title'],
          'isPublished': story['isPublished'],
          'createdAt': story['createdAt'],
        });
        
        print('✅ Turkish test story created successfully with ID: ${docRef.id}');
      }
      
    } catch (e) {
      print('❌ Error creating Turkish test stories: $e');
    }
  }
}
