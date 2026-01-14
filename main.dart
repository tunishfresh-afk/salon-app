import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// Глобальная переменная для управления темой
final ValueNotifier<ThemeMode> _themeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  runApp(const BookingApp());
}

class BookingApp extends StatelessWidget {
  const BookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeNotifier,
      builder: (_, ThemeMode mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Мои Записи',
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: mode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ru', 'RU'),
          ],
          locale: const Locale('ru', 'RU'),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
          home: const LoginScreen(),
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    bool isDark = brightness == Brightness.dark;
    return ThemeData(
      primarySwatch: Colors.teal,
      brightness: brightness,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // ЕДИНЫЙ СТИЛЬ ДЛЯ ВСЕХ КАРТОЧЕК И ПАНЕЛЕЙ
      cardTheme: CardTheme(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0, // Убираем стандартную тень, делаем свою мягкую
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dialogBackgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      // Чтобы нижняя панель совпадала по цвету с карточками
      cardColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
    );
  }
}

// --- ЭКРАН ВХОДА ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedName = prefs.getString('current_master');
    if (savedName != null && savedName.isNotEmpty) {
      _goToCalendar(savedName);
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _login() async {
    String name = _nameController.text.trim();
    if (name.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_master', name);
    _goToCalendar(name);
  }

  void _goToCalendar(String name) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => CalendarScreen(masterName: name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.spa, size: 70, color: Colors.teal),
              ),
              const SizedBox(height: 30),
              const Text("Добро пожаловать",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Личный календарь мастера",
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 40),
              TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(hintText: "Введите ваше имя"),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                    shadowColor: Colors.teal.withOpacity(0.4),
                  ),
                  onPressed: _login,
                  child: const Text("Войти",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- МОДЕЛИ ---
class Appointment {
  final String clientName;
  final String phone;
  final String serviceName;
  final double price;
  final TimeOfDay time;
  final String note;

  Appointment(this.clientName, this.phone, this.serviceName, this.price,
      this.time, this.note);

  Map<String, dynamic> toMap() {
    return {
      'clientName': clientName,
      'phone': phone,
      'serviceName': serviceName,
      'price': price,
      'hour': time.hour,
      'minute': time.minute,
      'note': note,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      map['clientName'] ?? '',
      map['phone'] ?? '',
      map['serviceName'] ?? '',
      (map['price'] ?? 0).toDouble(),
      TimeOfDay(hour: map['hour'] ?? 9, minute: map['minute'] ?? 0),
      map['note'] ?? '',
    );
  }
}

class Expense {
  final String title;
  final double amount;
  final DateTime date;

  Expense(this.title, this.amount, this.date);

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      map['title'] ?? '',
      (map['amount'] ?? 0).toDouble(),
      DateTime.parse(map['date']),
    );
  }
}

// --- ГЛАВНЫЙ ЭКРАН ---
class CalendarScreen extends StatefulWidget {
  final String masterName;

  const CalendarScreen({super.key, required this.masterName});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<DateTime, List<Appointment>> _appointments = {};
  List<Expense> _expenses = [];
  Map<DateTime, String> _blockedDays = {};

  final Map<String, int> _services = {
    'Маникюр': 600,
    'Маникюр с покрытием': 1000,
    'Наращивание (до 3)': 1300,
    'Наращивание (>3)': 1400,
    'Дизайн': 50,
    'Снятие': 200,
    'Ремонт ногтя': 100,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String get _bookingKey => '${widget.masterName}_booking_data';
  String get _expenseKey => '${widget.masterName}_expense_data';
  String get _blockedKey => '${widget.masterName}_blocked_data';

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    Map<String, dynamic> encodeAppMap = {};
    _appointments.forEach((key, value) {
      encodeAppMap[key.toIso8601String()] =
          value.map((e) => e.toMap()).toList();
    });
    await prefs.setString(_bookingKey, json.encode(encodeAppMap));

    List<Map<String, dynamic>> encodeExpList =
        _expenses.map((e) => e.toMap()).toList();
    await prefs.setString(_expenseKey, json.encode(encodeExpList));

    Map<String, String> blockedMap = {};
    _blockedDays.forEach((key, value) {
      blockedMap[key.toIso8601String()] = value;
    });
    await prefs.setString(_blockedKey, json.encode(blockedMap));
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    String? appData = prefs.getString(_bookingKey);
    if (appData != null) {
      Map<String, dynamic> decodedMap = json.decode(appData);
      Map<DateTime, List<Appointment>> tempAppointments = {};
      decodedMap.forEach((key, value) {
        DateTime dateKey = DateTime.parse(key);
        DateTime cleanDate = DateUtils.dateOnly(dateKey);
        List<Appointment> list =
            (value as List).map((e) => Appointment.fromMap(e)).toList();
        tempAppointments[cleanDate] = list;
      });
      _appointments = tempAppointments;
    }

    String? expData = prefs.getString(_expenseKey);
    if (expData != null) {
      List<dynamic> decodedList = json.decode(expData);
      _expenses = decodedList.map((e) => Expense.fromMap(e)).toList();
    }

    String? blockedData = prefs.getString(_blockedKey);
    if (blockedData != null) {
      dynamic decoded = json.decode(blockedData);
      Map<DateTime, String> tempBlocked = {};

      if (decoded is Map) {
        decoded.forEach((key, value) {
          tempBlocked[DateUtils.dateOnly(DateTime.parse(key))] =
              value.toString();
        });
      } else if (decoded is List) {
        for (var item in decoded) {
          tempBlocked[DateUtils.dateOnly(DateTime.parse(item))] = "Закрыто";
        }
      }
      _blockedDays = tempBlocked;
    }

    setState(() {});
  }

  void _toggleDayLock() async {
    DateTime dateKey = DateUtils.dateOnly(_selectedDate);

    if (_blockedDays.containsKey(dateKey)) {
      setState(() {
        _blockedDays.remove(dateKey);
        _saveData();
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("День снова открыт! ✅")));
      return;
    }

    if (_appointments[dateKey] != null && _appointments[dateKey]!.isNotEmpty) {
      bool confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("⚠️ Внимание"),
              content: const Text(
                  "На этот день есть записи! Вы точно хотите закрыть его?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Нет")),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text("Да, закрыть")),
              ],
            ),
          ) ??
          false;
      if (!confirm) return;
    }

    TextEditingController reasonController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Закрыть день ⛔"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Укажите причину:"),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              autofocus: true,
              decoration:
                  const InputDecoration(hintText: "Например: Отпуск..."),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Отмена")),
          ElevatedButton(
            onPressed: () {
              String reason = reasonController.text.isEmpty
                  ? "ДЕНЬ ЗАКРЫТ"
                  : reasonController.text;
              setState(() {
                _blockedDays[dateKey] = reason;
                _saveData();
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Закрыть"),
          )
        ],
      ),
    );
  }

  Future<void> _backupData() async {
    final prefs = await SharedPreferences.getInstance();
    String? bookingData = prefs.getString(_bookingKey);
    String? expenseData = prefs.getString(_expenseKey);
    String? blockedData = prefs.getString(_blockedKey);

    Map<String, dynamic> backupMap = {
      'master': widget.masterName,
      'booking_data': bookingData,
      'expense_data': expenseData,
      'blocked_data': blockedData,
      'date': DateTime.now().toIso8601String(),
    };

    String jsonString = json.encode(backupMap);
    await Clipboard.setData(ClipboardData(text: jsonString));

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Скопировано! ✅"),
          content:
              Text("База данных мастера ${widget.masterName} скопирована."),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Понятно"))
          ],
        ),
      );
    }
  }

  Future<void> _restoreData() async {
    TextEditingController controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Восстановление 📥"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Вставьте код резервной копии:",
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            TextField(
                controller: controller,
                maxLines: 5,
                decoration: const InputDecoration(hintText: "Вставьте код...")),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Отмена")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              try {
                Map<String, dynamic> backupMap = json.decode(controller.text);
                if (backupMap['master'] != widget.masterName) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          "Ошибка! Это база мастера ${backupMap['master']}.")));
                  Navigator.pop(context);
                  return;
                }

                final prefs = await SharedPreferences.getInstance();
                if (backupMap['booking_data'] != null)
                  await prefs.setString(_bookingKey, backupMap['booking_data']);
                if (backupMap['expense_data'] != null)
                  await prefs.setString(_expenseKey, backupMap['expense_data']);
                if (backupMap['blocked_data'] != null)
                  await prefs.setString(_blockedKey, backupMap['blocked_data']);

                await _loadData();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Данные восстановлены! 🎉")));
                }
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Ошибка формата ❌")));
              }
            },
            child: const Text("Восстановить"),
          )
        ],
      ),
    );
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_master');
    if (mounted) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  bool _isHoliday(DateTime date) {
    if (date.weekday == 6 || date.weekday == 7) return true;
    if (date.month == 1 && date.day <= 8) return true;
    if (date.month == 2 && date.day == 23) return true;
    if (date.month == 3 && date.day == 8) return true;
    if (date.month == 5 && (date.day == 1 || date.day == 9)) return true;
    if (date.month == 6 && date.day == 12) return true;
    if (date.month == 11 && date.day == 4) return true;
    return false;
  }

  void _addExpense() async {
    TextEditingController titleController = TextEditingController();
    TextEditingController amountController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить расход',
            style: TextStyle(
                color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'На что?')),
            const SizedBox(height: 10),
            TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Сумма (₽)')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  amountController.text.isNotEmpty) {
                setState(() {
                  _expenses.add(Expense(
                    titleController.text,
                    double.tryParse(amountController.text) ?? 0,
                    _selectedDate,
                  ));
                  _saveData();
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Добавить'),
          )
        ],
      ),
    );
  }

  void _showMonthlyStats() {
    double monthlyRevenue = 0;
    int clientsCount = 0;
    _appointments.forEach((date, list) {
      if (date.month == _selectedDate.month &&
          date.year == _selectedDate.year) {
        for (var app in list) {
          monthlyRevenue += app.price;
          clientsCount++;
        }
      }
    });
    double monthlyExpenses = 0;
    for (var exp in _expenses) {
      if (exp.date.month == _selectedDate.month &&
          exp.date.year == _selectedDate.year) {
        monthlyExpenses += exp.amount;
      }
    }
    double netProfit = monthlyRevenue - monthlyExpenses;
    String monthName = _monthName(_selectedDate.month);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Финансы: $monthName",
            style: const TextStyle(color: Colors.teal)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statRow("Выручка:", "+${monthlyRevenue.toInt()} ₽", Colors.green),
            const SizedBox(height: 8),
            _statRow("Расходы:", "-${monthlyExpenses.toInt()} ₽", Colors.red),
            const Divider(),
            _statRow("Прибыль:", "${netProfit.toInt()} ₽", Colors.teal,
                isBold: true),
            const SizedBox(height: 15),
            Text("Клиентов: $clientsCount",
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Отлично"))
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, Color color,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  void _generateWindows() async {
    String resultText =
        "💅 *Свободные окошки мастера ${widget.masterName}:*\n\n";
    DateTime startDate = DateTime.now();
    List<int> fixedSlots = [10, 13, 16];

    for (int i = 1; i <= 14; i++) {
      DateTime day = startDate.add(Duration(days: i));
      if (_isHoliday(day)) continue;

      DateTime dayKey = DateUtils.dateOnly(day);

      if (_blockedDays.containsKey(dayKey)) continue;

      List<Appointment> apps = _appointments[dayKey] ?? [];

      List<String> freeTimes = [];
      for (int slotHour in fixedSlots) {
        bool isBusy = false;
        for (var app in apps) {
          if ((app.time.hour - slotHour).abs() < 2) {
            isBusy = true;
            break;
          }
        }
        if (!isBusy) {
          freeTimes.add("$slotHour:00");
        }
      }

      if (freeTimes.isNotEmpty) {
        resultText +=
            "📅 *${day.day} ${_monthNameRod(day.month)}* (${_weekDayName(day.weekday)}):\n";
        resultText += "   ${freeTimes.join(', ')}\n";
      }
    }
    resultText += "\nЗапись у мастера: ${widget.masterName} 💌";

    await showDialog(
      context: context,
      builder: (context) {
        bool isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          title: const Text("Сторис (Умный подбор)"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Показано свободное время (10, 13, 16):",
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(resultText),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text("Скопировать"),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: resultText));
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Скопировано!")));
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }

  String _weekDayName(int day) {
    const days = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
    return days[day - 1];
  }

  void _openCustomCalendar() async {
    DateTime tempDate = _selectedDate;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            List<Widget> dayWidgets = [];
            int daysInMonth =
                DateUtils.getDaysInMonth(tempDate.year, tempDate.month);
            int firstWeekday =
                DateTime(tempDate.year, tempDate.month, 1).weekday;

            for (int i = 1; i < firstWeekday; i++) dayWidgets.add(Container());

            for (int day = 1; day <= daysInMonth; day++) {
              DateTime date = DateTime(tempDate.year, tempDate.month, day);
              bool isRedDay = _isHoliday(date);
              bool isSelected = DateUtils.isSameDay(date, _selectedDate);
              bool hasApp =
                  _appointments[DateUtils.dateOnly(date)]?.isNotEmpty ?? false;

              bool isBlocked =
                  _blockedDays.containsKey(DateUtils.dateOnly(date));

              Color boxColor;
              Color textColor;
              bool isDark = Theme.of(context).brightness == Brightness.dark;

              if (isSelected) {
                boxColor = Colors.teal;
                textColor = Colors.white;
              } else if (isBlocked) {
                boxColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
                textColor = isDark ? Colors.white70 : Colors.black54;
              } else if (isRedDay) {
                boxColor = isDark ? Colors.red[900]! : const Color(0xFFFFEBEE);
                textColor = isDark ? Colors.white : Colors.red;
              } else {
                boxColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
                textColor = isDark ? Colors.white : Colors.black87;
              }

              dayWidgets.add(
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedDate = date);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: boxColor,
                      borderRadius:
                          BorderRadius.circular(12), // Чуть круглее дни
                      border: DateUtils.isSameDay(date, DateTime.now())
                          ? Border.all(color: Colors.teal, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("$day",
                            style: TextStyle(
                                color: textColor, fontWeight: FontWeight.bold)),
                        if (isBlocked)
                          Icon(Icons.lock, size: 10, color: textColor)
                        else if (hasApp)
                          Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                  color:
                                      isSelected ? Colors.white : Colors.teal,
                                  shape: BoxShape.circle))
                      ],
                    ),
                  ),
                ),
              );
            }

            return AlertDialog(
              contentPadding: const EdgeInsets.all(10),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setDialogState(() => tempDate =
                          DateTime(tempDate.year, tempDate.month - 1))),
                  Text(_monthName(tempDate.month) + " ${tempDate.year}",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => setDialogState(() => tempDate =
                          DateTime(tempDate.year, tempDate.month + 1))),
                ],
              ),
              content: SizedBox(
                  width: double.maxFinite,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС']
                            .map((d) => SizedBox(
                                width: 30,
                                child: Center(
                                    child: Text(d,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey)))))
                            .toList()),
                    const SizedBox(height: 10),
                    GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 7,
                        children: dayWidgets),
                  ])),
            );
          },
        );
      },
    );
  }

  String _monthName(int month) => [
        "",
        "Январь",
        "Февраль",
        "Март",
        "Апрель",
        "Май",
        "Июнь",
        "Июль",
        "Август",
        "Сентябрь",
        "Октябрь",
        "Ноябрь",
        "Декабрь"
      ][month];
  String _monthNameRod(int month) => [
        "",
        "января",
        "февраля",
        "марта",
        "апреля",
        "мая",
        "июня",
        "июля",
        "августа",
        "сентября",
        "октября",
        "ноября",
        "декабря"
      ][month];

  void _addAppointment() async {
    TimeOfDay now = TimeOfDay.now();
    String timeString = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";

    TextEditingController nameController = TextEditingController();
    TextEditingController phoneController = TextEditingController();
    TextEditingController priceController = TextEditingController();
    TextEditingController noteController = TextEditingController();
    TextEditingController timeController =
        TextEditingController(text: timeString);
    String? selectedService;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Новая запись',
                  style: TextStyle(
                      color: Colors.teal, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        controller: timeController,
                        keyboardType: TextInputType.datetime,
                        decoration: const InputDecoration(
                            labelText: 'Время',
                            hintText: "Например 14:30 или 14",
                            prefixIcon: Icon(Icons.access_time))),
                    const SizedBox(height: 10),
                    TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                            labelText: 'Имя', prefixIcon: Icon(Icons.person))),
                    const SizedBox(height: 10),
                    TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                            labelText: 'Телефон',
                            prefixIcon: Icon(Icons.phone))),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                          labelText: 'Услуга', prefixIcon: Icon(Icons.cut)),
                      value: selectedService,
                      items: _services.keys
                          .map((String key) =>
                              DropdownMenuItem(value: key, child: Text(key)))
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedService = newValue;
                          if (newValue != null)
                            priceController.text =
                                _services[newValue].toString();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Цена',
                            prefixIcon: Icon(Icons.attach_money))),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                          labelText: 'Заметка', prefixIcon: Icon(Icons.note)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена',
                        style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text('Сохранить'),
                )
              ],
            );
          },
        );
      },
    );

    if (nameController.text.isEmpty) return;

    TimeOfDay? parsedTime = _parseTime(timeController.text);
    if (parsedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ошибка! Неверный формат времени ❌")));
      return;
    }

    setState(() {
      DateTime dateKey = DateUtils.dateOnly(_selectedDate);
      if (_appointments[dateKey] == null) _appointments[dateKey] = [];
      _appointments[dateKey]!.add(Appointment(
        nameController.text,
        phoneController.text,
        selectedService ?? "Услуга",
        double.tryParse(priceController.text) ?? 0,
        parsedTime,
        noteController.text,
      ));
      _appointments[dateKey]!.sort((a, b) => (a.time.hour * 60 + a.time.minute)
          .compareTo(b.time.hour * 60 + b.time.minute));
      _saveData();
    });
  }

  TimeOfDay? _parseTime(String input) {
    try {
      final clean = input.trim().replaceAll(RegExp(r'[.,\s]'), ':');
      final parts = clean.split(':');
      int h = int.parse(parts[0]);
      int m = 0;
      if (parts.length > 1) {
        m = int.parse(parts[1]);
      }
      if (h < 0 || h > 23 || m < 0 || m > 59) return null;
      return TimeOfDay(hour: h, minute: m);
    } catch (e) {
      return null;
    }
  }

  void _openSearch() {
    showSearch(
        context: context,
        delegate: AppointmentSearchDelegate(_appointments, _makePhoneCall));
  }

  @override
  Widget build(BuildContext context) {
    DateTime dateKey = DateUtils.dateOnly(_selectedDate);
    List<Appointment> todaysAppointments = _appointments[dateKey] ?? [];
    double dailyTotal = 0;
    for (var app in todaysAppointments) dailyTotal += app.price;

    bool isDayBlocked = _blockedDays.containsKey(dateKey);
    String blockReason = isDayBlocked ? _blockedDays[dateKey]! : "";
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
                '${_selectedDate.day} ${_monthNameRod(_selectedDate.month)} ${_selectedDate.year}',
                style: const TextStyle(fontSize: 16)),
            Text(widget.masterName,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Colors.white70)),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _openSearch),
          IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: _openCustomCalendar),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'lock') _toggleDayLock();
              if (value == 'stats') _showMonthlyStats();
              if (value == 'stories') _generateWindows();
              if (value == 'backup') _backupData();
              if (value == 'restore') _restoreData();
              if (value == 'theme') {
                _themeNotifier.value = _themeNotifier.value == ThemeMode.light
                    ? ThemeMode.dark
                    : ThemeMode.light;
              }
              if (value == 'logout') _logout();
            },
            itemBuilder: (BuildContext context) {
              String lockText = isDayBlocked ? "Открыть день" : "Закрыть день";
              IconData lockIcon = isDayBlocked ? Icons.lock_open : Icons.block;

              return <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                    value: 'lock',
                    child: ListTile(
                        leading: Icon(lockIcon, color: Colors.orange),
                        title: Text(lockText))),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                    value: 'stats',
                    child: ListTile(
                        leading: Icon(Icons.bar_chart),
                        title: Text('Финансы'))),
                const PopupMenuItem<String>(
                    value: 'stories',
                    child: ListTile(
                        leading: Icon(Icons.copy_all), title: Text('Сторис'))),
                const PopupMenuItem<String>(
                    value: 'backup',
                    child: ListTile(
                        leading: Icon(Icons.upload),
                        title: Text('Сохранить базу'))),
                const PopupMenuItem<String>(
                    value: 'restore',
                    child: ListTile(
                        leading: Icon(Icons.download),
                        title: Text('Восстановить'))),
                const PopupMenuItem<String>(
                    value: 'theme',
                    child: ListTile(
                        leading: Icon(Icons.brightness_6),
                        title: Text('Тема'))),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                    value: 'logout',
                    child: ListTile(
                        leading: Icon(Icons.logout, color: Colors.red),
                        title: Text('Выйти',
                            style: TextStyle(color: Colors.red)))),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isDayBlocked
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.block, size: 60, color: Colors.grey),
                        const SizedBox(height: 20),
                        Text(blockReason,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent)),
                        const SizedBox(height: 10),
                        const Text("День закрыт для записи",
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : (todaysAppointments.isEmpty
                    ? Center(
                        child: Text("Нет записей",
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 16)))
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 10),
                        itemCount: todaysAppointments.length,
                        itemBuilder: (context, index) {
                          final app = todaysAppointments[index];
                          // --- ВОТ ЗДЕСЬ ОБНОВЛЕННЫЙ ДИЗАЙН КАРТОЧКИ ---
                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black
                                          .withOpacity(isDark ? 0.3 : 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4))
                                ]),
                            child: Row(
                              children: [
                                // Время (Стильная капсула)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    app.time.format(context),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                        fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                // Инфо
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(app.clientName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text(app.serviceName,
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13)),
                                      if (app.note.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2),
                                          child: Text("📝 ${app.note}",
                                              style: TextStyle(
                                                  color: Colors.grey[500],
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic)),
                                        ),
                                    ],
                                  ),
                                ),
                                // Цена и действия
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text("${app.price.toInt()} ₽",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        if (app.phone.isNotEmpty)
                                          InkWell(
                                            onTap: () =>
                                                _makePhoneCall(app.phone),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: const Padding(
                                              padding: EdgeInsets.all(6.0),
                                              child: Icon(Icons.phone,
                                                  color: Colors.green,
                                                  size: 20),
                                            ),
                                          ),
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              todaysAppointments
                                                  .removeAt(index);
                                              _saveData();
                                            });
                                          },
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: const Padding(
                                            padding: EdgeInsets.all(6.0),
                                            child: Icon(Icons.delete_outline,
                                                color: Colors.redAccent,
                                                size: 20),
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                )
                              ],
                            ),
                          );
                          // ------------------------------------------
                        },
                      )),
          ),

          // Панель снизу
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                      color: isDark ? Colors.black45 : Colors.black12,
                      blurRadius: 15,
                      offset: const Offset(0, -5))
                ]),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Выручка за день",
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text("${dailyTotal.toInt()} ₽",
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal)),
                    ],
                  ),
                ),
                if (!isDayBlocked) ...[
                  SizedBox(
                    height: 50,
                    width: 50,
                    child: OutlinedButton(
                      onPressed: _addExpense,
                      style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: const Icon(Icons.remove, color: Colors.redAccent),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _addAppointment,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 24)),
                      icon: const Icon(Icons.add),
                      label: const Text("Запись",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ]
              ],
            ),
          )
        ],
      ),
    );
  }
}

class AppointmentSearchDelegate extends SearchDelegate {
  final Map<DateTime, List<Appointment>> appointments;
  final Function(String) onCall;

  AppointmentSearchDelegate(this.appointments, this.onCall);

  @override
  String get searchFieldLabel => 'Поиск клиента...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      inputDecorationTheme:
          const InputDecorationTheme(border: InputBorder.none),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null));
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    List<Map<String, dynamic>> results = [];
    appointments.forEach((date, list) {
      for (var app in list) {
        if (app.clientName.toLowerCase().contains(query.toLowerCase())) {
          results.add({'date': date, 'app': app});
        }
      }
    });

    results.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    if (results.isEmpty) {
      return const Center(child: Text("Ничего не найдено"));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        final Appointment app = item['app'];
        final DateTime date = item['date'];

        return ListTile(
          title: Text(app.clientName,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
              "${date.day}.${date.month}.${date.year} в ${app.time.format(context)} - ${app.serviceName}"),
          trailing: app.phone.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.phone, color: Colors.green),
                  onPressed: () => onCall(app.phone))
              : null,
        );
      },
    );
  }
}
