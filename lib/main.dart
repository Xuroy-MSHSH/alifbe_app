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

enum OquvBolimi { harflar, raqamlar }

class QuvnoqAlifbeApp extends StatelessWidget {
  const QuvnoqAlifbeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quvnoq Alifbe — Husnixat va Raqamlar',
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
          builder: (_) => HusnixatAlifbeSahifa(
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
        return 'HUSNIXAT ALIFBE';
      case AlifboTili.ru:
        return 'ПРОПИСИ АЗБУКА';
      case AlifboTili.en:
        return 'CURSIVE ALPHABET';
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
                          const Text('✍️🔢', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 6),
                          Text(
                            _sarlavha,
                            style: GoogleFonts.fredoka(
                              fontSize: 28,
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
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
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
/// 2. HARFLAR (UZ / RU / EN) VA RAQAMLAR (0-9) MA'LUMOT MODELLARI
/// ============================================================================
class HarfDarsModel {
  final String katta;
  final String kichik;
  final String sozUz;
  final String sozRu;
  final String sozEn;
  final String talaffuzUz;
  final String talaffuzRu;
  final String talaffuzEn;
  final String emoji;
  final String audioFayl;
  final bool unli;
  final bool raqammi;

  const HarfDarsModel({
    required this.katta,
    required this.kichik,
    required this.sozUz,
    String? sozRu,
    String? sozEn,
    required this.talaffuzUz,
    String? talaffuzRu,
    String? talaffuzEn,
    required this.emoji,
    required this.audioFayl,
    this.unli = false,
    this.raqammi = false,
  })  : sozRu = sozRu ?? sozUz,
        sozEn = sozEn ?? sozUz,
        talaffuzRu = talaffuzRu ?? talaffuzUz,
        talaffuzEn = talaffuzEn ?? talaffuzUz;

  String sozniOlish(AlifboTili til) {
    switch (til) {
      case AlifboTili.uz:
        return sozUz;
      case AlifboTili.ru:
        return sozRu;
      case AlifboTili.en:
        return sozEn;
    }
  }

  String talaffuzniOlish(AlifboTili til) {
    switch (til) {
      case AlifboTili.uz:
        return talaffuzUz;
      case AlifboTili.ru:
        return talaffuzRu;
      case AlifboTili.en:
        return talaffuzEn;
    }
  }
}

class OvozIjrochi {
  static final AudioPlayer _player = AudioPlayer();
  static final FlutterTts _tts = FlutterTts();

  static Future<void> elementniTalaffuzQil(
      HarfDarsModel item, AlifboTili til) async {
    try {
      await _player.stop();
      await _tts.stop();
      await _player
          .play(AssetSource('audio/${til.name}_${item.audioFayl}.mp3'));
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
      await _tts.speak(item.talaffuzniOlish(til));
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

/// 1. O'ZBEK ALIFBOSI (Barcha 30 ta harf va tutuq belgisi — husnixat)
const List<HarfDarsModel> uzbekAlifbosi = [
  HarfDarsModel(
      katta: 'O',
      kichik: 'o',
      sozUz: 'Olmaxon',
      talaffuzUz: 'O harfi! Olmaxon',
      emoji: '🐿️',
      audioFayl: 'o',
      unli: true),
  HarfDarsModel(
      katta: 'N',
      kichik: 'n',
      sozUz: 'Non',
      talaffuzUz: 'N harfi! Non',
      emoji: '🍞',
      audioFayl: 'n'),
  HarfDarsModel(
      katta: 'A',
      kichik: 'a',
      sozUz: 'Archa',
      talaffuzUz: 'A harfi! Archa',
      emoji: '🌲',
      audioFayl: 'a',
      unli: true),
  HarfDarsModel(
      katta: 'I',
      kichik: 'i',
      sozUz: 'Nina',
      talaffuzUz: 'I harfi! Nina',
      emoji: '🪡',
      audioFayl: 'i',
      unli: true),
  HarfDarsModel(
      katta: 'M',
      kichik: 'm',
      sozUz: 'Maymun',
      talaffuzUz: 'M harfi! Maymun',
      emoji: '🐒',
      audioFayl: 'm'),
  HarfDarsModel(
      katta: 'T',
      kichik: 't',
      sozUz: 'Tulki',
      talaffuzUz: 'T harfi! Tulki',
      emoji: '🦊',
      audioFayl: 't'),
  HarfDarsModel(
      katta: 'L',
      kichik: 'l',
      sozUz: 'Lola',
      talaffuzUz: 'L harfi! Lola',
      emoji: '🌷',
      audioFayl: 'l'),
  HarfDarsModel(
      katta: 'B',
      kichik: 'b',
      sozUz: 'Baliq',
      talaffuzUz: 'B harfi! Baliq',
      emoji: '🐠',
      audioFayl: 'b'),
  HarfDarsModel(
      katta: 'K',
      kichik: 'k',
      sozUz: 'Koptok',
      talaffuzUz: 'K harfi! Koptok',
      emoji: '⚽',
      audioFayl: 'k'),
  HarfDarsModel(
      katta: 'R',
      kichik: 'r',
      sozUz: 'Ruchka',
      talaffuzUz: 'R harfi! Ruchka',
      emoji: '🖊️',
      audioFayl: 'r'),
  HarfDarsModel(
      katta: 'O‘',
      kichik: 'o‘',
      sozUz: 'O‘rik',
      talaffuzUz: 'O‘ harfi! O‘rik',
      emoji: '🍑',
      audioFayl: 'o_tut',
      unli: true),
  HarfDarsModel(
      katta: 'D',
      kichik: 'd',
      sozUz: 'Doira',
      talaffuzUz: 'D harfi! Doira',
      emoji: '🥁',
      audioFayl: 'd'),
  HarfDarsModel(
      katta: 'U',
      kichik: 'u',
      sozUz: 'Uy',
      talaffuzUz: 'U harfi! Uy',
      emoji: '🏠',
      audioFayl: 'u',
      unli: true),
  HarfDarsModel(
      katta: 'Y',
      kichik: 'y',
      sozUz: 'Yo‘lbars',
      talaffuzUz: 'Y harfi! Yo‘lbars',
      emoji: '🐅',
      audioFayl: 'y'),
  HarfDarsModel(
      katta: 'E',
      kichik: 'e',
      sozUz: 'Echki',
      talaffuzUz: 'E harfi! Echki',
      emoji: '🐐',
      audioFayl: 'e',
      unli: true),
  HarfDarsModel(
      katta: 'G',
      kichik: 'g',
      sozUz: 'Gul',
      talaffuzUz: 'G harfi! Gul',
      emoji: '🌹',
      audioFayl: 'g'),
  HarfDarsModel(
      katta: 'Ng',
      kichik: 'ng',
      sozUz: 'Bodring',
      talaffuzUz: 'Ng harfi! Bodring',
      emoji: '🥒',
      audioFayl: 'ng'),
  HarfDarsModel(
      katta: 'S',
      kichik: 's',
      sozUz: 'Soyabon',
      talaffuzUz: 'S harfi! Soyabon',
      emoji: '☂️',
      audioFayl: 's'),
  HarfDarsModel(
      katta: 'H',
      kichik: 'h',
      sozUz: 'Handalak',
      talaffuzUz: 'H harfi! Handalak',
      emoji: '🍈',
      audioFayl: 'h'),
  HarfDarsModel(
      katta: 'Sh',
      kichik: 'sh',
      sozUz: 'Sher',
      talaffuzUz: 'Sh harfi! Sher',
      emoji: '🦁',
      audioFayl: 'sh'),
  HarfDarsModel(
      katta: 'P',
      kichik: 'p',
      sozUz: 'Kapalak',
      talaffuzUz: 'P harfi! Kapalak',
      emoji: '🦋',
      audioFayl: 'p'),
  HarfDarsModel(
      katta: 'Q',
      kichik: 'q',
      sozUz: 'Quyosh',
      talaffuzUz: 'Q harfi! Quyosh',
      emoji: '☀️',
      audioFayl: 'q'),
  HarfDarsModel(
      katta: 'Ch',
      kichik: 'ch',
      sozUz: 'Choynak',
      talaffuzUz: 'Ch harfi! Choynak',
      emoji: '🫖',
      audioFayl: 'ch'),
  HarfDarsModel(
      katta: 'J',
      kichik: 'j',
      sozUz: 'Jo‘ja',
      talaffuzUz: 'J harfi! Jo‘ja',
      emoji: '🐥',
      audioFayl: 'j'),
  HarfDarsModel(
      katta: 'G‘',
      kichik: 'g‘',
      sozUz: 'Nog‘ora',
      talaffuzUz: 'G‘ harfi! Nog‘ora',
      emoji: '🥁',
      audioFayl: 'g_tut'),
  HarfDarsModel(
      katta: 'Z',
      kichik: 'z',
      sozUz: 'Uzum',
      talaffuzUz: 'Z harfi! Uzum',
      emoji: '🍇',
      audioFayl: 'z'),
  HarfDarsModel(
      katta: 'V',
      kichik: 'v',
      sozUz: 'Varrak',
      talaffuzUz: 'V harfi! Varrak',
      emoji: '🪁',
      audioFayl: 'v'),
  HarfDarsModel(
      katta: 'X',
      kichik: 'x',
      sozUz: 'Xo‘roz',
      talaffuzUz: 'X harfi! Xo‘roz',
      emoji: '🐓',
      audioFayl: 'x'),
  HarfDarsModel(
      katta: 'F',
      kichik: 'f',
      sozUz: 'Fil',
      talaffuzUz: 'F harfi! Fil',
      emoji: '🐘',
      audioFayl: 'f'),
  HarfDarsModel(
      katta: '’',
      kichik: '’',
      sozUz: 'A’lo',
      talaffuzUz: 'Tutuq belgisi! A’lo',
      emoji: '🌟',
      audioFayl: 'tutuq'),
];

/// 2. RUS ALIFBOSI
const List<HarfDarsModel> rusAlifbosi = [
  HarfDarsModel(
      katta: 'А',
      kichik: 'а',
      sozUz: 'Арбуз',
      talaffuzUz: 'Буква А! Арбуз',
      emoji: '🍉',
      audioFayl: 'a',
      unli: true),
  HarfDarsModel(
      katta: 'Б',
      kichik: 'б',
      sozUz: 'Бабочка',
      talaffuzUz: 'Буква Б! Бабочка',
      emoji: '🦋',
      audioFayl: 'b'),
  HarfDarsModel(
      katta: 'В',
      kichik: 'в',
      sozUz: 'Волк',
      talaffuzUz: 'Буква В! Волк',
      emoji: '🐺',
      audioFayl: 'v'),
  HarfDarsModel(
      katta: 'Г',
      kichik: 'г',
      sozUz: 'Гриб',
      talaffuzUz: 'Буква Г! Гриб',
      emoji: '🍄',
      audioFayl: 'g'),
  HarfDarsModel(
      katta: 'Д',
      kichik: 'д',
      sozUz: 'Дом',
      talaffuzUz: 'Буква Д! Дом',
      emoji: '🏠',
      audioFayl: 'd'),
  HarfDarsModel(
      katta: 'Е',
      kichik: 'е',
      sozUz: 'Енот',
      talaffuzUz: 'Буква Е! Енот',
      emoji: '🦝',
      audioFayl: 'e',
      unli: true),
  HarfDarsModel(
      katta: 'Ё',
      kichik: 'ё',
      sozUz: 'Ёжик',
      talaffuzUz: 'Буква Ё! Ёжик',
      emoji: '🦔',
      audioFayl: 'yo',
      unli: true),
  HarfDarsModel(
      katta: 'Ж',
      kichik: 'ж',
      sozUz: 'Жираф',
      talaffuzUz: 'Буква Ж! Жираф',
      emoji: '🦒',
      audioFayl: 'zh'),
  HarfDarsModel(
      katta: 'З',
      kichik: 'з',
      sozUz: 'Заяц',
      talaffuzUz: 'Буква З! Заяц',
      emoji: '🐰',
      audioFayl: 'z'),
  HarfDarsModel(
      katta: 'И',
      kichik: 'и',
      sozUz: 'Игрушка',
      talaffuzUz: 'Буква И! Игрушка',
      emoji: '🧸',
      audioFayl: 'i',
      unli: true),
  HarfDarsModel(
      katta: 'Й',
      kichik: 'й',
      sozUz: 'Йогурт',
      talaffuzUz: 'И краткое! Йогурт',
      emoji: '🥛',
      audioFayl: 'y_kr'),
  HarfDarsModel(
      katta: 'К',
      kichik: 'к',
      sozUz: 'Кот',
      talaffuzUz: 'Буква К! Кот',
      emoji: '🐱',
      audioFayl: 'k'),
  HarfDarsModel(
      katta: 'Л',
      kichik: 'л',
      sozUz: 'Лиса',
      talaffuzUz: 'Буква Л! Лиса',
      emoji: '🦊',
      audioFayl: 'l'),
  HarfDarsModel(
      katta: 'М',
      kichik: 'м',
      sozUz: 'Медведь',
      talaffuzUz: 'Буква М! Медведь',
      emoji: '🐻',
      audioFayl: 'm'),
  HarfDarsModel(
      katta: 'Н',
      kichik: 'н',
      sozUz: 'Носорог',
      talaffuzUz: 'Буква Н! Носорог',
      emoji: '🦏',
      audioFayl: 'n'),
  HarfDarsModel(
      katta: 'О',
      kichik: 'о',
      sozUz: 'Облако',
      talaffuzUz: 'Буква О! Облако',
      emoji: '☁️',
      audioFayl: 'o',
      unli: true),
  HarfDarsModel(
      katta: 'П',
      kichik: 'п',
      sozUz: 'Пчела',
      talaffuzUz: 'Буква П! Пчела',
      emoji: '🐝',
      audioFayl: 'p'),
  HarfDarsModel(
      katta: 'Р',
      kichik: 'р',
      sozUz: 'Рыба',
      talaffuzUz: 'Буква Р! Рыба',
      emoji: '🐠',
      audioFayl: 'r'),
  HarfDarsModel(
      katta: 'С',
      kichik: 'с',
      sozUz: 'Солнце',
      talaffuzUz: 'Буква С! Солнце',
      emoji: '☀️',
      audioFayl: 's'),
  HarfDarsModel(
      katta: 'Т',
      kichik: 'т',
      sozUz: 'Тигр',
      talaffuzUz: 'Буква Т! Тигр',
      emoji: '🐅',
      audioFayl: 't'),
  HarfDarsModel(
      katta: 'У',
      kichik: 'у',
      sozUz: 'Утка',
      talaffuzUz: 'Буква У! Утка',
      emoji: '🦆',
      audioFayl: 'u',
      unli: true),
  HarfDarsModel(
      katta: 'Ф',
      kichik: 'ф',
      sozUz: 'Флаг',
      talaffuzUz: 'Буква Ф! Флаг',
      emoji: '🚩',
      audioFayl: 'f'),
  HarfDarsModel(
      katta: 'Х',
      kichik: 'х',
      sozUz: 'Хлеб',
      talaffuzUz: 'Буква Х! Хлеб',
      emoji: '🍞',
      audioFayl: 'x'),
  HarfDarsModel(
      katta: 'Ц',
      kichik: 'ц',
      sozUz: 'Цветок',
      talaffuzUz: 'Буква Ц! Цветок',
      emoji: '🌸',
      audioFayl: 'ts'),
  HarfDarsModel(
      katta: 'Ч',
      kichik: 'ч',
      sozUz: 'Черепаха',
      talaffuzUz: 'Буква Ч! Черепаха',
      emoji: '🐢',
      audioFayl: 'ch'),
  HarfDarsModel(
      katta: 'Ш',
      kichik: 'ш',
      sozUz: 'Шар',
      talaffuzUz: 'Буква Ш! Шар',
      emoji: '🎈',
      audioFayl: 'sh'),
  HarfDarsModel(
      katta: 'Щ',
      kichik: 'щ',
      sozUz: 'Щенок',
      talaffuzUz: 'Буква Щ! Щенок',
      emoji: '🐶',
      audioFayl: 'shch'),
  HarfDarsModel(
      katta: 'Ъ',
      kichik: 'ъ',
      sozUz: 'Твёрдый знак',
      talaffuzUz: 'Твёрдый знак',
      emoji: '✍️',
      audioFayl: 'tverd'),
  HarfDarsModel(
      katta: 'Ы',
      kichik: 'ы',
      sozUz: 'Сыр',
      talaffuzUz: 'Буква Ы! Сыр',
      emoji: '🧀',
      audioFayl: 'yi',
      unli: true),
  HarfDarsModel(
      katta: 'Ь',
      kichik: 'ь',
      sozUz: 'Мягкий знак',
      talaffuzUz: 'Мягкий знак',
      emoji: '🪶',
      audioFayl: 'myagk'),
  HarfDarsModel(
      katta: 'Э',
      kichik: 'э',
      sozUz: 'Экскаватор',
      talaffuzUz: 'Буква Э! Экскаватор',
      emoji: '🚜',
      audioFayl: 'eh',
      unli: true),
  HarfDarsModel(
      katta: 'Ю',
      kichik: 'ю',
      sozUz: 'Юла',
      talaffuzUz: 'Буква Ю! Юла',
      emoji: '🪀',
      audioFayl: 'yu',
      unli: true),
  HarfDarsModel(
      katta: 'Я',
      kichik: 'я',
      sozUz: 'Яблоко',
      talaffuzUz: 'Буква Я! Яблоко',
      emoji: '🍎',
      audioFayl: 'ya',
      unli: true),
];

/// 3. INGLIZ ALIFBOSI
const List<HarfDarsModel> englishAlifbosi = [
  HarfDarsModel(
      katta: 'A',
      kichik: 'a',
      sozUz: 'Apple',
      talaffuzUz: 'Letter A! Apple',
      emoji: '🍎',
      audioFayl: 'a',
      unli: true),
  HarfDarsModel(
      katta: 'B',
      kichik: 'b',
      sozUz: 'Ball',
      talaffuzUz: 'Letter B! Ball',
      emoji: '⚽',
      audioFayl: 'b'),
  HarfDarsModel(
      katta: 'C',
      kichik: 'c',
      sozUz: 'Cat',
      talaffuzUz: 'Letter C! Cat',
      emoji: '🐱',
      audioFayl: 'c'),
  HarfDarsModel(
      katta: 'D',
      kichik: 'd',
      sozUz: 'Dog',
      talaffuzUz: 'Letter D! Dog',
      emoji: '🐶',
      audioFayl: 'd'),
  HarfDarsModel(
      katta: 'E',
      kichik: 'e',
      sozUz: 'Elephant',
      talaffuzUz: 'Letter E! Elephant',
      emoji: '🐘',
      audioFayl: 'e',
      unli: true),
  HarfDarsModel(
      katta: 'F',
      kichik: 'f',
      sozUz: 'Fish',
      talaffuzUz: 'Letter F! Fish',
      emoji: '🐠',
      audioFayl: 'f'),
  HarfDarsModel(
      katta: 'G',
      kichik: 'g',
      sozUz: 'Grapes',
      talaffuzUz: 'Letter G! Grapes',
      emoji: '🍇',
      audioFayl: 'g'),
  HarfDarsModel(
      katta: 'H',
      kichik: 'h',
      sozUz: 'House',
      talaffuzUz: 'Letter H! House',
      emoji: '🏠',
      audioFayl: 'h'),
  HarfDarsModel(
      katta: 'I',
      kichik: 'i',
      sozUz: 'Ice cream',
      talaffuzUz: 'Letter I! Ice cream',
      emoji: '🍦',
      audioFayl: 'i',
      unli: true),
  HarfDarsModel(
      katta: 'J',
      kichik: 'j',
      sozUz: 'Juice',
      talaffuzUz: 'Letter J! Juice',
      emoji: '🧃',
      audioFayl: 'j'),
  HarfDarsModel(
      katta: 'K',
      kichik: 'k',
      sozUz: 'Kite',
      talaffuzUz: 'Letter K! Kite',
      emoji: '🪁',
      audioFayl: 'k'),
  HarfDarsModel(
      katta: 'L',
      kichik: 'l',
      sozUz: 'Lion',
      talaffuzUz: 'Letter L! Lion',
      emoji: '🦁',
      audioFayl: 'l'),
  HarfDarsModel(
      katta: 'M',
      kichik: 'm',
      sozUz: 'Monkey',
      talaffuzUz: 'Letter M! Monkey',
      emoji: '🐒',
      audioFayl: 'm'),
  HarfDarsModel(
      katta: 'N',
      kichik: 'n',
      sozUz: 'Nest',
      talaffuzUz: 'Letter N! Nest',
      emoji: '🪺',
      audioFayl: 'n'),
  HarfDarsModel(
      katta: 'O',
      kichik: 'o',
      sozUz: 'Orange',
      talaffuzUz: 'Letter O! Orange',
      emoji: '🍊',
      audioFayl: 'o',
      unli: true),
  HarfDarsModel(
      katta: 'P',
      kichik: 'p',
      sozUz: 'Panda',
      talaffuzUz: 'Letter P! Panda',
      emoji: '🐼',
      audioFayl: 'p'),
  HarfDarsModel(
      katta: 'Q',
      kichik: 'q',
      sozUz: 'Queen',
      talaffuzUz: 'Letter Q! Queen',
      emoji: '👑',
      audioFayl: 'q'),
  HarfDarsModel(
      katta: 'R',
      kichik: 'r',
      sozUz: 'Rabbit',
      talaffuzUz: 'Letter R! Rabbit',
      emoji: '🐰',
      audioFayl: 'r'),
  HarfDarsModel(
      katta: 'S',
      kichik: 's',
      sozUz: 'Sun',
      talaffuzUz: 'Letter S! Sun',
      emoji: '☀️',
      audioFayl: 's'),
  HarfDarsModel(
      katta: 'T',
      kichik: 't',
      sozUz: 'Tiger',
      talaffuzUz: 'Letter T! Tiger',
      emoji: '🐅',
      audioFayl: 't'),
  HarfDarsModel(
      katta: 'U',
      kichik: 'u',
      sozUz: 'Umbrella',
      talaffuzUz: 'Letter U! Umbrella',
      emoji: '☂️',
      audioFayl: 'u',
      unli: true),
  HarfDarsModel(
      katta: 'V',
      kichik: 'v',
      sozUz: 'Violin',
      talaffuzUz: 'Letter V! Violin',
      emoji: '🎻',
      audioFayl: 'v'),
  HarfDarsModel(
      katta: 'W',
      kichik: 'w',
      sozUz: 'Whale',
      talaffuzUz: 'Letter W! Whale',
      emoji: '🐋',
      audioFayl: 'w'),
  HarfDarsModel(
      katta: 'X',
      kichik: 'x',
      sozUz: 'Xylophone',
      talaffuzUz: 'Letter X! Xylophone',
      emoji: '🎶',
      audioFayl: 'x'),
  HarfDarsModel(
      katta: 'Y',
      kichik: 'y',
      sozUz: 'Yo-yo',
      talaffuzUz: 'Letter Y! Yo-yo',
      emoji: '🪀',
      audioFayl: 'y'),
  HarfDarsModel(
      katta: 'Z',
      kichik: 'z',
      sozUz: 'Zebra',
      talaffuzUz: 'Letter Z! Zebra',
      emoji: '🦓',
      audioFayl: 'z'),
];

/// 4. RAQAMLAR BO'LIMI (0 dan 9 gacha — 3 tilda talaffuz va sanash emojilari bilan)
const List<HarfDarsModel> raqamlarRoyxati = [
  HarfDarsModel(
    katta: '0',
    kichik: '0',
    sozUz: 'Nol',
    sozRu: 'Ноль',
    sozEn: 'Zero',
    talaffuzUz: 'Nol raqami!',
    talaffuzRu: 'Цифра ноль!',
    talaffuzEn: 'Number zero!',
    emoji: '⭕',
    audioFayl: 'num_0',
    raqammi: true,
  ),
  HarfDarsModel(
    katta: '1',
    kichik: '1',
    sozUz: 'Bir',
    sozRu: 'Один',
    sozEn: 'One',
    talaffuzUz: 'Bir! Bitta quyosh',
    talaffuzRu: 'Один! Одно солнце',
    talaffuzEn: 'One! One sun',
    emoji: '☀️',
    audioFayl: 'num_1',
    raqammi: true,
  ),
  HarfDarsModel(
    katta: '2',
    kichik: '2',
    sozUz: 'Ikki',
    sozRu: 'Два',
    sozEn: 'Two',
    talaffuzUz: 'Ikki! Ikkita olma',
    talaffuzRu: 'Два! Два яблока',
    talaffuzEn: 'Two! Two apples',
    emoji: '🍎🍎',
    audioFayl: 'num_2',
    raqammi: true,
  ),
  HarfDarsModel(
    katta: '3',
    kichik: '3',
    sozUz: 'Uch',
    sozRu: 'Три',
    sozEn: 'Three',
    talaffuzUz: 'Uch! Uchta yulduz',
    talaffuzRu: 'Три! Три звезды',
    talaffuzEn: 'Three! Three stars',
    emoji: '⭐⭐⭐',
    audioFayl: 'num_3',
    raqammi: true,
  ),
  HarfDarsModel(
    katta: '4',
    kichik: '4',
    sozUz: 'To‘rt',
    sozRu: 'Четыре',
    sozEn: 'Four',
    talaffuzUz: 'To‘rt! To‘rtta kapalak',
    talaffuzRu: 'Четыре! Четыре бабочки',
    talaffuzEn: 'Four! Four butterflies',
    emoji: '🦋🦋🦋🦋',
    audioFayl: 'num_4',
    raqammi: true,
  ),
  HarfDarsModel(
    katta: '5',
    kichik: '5',
    sozUz: 'Besh',
    sozRu: 'Пять',
    sozEn: 'Five',
    talaffuzUz: 'Besh! Beshta gul',
    talaffuzRu: 'Пять! Пять цветов',
    talaffuzEn: 'Five! Five flowers',
    emoji: '🌷🌷🌷🌷🌷',
    audioFayl: 'num_5',
    raqammi: true,
  ),
  HarfDarsModel(
    katta: '6',
    kichik: '6',
    sozUz: 'Olti',
    sozRu: 'Шесть',
    sozEn: 'Six',
    talaffuzUz: 'Olti! Oltita baliq',
    talaffuzRu: 'Шесть! Шесть рыбок',
    talaffuzEn: 'Six! Six fish',
    emoji: '🐠🐠🐠🐠🐠🐠',
    audioFayl: 'num_6',
    raqammi: true,
  ),
  HarfDarsModel(
    katta: '7',
    kichik: '7',
    sozUz: 'Yetti',
    sozRu: 'Семь',
    sozEn: 'Seven',
    talaffuzUz: 'Yetti! Yettita qulupnay',
    talaffuzRu: 'Семь! Семь ягод',
    talaffuzEn: 'Seven! Seven berries',
    emoji: '🍓🍓🍓🍓🍓🍓🍓',
    audioFayl: 'num_7',
    raqammi: true,
  ),
  HarfDarsModel(
    katta: '8',
    kichik: '8',
    sozUz: 'Sakkiz',
    sozRu: 'Восемь',
    sozEn: 'Eight',
    talaffuzUz: 'Sakkiz! Sakkizta ari',
    talaffuzRu: 'Восемь! Восемь пчёл',
    talaffuzEn: 'Eight! Eight bees',
    emoji: '🐝🐝🐝🐝🐝🐝🐝🐝',
    audioFayl: 'num_8',
    raqammi: true,
  ),
  HarfDarsModel(
    katta: '9',
    kichik: '9',
    sozUz: 'To‘qqiz',
    sozRu: 'Девять',
    sozEn: 'Nine',
    talaffuzUz: 'To‘qqiz! To‘qqizta yurakcha',
    talaffuzRu: 'Девять! Девять сердечек',
    talaffuzEn: 'Nine! Nine hearts',
    emoji: '❤️❤️❤️❤️❤️❤️❤️❤️❤️',
    audioFayl: 'num_9',
    raqammi: true,
  ),
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

/// ============================================================================
/// 3. BARCHA HARFLAR (KATTA/KICHIK) VA RAQAMLAR (0-9) UCHUN HUSNIXAT GEOMETRIYASI
/// ============================================================================
class HusnixatGeometriyasi {
  static List<HarfYolagi> yolaklarniOlish(
      String belgi, bool kattaHarf, bool raqammi, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w * 0.50;
    final double cy = (kattaHarf || raqammi) ? h * 0.50 : h * 0.54;

    final double ry = h * ((kattaHarf || raqammi) ? 0.34 : 0.25);
    final double rx = min(w * 0.30, ry * 0.92);

    // Haqiqiy maktab husnixat (kursiv/propisi) qiyaligi — o'ngga 15 gradus og'ish
    Offset p(double nx, double ny) {
      final double ogish = -ny * 0.24;
      return Offset(cx + (nx + ogish) * rx, cy + ny * ry);
    }

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

    // --- A) RAQAMLAR (0 dan 9 gacha husnixat ko'rinishida) ---
    if (raqammi) {
      switch (belgi) {
        case '0':
          return [
            HarfYolagi(
              raqam: 1,
              yopiqKontur: true,
              nuqtalar: yoy(0, 0, 0.72, 0.95, -pi / 2, 2 * pi, 18),
            ),
          ];
        case '1':
          return [
            HarfYolagi(
              raqam: 1,
              nuqtalar: [
                ...chiziq(p(-0.45, -0.35), p(0.15, -0.95), 5),
                ...chiziq(p(0.15, -0.95), p(0.15, 0.95), 10),
              ],
            ),
            HarfYolagi(
              raqam: 2,
              nuqtalar: chiziq(p(-0.35, 0.95), p(0.60, 0.95), 6),
            ),
          ];
        case '2':
          return [
            HarfYolagi(
              raqam: 1,
              nuqtalar: [
                ...yoy(-0.05, -0.45, 0.62, 0.50, -0.85 * pi, 1.15 * pi, 10),
                ...chiziq(p(0.50, -0.25), p(-0.65, 0.95), 8),
                ...chiziq(p(-0.65, 0.95), p(0.68, 0.95), 7),
              ],
            ),
          ];
        case '3':
          return [
            HarfYolagi(
              raqam: 1,
              nuqtalar: yoy(-0.10, -0.48, 0.62, 0.48, -0.75 * pi, 1.25 * pi, 9),
            ),
            HarfYolagi(
              raqam: 2,
              nuqtalar: yoy(-0.10, 0.48, 0.68, 0.48, -pi / 2, 1.25 * pi, 10),
            ),
          ];
        case '4':
          return [
            HarfYolagi(
              raqam: 1,
              nuqtalar: [
                ...chiziq(p(0.25, -0.95), p(-0.68, 0.25), 8),
                ...chiziq(p(-0.68, 0.25), p(0.72, 0.25), 7),
              ],
            ),
            HarfYolagi(
              raqam: 2,
              nuqtalar: chiziq(p(0.25, -0.95), p(0.25, 0.95), 10),
            ),
          ];
        case '5':
          return [
            HarfYolagi(
              raqam: 1,
              nuqtalar: [
                ...chiziq(p(-0.45, -0.95), p(-0.55, -0.10), 6),
                ...yoy(-0.05, 0.42, 0.68, 0.53, -0.75 * pi, 1.45 * pi, 11),
              ],
            ),
            HarfYolagi(
              raqam: 2,
              nuqtalar: chiziq(p(-0.45, -0.95), p(0.62, -0.95), 6),
            ),
          ];
        case '6':
          return [
            HarfYolagi(
              raqam: 1,
              nuqtalar: [
                ...yoy(0.10, -0.10, 0.72, 0.85, -0.25 * pi, -0.85 * pi, 9),
                ...yoy(0.0, 0.42, 0.64, 0.52, pi, -2 * pi, 12),
              ],
            ),
          ];
        case '7':
          return [
            HarfYolagi(
              raqam: 1,
              nuqtalar: [
                ...chiziq(p(-0.65, -0.95), p(0.65, -0.95), 7),
                ...chiziq(p(0.65, -0.95), p(-0.20, 0.95), 10),
              ],
            ),
            HarfYolagi(
              raqam: 2,
              nuqtalar: chiziq(p(-0.25, 0.0), p(0.55, 0.0), 5),
            ),
          ];
        case '8':
          return [
            HarfYolagi(
              raqam: 1,
              yopiqKontur: true,
              nuqtalar: yoy(0, -0.48, 0.55, 0.46, -pi / 2, 2 * pi, 12),
            ),
            HarfYolagi(
              raqam: 2,
              yopiqKontur: true,
              nuqtalar: yoy(0, 0.48, 0.64, 0.48, -pi / 2, 2 * pi, 14),
            ),
          ];
        case '9':
          return [
            HarfYolagi(
              raqam: 1,
              nuqtalar: [
                ...yoy(0.0, -0.45, 0.62, 0.48, 0, -2 * pi, 12),
                ...yoy(-0.08, 0.15, 0.70, 0.80, -0.15 * pi, 0.95 * pi, 10),
              ],
            ),
          ];
      }
    }

    // --- B) KICHIK YOZMA HUSNIXAT HARFLARI (a, o, n, m, i, l, b, k, d, u...) ---
    if (!kattaHarf) {
      switch (belgi) {
        case 'a':
        case 'а':
          return [
            HarfYolagi(
              raqam: 1,
              yopiqKontur: true,
              nuqtalar: yoy(-0.15, 0.05, 0.62, 0.85, -pi / 4, -2 * pi, 14),
            ),
            HarfYolagi(
              raqam: 2,
              nuqtalar: [
                ...chiziq(p(0.47, -0.75), p(0.47, 0.65), 7),
                ...yoy(0.72, 0.65, 0.25, 0.25, pi, -pi, 4),
              ],
            ),
          ];
        case 'o':
        case 'о':
          return [
            HarfYolagi(
              raqam: 1,
              yopiqKontur: true,
              nuqtalar: yoy(0, 0.05, 0.68, 0.85, -pi / 2, 2 * pi, 16),
            ),
          ];
        case 'o‘':
          return [
            HarfYolagi(
              raqam: 1,
              yopiqKontur: true,
              nuqtalar: yoy(-0.12, 0.08, 0.65, 0.82, -pi / 2, 2 * pi, 15),
            ),
            HarfYolagi(
              raqam: 2,
              nuqtalar: yoy(0.75, -0.80, 0.24, 0.24, -pi / 2, pi, 5),
            ),
          ];
        case 'i':
          return [
            HarfYolagi(
              raqam: 1,
              nuqtalar: [
                ...chiziq(p(-0.10, -0.75), p(-0.10, 0.65), 7),
                ...yoy(0.18, 0.65, 0.28, 0.25, pi, -pi, 4),
              ],
            ),
            HarfYolagi(
              raqam: 2,
              nuqtalar: [p(-0.10, -1.18), p(-0.08, -1.18)],
            ),
          ];
        case 'и':
        case 'й':
          return [
            HarfYolagi(
              raqam: 1,
              nuqtalar: [
                ...chiziq(p(-0.55, -0.75), p(-0.55, 0.65), 6),
                ...yoy(-0.05, 0.65, 0.50, 0.25, pi, -pi, 6),
              ],
            ),
            HarfYolagi(
              raqam: 2,
              nuqtalar: [
                ...chiziq(p(0.45, -0.75), p(0.45, 0.65), 6),
                ...yoy(0.70, 0.65, 0.25, 0.22, pi, -pi, 4),
              ],
            ),
          ];
        case 'n':
        case 'п':
          return [
            HarfYolagi(
                raqam: 1, nuqtalar: chiziq(p(-0.55, -0.75), p(-0.55, 0.88), 7)),
            HarfYolagi(
              raqam: 2,
              nuqtalar: [
                ...yoy(0.0, -0.35, 0.55, 0.42, pi, pi, 7),
                ...chiziq(p(0.55, -0.35), p(0.55, 0.68), 5),
                ...yoy(0.78, 0.68, 0.23, 0.20, pi, -pi, 4),
              ],
            ),
          ];
        case 'm':
        case 'т':
          return [
            HarfYolagi(
                raqam: 1, nuqtalar: chiziq(p(-0.85, -0.75), p(-0.85, 0.88), 7)),
            HarfYolagi(
              raqam: 2,
              nuqtalar: [
                ...yoy(-0.42, -0.38, 0.42, 0.38, pi, pi, 6),
                ...chiziq(p(0, -0.38), p(0, 0.88), 6),
              ],
            ),
            HarfYolagi(
              raqam: 3,
              nuqtalar: [
                ...yoy(0.42, -0.38, 0.42, 0.38, pi, pi, 6),
                ...chiziq(p(0.85, -0.38), p(0.85, 0.68), 5),
                ...yoy(1.05, 0.68, 0.20, 0.18, pi, -pi, 3),
              ],
            ),
          ];
        case 'l':
          return [
            HarfYolagi(
              raqam: 1,
              nuqtalar: [
                ...chiziq(p(-0.15, -1.15), p(-0.15, 0.65), 9),
                ...yoy(0.15, 0.65, 0.30, 0.25, pi, -pi, 4),
              ],
            ),
          ];
        case 'b':
          return [
            HarfYolagi(
                raqam: 1,
                nuqtalar: chiziq(p(-0.55, -1.18), p(-0.55, 0.88), 10)),
            HarfYolagi(
              raqam: 2,
              yopiqKontur: true,
              nuqtalar: yoy(0.05, 0.15, 0.60, 0.72, -pi / 2, 2 * pi, 14),
            ),
          ];
        case 'd':
          return [
            HarfYolagi(
              raqam: 1,
              yopiqKontur: true,
              nuqtalar: yoy(-0.15, 0.15, 0.60, 0.72, -pi / 4, -2 * pi, 14),
            ),
            HarfYolagi(
              raqam: 2,
              nuqtalar: [
                ...chiziq(p(0.45, -1.18), p(0.45, 0.65), 9),
                ...yoy(0.70, 0.65, 0.25, 0.22, pi, -pi, 4),
              ],
            ),
          ];
        case 'u':
          return [
            HarfYolagi(
              raqam: 1,
              nuqtalar: [
                ...chiziq(p(-0.55, -0.75), p(-0.55, 0.35), 5),
                ...yoy(0.0, 0.35, 0.55, 0.52, pi, -pi, 8),
              ],
            ),
            HarfYolagi(
              raqam: 2,
              nuqtalar: [
                ...chiziq(p(0.55, -0.75), p(0.55, 0.65), 6),
                ...yoy(0.78, 0.65, 0.23, 0.22, pi, -pi, 4),
              ],
            ),
          ];
        case 'e':
        case 'е':
        case 'ё':
          return [
            HarfYolagi(
              raqam: 1,
              nuqtalar: [
                ...chiziq(p(-0.55, 0.05), p(0.62, 0.05), 5),
                ...yoy(0.0, 0.05, 0.65, 0.82, 0, -1.70 * pi, 13),
              ],
            ),
          ];
      }
    }

    // --- C) KATTA YOZMA HUSNIXAT HARFLARI (Kalligrafik ilmoqchalar bilan) ---
    final String hNorm = belgi.toUpperCase();

    switch (hNorm) {
      case 'O':
      case 'О':
        return [
          HarfYolagi(
            raqam: 1,
            yopiqKontur: true,
            nuqtalar: yoy(0, 0, 0.78, 0.95, -pi / 2, 2 * pi, 20),
          ),
        ];

      case 'O‘':
        return [
          HarfYolagi(
            raqam: 1,
            yopiqKontur: true,
            nuqtalar: yoy(-0.12, 0.04, 0.74, 0.90, -pi / 2, 2 * pi, 18),
          ),
          HarfYolagi(
            raqam: 2,
            nuqtalar: yoy(0.82, -0.78, 0.25, 0.25, -pi / 2, pi, 5),
          ),
        ];

      // Yozma husnixat 'A' (pastda ilmoqchali va o'rtada to'lqinli)
      case 'A':
      case 'А':
        return [
          HarfYolagi(
            raqam: 1,
            nuqtalar: [
              ...yoy(-0.68, 0.75, 0.22, 0.20, pi * 0.8, -pi * 0.8, 4),
              ...chiziq(p(-0.52, 0.85), p(0.05, -0.95), 9),
            ],
          ),
          HarfYolagi(
            raqam: 2,
            nuqtalar: [
              ...chiziq(p(0.05, -0.95), p(0.62, 0.75), 9),
              ...yoy(0.84, 0.75, 0.22, 0.20, pi, -pi, 4),
            ],
          ),
          HarfYolagi(
            raqam: 3,
            nuqtalar: chiziq(p(-0.35, 0.22), p(0.45, 0.22), 5),
          ),
        ];

      case 'N':
        return [
          HarfYolagi(
            raqam: 1,
            nuqtalar: [
              ...yoy(-0.78, 0.75, 0.20, 0.20, pi, -pi, 4),
              ...chiziq(p(-0.58, 0.75), p(-0.58, -0.95), 9),
            ],
          ),
          HarfYolagi(
            raqam: 2,
            nuqtalar: chiziq(p(-0.58, -0.95), p(0.58, 0.95), 10),
          ),
          HarfYolagi(
            raqam: 3,
            nuqtalar: [
              ...chiziq(p(0.58, 0.95), p(0.58, -0.75), 9),
              ...yoy(0.78, -0.75, 0.20, 0.20, pi, pi, 4),
            ],
          ),
        ];

      case 'Н':
        return [
          HarfYolagi(
            raqam: 1,
            nuqtalar: [
              ...yoy(-0.75, 0.75, 0.20, 0.20, pi, -pi, 4),
              ...chiziq(p(-0.55, 0.75), p(-0.55, -0.95), 9),
            ],
          ),
          HarfYolagi(
            raqam: 2,
            nuqtalar: [
              ...chiziq(p(0.58, -0.95), p(0.58, 0.75), 9),
              ...yoy(0.80, 0.75, 0.22, 0.20, pi, -pi, 4),
            ],
          ),
          HarfYolagi(raqam: 3, nuqtalar: chiziq(p(-0.55, 0), p(0.58, 0), 6)),
        ];

      case 'I':
        return [
          HarfYolagi(
            raqam: 1,
            nuqtalar: [
              ...yoy(0.25, -0.75, 0.25, 0.20, 0, -pi, 4),
              ...chiziq(p(0.0, -0.75), p(0.0, 0.75), 8),
              ...yoy(-0.28, 0.75, 0.28, 0.20, 0, pi, 4),
            ],
          ),
        ];

      case 'И':
      case 'Й':
        return [
          HarfYolagi(
            raqam: 1,
            nuqtalar: [
              ...yoy(-0.78, -0.75, 0.20, 0.20, pi, pi, 4),
              ...chiziq(p(-0.58, -0.75), p(-0.58, 0.75), 8),
              ...yoy(-0.02, 0.75, 0.56, 0.22, pi, -pi, 7),
            ],
          ),
          HarfYolagi(
            raqam: 2,
            nuqtalar: [
              ...chiziq(p(0.54, -0.95), p(0.54, 0.75), 9),
              ...yoy(0.78, 0.75, 0.24, 0.20, pi, -pi, 4),
            ],
          ),
        ];

      case 'M':
      case 'М':
        return [
          HarfYolagi(
            raqam: 1,
            nuqtalar: [
              ...yoy(-0.92, 0.75, 0.18, 0.20, pi, -pi, 4),
              ...chiziq(p(-0.74, 0.75), p(-0.74, -0.95), 9),
            ],
          ),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(-0.74, -0.95), p(0, 0.35), 7)),
          HarfYolagi(raqam: 3, nuqtalar: chiziq(p(0, 0.35), p(0.74, -0.95), 7)),
          HarfYolagi(
            raqam: 4,
            nuqtalar: [
              ...chiziq(p(0.74, -0.95), p(0.74, 0.75), 9),
              ...yoy(0.94, 0.75, 0.20, 0.20, pi, -pi, 4),
            ],
          ),
        ];

      case 'T':
      case 'Т':
        return [
          HarfYolagi(
            raqam: 1,
            nuqtalar: [
              ...yoy(-0.75, -0.75, 0.18, 0.20, pi, pi, 4),
              ...chiziq(p(-0.57, -0.95), p(0.75, -0.95), 7),
            ],
          ),
          HarfYolagi(
            raqam: 2,
            nuqtalar: [
              ...chiziq(p(0.05, -0.95), p(0.05, 0.75), 9),
              ...yoy(-0.22, 0.75, 0.27, 0.20, 0, pi, 4),
            ],
          ),
        ];

      case 'L':
        return [
          HarfYolagi(
            raqam: 1,
            nuqtalar: [
              ...yoy(-0.25, -0.75, 0.25, 0.20, 0, -pi, 4),
              ...chiziq(p(-0.50, -0.75), p(-0.50, 0.75), 8),
              ...yoy(-0.20, 0.75, 0.30, 0.20, pi, -pi, 4),
              ...chiziq(p(0.10, 0.92), p(0.75, 0.85), 5),
            ],
          ),
        ];

      case 'Л':
        return [
          HarfYolagi(
            raqam: 1,
            nuqtalar: [
              ...yoy(-0.78, 0.75, 0.20, 0.20, pi, -pi, 4),
              ...chiziq(p(-0.58, 0.75), p(0.05, -0.95), 9),
            ],
          ),
          HarfYolagi(
            raqam: 2,
            nuqtalar: [
              ...chiziq(p(0.05, -0.95), p(0.62, 0.75), 9),
              ...yoy(0.84, 0.75, 0.22, 0.20, pi, -pi, 4),
            ],
          ),
        ];

      case 'B':
      case 'В':
        return [
          HarfYolagi(
            raqam: 1,
            nuqtalar: [
              ...chiziq(p(-0.55, -0.95), p(-0.55, 0.75), 9),
              ...yoy(-0.78, 0.75, 0.23, 0.20, 0, pi, 4),
            ],
          ),
          HarfYolagi(
            raqam: 2,
            nuqtalar: [
              ...chiziq(p(-0.42, -0.95), p(0.10, -0.95), 4),
              ...yoy(0.10, -0.50, 0.55, 0.45, -pi / 2, pi, 8),
              ...chiziq(p(0.10, -0.05), p(-0.35, -0.05), 4),
            ],
          ),
          HarfYolagi(
            raqam: 3,
            nuqtalar: [
              ...chiziq(p(-0.35, 0.05), p(0.18, 0.05), 4),
              ...yoy(0.18, 0.50, 0.65, 0.45, -pi / 2, pi, 9),
              ...chiziq(p(0.18, 0.95), p(-0.42, 0.95), 4),
            ],
          ),
        ];

      case 'Б':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.55, -0.95), p(0.65, -0.95), 7)),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(-0.55, -0.95), p(-0.55, 0.95), 10)),
          HarfYolagi(
            raqam: 3,
            nuqtalar: [
              ...chiziq(p(-0.50, -0.05), p(0.15, -0.05), 4),
              ...yoy(0.15, 0.45, 0.65, 0.50, -pi / 2, pi, 9),
              ...chiziq(p(0.15, 0.95), p(-0.50, 0.95), 4),
            ],
          ),
        ];

      case 'K':
      case 'К':
        return [
          HarfYolagi(
            raqam: 1,
            nuqtalar: [
              ...yoy(-0.75, -0.75, 0.20, 0.20, pi, pi, 4),
              ...chiziq(p(-0.55, -0.75), p(-0.55, 0.75), 8),
              ...yoy(-0.78, 0.75, 0.23, 0.20, 0, pi, 4),
            ],
          ),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(0.65, -0.95), p(-0.48, 0), 8)),
          HarfYolagi(
            raqam: 3,
            nuqtalar: [
              ...chiziq(p(-0.48, 0), p(0.55, 0.75), 7),
              ...yoy(0.78, 0.75, 0.23, 0.20, pi, -pi, 4),
            ],
          ),
        ];

      case 'R':
        return [
          HarfYolagi(
            raqam: 1,
            nuqtalar: [
              ...chiziq(p(-0.55, -0.95), p(-0.55, 0.75), 9),
              ...yoy(-0.78, 0.75, 0.23, 0.20, 0, pi, 4),
            ],
          ),
          HarfYolagi(
            raqam: 2,
            nuqtalar: [
              ...chiziq(p(-0.40, -0.95), p(0.15, -0.95), 4),
              ...yoy(0.15, -0.45, 0.60, 0.50, -pi / 2, pi, 8),
              ...chiziq(p(0.15, 0.05), p(-0.40, 0.05), 4),
            ],
          ),
          HarfYolagi(
            raqam: 3,
            nuqtalar: [
              ...chiziq(p(-0.10, 0.05), p(0.58, 0.75), 6),
              ...yoy(0.80, 0.75, 0.22, 0.20, pi, -pi, 4),
            ],
          ),
        ];

      case 'P':
      case 'Р':
        return [
          HarfYolagi(
            raqam: 1,
            nuqtalar: [
              ...chiziq(p(-0.55, -0.95), p(-0.55, 0.75), 9),
              ...yoy(-0.78, 0.75, 0.23, 0.20, 0, pi, 4),
            ],
          ),
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
            raqam: 1,
            nuqtalar: [
              ...yoy(-0.78, 0.75, 0.20, 0.20, pi, -pi, 4),
              ...chiziq(p(-0.58, 0.75), p(-0.58, -0.95), 9),
            ],
          ),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(-0.58, -0.95), p(0.58, -0.95), 7)),
          HarfYolagi(
            raqam: 3,
            nuqtalar: [
              ...chiziq(p(0.58, -0.95), p(0.58, 0.75), 9),
              ...yoy(0.80, 0.75, 0.22, 0.20, pi, -pi, 4),
            ],
          ),
        ];

      case 'D':
      case 'Д':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.55, -0.95), p(-0.55, 0.95), 10)),
          HarfYolagi(
            raqam: 2,
            nuqtalar: [
              ...chiziq(p(-0.45, -0.95), p(-0.10, -0.95), 3),
              ...yoy(-0.10, 0, 0.88, 0.95, -pi / 2, pi, 12),
              ...chiziq(p(-0.10, 0.95), p(-0.65, 0.95), 4),
            ],
          ),
        ];

      case 'U':
        return [
          HarfYolagi(
            raqam: 1,
            nuqtalar: [
              ...yoy(-0.78, -0.75, 0.20, 0.20, pi, pi, 4),
              ...chiziq(p(-0.58, -0.75), p(-0.58, 0.25), 5),
              ...yoy(0, 0.25, 0.58, 0.68, pi, -pi, 8),
            ],
          ),
          HarfYolagi(
            raqam: 2,
            nuqtalar: [
              ...chiziq(p(0.58, -0.95), p(0.58, 0.75), 9),
              ...yoy(0.80, 0.75, 0.22, 0.20, pi, -pi, 4),
            ],
          ),
        ];

      case 'У':
      case 'Y':
        return [
          HarfYolagi(
            raqam: 1,
            nuqtalar: [
              ...yoy(-0.78, -0.75, 0.20, 0.20, pi, pi, 4),
              ...chiziq(p(-0.58, -0.75), p(-0.58, -0.10), 4),
              ...yoy(0, -0.10, 0.58, 0.45, pi, -pi, 7),
            ],
          ),
          HarfYolagi(
            raqam: 2,
            nuqtalar: [
              ...chiziq(p(0.58, -0.95), p(0.58, 0.65), 8),
              ...yoy(0.15, 0.65, 0.43, 0.32, 0, pi, 6),
            ],
          ),
        ];

      case 'E':
      case 'Е':
      case 'Ё':
        return [
          HarfYolagi(
              raqam: 1,
              nuqtalar: yoy(0.10, -0.48, 0.65, 0.46, -pi / 4, -1.25 * pi, 8)),
          HarfYolagi(
              raqam: 2,
              nuqtalar: yoy(0.10, 0.48, 0.70, 0.48, -pi / 2, -1.25 * pi, 9)),
        ];

      case 'Э':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: yoy(-0.10, 0, 0.82, 0.95, -pi / 2, pi, 14)),
          HarfYolagi(raqam: 2, nuqtalar: chiziq(p(-0.10, 0), p(0.68, 0), 5)),
        ];

      case 'G':
      case 'G‘':
        return [
          HarfYolagi(
              raqam: 1,
              nuqtalar: yoy(0.05, 0, 0.82, 0.95, -pi / 5, -1.55 * pi, 15)),
          HarfYolagi(
            raqam: 2,
            nuqtalar: [
              ...chiziq(p(0.10, 0.15), p(0.82, 0.15), 5),
              ...chiziq(p(0.82, 0.15), p(0.82, 0.90), 5),
            ],
          ),
        ];

      case 'Г':
        return [
          HarfYolagi(
            raqam: 1,
            nuqtalar: [
              ...chiziq(p(-0.45, -0.95), p(-0.45, 0.75), 9),
              ...yoy(-0.70, 0.75, 0.25, 0.20, 0, pi, 4),
            ],
          ),
          HarfYolagi(
            raqam: 2,
            nuqtalar: [
              ...chiziq(p(-0.45, -0.95), p(0.60, -0.95), 6),
              ...yoy(0.60, -0.75, 0.20, 0.20, -pi / 2, pi, 4),
            ],
          ),
        ];

      case 'S':
      case 'С':
      case 'C':
        return [
          HarfYolagi(
              raqam: 1,
              nuqtalar: yoy(0.15, 0, 0.82, 0.95, -pi / 4, -1.5 * pi, 16)),
        ];

      case 'H':
        return [
          HarfYolagi(
            raqam: 1,
            nuqtalar: [
              ...chiziq(p(-0.58, -0.95), p(-0.58, 0.75), 9),
              ...yoy(-0.80, 0.75, 0.22, 0.20, 0, pi, 4),
            ],
          ),
          HarfYolagi(
            raqam: 2,
            nuqtalar: [
              ...chiziq(p(0.58, -0.95), p(0.58, 0.75), 9),
              ...yoy(0.80, 0.75, 0.22, 0.20, pi, -pi, 4),
            ],
          ),
          HarfYolagi(raqam: 3, nuqtalar: chiziq(p(-0.58, 0), p(0.58, 0), 6)),
        ];

      case 'X':
      case 'Х':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: yoy(-0.35, 0, 0.55, 0.95, -pi / 2, pi, 11)),
          HarfYolagi(
              raqam: 2, nuqtalar: yoy(0.35, 0, 0.55, 0.95, -pi / 2, -pi, 11)),
        ];

      case 'Q':
        return [
          HarfYolagi(
            raqam: 1,
            yopiqKontur: true,
            nuqtalar: yoy(0, -0.05, 0.80, 0.90, -pi / 2, 2 * pi, 18),
          ),
          HarfYolagi(
            raqam: 2,
            nuqtalar: [
              ...chiziq(p(0.20, 0.45), p(0.65, 0.85), 4),
              ...yoy(0.85, 0.85, 0.20, 0.15, pi, -pi, 3),
            ],
          ),
        ];

      case 'J':
        return [
          HarfYolagi(
            raqam: 1,
            nuqtalar: [
              ...chiziq(p(0.30, -0.95), p(0.30, 0.45), 8),
              ...yoy(-0.18, 0.45, 0.48, 0.50, 0, pi, 7),
            ],
          ),
        ];

      case 'Z':
      case 'З':
        return [
          HarfYolagi(
              raqam: 1,
              nuqtalar: yoy(-0.15, -0.48, 0.68, 0.48, -pi / 2, pi, 8)),
          HarfYolagi(
              raqam: 2, nuqtalar: yoy(-0.15, 0.48, 0.72, 0.48, -pi / 2, pi, 8)),
        ];

      case 'V':
        return [
          HarfYolagi(
            raqam: 1,
            nuqtalar: [
              ...yoy(-0.85, -0.75, 0.18, 0.20, pi, pi, 4),
              ...chiziq(p(-0.67, -0.75), p(0, 0.95), 9),
              ...chiziq(p(0, 0.95), p(0.67, -0.75), 9),
              ...yoy(0.85, -0.75, 0.18, 0.20, pi, -pi, 4),
            ],
          ),
        ];

      case 'W':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.90, -0.95), p(-0.45, 0.95), 8)),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(-0.45, 0.95), p(0, -0.20), 6)),
          HarfYolagi(raqam: 3, nuqtalar: chiziq(p(0, -0.20), p(0.45, 0.95), 6)),
          HarfYolagi(
              raqam: 4, nuqtalar: chiziq(p(0.45, 0.95), p(0.90, -0.95), 8)),
        ];

      case 'F':
      case 'Ф':
        return [
          HarfYolagi(
            raqam: 1,
            nuqtalar: [
              ...chiziq(p(0, -0.95), p(0, 0.75), 9),
              ...yoy(-0.22, 0.75, 0.22, 0.20, 0, pi, 4),
            ],
          ),
          HarfYolagi(
            raqam: 2,
            yopiqKontur: true,
            nuqtalar: yoy(0, -0.15, 0.78, 0.52, -pi / 2, 2 * pi, 14),
          ),
        ];

      case 'Ш':
      case 'Щ':
      case 'SH':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.75, -0.95), p(-0.75, 0.95), 8)),
          HarfYolagi(raqam: 2, nuqtalar: chiziq(p(0, -0.95), p(0, 0.95), 8)),
          HarfYolagi(
              raqam: 3, nuqtalar: chiziq(p(0.75, -0.95), p(0.75, 0.95), 8)),
          HarfYolagi(
              raqam: 4, nuqtalar: chiziq(p(-0.75, 0.95), p(0.75, 0.95), 8)),
        ];

      case 'Ч':
      case 'CH':
        return [
          HarfYolagi(
            raqam: 1,
            nuqtalar: [
              ...yoy(-0.78, -0.75, 0.18, 0.20, pi, pi, 4),
              ...chiziq(p(-0.60, -0.75), p(-0.60, -0.10), 4),
              ...yoy(0, -0.10, 0.60, 0.35, pi, -pi, 7),
            ],
          ),
          HarfYolagi(
            raqam: 2,
            nuqtalar: [
              ...chiziq(p(0.60, -0.95), p(0.60, 0.75), 9),
              ...yoy(0.82, 0.75, 0.22, 0.20, pi, -pi, 4),
            ],
          ),
        ];

      case 'Ж':
        return [
          HarfYolagi(raqam: 1, nuqtalar: chiziq(p(0, -0.95), p(0, 0.95), 10)),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(-0.80, -0.95), p(0.80, 0.95), 10)),
          HarfYolagi(
              raqam: 3, nuqtalar: chiziq(p(0.80, -0.95), p(-0.80, 0.95), 10)),
        ];

      case 'Ц':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.62, -0.95), p(-0.62, 0.95), 9)),
          HarfYolagi(
              raqam: 2, nuqtalar: chiziq(p(0.52, -0.95), p(0.52, 0.95), 9)),
          HarfYolagi(
              raqam: 3, nuqtalar: chiziq(p(-0.62, 0.95), p(0.82, 0.95), 8)),
        ];

      case 'Ю':
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.78, -0.95), p(-0.78, 0.95), 9)),
          HarfYolagi(raqam: 2, nuqtalar: chiziq(p(-0.78, 0), p(-0.22, 0), 4)),
          HarfYolagi(
            raqam: 3,
            yopiqKontur: true,
            nuqtalar: yoy(0.35, 0, 0.58, 0.90, -pi / 2, 2 * pi, 14),
          ),
        ];

      case 'Я':
        return [
          HarfYolagi(
            raqam: 1,
            nuqtalar: [
              ...chiziq(p(0.58, -0.95), p(0.58, 0.75), 9),
              ...yoy(0.80, 0.75, 0.22, 0.20, pi, -pi, 4),
            ],
          ),
          HarfYolagi(
            raqam: 2,
            nuqtalar: [
              ...chiziq(p(0.45, -0.95), p(0.05, -0.95), 3),
              ...yoy(0.05, -0.45, 0.65, 0.50, -pi / 2, -pi, 8),
              ...chiziq(p(0.05, 0.05), p(0.45, 0.05), 3),
            ],
          ),
          HarfYolagi(
            raqam: 3,
            nuqtalar: [
              ...chiziq(p(0.15, 0.05), p(-0.55, 0.75), 6),
              ...yoy(-0.75, 0.75, 0.20, 0.20, 0, pi, 4),
            ],
          ),
        ];

      default:
        return [
          HarfYolagi(
              raqam: 1, nuqtalar: chiziq(p(-0.45, -0.95), p(-0.45, 0.95), 10)),
          HarfYolagi(
            raqam: 2,
            nuqtalar: [
              ...chiziq(p(-0.35, -0.05), p(0.15, -0.05), 4),
              ...yoy(0.15, 0.45, 0.58, 0.50, -pi / 2, pi, 8),
              ...chiziq(p(0.15, 0.95), p(-0.35, 0.95), 4),
            ],
          ),
        ];
    }
  }
}

/// ============================================================================
/// 4. ASOSIY HUSNIXAT ALIFBE VA RAQAMLAR SAHIFASI
/// ============================================================================
class HusnixatAlifbeSahifa extends StatefulWidget {
  final AlifboTili boshlangichTil;
  final String foydalanuvchiTelefoni;

  const HusnixatAlifbeSahifa({
    super.key,
    this.boshlangichTil = AlifboTili.uz,
    this.foydalanuvchiTelefoni = '',
  });

  @override
  State<HusnixatAlifbeSahifa> createState() => _HusnixatAlifbeSahifaState();
}

class _HusnixatAlifbeSahifaState extends State<HusnixatAlifbeSahifa> {
  late AlifboTili _tanlanganTil;
  OquvBolimi _tanlanganBolim = OquvBolimi.harflar;
  int _tanlanganIndex = 0;
  bool _kattaHarf = true;

  final Set<String> _ulanganNuqtalar = {};
  final List<List<Offset>> _chiziqlar = [];
  List<Offset> _joriyChiziq = [];
  Offset? _oxirgiUchqunJoyi;

  int _yulduzlar = 0;
  bool _elementYakunlandi = false;

  List<HarfDarsModel> get _joriyRoyxat {
    if (_tanlanganBolim == OquvBolimi.raqamlar) {
      return raqamlarRoyxati;
    }
    switch (_tanlanganTil) {
      case AlifboTili.uz:
        return uzbekAlifbosi;
      case AlifboTili.ru:
        return rusAlifbosi;
      case AlifboTili.en:
        return englishAlifbosi;
    }
  }

  HarfDarsModel get _joriyElement => _joriyRoyxat[_tanlanganIndex];

  @override
  void initState() {
    super.initState();
    _tanlanganTil = widget.boshlangichTil;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OvozIjrochi.elementniTalaffuzQil(_joriyElement, _tanlanganTil);
    });
  }

  void _bolimniAlmashtirish(OquvBolimi yangiBolim) {
    setState(() {
      _tanlanganBolim = yangiBolim;
      _tanlanganIndex = 0;
      _ulanganNuqtalar.clear();
      _chiziqlar.clear();
      _joriyChiziq = [];
      _oxirgiUchqunJoyi = null;
      _elementYakunlandi = false;
    });
    OvozIjrochi.elementniTalaffuzQil(_joriyElement, _tanlanganTil);
  }

  void _tilniAlmashtirish(AlifboTili yangiTil) {
    setState(() {
      _tanlanganTil = yangiTil;
      _tanlanganIndex = 0;
      _ulanganNuqtalar.clear();
      _chiziqlar.clear();
      _joriyChiziq = [];
      _oxirgiUchqunJoyi = null;
      _elementYakunlandi = false;
    });
    OvozIjrochi.elementniTalaffuzQil(_joriyElement, _tanlanganTil);
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

    if (yangiUlandi && !_elementYakunlandi && jamiNuqtalar > 0) {
      if (_ulanganNuqtalar.length >= (jamiNuqtalar * 0.85).ceil()) {
        _elementYakunlandi = true;
        _yulduzlar += 1;
        OvozIjrochi.tabrikOvoz(_tanlanganTil);
      }
    }
  }

  void _elementniTanlash(int index) {
    setState(() {
      _tanlanganIndex = index;
      _ulanganNuqtalar.clear();
      _chiziqlar.clear();
      _joriyChiziq = [];
      _oxirgiUchqunJoyi = null;
      _elementYakunlandi = false;
    });
    OvozIjrochi.elementniTalaffuzQil(_joriyElement, _tanlanganTil);
  }

  void _oldingiElementgaOtish() {
    final int oldingi =
        (_tanlanganIndex - 1 + _joriyRoyxat.length) % _joriyRoyxat.length;
    _elementniTanlash(oldingi);
  }

  void _keyingiElementgaOtish() {
    final int keyingi = (_tanlanganIndex + 1) % _joriyRoyxat.length;
    _elementniTanlash(keyingi);
  }

  void _tozalash() {
    setState(() {
      _ulanganNuqtalar.clear();
      _chiziqlar.clear();
      _joriyChiziq = [];
      _oxirgiUchqunJoyi = null;
      _elementYakunlandi = false;
    });
  }

  void _tizimdanChiqish() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const KirishSahifasi()),
    );
  }

  String get _sarlavhaMatni {
    if (_tanlanganBolim == OquvBolimi.raqamlar) {
      switch (_tanlanganTil) {
        case AlifboTili.uz:
          return '${_joriyElement.katta} RAQAMI';
        case AlifboTili.ru:
          return 'ЦИФРА ${_joriyElement.katta}';
        case AlifboTili.en:
          return 'NUMBER ${_joriyElement.katta}';
      }
    }
    switch (_tanlanganTil) {
      case AlifboTili.uz:
        return '${_joriyElement.katta} HARFI';
      case AlifboTili.ru:
        return 'БУКВА ${_joriyElement.katta}';
      case AlifboTili.en:
        return 'LETTER ${_joriyElement.katta}';
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
    final bool raqamRejimi = _tanlanganBolim == OquvBolimi.raqamlar;
    final String korsatiladiganBelgi = (_kattaHarf || raqamRejimi)
        ? _joriyElement.katta
        : _joriyElement.kichik;

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
                            HusnixatGeometriyasi.yolaklarniOlish(
                          korsatiladiganBelgi,
                          _kattaHarf,
                          raqamRejimi,
                          doskaSize,
                        );

                        return Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: KonturNuqtaliHarfPainter(
                                  yolaklar: yolaklar,
                                  ulanganlar: _ulanganNuqtalar,
                                  yakunlandi: _elementYakunlandi,
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
                                    yakunlandi: _elementYakunlandi,
                                  ),
                                ),
                              ),
                            ),

                            // Chap yuqori: Bo'lim (Harflar / 0-9), Katta/Kichik, Til (UZ/RU/EN) va Chiqish
                            Positioned(
                              top: 14,
                              left: 16,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _bolimTanlashTugmasi(),
                                  if (!raqamRejimi) _kattaKichikTugma(),
                                  _tilTanlashTugmasi(),
                                  if (widget.foydalanuvchiTelefoni.isNotEmpty)
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
                                          const Icon(
                                              Icons.phone_android_rounded,
                                              size: 16,
                                              color: Colors.blueGrey),
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
                            if (_elementYakunlandi)
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
                                onPressed: _keyingiElementgaOtish,
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
                  onTap: _oldingiElementgaOtish,
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

              // 3. Yuqori markaz: "B HARFI" / "5 RAQAMI" sarlavhasi
              Positioned(
                top: 8,
                left: 80,
                right: 170,
                child: Center(
                  child: GestureDetector(
                    onTap: () => OvozIjrochi.elementniTalaffuzQil(
                        _joriyElement, _tanlanganTil),
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
                                text: _joriyElement.katta,
                                style:
                                    const TextStyle(color: Color(0xFFE53935)),
                              ),
                              TextSpan(
                                text: _sarlavhaMatni
                                    .substring(_joriyElement.katta.length),
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

              // 4. Yuqori o'ng burchak: Oq rasm / sanash kartochkasi
              Positioned(
                top: 10,
                right: 28,
                child: GestureDetector(
                  onTap: () => OvozIjrochi.elementniTalaffuzQil(
                      _joriyElement, _tanlanganTil),
                  child: Container(
                    width: 152,
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
                            Flexible(
                              child: Text(
                                _joriyElement.emoji,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: raqamRejimi ? 22 : 42,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.volume_up_rounded,
                                color: Colors.blue.shade600, size: 22),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _joriyElement.sozniOlish(_tanlanganTil),
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

              // 5. Pastki alifbo yoki raqamlar lentasi (Husnixat kursiv uslubida)
              Positioned(
                bottom: 6,
                left: 18,
                right: 18,
                height: 42,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _joriyRoyxat.length,
                  itemBuilder: (context, index) {
                    final item = _joriyRoyxat[index];
                    final bool tanlangan = index == _tanlanganIndex;
                    return GestureDetector(
                      onTap: () => _elementniTanlash(index),
                      child: Container(
                        width: 44,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: tanlangan
                              ? const Color(0xFF1E88E5)
                              : Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: item.unli
                                ? const Color(0xFFE53935)
                                : const Color(0xFF1E88E5),
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          item.katta,
                          style: GoogleFonts.badScript(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: tanlangan
                                ? Colors.white
                                : (item.unli
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

  Widget _bolimTanlashTugmasi() {
    final String harfMatn = _tanlanganTil == AlifboTili.ru
        ? 'Буквы'
        : (_tanlanganTil == AlifboTili.en ? 'Letters' : 'Harflar');
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _miniChip(
            '🔤 $harfMatn',
            _tanlanganBolim == OquvBolimi.harflar,
            () => _bolimniAlmashtirish(OquvBolimi.harflar),
            aktivRang: const Color(0xFFFF8F00),
          ),
          _miniChip(
            '🔢 0–9',
            _tanlanganBolim == OquvBolimi.raqamlar,
            () => _bolimniAlmashtirish(OquvBolimi.raqamlar),
            aktivRang: const Color(0xFFFF8F00),
          ),
        ],
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
          _miniChip(_joriyElement.katta, _kattaHarf, () {
            setState(() {
              _kattaHarf = true;
              _tozalash();
            });
          }, kursiv: true),
          _miniChip(_joriyElement.kichik, !_kattaHarf, () {
            setState(() {
              _kattaHarf = false;
              _tozalash();
            });
          }, kursiv: true),
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

  Widget _miniChip(String matn, bool aktiv, VoidCallback onTap,
      {Color aktivRang = const Color(0xFF2196F3), bool kursiv = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: aktiv ? aktivRang : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          matn,
          style: kursiv
              ? GoogleFonts.badScript(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: aktiv ? Colors.white : Colors.black87,
                )
              : TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: aktiv ? Colors.white : Colors.black87,
                ),
        ),
      ),
    );
  }
}

/// Maktab husnixat qiya chiziqlari + ichi bo'sh keng konturli husnixat harf/raqam
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
    // 0. Yengil maktab husnixat daftarining gorizontal va qiya chiziqlari
    final Paint daftarGorizontal = Paint()
      ..color = const Color(0xFFBBDEFB).withValues(alpha: 0.55)
      ..strokeWidth = 1.3;

    final Paint daftarQiya = Paint()
      ..color = const Color(0xFFBBDEFB).withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(0, size.height * 0.16),
        Offset(size.width, size.height * 0.16), daftarGorizontal);
    canvas.drawLine(Offset(0, size.height * 0.84),
        Offset(size.width, size.height * 0.84), daftarGorizontal);

    for (double x = -size.height; x < size.width + size.height; x += 75) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height * 0.24, 0),
        daftarQiya,
      );
    }

    // 1. Tashqi keng kulrang kontur va ichki oq yo'lak
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

    // 2. Yo'lak ichidagi nuqtalar, 1-2-3 raqamli doiralar va strelkalar
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
