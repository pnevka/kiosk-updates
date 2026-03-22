import 'dart:ui';
import 'package:flutter/material.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F1F),
      body: Stack(
        children: [
          // Градиент фона
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, const Color(0xFF0D1F1F)],
              ),
            ),
          ),
          // Контент
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            child: Column(
              children: [
                // Фото здания - полностью видно
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'Data/header_contacts.jpg',
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 300,
                        color: const Color(0xFF1D2F2F),
                        child: const Center(
                          child: Icon(Icons.location_city, size: 120, color: Color(0xFF78133A)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
                // Заголовок
                const Text(
                  'КДЦ Тимоново',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                // Карточка с контактами
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D2F2F),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF78133A).withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: Column(
                    children: [
                      _row(Icons.location_on, 'Адрес', '141507, Московская обл., г. Солнечногорск, Подмосковная ул., стр. 1'),
                      const Divider(color: Color(0xFF78133A), height: 40, thickness: 2),
                      _row(Icons.phone, 'Телефон', '+7 (901) 400-45-00'),
                      const Divider(color: Color(0xFF78133A), height: 40, thickness: 2),
                      _row(Icons.email, 'Email', 'kdctimonovo@mail.ru'),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Заголовок соцсетей
                const Text(
                  'Мы в социальных сетях',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                // QR коды - большие
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _qrCard('Data/Contacts/site.png', 'Сайт', Colors.blue),
                    const SizedBox(width: 30),
                    _qrCard('Data/Contacts/vk.png', 'VK', const Color(0xFF0077FF)),
                    const SizedBox(width: 30),
                    _qrCard('Data/Contacts/telegram.png', 'Telegram', const Color(0xFF0088CC)),
                    const SizedBox(width: 30),
                    _qrCard('Data/Contacts/max.png', 'MAX', Colors.purple),
                  ],
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          // Кнопка назад внизу
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          const Text(
                            'Назад',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF78133A).withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF78133A), size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF78133A),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qrCard(String imagePath, String label, Color color) {
    return Container(
      width: 200,
      height: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              imagePath,
              width: 160,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 160,
                  height: 160,
                  color: color.withOpacity(0.2),
                  child: Icon(Icons.qr_code, size: 100, color: color),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
