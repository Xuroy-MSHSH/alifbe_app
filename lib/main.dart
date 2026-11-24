import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const QuvnoqAlifbeApp());
}

enum AlifboTili { uz, ru, en }

class QuvnoqAlifbeApp extends StatelessWidget {
  const QuvnoqAlifbeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quvnoq Alifbe (UZ / RU / EN)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.fredokaTextTheme(),
      ),
      home: const KirishSahifasi(),
    );
  }
}

/// ============================================================================
/// 1. TELEFON RAQAM VA SMS-KOD ORQALI KIRISH / RO'YXATDAN O'TISH SAHIFASI
/// ============================================================================
class KirishSahifasi extends StatefulWidget {
  const KirishSahifasi({super.key});

  @override
  State<KirishSahifasi> createState() => _KirishSahifasiState();
}

class _KirishSahifasiState extends State<KirishSahifasi> {
  AlifboTili _tanlanganTil = AlifboTili.uz;
  final TextEditingController _telefonController = TextEditingController();
  final List<TextEditingController> _kodControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _kodFocusNodes = List.generate(4, (_) => FocusNode());

  bool _smsYuborildi = false;
  String _generatsiyaQilinganKod = '';
  String? _xatoMatni;

  Timer? _taymer;
  int _qolganSoniya = 60;

  @override
  void dispose() {
    _taymer?.cancel();
    _telefonController.dispose();
    for (final c in _kodControllers) {
      c.dispose();
    }
    for (final f in _kodFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _taymerniBoshlash() {
    _taymer?.cancel();
    setState(() => _qolganSoniya = 60);
    _taymer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_qolganSoniya > 0) {
        setState(() => _qolganSoniya--);
      } else {
        timer.cancel();
      }
    });
  }

  void _smsKodYuborish() {
    final raqam = _telefonController.text.replaceAll(RegExp(r'\D'), '');
    if (raqam.length < 9) {
      setState(() {
        _xatoMatni = _tanlanganTil == AlifboTili.ru
            ? 'Введите 9-значный номер телефона'
            : (_tanlanganTil == AlifboTili.en
                ? 'Enter a 9-digit phone number'
                : '9 xonali telefon raqamingizni to‘liq kiriting');
      });
      return;
    }

    // 4 xonali tasodifiy SMS-kod yaratish (Real loyihada Eskiz.uz / Firebase API shu yerga ulanadi)
    final tasodifiyKod = (1000 + Random().nextInt(9000)).toString();

    setState(() {
      _generatsiyaQilinganKod = tasodifiyKod;
      _smsYuborildi = true;
      _xatoMatni = null;
      for (final c in _kodControllers) {
        c.clear();
      }
    });

    _taymerniBoshlash();

    // Brauzerda darhol sinash uchun SMS-kodni bildirishnoma sifatida ko'rsatish
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E88E5),
        duration: const Duration(seconds: 8),
        content: Text(
          '📩 SMS (+998 ${_telefonController.text}): Tasdiqlash kodi — $tasodifiyKod',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _kodFocusNodes[0].requestFocus();
    });
  }

  void _smsKodniTekshirish() {
    final kiritilganKod = _kodControllers.map((c) => c.text).join();
    if (kiritilganKod.length < 4) {
      setState(() {
        _xatoMatni = _tanlanganTil == AlifboTili.ru
            ? 'Введите 4-значный код из СМС'
            : (_tanlanganTil == AlifboTili.en
                ? 'Enter the 4-digit SMS code'
                : 'SMS orqali kelgan 4 xonali kodni kiriting');
      });
      return;
    }

    if (kiritilganKod == _generatsiyaQilinganKod) {
      _taymer?.cancel();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RasmMosAlifbeSahifa(
            boshlangichTil: _tanlanganTil,
            foydalanuvchiTelefoni: '+998 ${_telefonController.text}',
          ),
        ),
      );
    } else {
      setState(() {
        _xatoMatni = _tanlanganTil == AlifboTili.ru
            ? 'Неверный СМС-код, попробуйте снова'
            : (_tanlanganTil == AlifboTili.en
                ? 'Invalid SMS code, please try again'
                : 'SMS-kod noto‘g‘ri, qayta tekshirib kiriting');
      });
    }
  }

  String get _sarlavha {
    switch (_tanlanganTil) {
      case AlifboTili.uz:
        return 'QUVNOQ ALIFBE';
      case AlifboTili.ru:
        return 'ВЕСЁЛАЯ АЗБУКА';
      case AlifboTili.en:
        return 'FUN ALPHABET';
    }
  }

  String get _kirishMatni {
    if (!_smsYuborildi) {
      switch (_tanlanganTil) {
        case AlifboTili.uz:
          return 'Kirish va ro‘yxatdan o‘tish';
        case AlifboTili.ru:
          return 'Вход и регистрация';
        case AlifboTili.en:
          return 'Login & Sign Up';
      }
    } else {
      switch (_tanlanganTil) {
        case AlifboTili.uz:
          return 'SMS-kodni tasdiqlang';
        case AlifboTili.ru:
          return 'Подтвердите СМС-код';
        case AlifboTili.en:
          return 'Verify SMS Code';
      }
    }
  }

  String get _tugmaMatni {
    if (!_smsYuborildi) {
      switch (_tanlanganTil) {
        case AlifboTili.uz:
          return 'SMS-kod olish';
        case AlifboTili.ru:
          return 'Получить СМС-код';
        case AlifboTili.en:
          return 'Get SMS Code';
      }
    } else {
      switch (_tanlanganTil) {
        case AlifboTili.uz:
          return 'Tasdiqlash va kirish';
        case AlifboTili.ru:
          return 'Подтвердить и войти';
        case AlifboTili.en:
          return 'Verify & Enter';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4ECDC4),
              Color(0xFF88D498),
              Color(0xFF6BCB77),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Til tanlash tugmalari (UZ / RU / EN)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _tilChip('🇺🇿 UZ', AlifboTili.uz),
                          _tilChip('🇷🇺 RU', AlifboTili.ru),
                          _tilChip('🇬🇧 EN', AlifboTili.en),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Oq asosiy kirish kartochkasi
                    Container(
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text('🎨📚', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 6),
                          Text(
                            _sarlavha,
                            style: GoogleFonts.fredoka(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E88E5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _kirishMatni,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (!_smsYuborildi) ...[
                            // Telefon raqam kiritish maydoni (+998)
                            TextField(
                              controller: _telefonController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(9),
                              ],
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                              decoration: InputDecoration(
                                labelText: _tanlanganTil == AlifboTili.ru
                                    ? 'Номер телефона'
                                    : (_tanlanganTil == AlifboTili.en
                                        ? 'Phone number'
                                        : 'Telefon raqami'),
                                hintText: '90 123 45 67',
                                prefixIcon: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 14),
                                  child: const Text(
                                    '🇺🇿 +998',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1565C0),
                                    ),
                                  ),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF3F8FF),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF90CAF9), width: 2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF90CAF9), width: 2),
                                ),
                              ),
                              onSubmitted: (_) => _smsKodYuborish(),
                            ),
                          ] else ...[
                            // Yuborilgan telefon raqami va o'zgartirish tugmasi
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '+998 ${_telefonController.text}',
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    _taymer?.cancel();
                                    setState(() {
                                      _smsYuborildi = false;
                                      _xatoMatni = null;
                                    });
                                  },
                                  icon: const Icon(Icons.edit_rounded,
                                      color: Colors.orange),
                                  tooltip: 'Raqamni o‘zgartirish',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // 4 xonali SMS-kod katakchalari
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(4, (index) {
                                return SizedBox(
                                  width: 62,
                                  height: 68,
                                  child: TextField(
                                    controller: _kodControllers[index],
                                    focusNode: _kodFocusNodes[index],
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(1),
                                    ],
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1565C0),
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFFF3F8FF),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF2196F3), width: 2),
                                      ),
                                    ),
                                    onChanged: (val) {
                                      if (val.isNotEmpty && index < 3) {
                                        _kodFocusNodes[index + 1]
                                            .requestFocus();
                                      } else if (val.isEmpty && index > 0) {
                                        _kodFocusNodes[index - 1]
                                            .requestFocus();
                                      }
                                      if (index == 3 && val.isNotEmpty) {
                                        _smsKodniTekshirish();
                                      }
                                    },
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 12),

                            // Qayta SMS yuborish taymeri
                            if (_qolganSoniya > 0)
                              Text(
                                _tanlanganTil == AlifboTili.ru
                                    ? 'Отправить повторно через $_qolganSoniya сек'
                                    : (_tanlanganTil == AlifboTili.en
                                        ? 'Resend code in $_qolganSoniya s'
                                        : 'Kodni qayta yuborish: $_qolganSoniya soniya'),
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 14),
                              )
                            else
                              TextButton.icon(
                                onPressed: _smsKodYuborish,
                                icon: const Icon(Icons.refresh_rounded),
                                label: Text(
                                  _tanlanganTil == AlifboTili.ru
                                      ? 'Отправить СМС снова'
                                      : (_tanlanganTil == AlifboTili.en
                                          ? 'Resend SMS Code'
                                          : 'SMS-kodni qayta yuborish'),
                                ),
                              ),
                          ],

                          // Xatolik xabari
                          if (_xatoMatni != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _xatoMatni!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFE53935),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],

                          const SizedBox(height: 22),

                          // Asosiy tasdiqlash tugmasi
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _smsYuborildi
                                  ? _smsKodniTekshirish
                                  : _smsKodYuborish,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _smsYuborildi
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFF2196F3),
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                              child: Text(
                                _tugmaMatni,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tilChip(String label, AlifboTili til) {
    final bool aktiv = _tanlanganTil == til;
    return GestureDetector(
      onTap: () => setState(() {
        _tanlanganTil = til;
        _xatoMatni = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: aktiv ? const Color(0xFF2196F3) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: aktiv ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// 2. ASOSIY ALIFBE VA HUSNIXAT O'YIN SAHIFASI (UZ / RU / EN)
/// ============================================================================
class HarfDarsModel {
  final String katta;
  final String kichik;
  final String soz;
  final String talaffuzMatni;
  final String emoji;
  final String audioFayl;
  final bool unli;

  const HarfDarsModel({
    required this.katta,
    required this.kichik,
    required this.soz,
    required this.talaffuzMatni,
    required this.emoji,
    required this.audioFayl,
    this.unli = false,
  });
}

class OvozIjrochi {
  static final AudioPlayer _player = AudioPlayer();
  static final FlutterTts _tts = FlutterTts();

  static Future<void> harfniTalaffuzQil(
      HarfDarsModel harf, AlifboTili til) async {
    try {
      await _player.stop();
      await _tts.stop();
      await _player
          .play(AssetSource('audio/${til.name}_${harf.audioFayl}.mp3'));
    } catch (_) {
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.15);

      final tillar = await _tts.getLanguages;
      if (til == AlifboTili.ru) {
        await _tts.setLanguage('ru-RU');
      } else if (til == AlifboTili.en) {
        await _tts.setLanguage('en-US');
      } else {
        if (tillar is List && tillar.contains('uz-UZ')) {
          await _tts.setLanguage('uz-UZ');
        } else if (tillar is List && tillar.contains('tr-TR')) {
          await _tts.setLanguage('tr-TR');
        } else {
          await _tts.setLanguage('ru-RU');
        }
      }
      await _tts.speak(harf.talaffuzMatni);
    }
  }

  static Future<void> tabrikOvoz(AlifboTili til) async {
    await _tts.stop();
    if (til == AlifboTili.ru) {
      await _tts.setLanguage('ru-RU');
      await _tts.speak('Молодец! Отлично!');
    } else if (til == AlifboTili.en) {
      await _tts.setLanguage('en-US');
      await _tts.speak('Awesome! Great job!');
    } else {
      await _tts.speak('Barakalla! Ajoyib!');
    }
  }
}

/// 1. O'ZBEK ALIFBOSI
const List<HarfDarsModel> uzbekAlifbosi = [
  HarfDarsModel(
      katta: 'O',
      kichik: 'o',
      soz: 'Olmaxon',
      talaffuzMatni: 'O harfi! Olmaxon',
      emoji: '🐿️',
      audioFayl: 'o',
      unli: true),
  HarfDarsModel(
      katta: 'N',
      kichik: 'n',
      soz: 'Non',
      talaffuzMatni: 'N harfi! Non',
      emoji: '🍞',
      audioFayl: 'n'),
  HarfDarsModel(
      katta: 'A',
      kichik: 'a',
      soz: 'Archa',
      talaffuzMatni: 'A harfi! Archa',
      emoji: '🌲',
      audioFayl: 'a',
      unli: true),
  HarfDarsModel(
      katta: 'I',
      kichik: 'i',
      soz: 'Nina',
      talaffuzMatni: 'I harfi! Nina',
      emoji: '🪡',
      audioFayl: 'i',
      unli: true),
  HarfDarsModel(
      katta: 'M',
      kichik: 'm',
      soz: 'Maymun',
      talaffuzMatni: 'M harfi! Maymun',
      emoji: '🐒',
      audioFayl: 'm'),
  HarfDarsModel(
      katta: 'T',
      kichik: 't',
      soz: 'Tulki',
      talaffuzMatni: 'T harfi! Tulki',
      emoji: '🦊',
      audioFayl: 't'),
  HarfDarsModel(
      katta: 'L',
      kichik: 'l',
      soz: 'Lola',
      talaffuzMatni: 'L harfi! Lola',
      emoji: '🌷',
      audioFayl: 'l'),
  HarfDarsModel(
      katta: 'B',
      kichik: 'b',
      soz: 'Baliq',
      talaffuzMatni: 'B harfi! Baliq',
      emoji: '🐠',
      audioFayl: 'b'),
  HarfDarsModel(
      katta: 'K',
      kichik: 'k',
      soz: 'Koptok',
      talaffuzMatni: 'K harfi! Koptok',
      emoji: '⚽',
      audioFayl: 'k'),
  HarfDarsModel(
      katta: 'R',
      kichik: 'r',
      soz: 'Ruchka',
      talaffuzMatni: 'R harfi! Ruchka',
      emoji: '🖊️',
      audioFayl: 'r'),
  HarfDarsModel(
      katta: 'O‘',
      kichik: 'o‘',
      soz: 'O‘rik',
      talaffuzMatni: 'O‘ harfi! O‘rik',
      emoji: '🍑',
      audioFayl: 'o_tut',
      unli: true),
  HarfDarsModel(
      katta: 'D',
      kichik: 'd',
      soz: 'Doira',
      talaffuzMatni: 'D harfi! Doira',
      emoji: '🥁',
      audioFayl: 'd'),
  HarfDarsModel(
      katta: 'U',
      kichik: 'u',
      soz: 'Uy',
      talaffuzMatni: 'U harfi! Uy',
      emoji: '🏠',
      audioFayl: 'u',
      unli: true),
  HarfDarsModel(
      katta: 'Y',
      kichik: 'y',
      soz: 'Yo‘lbars',
      talaffuzMatni: 'Y harfi! Yo‘lbars',
      emoji: '🐅',
      audioFayl: 'y'),
  HarfDarsModel(
      katta: 'E',
      kichik: 'e',
      soz: 'Echki',
      talaffuzMatni: 'E harfi! Echki',
      emoji: '🐐',
      audioFayl: 'e',
      unli: true),
  HarfDarsModel(
      katta: 'G',
      kichik: 'g',
      soz: 'Gul',
      talaffuzMatni: 'G harfi! Gul',
      emoji: '🌹',
      audioFayl: 'g'),
  HarfDarsModel(
      katta: 'Ng',
      kichik: 'ng',
      soz: 'Bodring',
      talaffuzMatni: 'Ng harfi! Bodring',
      emoji: '🥒',
      audioFayl: 'ng'),
  HarfDarsModel(
      katta: 'S',
      kichik: 's',
      soz: 'Soyabon',
      talaffuzMatni: 'S harfi! Soyabon',
      emoji: '☂️',
      audioFayl: 's'),
  HarfDarsModel(
      katta: 'H',
      kichik: 'h',
      soz: 'Handalak',
      talaffuzMatni: 'H harfi! Handalak',
      emoji: '🍈',
      audioFayl: 'h'),
  HarfDarsModel(
      katta: 'Sh',
      kichik: 'sh',
      soz: 'Sher',
      talaffuzMatni: 'Sh harfi! Sher',
      emoji: '🦁',
      audioFayl: 'sh'),
  HarfDarsModel(
      katta: 'P',
      kichik: 'p',
      soz: 'Kapalak',
      talaffuzMatni: 'P harfi! Kapalak',
      emoji: '🦋',
      audioFayl: 'p'),
  HarfDarsModel(
      katta: 'Q',
      kichik: 'q',
      soz: 'Quyosh',
      talaffuzMatni: 'Q harfi! Quyosh',
      emoji: '☀️',
      audioFayl: 'q'),
  HarfDarsModel(
      katta: 'Ch',
      kichik: 'ch',
      soz: 'Choynak',
      talaffuzMatni: 'Ch harfi! Choynak',
      emoji: '🫖',
      audioFayl: 'ch'),
  HarfDarsModel(
      katta: 'J',
      kichik: 'j',
      soz: 'Jo‘ja',
      talaffuzMatni: 'J harfi! Jo‘ja',
      emoji: '🐥',
      audioFayl: 'j'),
  HarfDarsModel(
      katta: 'G‘',
      kichik: 'g‘',
      soz: 'Nog‘ora',
      talaffuzMatni: 'G‘ harfi! Nog‘ora',
      emoji: '🥁',
      audioFayl: 'g_tut'),
  HarfDarsModel(
      katta: 'Z',
      kichik: 'z',
      soz: 'Uzum',
      talaffuzMatni: 'Z harfi! Uzum',
      emoji: '🍇',
      audioFayl: 'z'),
  HarfDarsModel(
      katta: 'V',
      kichik: 'v',
      soz: 'Varrak',
      talaffuzMatni: 'V harfi! Varrak',
      emoji: '🪁',
      audioFayl: 'v'),
  HarfDarsModel(
      katta: 'X',
      kichik: 'x',
      soz: 'Xo‘roz',
      talaffuzMatni: 'X harfi! Xo‘roz',
      emoji: '🐓',
      audioFayl: 'x'),
  HarfDarsModel(
      katta: 'F',
      kichik: 'f',
      soz: 'Fil',
      talaffuzMatni: 'F harfi! Fil',
      emoji: '🐘',
      audioFayl: 'f'),
  HarfDarsModel(
      katta: '’',
      kichik: '’',
      soz: 'A’lo',
      talaffuzMatni: 'Tutuq belgisi! A’lo',
      emoji: '🌟',
      audioFayl: 'tutuq'),
];

/// 2. RUS ALIFBOSI
const List<HarfDarsModel> rusAlifbosi = [
  HarfDarsModel(
      katta: 'А',
      kichik: 'а',
      soz: 'Арбуз',
      talaffuzMatni: 'Буква А! Арбуз',
      emoji: '🍉',
      audioFayl: 'a',
      unli: true),
  HarfDarsModel(
      katta: 'Б',
      kichik: 'б',
      soz: 'Бабочка',
      talaffuzMatni: 'Буква Б! Бабочка',
      emoji: '🦋',
      audioFayl: 'b'),
  HarfDarsModel(
      katta: 'В',
      kichik: 'в',
      soz: 'Волк',
      talaffuzMatni: 'Буква В! Волк',
      emoji: '🐺',
      audioFayl: 'v'),
  HarfDarsModel(
      katta: 'Г',
      kichik: 'г',
      soz: 'Гриб',
      talaffuzMatni: 'Буква Г! Гриб',
      emoji: '🍄',
      audioFayl: 'g'),
  HarfDarsModel(
      katta: 'Д',
      kichik: 'д',
      soz: 'Дом',
      talaffuzMatni: 'Буква Д! Дом',
      emoji: '🏠',
      audioFayl: 'd'),
  HarfDarsModel(
      katta: 'Е',
      kichik: 'е',
      soz: 'Енот',
      talaffuzMatni: 'Буква Е! Енот',
      emoji: '🦝',
      audioFayl: 'e',
      unli: true),
  HarfDarsModel(
      katta: 'Ё',
      kichik: 'ё',
      soz: 'Ёжик',
      talaffuzMatni: 'Буква Ё! Ёжик',
      emoji: '🦔',
      audioFayl: 'yo',
      unli: true),
  HarfDarsModel(
      katta: 'Ж',
      kichik: 'ж',
      soz: 'Жираф',
      talaffuzMatni: 'Буква Ж! Жираф',
      emoji: '🦒',
      audioFayl: 'zh'),
  HarfDarsModel(
      katta: 'З',
      kichik: 'з',
      soz: 'Заяц',
      talaffuzMatni: 'Буква З! Заяц',
      emoji: '🐰',
      audioFayl: 'z'),
  HarfDarsModel(
      katta: 'И',
      kichik: 'и',
      soz: 'Игрушка',
      talaffuzMatni: 'Буква И! Игрушка',
      emoji: '🧸',
      audioFayl: 'i',
      unli: true),
  HarfDarsModel(
      katta: 'Й',
      kichik: 'й',
      soz: 'Йогурт',
      talaffuzMatni: 'И краткое! Йогурт',
      emoji: '🥛',
      audioFayl: 'y_kr'),
  HarfDarsModel(
      katta: 'К',
      kichik: 'к',
      soz: 'Кот',
      talaffuzMatni: 'Буква К! Кот',
      emoji: '🐱',
      audioFayl: 'k'),
  HarfDarsModel(
      katta: 'Л',
      kichik: 'л',
      soz: 'Лиса',
      talaffuzMatni: 'Буква Л! Лиса',
      emoji: '🦊',
      audioFayl: 'l'),
  HarfDarsModel(
      katta: 'М',
      kichik: 'м',
      soz: 'Медведь',
      talaffuzMatni: 'Буква М! Медведь',
      emoji: '🐻',
      audioFayl: 'm'),
  HarfDarsModel(
      katta: 'Н',
      kichik: 'н',
      soz: 'Носорог',
      talaffuzMatni: 'Буква Н! Носорог',
      emoji: '🦏',
      audioFayl: 'n'),
  HarfDarsModel(
      katta: 'О',
      kichik: 'о',
      soz: 'Облако',
      talaffuzMatni: 'Буква О! Облако',
      emoji: '☁️',
      audioFayl: 'o',
      unli: true),
  HarfDarsModel(
      katta: 'П',
      kichik: 'п',
      soz: 'Пчела',
      talaffuzMatni: 'Буква П! Пчела',
      emoji: '🐝',
      audioFayl: 'p'),
  HarfDarsModel(
      katta: 'Р',
      kichik: 'р',
      soz: 'Рыба',
      talaffuzMatni: 'Буква Р! Рыба',
      emoji: '🐠',
      audioFayl: 'r'),
  HarfDarsModel(
      katta: 'С',
      kichik: 'с',
      soz: 'Солнце',
      talaffuzMatni: 'Буква С! Солнце',
      emoji: '☀️',
      audioFayl: 's'),
  HarfDarsModel(
      katta: 'Т',
      kichik: 'т',
      soz: 'Тигр',
      talaffuzMatni: 'Буква Т! Тигр',
      emoji: '🐅',
      audioFayl: 't'),
  HarfDarsModel(
      katta: 'У',
      kichik: 'у',
      soz: 'Утка',
      talaffuzMatni: 'Буква У! Утка',
      emoji: '🦆',
      audioFayl: 'u',
      unli: true),
  HarfDarsModel(
      katta: 'Ф',
      kichik: 'ф',
      soz: 'Флаг',
      talaffuzMatni: 'Буква Ф! Флаг',
      emoji: '🚩',
      audioFayl: 'f'),
  HarfDarsModel(
      katta: 'Х',
      kichik: 'х',
      soz: 'Хлеб',
      talaffuzMatni: 'Буква Х! Хлеб',
      emoji: '🍞',
      audioFayl: 'x'),
  HarfDarsModel(
      katta: 'Ц',
      kichik: 'ц',
      soz: 'Цветок',
      talaffuzMatni: 'Буква Ц! Цветок',
      emoji: '🌸',
      audioFayl: 'ts'),
  HarfDarsModel(
      katta: 'Ч',
      kichik: 'ч',
      soz: 'Черепаха',
      talaffuzMatni: 'Буква Ч! Черепаха',
      emoji: '🐢',
      audioFayl: 'ch'),
  HarfDarsModel(
      katta: 'Ш',
      kichik: 'ш',
      soz: 'Шар',
      talaffuzMatni: 'Буква Ш! Шар',
      emoji: '🎈',
      audioFayl: 'sh'),
  HarfDarsModel(
      katta: 'Щ',
      kichik: 'щ',
      soz: 'Щенок',
      talaffuzMatni: 'Буква Щ! Щенок',
      emoji: '🐶',
      audioFayl: 'shch'),
  HarfDarsModel(
      katta: 'Ъ',
      kichik: 'ъ',
      soz: 'Твёрдый знак',
      talaffuzMatni: 'Твёрдый знак',
      emoji: '✍️',
      audioFayl: 'tverd'),
  HarfDarsModel(
      katta: 'Ы',
      kichik: 'ы',
      soz: 'Сыр',
      talaffuzMatni: 'Буква Ы! Сыр',
      emoji: '🧀',
      audioFayl: 'yi',
      unli: true),
  HarfDarsModel(
      katta: 'Ь',
      kichik: 'ь',
      soz: 'Мягкий знак',
      talaffuzMatni: 'Мягкий знак',
      emoji: '🪶',
      audioFayl: 'myagk'),
  HarfDarsModel(
      katta: 'Э',
      kichik: 'э',
      soz: 'Экскаватор',
      talaffuzMatni: 'Буква Э! Экскаватор',
      emoji: '🚜',
      audioFayl: 'eh',
      unli: true),
  HarfDarsModel(
      katta: 'Ю',
      kichik: 'ю',
      soz: 'Юла',
      talaffuzMatni: 'Буква Ю! Юла',
      emoji: '🪀',
      audioFayl: 'yu',
      unli: true),
  HarfDarsModel(
      katta: 'Я',
      kichik: 'я',
      soz: 'Яблоко',
      talaffuzMatni: 'Буква Я! Яблоко',
      emoji: '🍎',
      audioFayl: 'ya',
      unli: true),
];

/// 3. INGLIZ ALIFBOSI
const List<HarfDarsModel> englishAlifbosi = [
  HarfDarsModel(
      katta: 'A',
      kichik: 'a',
      soz: 'Apple',
      talaffuzMatni: 'Letter A! Apple',
      emoji: '🍎',
      audioFayl: 'a',
      unli: true),
  HarfDarsModel(
      katta: 'B',
      kichik: 'b',
      soz: 'Ball',
      talaffuzMatni: 'Letter B! Ball',
      emoji: '⚽',
      audioFayl: 'b'),
  HarfDarsModel(
      katta: 'C',
      kichik: 'c',
      soz: 'Cat',
      talaffuzMatni: 'Letter C! Cat',
      emoji: '🐱',
      audioFayl: 'c'),
  HarfDarsModel(
      katta: 'D',
      kichik: 'd',
      soz: 'Dog',
      talaffuzMatni: 'Letter D! Dog',
      emoji: '🐶',
      audioFayl: 'd'),
  HarfDarsModel(
      katta: 'E',
      kichik: 'e',
      soz: 'Elephant',
      talaffuzMatni: 'Letter E! Elephant',
      emoji: '🐘',
      audioFayl: 'e',
      unli: true),
  HarfDarsModel(
      katta: 'F',
      kichik: 'f',
      soz: 'Fish',
      talaffuzMatni: 'Letter F! Fish',
      emoji: '🐠',
      audioFayl: 'f'),
  HarfDarsModel(
      katta: 'G',
      kichik: 'g',
      soz: 'Grapes',
      talaffuzMatni: 'Letter G! Grapes',
      emoji: '🍇',
      audioFayl: 'g'),
  HarfDarsModel(
      katta: 'H',
      kichik: 'h',
      soz: 'House',
      talaffuzMatni: 'Letter H! House',
      emoji: '🏠',
      audioFayl: 'h'),
  HarfDarsModel(
      katta: 'I',
      kichik: 'i',
      soz: 'Ice cream',
      talaffuzMatni: 'Letter I! Ice cream',
      emoji: '🍦',
      audioFayl: 'i',
      unli: true),
  HarfDarsModel(
      katta: 'J',
      kichik: 'j',
      soz: 'Juice',
      talaffuzMatni: 'Letter J! Juice',
      emoji: '🧃',
      audioFayl: 'j'),
  HarfDarsModel(
      katta: 'K',
      kichik: 'k',
      soz: 'Kite',
      talaffuzMatni: 'Letter K! Kite',
      emoji: '🪁',
      audioFayl: 'k'),
  HarfDarsModel(
      katta: 'L',
      kichik: 'l',
      soz: 'Lion',
      talaffuzMatni: 'Letter L! Lion',
      emoji: '🦁',
      audioFayl: 'l'),
  HarfDarsModel(
      katta: 'M',
      kichik: 'm',
      soz: 'Monkey',
      talaffuzMatni: 'Letter M! Monkey',
      emoji: '🐒',
      audioFayl: 'm'),
  HarfDarsModel(
      katta: 'N',
      kichik: 'n',
      soz: 'Nest',
      talaffuzMatni: 'Letter N! Nest',
      emoji: '🪺',
      audioFayl: 'n'),
  HarfDarsModel(
      katta: 'O',
      kichik: 'o',
      soz: 'Orange',
      talaffuzMatni: 'Letter O! Orange',
      emoji: '🍊',
      audioFayl: 'o',
      unli: true),
  HarfDarsModel(
      katta: 'P',
      kichik: 'p',
      soz: 'Panda',
      talaffuzMatni: 'Letter P! Panda',
      emoji: '🐼',
      audioFayl: 'p'),
  HarfDarsModel(
      katta: 'Q',
      kichik: 'q',
      soz: 'Queen',
      talaffuzMatni: 'Letter Q! Queen',
      emoji: '👑',
      audioFayl: 'q'),
  HarfDarsModel(
      katta: 'R',
      kichik: 'r',
      soz: 'Rabbit',
      talaffuzMatni: 'Letter R! Rabbit',
      emoji: '🐰',
      audioFayl: 'r'),
  HarfDarsModel(
      katta: 'S',
      kichik: 's',
      soz: 'Sun',
      talaffuzMatni: 'Letter S! Sun',
      emoji: '☀️',
      audioFayl: 's'),
  HarfDarsModel(
      katta: 'T',
      kichik: 't',
      soz: 'Tiger',
      talaffuzMatni: 'Letter T! Tiger',
      emoji: '🐅',
      audioFayl: 't'),
  HarfDarsModel(
      katta: 'U',
      kichik: 'u',
      soz: 'Umbrella',
      talaffuzMatni: 'Letter U! Umbrella',
      emoji: '☂️',
      audioFayl: 'u',
      unli: true),
  HarfDarsModel(
      katta: 'V',
      kichik: 'v',
      soz: 'Violin',
      talaffuzMatni: 'Letter V! Violin',
      emoji: '🎻',
      audioFayl: 'v'),
  HarfDarsModel(
      katta: 'W',
      kichik: 'w',
      soz: 'Whale',
      talaffuzMatni: 'Letter W! Whale',
      emoji: '🐋',
      audioFayl: 'w'),
  HarfDarsModel(
      katta: 'X',
      kichik: 'x',
      soz: 'Xylophone',
      talaffuzMatni: 'Letter X! Xylophone',
      emoji: '🎶',
      audioFayl: 'x'),
  HarfDarsModel(
      katta: 'Y',
      kichik: 'y',
      soz: 'Yo-yo',
      talaffuzMatni: 'Letter Y! Yo-yo',
      emoji: '🪀',
      audioFayl: 'y'),
  HarfDarsModel(
      katta: 'Z',
      kichik: 'z',
      soz: 'Zebra',
      talaffuzMatni: 'Letter Z! Zebra',
      emoji: '🦓',
      audioFayl: 'z'),
];

class HarfYolagi {
  final int raqam;
  final List<Offset> nuqtalar;
  final bool yopiqKontur;

  const HarfYolagi({
    required this.raqam,
    required this.nuqtalar,
    this.yopiqKontur = false,
  });
}

class KengHarfGeometriyasi {
  static List<HarfYolagi> yolaklarniOlish(
      String harf, bool kattaHarf, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w * 0.50;
    final double cy = h * 0.50;

    final double ry = h * (kattaHarf ? 0.34 : 0.26);
    final double rx = min(w * 0.30, ry * 0.92);

    Offset p(double nx, double ny) => Offset(cx + nx * rx, cy + ny * ry);

    List<Offset> chiziq(Offset a, Offset b, int n) {
      return List.generate(n, (i) {
        final t = n <= 1 ? 0.0 : i / (n - 1);
        return Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);
      });
    }

    List<Offset> yoy(double ox, double oy, double arx, double ary, double bosh,
        double jami, int n) {
      return List.generate(n, (i) {
        final t = n <= 1 ? 0.0 : i / (n - 1);
        final a = bosh + jami * t;
        return p(ox + arx * cos(a), oy + ary * sin(a));
      });
    }

    final String hNorm = harf.toUpperCase();

    switch (hNorm) {
      case 'B':
      case 'В':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.65, -0.95), p(-0.65, 0.95), 11)),
          HarfYolagi(
            raqam: 2,
            nuqtalar: [
              ...chiziq(p(-0.42, -0.95), p(0.10, -0.95), 4),
              ...yoy(0.10, -0.50, 0.55, 0.45, -pi / 2, pi, 8),
              ...chiziq(p(0.10, -0.05), p(-0.42, -0.05), 4),
            ],
          ),
          HarfYolagi(
            raqam: 3,
            nuqtalar: [
              ...chiziq(p(-0.42, 0.05), p(0.18, 0.05), 4),
              ...yoy(0.18, 0.50, 0.65, 0.45, -pi / 2, pi, 9),
              ...chiziq(p(0.18, 0.95), p(-0.42, 0.95), 4),
            ],
          ),
        ];
      case 'Б':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.60, -0.95), p(0.65, -0.95), 7)),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(-0.60, -0.95), p(-0.60, 0.95), 10)),
          HarfYolagi(
            raqam: 3,
            nuqtalar: [
              ...chiziq(p(-0.55, -0.05), p(0.15, -0.05), 4),
              ...yoy(0.15, 0.45, 0.65, 0.50, -pi / 2, pi, 9),
              ...chiziq(p(0.15, 0.95), p(-0.55, 0.95), 4),
            ],
          ),
        ];
      case 'O':
      case 'О':
        return [
          HarfYolagi(
            raqam: 1,
            yopiqKontur: true,
            nuqtalar: yoy(0, 0, 0.85, 0.95, -pi / 2, 2 * pi, 20),
          ),
        ];
      case 'O‘':
        return [
          HarfYolagi(
            raqam: 1,
            yopiqKontur: true,
            nuqtalar: yoy(-0.12, 0.04, 0.78, 0.90, -pi / 2, 2 * pi, 18),
          ),
          HarfYolagi(
            raqam: 2,
            nuqtalar: yoy(0.82, -0.78, 0.25, 0.25, -pi / 2, pi, 5),
          ),
        ];
      case 'A':
      case 'А':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(0, -0.95), p(-0.82, 0.95), 10)),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(0, -0.95), p(0.82, 0.95), 10)),
          HarfYolagi(
              raqam: 3, nuqtalar: chiziq(p(-0.48, 0.25), p(0.48, 0.25), 6)),
        ];
      case 'N':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.70, 0.95), p(-0.70, -0.95), 10)),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(-0.70, -0.95), p(0.70, 0.95), 10)),
          HarfYolagi(
              raqam: 3, nuqtalar: chiziq(p(0.70, 0.95), p(0.70, -0.95), 10)),
        ];
      case 'Н':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.70, -0.95), p(-0.70, 0.95), 10)),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(0.70, -0.95), p(0.70, 0.95), 10)),
          HarfYolagi(raqam: 3, nuqtalar: chiziq(p(-0.70, 0), p(0.70, 0), 7)),
        ];
      case 'I':
        return [
          HarfYolagi(raqam: 1, nuqtalar: chiziq(p(0, -0.95), p(0, 0.95), 11)),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(-0.42, -0.95), p(0.42, -0.95), 5)),
          HarfYolagi(
              raqam: 3, nuqtalar: chiziq(p(-0.42, 0.95), p(0.42, 0.95), 5)),
        ];
      case 'И':
      case 'Й':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.70, -0.95), p(-0.70, 0.95), 10)),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(-0.70, 0.95), p(0.70, -0.95), 10)),
          HarfYolagi(
              raqam: 3, nuqtalar: chiziq(p(0.70, -0.95), p(0.70, 0.95), 10)),
        ];
      case 'M':
      case 'М':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.85, 0.95), p(-0.85, -0.95), 10)),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(-0.85, -0.95), p(0, 0.25), 7)),
          HarfYolagi(raqam: 3, nuqtalar: chiziq(p(0, 0.25), p(0.85, -0.95), 7)),
          HarfYolagi(
              raqam: 4, nuqtalar: chiziq(p(0.85, -0.95), p(0.85, 0.95), 10)),
        ];
      case 'T':
      case 'Т':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.85, -0.95), p(0.85, -0.95), 9)),
          HarfYolagi(raqam: 2, nuqtalar: chiziq(p(0, -0.95), p(0, 0.95), 10)),
        ];
      case 'L':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.55, -0.95), p(-0.55, 0.95), 10)),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(-0.55, 0.95), p(0.70, 0.95), 7)),
        ];
      case 'Л':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(0, -0.95), p(-0.75, 0.95), 10)),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(0, -0.95), p(0.75, 0.95), 10)),
        ];
      case 'K':
      case 'К':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.60, -0.95), p(-0.60, 0.95), 10)),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(0.70, -0.95), p(-0.55, 0), 8)),
          HarfYolagi(raqam: 3, nuqtalar: chiziq(p(-0.55, 0), p(0.70, 0.95), 8)),
        ];
      case 'R':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.60, -0.95), p(-0.60, 0.95), 10)),
          HarfYolagi(
            raqam: 2,
            nuqtalar: [
              ...chiziq(p(-0.40, -0.95), p(0.15, -0.95), 4),
              ...yoy(0.15, -0.45, 0.60, 0.50, -pi / 2, pi, 8),
              ...chiziq(p(0.15, 0.05), p(-0.40, 0.05), 4),
            ],
          ),
          HarfYolagi(
              raqam: 3, nuqtalar: chiziq(p(-0.10, 0.05), p(0.70, 0.95), 7)),
        ];
      case 'P':
      case 'Р':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.60, -0.95), p(-0.60, 0.95), 10)),
          HarfYolagi(
            raqam: 2,
            nuqtalar: [
              ...chiziq(p(-0.40, -0.95), p(0.15, -0.95), 4),
              ...yoy(0.15, -0.45, 0.65, 0.50, -pi / 2, pi, 9),
              ...chiziq(p(0.15, 0.05), p(-0.40, 0.05), 4),
            ],
          ),
        ];
      case 'П':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.70, 0.95), p(-0.70, -0.95), 10)),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(-0.70, -0.95), p(0.70, -0.95), 8)),
          HarfYolagi(
              raqam: 3, nuqtalar: chiziq(p(0.70, -0.95), p(0.70, 0.95), 10)),
        ];
      case 'D':
      case 'Д':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.65, -0.95), p(-0.65, 0.95), 10)),
          HarfYolagi(
            raqam: 2,
            nuqtalar: [
              ...chiziq(p(-0.45, -0.95), p(-0.10, -0.95), 3),
              ...yoy(-0.10, 0, 0.90, 0.95, -pi / 2, pi, 12),
              ...chiziq(p(-0.10, 0.95), p(-0.45, 0.95), 3),
            ],
          ),
        ];
      case 'U':
        return [
          HarfYolagi(
            raqam: 1,
            nuqtalar: [
              ...chiziq(p(-0.70, -0.95), p(-0.70, 0.25), 6),
              ...yoy(0, 0.25, 0.70, 0.70, pi, -pi, 9),
              ...chiziq(p(0.70, 0.25), p(0.70, -0.95), 6),
            ],
          ),
        ];
      case 'У':
      case 'Y':
        return [
          HarfYolagi(raqam: 1, nuqtalar: chiziq(p(-0.75, -0.95), p(0, 0), 7)),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(0.75, -0.95), p(-0.35, 0.95), 11)),
        ];
      case 'E':
      case 'Е':
      case 'Ё':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.65, -0.95), p(-0.65, 0.95), 10)),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(-0.65, -0.95), p(0.70, -0.95), 7)),
          HarfYolagi(raqam: 3, nuqtalar: chiziq(p(-0.65, 0), p(0.55, 0), 6)),
          HarfYolagi(
              raqam: 4, nuqtalar: chiziq(p(-0.65, 0.95), p(0.70, 0.95), 7)),
        ];
      case 'Э':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: yoy(-0.10, 0, 0.85, 0.95, -pi / 2, pi, 14)),
          HarfYolagi(raqam: 2, nuqtalar: chiziq(p(-0.10, 0), p(0.70, 0), 5)),
        ];
      case 'G':
      case 'G‘':
        return [
          HarfYolagi(
              raqam: 1,
              nuqtalar: yoy(0.05, 0, 0.85, 0.95, -pi / 5, -1.55 * pi, 15)),
          HarfYolagi(
            raqam: 2,
            nuqtalar: [
              ...chiziq(p(0.10, 0.15), p(0.85, 0.15), 5),
              ...chiziq(p(0.85, 0.15), p(0.85, 0.90), 5),
            ],
          ),
        ];
      case 'Г':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.60, 0.95), p(-0.60, -0.95), 10)),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(-0.60, -0.95), p(0.75, -0.95), 7)),
        ];
      case 'S':
      case 'С':
      case 'C':
        return [
          HarfYolagi(
              raqam: 1,
              nuqtalar: yoy(0.15, 0, 0.85, 0.95, -pi / 4, -1.5 * pi, 16)),
        ];
      case 'H':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.70, -0.95), p(-0.70, 0.95), 10)),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(0.70, -0.95), p(0.70, 0.95), 10)),
          HarfYolagi(raqam: 3, nuqtalar: chiziq(p(-0.70, 0), p(0.70, 0), 7)),
        ];
      case 'X':
      case 'Х':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.75, -0.95), p(0.75, 0.95), 11)),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(0.75, -0.95), p(-0.75, 0.95), 11)),
        ];
      case 'Q':
        return [
          HarfYolagi(
            raqam: 1,
            yopiqKontur: true,
            nuqtalar: yoy(0, -0.05, 0.85, 0.90, -pi / 2, 2 * pi, 18),
          ),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(0.25, 0.45), p(0.90, 1.0), 5)),
        ];
      case 'J':
        return [
          HarfYolagi(
            raqam: 1,
            nuqtalar: [
              ...chiziq(p(0.35, -0.95), p(0.35, 0.40), 8),
              ...yoy(-0.15, 0.40, 0.50, 0.55, 0, pi, 7),
            ],
          ),
        ];
      case 'Z':
      case 'З':
        return [
          HarfYolagi(
              raqam: 1,
              nuqtalar: yoy(-0.15, -0.48, 0.70, 0.48, -pi / 2, pi, 8)),
          HarfYolagi(
              raqam: 2, nuqtalar: yoy(-0.15, 0.48, 0.75, 0.48, -pi / 2, pi, 8)),
        ];
      case 'V':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.80, -0.95), p(0, 0.95), 10)),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(0, 0.95), p(0.80, -0.95), 10)),
        ];
      case 'W':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.95, -0.95), p(-0.48, 0.95), 8)),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(-0.48, 0.95), p(0, -0.20), 6)),
          HarfYolagi(raqam: 3, nuqtalar: chiziq(p(0, -0.20), p(0.48, 0.95), 6)),
          HarfYolagi(
              raqam: 4, nuqtalar: chiziq(p(0.48, 0.95), p(0.95, -0.95), 8)),
        ];
      case 'F':
      case 'Ф':
        return [
          HarfYolagi(raqam: 1, nuqtalar: chiziq(p(0, -0.95), p(0, 0.95), 11)),
          HarfYolagi(
            raqam: 2,
            yopiqKontur: true,
            nuqtalar: yoy(0, -0.15, 0.80, 0.52, -pi / 2, 2 * pi, 14),
          ),
        ];
      case 'Ш':
      case 'Щ':
      case 'SH':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.80, -0.95), p(-0.80, 0.95), 8)),
          HarfYolagi(raqam: 2, nuqtalar: chiziq(p(0, -0.95), p(0, 0.95), 8)),
          HarfYolagi(
              raqam: 3, nuqtalar: chiziq(p(0.80, -0.95), p(0.80, 0.95), 8)),
          HarfYolagi(
              raqam: 4, nuqtalar: chiziq(p(-0.80, 0.95), p(0.80, 0.95), 8)),
        ];
      case 'Ч':
      case 'CH':
        return [
          HarfYolagi(
            raqam: 1,
            nuqtalar: [
              ...chiziq(p(-0.65, -0.95), p(-0.65, 0), 6),
              ...chiziq(p(-0.65, 0), p(0.65, 0), 6),
            ],
          ),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(0.65, -0.95), p(0.65, 0.95), 10)),
        ];
      case 'Ж':
        return [
          HarfYolagi(raqam: 1, nuqtalar: chiziq(p(0, -0.95), p(0, 0.95), 10)),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(-0.85, -0.95), p(0.85, 0.95), 10)),
          HarfYolagi(
              raqam: 3, nuqtalar: chiziq(p(0.85, -0.95), p(-0.85, 0.95), 10)),
        ];
      case 'Ц':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.65, -0.95), p(-0.65, 0.95), 9)),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(0.55, -0.95), p(0.55, 0.95), 9)),
          HarfYolagi(
              raqam: 3, nuqtalar: chiziq(p(-0.65, 0.95), p(0.85, 0.95), 8)),
        ];
      case 'Ю':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.80, -0.95), p(-0.80, 0.95), 9)),
          HarfYolagi(raqam: 2, nuqtalar: chiziq(p(-0.80, 0), p(-0.25, 0), 4)),
          HarfYolagi(
            raqam: 3,
            yopiqKontur: true,
            nuqtalar: yoy(0.35, 0, 0.60, 0.90, -pi / 2, 2 * pi, 14),
          ),
        ];
      case 'Я':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(0.60, -0.95), p(0.60, 0.95), 10)),
          HarfYolagi(
            raqam: 2,
            nuqtalar: [
              ...chiziq(p(0.45, -0.95), p(0.05, -0.95), 3),
              ...yoy(0.05, -0.45, 0.65, 0.50, -pi / 2, -pi, 8),
              ...chiziq(p(0.05, 0.05), p(0.45, 0.05), 3),
            ],
          ),
          HarfYolagi(
              raqam: 3, nuqtalar: chiziq(p(0.15, 0.05), p(-0.70, 0.95), 7)),
        ];
      default:
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.50, -0.95), p(-0.50, 0.95), 10)),
          HarfYolagi(
            raqam: 2,
            nuqtalar: [
              ...chiziq(p(-0.35, -0.05), p(0.15, -0.05), 4),
              ...yoy(0.15, 0.45, 0.60, 0.50, -pi / 2, pi, 8),
              ...chiziq(p(0.15, 0.95), p(-0.35, 0.95), 4),
            ],
          ),
        ];
    }
  }
}

class RasmMosAlifbeSahifa extends StatefulWidget {
  final AlifboTili boshlangichTil;
  final String foydalanuvchiTelefoni;

  const RasmMosAlifbeSahifa({
    super.key,
    this.boshlangichTil = AlifboTili.uz,
    this.foydalanuvchiTelefoni = '',
  });

  @override
  State<RasmMosAlifbeSahifa> createState() => _RasmMosAlifbeSahifaState();
}

class _RasmMosAlifbeSahifaState extends State<RasmMosAlifbeSahifa> {
  late AlifboTili _tanlanganTil;
  int _tanlanganIndex = 0;
  bool _kattaHarf = true;

  final Set<String> _ulanganNuqtalar = {};
  final List<List<Offset>> _chiziqlar = [];
  List<Offset> _joriyChiziq = [];
  Offset? _oxirgiUchqunJoyi;

  int _yulduzlar = 0;
  bool _harfYakunlandi = false;

  List<HarfDarsModel> get _joriyAlifbo {
    switch (_tanlanganTil) {
      case AlifboTili.uz:
        return uzbekAlifbosi;
      case AlifboTili.ru:
        return rusAlifbosi;
      case AlifboTili.en:
        return englishAlifbosi;
    }
  }

  HarfDarsModel get _joriyHarf => _joriyAlifbo[_tanlanganIndex];

  @override
  void initState() {
    super.initState();
    _tanlanganTil = widget.boshlangichTil;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OvozIjrochi.harfniTalaffuzQil(_joriyHarf, _tanlanganTil);
    });
  }

  void _tilniAlmashtirish(AlifboTili yangiTil) {
    setState(() {
      _tanlanganTil = yangiTil;
      _tanlanganIndex = 0;
      _ulanganNuqtalar.clear();
      _chiziqlar.clear();
      _joriyChiziq = [];
      _oxirgiUchqunJoyi = null;
      _harfYakunlandi = false;
    });
    OvozIjrochi.harfniTalaffuzQil(_joriyHarf, _tanlanganTil);
  }

  void _nuqtaniTekshir(Offset barmoqJoyi, List<HarfYolagi> yolaklar) {
    int jamiNuqtalar = 0;
    bool yangiUlandi = false;
    const double radius = 34.0;

    for (int yIdx = 0; yIdx < yolaklar.length; yIdx++) {
      final nuqtalar = yolaklar[yIdx].nuqtalar;
      jamiNuqtalar += nuqtalar.length;
      for (int nIdx = 0; nIdx < nuqtalar.length; nIdx++) {
        final key = '$yIdx-$nIdx';
        if (!_ulanganNuqtalar.contains(key)) {
          if ((nuqtalar[nIdx] - barmoqJoyi).distance <= radius) {
            _ulanganNuqtalar.add(key);
            _oxirgiUchqunJoyi = nuqtalar[nIdx];
            yangiUlandi = true;
          }
        }
      }
    }

    if (yangiUlandi && !_harfYakunlandi && jamiNuqtalar > 0) {
      if (_ulanganNuqtalar.length >= (jamiNuqtalar * 0.85).ceil()) {
        _harfYakunlandi = true;
        _yulduzlar += 1;
        OvozIjrochi.tabrikOvoz(_tanlanganTil);
      }
    }
  }

  void _harfniTanlash(int index) {
    setState(() {
      _tanlanganIndex = index;
      _ulanganNuqtalar.clear();
      _chiziqlar.clear();
      _joriyChiziq = [];
      _oxirgiUchqunJoyi = null;
      _harfYakunlandi = false;
    });
    OvozIjrochi.harfniTalaffuzQil(_joriyHarf, _tanlanganTil);
  }

  void _oldingiHarfgaOtish() {
    final int oldingi =
        (_tanlanganIndex - 1 + _joriyAlifbo.length) % _joriyAlifbo.length;
    _harfniTanlash(oldingi);
  }

  void _keyingiHarfgaOtish() {
    final int keyingi = (_tanlanganIndex + 1) % _joriyAlifbo.length;
    _harfniTanlash(keyingi);
  }

  void _tozalash() {
    setState(() {
      _ulanganNuqtalar.clear();
      _chiziqlar.clear();
      _joriyChiziq = [];
      _oxirgiUchqunJoyi = null;
      _harfYakunlandi = false;
    });
  }

  void _tizimdanChiqish() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const KirishSahifasi()),
    );
  }

  String get _sarlavhaMatni {
    switch (_tanlanganTil) {
      case AlifboTili.uz:
        return '${_joriyHarf.katta} HARFI';
      case AlifboTili.ru:
        return 'БУКВА ${_joriyHarf.katta}';
      case AlifboTili.en:
        return 'LETTER ${_joriyHarf.katta}';
    }
  }

  String get _tozalashMatni {
    switch (_tanlanganTil) {
      case AlifboTili.uz:
        return 'Tozalash';
      case AlifboTili.ru:
        return 'Очистить';
      case AlifboTili.en:
        return 'Clear';
    }
  }

  String get _keyingiMatni {
    switch (_tanlanganTil) {
      case AlifboTili.uz:
        return 'Keyingi';
      case AlifboTili.ru:
        return 'Дальше';
      case AlifboTili.en:
        return 'Next';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String korsatiladiganHarf =
        _kattaHarf ? _joriyHarf.katta : _joriyHarf.kichik;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4ECDC4),
              Color(0xFF88D498),
              Color(0xFF6BCB77),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 1. O'rtadagi yirik oq doska
              Positioned(
                top: 68,
                left: 18,
                right: 18,
                bottom: 54,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final Size doskaSize =
                            Size(constraints.maxWidth, constraints.maxHeight);
                        final List<HarfYolagi> yolaklar =
                            KengHarfGeometriyasi.yolaklarniOlish(
                                korsatiladiganHarf, _kattaHarf, doskaSize);

                        return Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: KonturNuqtaliHarfPainter(
                                  yolaklar: yolaklar,
                                  ulanganlar: _ulanganNuqtalar,
                                  yakunlandi: _harfYakunlandi,
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: GestureDetector(
                                onPanStart: (details) {
                                  setState(() {
                                    _joriyChiziq = [details.localPosition];
                                    _chiziqlar.add(_joriyChiziq);
                                    _nuqtaniTekshir(
                                        details.localPosition, yolaklar);
                                  });
                                },
                                onPanUpdate: (details) {
                                  setState(() {
                                    _joriyChiziq.add(details.localPosition);
                                    _nuqtaniTekshir(
                                        details.localPosition, yolaklar);
                                  });
                                },
                                onPanEnd: (_) {
                                  _joriyChiziq = [];
                                },
                                child: CustomPaint(
                                  painter: MoviySiyohPainter(
                                    chiziqlar: _chiziqlar,
                                    uchqunJoyi: _oxirgiUchqunJoyi,
                                    yakunlandi: _harfYakunlandi,
                                  ),
                                ),
                              ),
                            ),

                            // Chap yuqori: Katta/Kichik (A/a), Til (UZ/RU/EN) va Chiqish tugmasi
                            Positioned(
                              top: 14,
                              left: 16,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _kattaKichikTugma(),
                                  _tilTanlashTugmasi(),
                                  // Foydalanuvchi telefoni va Chiqish tugmasi
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.phone_android_rounded,
                                            size: 16, color: Colors.blueGrey),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.foydalanuvchiTelefoni,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: _tizimdanChiqish,
                                          child: const Icon(
                                            Icons.logout_rounded,
                                            size: 18,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Tabrik nishoni
                            if (_harfYakunlandi)
                              Positioned(
                                top: 96,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('⭐ ',
                                          style: TextStyle(fontSize: 20)),
                                      Text(
                                        'Barakalla! ($_yulduzlar)',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Pastki chap: Tozalash tugmasi
                            Positioned(
                              bottom: 16,
                              left: 18,
                              child: ElevatedButton.icon(
                                onPressed: _tozalash,
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 24),
                                label: Text(
                                  _tozalashMatni,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE56B6F),
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                              ),
                            ),

                            // Pastki o'ng: Keyingi -> tugmasi
                            Positioned(
                              bottom: 16,
                              right: 18,
                              child: ElevatedButton(
                                onPressed: _keyingiHarfgaOtish,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2196F3),
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 22, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _keyingiMatni,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_rounded,
                                        size: 24),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

              // 2. Yuqori chap burchak: Qizil dumaloq Orqaga (<) tugmasi
              Positioned(
                top: 10,
                left: 18,
                child: GestureDetector(
                  onTap: _oldingiHarfgaOtish,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE56B6F),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
              ),

              // 3. Yuqori markaz: "B HARFI" sarlavhasi
              Positioned(
                top: 8,
                left: 80,
                right: 170,
                child: Center(
                  child: GestureDetector(
                    onTap: () => OvozIjrochi.harfniTalaffuzQil(
                        _joriyHarf, _tanlanganTil),
                    child: Stack(
                      children: [
                        Text(
                          _sarlavhaMatni,
                          style: GoogleFonts.fredoka(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 7
                              ..color = Colors.white,
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.fredoka(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                            ),
                            children: [
                              TextSpan(
                                text: _joriyHarf.katta,
                                style:
                                    const TextStyle(color: Color(0xFFE53935)),
                              ),
                              TextSpan(
                                text: _sarlavhaMatni
                                    .substring(_joriyHarf.katta.length),
                                style:
                                    const TextStyle(color: Color(0xFF1E88E5)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Yuqori o'ng burchak: Oq rasm kartochkasi
              Positioned(
                top: 10,
                right: 28,
                child: GestureDetector(
                  onTap: () =>
                      OvozIjrochi.harfniTalaffuzQil(_joriyHarf, _tanlanganTil),
                  child: Container(
                    width: 148,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: const Color(0xFFB3E5FC), width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _joriyHarf.emoji,
                              style: const TextStyle(fontSize: 44),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.volume_up_rounded,
                                color: Colors.blue.shade600, size: 22),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _joriyHarf.soz,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.fredoka(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF263238),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 5. Pastki alifbo lentasi
              Positioned(
                bottom: 6,
                left: 18,
                right: 18,
                height: 42,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _joriyAlifbo.length,
                  itemBuilder: (context, index) {
                    final harf = _joriyAlifbo[index];
                    final bool tanlangan = index == _tanlanganIndex;
                    return GestureDetector(
                      onTap: () => _harfniTanlash(index),
                      child: Container(
                        width: 42,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: tanlangan
                              ? const Color(0xFF1E88E5)
                              : Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: harf.unli
                                ? const Color(0xFFE53935)
                                : const Color(0xFF1E88E5),
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          harf.katta,
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: tanlangan
                                ? Colors.white
                                : (harf.unli
                                    ? const Color(0xFFE53935)
                                    : const Color(0xFF1565C0)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kattaKichikTugma() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _miniChip(_joriyHarf.katta, _kattaHarf, () {
            setState(() {
              _kattaHarf = true;
              _tozalash();
            });
          }),
          _miniChip(_joriyHarf.kichik, !_kattaHarf, () {
            setState(() {
              _kattaHarf = false;
              _tozalash();
            });
          }),
        ],
      ),
    );
  }

  Widget _tilTanlashTugmasi() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _miniChip('UZ', _tanlanganTil == AlifboTili.uz,
              () => _tilniAlmashtirish(AlifboTili.uz)),
          _miniChip('RU', _tanlanganTil == AlifboTili.ru,
              () => _tilniAlmashtirish(AlifboTili.ru)),
          _miniChip('EN', _tanlanganTil == AlifboTili.en,
              () => _tilniAlmashtirish(AlifboTili.en)),
        ],
      ),
    );
  }

  Widget _miniChip(String matn, bool aktiv, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: aktiv ? const Color(0xFF2196F3) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          matn,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: aktiv ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class KonturNuqtaliHarfPainter extends CustomPainter {
  final List<HarfYolagi> yolaklar;
  final Set<String> ulanganlar;
  final bool yakunlandi;

  KonturNuqtaliHarfPainter({
    required this.yolaklar,
    required this.ulanganlar,
    required this.yakunlandi,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint tashqiQobiq = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..strokeWidth = 46.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final Paint ichkiOqYolak = Paint()
      ..color = Colors.white
      ..strokeWidth = 40.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final yolak in yolaklar) {
      if (yolak.nuqtalar.length < 2) continue;
      final path = Path()
        ..moveTo(yolak.nuqtalar.first.dx, yolak.nuqtalar.first.dy);
      for (int i = 1; i < yolak.nuqtalar.length; i++) {
        path.lineTo(yolak.nuqtalar[i].dx, yolak.nuqtalar[i].dy);
      }
      if (yolak.yopiqKontur) path.close();
      canvas.drawPath(path, tashqiQobiq);
    }

    for (final yolak in yolaklar) {
      if (yolak.nuqtalar.length < 2) continue;
      final path = Path()
        ..moveTo(yolak.nuqtalar.first.dx, yolak.nuqtalar.first.dy);
      for (int i = 1; i < yolak.nuqtalar.length; i++) {
        path.lineTo(yolak.nuqtalar[i].dx, yolak.nuqtalar[i].dy);
      }
      if (yolak.yopiqKontur) path.close();
      canvas.drawPath(path, ichkiOqYolak);
    }

    final Paint nuqtaKulrang = Paint()..color = const Color(0xFF90A4AE);
    final Paint nuqtaKok = Paint()..color = const Color(0xFF2196F3);
    final Paint raqamDoira = Paint()..color = const Color(0xFF78909C);

    for (int yIdx = 0; yIdx < yolaklar.length; yIdx++) {
      final yolak = yolaklar[yIdx];
      final nuqtalar = yolak.nuqtalar;

      for (int nIdx = 0; nIdx < nuqtalar.length; nIdx++) {
        final pos = nuqtalar[nIdx];
        final bool ulandi = ulanganlar.contains('$yIdx-$nIdx');

        if (nIdx == 0) {
          canvas.drawCircle(pos, 11, ulandi ? nuqtaKok : raqamDoira);
          final tp = TextPainter(
            text: TextSpan(
              text: '${yolak.raqam}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(
              canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));

          if (nuqtalar.length > 1) {
            _strelkaChiz(canvas, pos, nuqtalar[1]);
          }
        } else {
          canvas.drawCircle(pos, 4.5, ulandi ? nuqtaKok : nuqtaKulrang);
        }
      }
    }
  }

  void _strelkaChiz(Canvas canvas, Offset a, Offset b) {
    final double angle = atan2(b.dy - a.dy, b.dx - a.dx);
    final Offset yonJoy = Offset(
      a.dx + cos(angle) * 20 - sin(angle) * 14,
      a.dy + sin(angle) * 20 + cos(angle) * 14,
    );
    final Offset uchi = Offset(
      yonJoy.dx + cos(angle) * 12,
      yonJoy.dy + sin(angle) * 12,
    );

    final Paint strelkaPaint = Paint()
      ..color = const Color(0xFF78909C)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(yonJoy, uchi, strelkaPaint);
    canvas.drawLine(
      uchi,
      Offset(uchi.dx - cos(angle - 0.5) * 5, uchi.dy - sin(angle - 0.5) * 5),
      strelkaPaint,
    );
    canvas.drawLine(
      uchi,
      Offset(uchi.dx - cos(angle + 0.5) * 5, uchi.dy - sin(angle + 0.5) * 5),
      strelkaPaint,
    );
  }

  @override
  bool shouldRepaint(covariant KonturNuqtaliHarfPainter oldDelegate) => true;
}

class MoviySiyohPainter extends CustomPainter {
  final List<List<Offset>> chiziqlar;
  final Offset? uchqunJoyi;
  final bool yakunlandi;

  MoviySiyohPainter({
    required this.chiziqlar,
    required this.uchqunJoyi,
    required this.yakunlandi,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint siyoh = Paint()
      ..color = yakunlandi ? const Color(0xFF00C853) : const Color(0xFF2196F3)
      ..strokeWidth = 18.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final chiziq in chiziqlar) {
      if (chiziq.length > 1) {
        final path = Path()..moveTo(chiziq.first.dx, chiziq.first.dy);
        for (int i = 1; i < chiziq.length; i++) {
          path.lineTo(chiziq[i].dx, chiziq[i].dy);
        }
        canvas.drawPath(path, siyoh);
      } else if (chiziq.length == 1) {
        canvas.drawCircle(chiziq.first, 9, siyoh..style = PaintingStyle.fill);
        siyoh.style = PaintingStyle.stroke;
      }
    }

    if (uchqunJoyi != null) {
      final Paint uchqun = Paint()
        ..color = const Color(0xFF00B0FF)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;

      final offsets = [
        const Offset(-18, -18),
        const Offset(18, -14),
        const Offset(-14, 18),
      ];
      for (final d in offsets) {
        final c = uchqunJoyi! + d;
        canvas.drawLine(
            c + const Offset(-5, 0), c + const Offset(5, 0), uchqun);
        canvas.drawLine(
            c + const Offset(0, -5), c + const Offset(0, 5), uchqun);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MoviySiyohPainter oldDelegate) => true;
}
