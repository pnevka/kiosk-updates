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
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Заголовок
                const Text(
                  'КДЦ Тимоново',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),
                // Полное наименование
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D2F2F).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF78133A).withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Муниципальное учреждение культуры городского округа Солнечногорск культурно-досуговый центр «Тимоново»',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'МУК КДЦ «Тимоново»',
                        style: TextStyle(
                          color: Color(0xFF78133A),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                // Директор
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D2F2F),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF78133A).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person, color: Color(0xFF78133A), size: 32),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Директор',
                            style: TextStyle(
                              color: Color(0xFF78133A),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Тюленева Галина Евгеньевна',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                // Карточка с контактами
                Container(
                  padding: const EdgeInsets.all(24),
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
                      _row(Icons.phone, 'Приемная директора', '+7 (901) 400-45-00'),
                      const Divider(color: Color(0xFF78133A), height: 30, thickness: 2),
                      _row(Icons.phone_android, 'Администратор', '+7 (901) 400-45-00'),
                      const Divider(color: Color(0xFF78133A), height: 30, thickness: 2),
                      _row(Icons.access_time, 'Режим работы', 'ПН-ВС 8:00 - 22:00 (без выходных)'),
                      const Divider(color: Color(0xFF78133A), height: 30, thickness: 2),
                      _row(Icons.location_on, 'Адрес', '141507, Московская область, г. Солнечногорск, мкрн. Тимоново, ул.Подмосковная, д. 50'),
                      const Divider(color: Color(0xFF78133A), height: 30, thickness: 2),
                      _row(Icons.email, 'E-mail', 'kdctimonovo@mail.ru'),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Заголовок соцсетей
                const Text(
                  'Мы в социальных сетях',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),
                // QR коды - большие
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _qrCard('Data/Contacts/site.png', 'Сайт', Colors.blue),
                    const SizedBox(width: 25),
                    _qrCard('Data/Contacts/vk.png', 'VK', const Color(0xFF0077FF)),
                    const SizedBox(width: 25),
                    _qrCard('Data/Contacts/telegram.png', 'Telegram', const Color(0xFF0088CC)),
                    const SizedBox(width: 25),
                    _qrCard('Data/Contacts/max.png', 'MAX', Colors.purple),
                  ],
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
          // Кнопка назад внизу
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF78133A).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF78133A), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF78133A),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.3),
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
      width: 180,
      height: 220,
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
              width: 140,
              height: 140,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 140,
                  height: 140,
                  color: color.withOpacity(0.2),
                  child: Icon(Icons.qr_code, size: 80, color: color),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
