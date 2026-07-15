import 'package:flutter/material.dart';

class ActionTextFormField extends StatefulWidget {
  const ActionTextFormField({
    super.key,
    required this.labelText,
    required this.onSave,
    this.initialValue = '',
    this.saveIcon = Icons.save_outlined,
  });

  final String labelText;
  final String initialValue;
  final IconData saveIcon;
  final void Function(String value) onSave;

  @override
  State<ActionTextFormField> createState() => _ActionTextFormFieldState();
}

class _ActionTextFormFieldState extends State<ActionTextFormField> {
  late final TextEditingController _controller;

  // 1. YENİ DURUM: Metnin değişip değişmediğini takip eder.
  bool _isModified = false;

  // Butonun animasyonlu genişliği için bir sabit
  final double _kButtonWidth = 56;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);

    // 2. DİNLEYİCİ: Controller'a _handleTextChange fonksiyonunu ekle
    _controller.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    // 3. TEMİZLİK: Widget kaldırılırken dinleyiciyi de kaldır
    _controller.removeListener(_handleTextChange);
    _controller.dispose();
    super.dispose();
  }

  // Controller her değiştiğinde bu fonksiyon çalışır
  void _handleTextChange() {
    // O anki metin, başlangıçtaki metinden farklı mı?
    final currentlyModified = _controller.text != widget.initialValue;

    // Durum değiştiyse (örn. false -> true olduysa) setState'i çağır
    if (_isModified != currentlyModified) {
      setState(() {
        _isModified = currentlyModified;
      });
    }
  }

  @override
  void didUpdateWidget(covariant ActionTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 1. Dışarıdan gelen 'initialValue' gerçekten değişti mi diye kontrol et
    if (widget.initialValue != oldWidget.initialValue) {
      // 2. Değiştiyse, controller'ın metnini güncelle
      _controller.text = widget.initialValue;

      // 3. BİTTİ. _handleTextChange() fonksiyonunu BURADA ÇAĞIRMAYIN.
      //
      // Neden?
      // Çünkü _controller.text'i değiştirdiğimiz anda, initState'te
      // addListener ile eklediğimiz _handleTextChange fonksiyonu
      // zaten otomatik olarak tetiklenecek ve setState'i güvenle çağıracaktır.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onPrimaryColor = theme.colorScheme.onPrimary;
    final onSurfaceColor = theme.colorScheme.onSurface;

    final inputDecoration = InputDecoration(
      labelText: widget.labelText,
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );

    final defaultBorderRadius = BorderRadius.circular(10);

    return Material(
      elevation: 3,
      borderRadius: defaultBorderRadius,
      clipBehavior: Clip.antiAlias,
      color: theme.cardColor,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TextFormField(
                controller: _controller,
                decoration: inputDecoration,
                style: TextStyle(color: onSurfaceColor),
              ),
            ),

            // 4. ANİMASYON: Butonu AnimatedContainer ile sar
            AnimatedContainer(
              // Animasyonun süresi ve eğrisi
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut, // Yumuşak bir geçiş
              // 5. KOŞULLU GENİŞLİK:
              // Değiştirilmişse _kButtonWidth (56.0) yap, değilse 0.0 yap
              width: _isModified ? _kButtonWidth : 0.0,
              color: primaryColor.withValues(alpha: 0.8),

              // 6. TAŞMAYI ENGELLEME:
              // Genişlik 0 olduğunda içindeki ikonun görünmesini engeller
              clipBehavior: Clip.hardEdge,

              // Animasyon sırasında layout hatası vermemesi için
              // içindeki widget'ın genişliğini sabitliyoruz.
              child: SizedBox(
                width: _kButtonWidth,
                height: double.infinity,
                child: IconButton(
                  onPressed: () {
                    // Kaydete basılınca değişikliği bildir
                    widget.onSave(_controller.text);
                    // (Opsiyonel) Kaydettikten sonra
                    // butonu tekrar gizleyebilirsin
                    // setState(() { _isModified = false; });
                  },
                  icon: Icon(widget.saveIcon),
                  color: onPrimaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
