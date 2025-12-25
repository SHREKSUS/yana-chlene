import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';
import 'dart:convert';
import '../models/building.dart';
import '../models/shelf.dart';
import '../models/rack.dart';
import '../models/book.dart';
import '../models/user.dart';
import '../models/favorite.dart';
import '../models/loan.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static SharedPreferences? _prefs;
  static bool _initialized = false;

  DatabaseHelper._init();

  Future<void> init() async {
    if (_initialized) return;
    
    if (kIsWeb) {
      _prefs = await SharedPreferences.getInstance();
      await _initializeWebData();
    } else {
      if (_database != null) return;
      _database = await _initDB('library.db');
    }
    _initialized = true;
  }

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('Use web methods for web platform');
    }
    if (_database != null) return _database!;
    _database = await _initDB('library.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // Web storage methods
  List<T> _getList<T>(String key, T Function(Map<String, dynamic>) fromMap) {
    if (!kIsWeb || _prefs == null) return [];
    final jsonString = _prefs!.getString(key);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((item) => fromMap(item as Map<String, dynamic>)).toList();
  }

  Future<void> _saveList<T>(String key, List<T> items, Map<String, dynamic> Function(T) toMap) async {
    if (!kIsWeb || _prefs == null) return;
    final jsonList = items.map((item) => toMap(item)).toList();
    await _prefs!.setString(key, json.encode(jsonList));
  }

  Future<void> _addToList<T>(String key, T item, Map<String, dynamic> Function(T) toMap, int? Function(T) getId) async {
    final list = _getList(key, (map) => item);
    final jsonList = _prefs!.getString(key);
    if (jsonList == null) {
      await _saveList(key, [item], toMap);
      return;
    }
    final List<dynamic> items = json.decode(jsonList);
    final maxId = items.isEmpty ? 0 : (items.map((e) => (e as Map)['id'] as int? ?? 0).reduce((a, b) => a > b ? a : b));
    final itemMap = toMap(item);
    itemMap['id'] = (maxId + 1);
    items.add(itemMap);
    await _prefs!.setString(key, json.encode(items));
  }

  Future<void> _initializeWebData() async {
    if (_prefs == null) return;
    
    // Check if already initialized
    if (_prefs!.getBool('db_initialized') == true) return;

    // Initialize buildings
    final buildings = [
      Building(id: 1, name: 'Домалак Ана', code: 'DA'),
      Building(id: 2, name: 'Толе Би', code: 'TB'),
    ];
    await _saveList('buildings', buildings, (b) => b.toMap());

    // Initialize user
    final user = User(
      id: 1,
      username: 'admin',
      password: 'admin123',
      role: UserRole.librarian,
    );
    await _saveList('users', [user], (u) => u.toMap());

    // Initialize shelves for DA building
    final shelves = [
      Shelf(id: 1, buildingId: 1, letter: 'A'),
      Shelf(id: 2, buildingId: 1, letter: 'B'),
      Shelf(id: 3, buildingId: 1, letter: 'C'),
      Shelf(id: 4, buildingId: 1, letter: 'D'),
      Shelf(id: 5, buildingId: 1, letter: 'E'),
      Shelf(id: 6, buildingId: 1, letter: 'F'),
    ];
    await _saveList('shelves', shelves, (s) => s.toMap());

    // Initialize shelves for TB building
    final shelvesTB = [
      Shelf(id: 7, buildingId: 2, letter: 'A'),
      Shelf(id: 8, buildingId: 2, letter: 'B'),
      Shelf(id: 9, buildingId: 2, letter: 'C'),
    ];
    shelves.addAll(shelvesTB);
    await _saveList('shelves', shelves, (s) => s.toMap());

    // Initialize racks
    final racks = <Rack>[];
    int rackId = 1;
    for (var shelf in shelves) {
      for (int i = 1; i <= 5; i++) {
        racks.add(Rack(id: rackId++, shelfId: shelf.id!, number: i));
      }
    }
    await _saveList('racks', racks, (r) => r.toMap());

    // Initialize books
    final books = [
      Book(
        id: 1,
        rackId: 1, // Shelf A, Rack 1
        title: 'Учебник «Алгебра 10 класс»',
        author: 'Иванов И.И.',
        subject: 'Математика',
        description: 'Учебник по алгебре для 10 класса',
        totalCopies: 2,
        availableCopies: 1,
        onHandCopies: 1,
        coverImagePath: 'assets/images/algebra.jpg',
      ),
      Book(
        id: 2,
        rackId: 1,
        title: 'Геометрия 10-11 класс',
        author: 'Петров П.П.',
        subject: 'Математика',
        description: 'Учебник по геометрии для старших классов',
        totalCopies: 3,
        availableCopies: 2,
        onHandCopies: 1,
        coverImagePath: 'assets/images/geometry.jpg',
      ),
      Book(
        id: 3,
        rackId: 6, // Shelf B, Rack 1
        title: 'История Казахстана',
        author: 'Сидоров С.С.',
        subject: 'История',
        description: 'Учебник по истории Казахстана',
        totalCopies: 5,
        availableCopies: 4,
        onHandCopies: 1,
        coverImagePath: 'assets/images/histkz.jpg',
      ),
      Book(
        id: 4,
        rackId: 6,
        title: 'Всемирная история',
        author: 'Кузнецов К.К.',
        subject: 'История',
        description: 'Учебник по всемирной истории',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: 'assets/images/vshist.jpg',
      ),
      Book(
        id: 5,
        rackId: 11, // Shelf C, Rack 1
        title: 'Физика 10 класс',
        author: 'Новый Н.Н.',
        subject: 'Физика',
        description: 'Учебник по физике для 10 класса',
        totalCopies: 3,
        availableCopies: 2,
        onHandCopies: 1,
        coverImagePath: 'assets/images/fisic.jpg',
      ),
      Book(
        id: 6,
        rackId: 11,
        title: 'Химия 10 класс',
        author: 'Морозов М.М.',
        subject: 'Химия',
        description: 'Учебник по химии для 10 класса',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: 'assets/images/himiya.jpg',
      ),
      Book(
        id: 7,
        rackId: 16, // Shelf D, Rack 1
        title: 'Биология 10 класс',
        author: 'Волков В.В.',
        subject: 'Биология',
        description: 'Учебник по биологии для 10 класса',
        totalCopies: 3,
        availableCopies: 2,
        onHandCopies: 1,
        coverImagePath: 'assets/images/bilolgy.jpg',
      ),
      Book(
        id: 8,
        rackId: 16,
        title: 'География Казахстана',
        author: 'Орлов О.О.',
        subject: 'География',
        description: 'Учебник по географии Казахстана',
        totalCopies: 5,
        availableCopies: 4,
        onHandCopies: 1,
        coverImagePath: 'assets/images/geography.jpg',
      ),
      Book(
        id: 9,
        rackId: 21, // Shelf E, Rack 1
        title: 'Казахский язык 10 класс',
        author: 'Абдуллаев А.А.',
        subject: 'Казахский язык',
        description: 'Учебник по казахскому языку',
        totalCopies: 6,
        availableCopies: 5,
        onHandCopies: 1,
        coverImagePath: 'assets/images/kazakh.jpg',
      ),
      Book(
        id: 10,
        rackId: 21,
        title: 'Русский язык 10 класс',
        author: 'Смирнова С.С.',
        subject: 'Русский язык',
        description: 'Учебник по русскому языку',
        totalCopies: 5,
        availableCopies: 4,
        onHandCopies: 1,
        coverImagePath: 'assets/images/russ.jpg',
      ),
      Book(
        id: 11,
        rackId: 26, // Shelf F, Rack 1
        title: 'Английский язык 10 класс',
        author: 'Brown J.',
        subject: 'Английский язык',
        description: 'Учебник по английскому языку',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: 'assets/images/english.jpg',
      ),
      Book(
        id: 12,
        rackId: 26,
        title: 'Информатика 10 класс',
        author: 'Техников Т.Т.',
        subject: 'Информатика',
        description: 'Учебник по информатике',
        totalCopies: 3,
        availableCopies: 2,
        onHandCopies: 1,
        coverImagePath: 'assets/images/inform.jpg',
      ),
      Book(
        id: 13,
        rackId: 31, // TB Building, Shelf A, Rack 1
        title: 'Литература Казахстана',
        author: 'Писатель П.П.',
        subject: 'Литература',
        description: 'Учебник по казахской литературе',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
      ),
      Book(
        id: 14,
        rackId: 31,
        title: 'Мировая литература',
        author: 'Классик К.К.',
        subject: 'Литература',
        description: 'Учебник по мировой литературе',
        totalCopies: 5,
        availableCopies: 4,
        onHandCopies: 1,
      ),
      Book(
        id: 15,
        rackId: 36, // TB Building, Shelf B, Rack 1
        title: 'Основы права',
        author: 'Юристов Ю.Ю.',
        subject: 'Право',
        description: 'Учебник по основам права',
        totalCopies: 3,
        availableCopies: 2,
        onHandCopies: 1,
      ),
      // Художественная литература
      Book(
        id: 16,
        rackId: 2, // DA Building, Shelf A, Rack 2
        title: 'Абай жолы',
        author: 'Мухтар Ауэзов',
        subject: null,
        genre: 'Исторический роман',
        description: 'Роман-эпопея о жизни и творчестве Абая Кунанбаева',
        totalCopies: 5,
        availableCopies: 4,
        onHandCopies: 1,
        coverImagePath: 'assets/images/histkz.jpg',
      ),
      Book(
        id: 17,
        rackId: 2,
        title: 'Путь Абая',
        author: 'Мухтар Ауэзов',
        subject: null,
        genre: 'Исторический роман',
        description: 'Эпопея о великом казахском поэте и мыслителе',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: 'assets/images/histkz.jpg',
      ),
      Book(
        id: 18,
        rackId: 3, // DA Building, Shelf A, Rack 3
        title: 'Война и мир',
        author: 'Лев Толстой',
        subject: null,
        description: 'Роман-эпопея о русском обществе эпохи войн против Наполеона',
        totalCopies: 3,
        availableCopies: 2,
        onHandCopies: 1,
      ),
      Book(
        id: 19,
        rackId: 3,
        title: 'Преступление и наказание',
        author: 'Фёдор Достоевский',
        subject: null,
        description: 'Психологический роман о преступлении и его последствиях',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
      ),
      Book(
        id: 20,
        rackId: 7, // DA Building, Shelf B, Rack 2
        title: 'Мастер и Маргарита',
        author: 'Михаил Булгаков',
        subject: null,
        genre: 'Философский роман',
        description: 'Философский роман о добре и зле, любви и предательстве',
        totalCopies: 5,
        availableCopies: 4,
        onHandCopies: 1,
        coverImagePath: 'assets/images/russ.jpg',
      ),
      Book(
        id: 21,
        rackId: 7,
        title: 'Евгений Онегин',
        author: 'Александр Пушкин',
        subject: null,
        genre: 'Роман в стихах',
        description: 'Роман в стихах о любви и жизни русского дворянства',
        totalCopies: 6,
        availableCopies: 5,
        onHandCopies: 1,
        coverImagePath: 'assets/images/russ.jpg',
      ),
      Book(
        id: 22,
        rackId: 12, // DA Building, Shelf C, Rack 2
        title: 'Гарри Поттер и философский камень',
        author: 'Дж. К. Роулинг',
        subject: null,
        genre: 'Фэнтези',
        description: 'Первая книга серии о юном волшебнике',
        totalCopies: 7,
        availableCopies: 6,
        onHandCopies: 1,
        coverImagePath: null, // F39C12/FFFFFF?text=Гарри+Поттер',
      ),
      Book(
        id: 23,
        rackId: 12,
        title: 'Властелин колец',
        author: 'Дж. Р. Р. Толкин',
        subject: null,
        genre: 'Фэнтези',
        description: 'Эпическая фантастическая трилогия о Средиземье',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null, // 16A085/FFFFFF?text=Властелин',
      ),
      Book(
        id: 24,
        rackId: 17, // DA Building, Shelf D, Rack 2
        title: '1984',
        author: 'Джордж Оруэлл',
        subject: null,
        genre: 'Антиутопия',
        description: 'Антиутопический роман о тоталитарном обществе',
        totalCopies: 5,
        availableCopies: 4,
        onHandCopies: 1,
        coverImagePath: null, // 2C3E50/FFFFFF?text=1984',
      ),
      Book(
        id: 25,
        rackId: 17,
        title: 'Скотный двор',
        author: 'Джордж Оруэлл',
        subject: null,
        genre: 'Антиутопия',
        description: 'Аллегорическая повесть о революции и власти',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null, // 34495E/FFFFFF?text=Скотный+двор',
      ),
      Book(
        id: 26,
        rackId: 22, // DA Building, Shelf E, Rack 2
        title: 'Анна Каренина',
        author: 'Лев Толстой',
        subject: null,
        genre: 'Роман',
        description: 'Роман о трагической любви и общественных нравах',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null, // E67E22/FFFFFF?text=Анна+Каренина',
      ),
      Book(
        id: 27,
        rackId: 22,
        title: 'Отцы и дети',
        author: 'Иван Тургенев',
        subject: null,
        genre: 'Роман',
        description: 'Роман о конфликте поколений в России XIX века',
        totalCopies: 5,
        availableCopies: 4,
        onHandCopies: 1,
        coverImagePath: null, // D35400/FFFFFF?text=Отцы+и+дети',
      ),
      Book(
        id: 28,
        rackId: 27, // DA Building, Shelf F, Rack 2
        title: 'Герой нашего времени',
        author: 'Михаил Лермонтов',
        subject: null,
        genre: 'Психологический роман',
        description: 'Психологический роман о русском офицере',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null, // 8E44AD/FFFFFF?text=Герой',
      ),
      Book(
        id: 29,
        rackId: 27,
        title: 'Мёртвые души',
        author: 'Николай Гоголь',
        subject: null,
        genre: 'Поэма',
        description: 'Поэма о похождениях Чичикова и русском обществе',
        totalCopies: 5,
        availableCopies: 4,
        onHandCopies: 1,
        coverImagePath: null, // 27AE60/FFFFFF?text=Мёртвые+души',
      ),
      Book(
        id: 30,
        rackId: 41, // TB Building, Shelf C, Rack 1
        title: 'Алиса в Стране чудес',
        author: 'Льюис Кэрролл',
        subject: null,
        genre: 'Сказка',
        description: 'Сказка о приключениях девочки Алисы',
        totalCopies: 6,
        availableCopies: 5,
        onHandCopies: 1,
        coverImagePath: null, // F1C40F/000000?text=Алиса',
      ),
      Book(
        id: 31,
        rackId: 41,
        title: 'Маленький принц',
        author: 'Антуан де Сент-Экзюпери',
        subject: null,
        genre: 'Философская сказка',
        description: 'Философская сказка о дружбе, любви и смысле жизни',
        totalCopies: 8,
        availableCopies: 7,
        onHandCopies: 1,
        coverImagePath: null, // 1ABC9C/FFFFFF?text=Маленький+принц',
      ),
      Book(
        id: 32,
        rackId: 42, // TB Building, Shelf C, Rack 2
        title: 'Три мушкетёра',
        author: 'Александр Дюма',
        subject: null,
        genre: 'Приключенческий роман',
        description: 'Приключенческий роман о дружбе и чести',
        totalCopies: 5,
        availableCopies: 4,
        onHandCopies: 1,
        coverImagePath: null, // E74C3C/FFFFFF?text=Мушкетёры',
      ),
      Book(
        id: 33,
        rackId: 42,
        title: 'Граф Монте-Кристо',
        author: 'Александр Дюма',
        subject: null,
        genre: 'Приключенческий роман',
        description: 'Роман о мести и справедливости',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null, // C0392B/FFFFFF?text=Монте-Кристо',
      ),
      Book(
        id: 34,
        rackId: 43, // TB Building, Shelf C, Rack 3
        title: 'Шерлок Холмс',
        author: 'Артур Конан Дойл',
        subject: null,
        genre: 'Детектив',
        description: 'Сборник детективных рассказов о знаменитом сыщике',
        totalCopies: 6,
        availableCopies: 5,
        onHandCopies: 1,
        coverImagePath: null, // 7F8C8D/FFFFFF?text=Шерлок+Холмс',
      ),
      Book(
        id: 35,
        rackId: 43,
        title: 'Дон Кихот',
        author: 'Мигель де Сервантес',
        subject: null,
        genre: 'Роман',
        description: 'Роман о рыцаре печального образа и его верном оруженосце',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null, // 95A5A6/FFFFFF?text=Дон+Кихот',
      ),
      // Дополнительные книги для заполнения стеллажей до 10 книг на каждом
      // DA A - добавляем 4 книги (уже есть 6)
      Book(
        id: 36,
        rackId: 1, // DA A, Rack 1
        title: 'Алгебра 9 класс',
        author: 'Иванов И.И.',
        subject: 'Математика',
        description: 'Учебник по алгебре для 9 класса',
        totalCopies: 3,
        availableCopies: 2,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 37,
        rackId: 2, // DA A, Rack 2
        title: 'Геометрия 9 класс',
        author: 'Петров П.П.',
        subject: 'Математика',
        description: 'Учебник по геометрии для 9 класса',
        totalCopies: 3,
        availableCopies: 2,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 38,
        rackId: 3, // DA A, Rack 3
        title: 'Математика 11 класс',
        author: 'Сидоров С.С.',
        subject: 'Математика',
        description: 'Учебник по математике для 11 класса',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 39,
        rackId: 4, // DA A, Rack 4
        title: 'Идиот',
        author: 'Фёдор Достоевский',
        subject: null,
        genre: 'Роман',
        description: 'Роман о князе Мышкине и его влиянии на окружающих',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      // DA B - добавляем 6 книг (уже есть 4)
      Book(
        id: 40,
        rackId: 6, // DA B, Rack 1
        title: 'История России',
        author: 'Историков И.И.',
        subject: 'История',
        description: 'Учебник по истории России',
        totalCopies: 5,
        availableCopies: 4,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 41,
        rackId: 7, // DA B, Rack 2
        title: 'История Средних веков',
        author: 'Средневеков С.С.',
        subject: 'История',
        description: 'Учебник по истории Средних веков',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 42,
        rackId: 8, // DA B, Rack 3
        title: 'История Нового времени',
        author: 'Нововременный Н.Н.',
        subject: 'История',
        description: 'Учебник по истории Нового времени',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 43,
        rackId: 9, // DA B, Rack 4
        title: 'Братья Карамазовы',
        author: 'Фёдор Достоевский',
        subject: null,
        genre: 'Роман',
        description: 'Философский роман о братьях Карамазовых',
        totalCopies: 5,
        availableCopies: 4,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 44,
        rackId: 10, // DA B, Rack 5
        title: 'Бесы',
        author: 'Фёдор Достоевский',
        subject: null,
        genre: 'Роман',
        description: 'Роман о революционном движении в России',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 45,
        rackId: 6, // DA B, Rack 1 (дополнительная книга)
        title: 'Белые ночи',
        author: 'Фёдор Достоевский',
        subject: null,
        genre: 'Повесть',
        description: 'Сентиментальный роман о встрече в Петербурге',
        totalCopies: 6,
        availableCopies: 5,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      // DA C - добавляем 6 книг (уже есть 4)
      Book(
        id: 46,
        rackId: 11, // DA C, Rack 1
        title: 'Физика 9 класс',
        author: 'Физиков Ф.Ф.',
        subject: 'Физика',
        description: 'Учебник по физике для 9 класса',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 47,
        rackId: 12, // DA C, Rack 2
        title: 'Физика 11 класс',
        author: 'Физиков Ф.Ф.',
        subject: 'Физика',
        description: 'Учебник по физике для 11 класса',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 48,
        rackId: 13, // DA C, Rack 3
        title: 'Химия 9 класс',
        author: 'Химиков Х.Х.',
        subject: 'Химия',
        description: 'Учебник по химии для 9 класса',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 49,
        rackId: 14, // DA C, Rack 4
        title: 'Химия 11 класс',
        author: 'Химиков Х.Х.',
        subject: 'Химия',
        description: 'Учебник по химии для 11 класса',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 50,
        rackId: 16, // DA C, Rack 5
        title: 'Гарри Поттер и Тайная комната',
        author: 'Дж. К. Роулинг',
        subject: null,
        genre: 'Фэнтези',
        description: 'Вторая книга серии о юном волшебнике',
        totalCopies: 6,
        availableCopies: 5,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 51,
        rackId: 46, // DA C, Rack 6
        title: 'Гарри Поттер и узник Азкабана',
        author: 'Дж. К. Роулинг',
        subject: null,
        genre: 'Фэнтези',
        description: 'Третья книга серии о юном волшебнике',
        totalCopies: 5,
        availableCopies: 4,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      // DA D - добавляем 6 книг (уже есть 4)
      Book(
        id: 52,
        rackId: 61, // DA D, Rack 1
        title: 'Биология 9 класс',
        author: 'Биологов Б.Б.',
        subject: 'Биология',
        description: 'Учебник по биологии для 9 класса',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 53,
        rackId: 62, // DA D, Rack 2
        title: 'Биология 11 класс',
        author: 'Биологов Б.Б.',
        subject: 'Биология',
        description: 'Учебник по биологии для 11 класса',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 54,
        rackId: 63, // DA D, Rack 3
        title: 'География мира',
        author: 'Географов Г.Г.',
        subject: 'География',
        description: 'Учебник по географии мира',
        totalCopies: 5,
        availableCopies: 4,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 55,
        rackId: 64, // DA D, Rack 4
        title: 'Экономическая география',
        author: 'Экономгеограф Э.Э.',
        subject: 'География',
        description: 'Учебник по экономической географии',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 56,
        rackId: 26, // DA D, Rack 5
        title: 'Хоббит',
        author: 'Дж. Р. Р. Толкин',
        subject: null,
        genre: 'Фэнтези',
        description: 'Повесть о приключениях хоббита Бильбо Бэггинса',
        totalCopies: 5,
        availableCopies: 4,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 57,
        rackId: 66, // DA D, Rack 6
        title: 'Сильмариллион',
        author: 'Дж. Р. Р. Толкин',
        subject: null,
        genre: 'Фэнтези',
        description: 'Мифология Средиземья',
        totalCopies: 3,
        availableCopies: 2,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      // DA E - добавляем 6 книг (уже есть 4)
      Book(
        id: 58,
        rackId: 81, // DA E, Rack 1
        title: 'Казахский язык 9 класс',
        author: 'Казахский К.К.',
        subject: 'Казахский язык',
        description: 'Учебник по казахскому языку для 9 класса',
        totalCopies: 5,
        availableCopies: 4,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 59,
        rackId: 82, // DA E, Rack 2
        title: 'Русский язык 9 класс',
        author: 'Русский Р.Р.',
        subject: 'Русский язык',
        description: 'Учебник по русскому языку для 9 класса',
        totalCopies: 5,
        availableCopies: 4,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 60,
        rackId: 83, // DA E, Rack 3
        title: 'Английский язык 9 класс',
        author: 'English E.E.',
        subject: 'Английский язык',
        description: 'Учебник по английскому языку для 9 класса',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 61,
        rackId: 84, // DA E, Rack 4
        title: 'Немецкий язык 10 класс',
        author: 'Адольф Г.',
        subject: 'Немецкий язык',
        description: 'Учебник по немецкому языку',
        totalCopies: 3,
        availableCopies: 2,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 62,
        rackId: 85, // DA E, Rack 5
        title: 'Французский язык 10 класс',
        author: 'Français F.F.',
        subject: 'Французский язык',
        description: 'Учебник по французскому языку',
        totalCopies: 3,
        availableCopies: 2,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 63,
        rackId: 86, // DA E, Rack 6
        title: 'Капитанская дочка',
        author: 'Александр Пушкин',
        subject: null,
        genre: 'Исторический роман',
        description: 'Исторический роман о Пугачёвском восстании',
        totalCopies: 5,
        availableCopies: 4,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      // DA F - добавляем 6 книг (уже есть 4)
      Book(
        id: 64,
        rackId: 101, // DA F, Rack 1
        title: 'Информатика 9 класс',
        author: 'Информатик И.И.',
        subject: 'Информатика',
        description: 'Учебник по информатике для 9 класса',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 65,
        rackId: 102, // DA F, Rack 2
        title: 'Информатика 11 класс',
        author: 'Информатик И.И.',
        subject: 'Информатика',
        description: 'Учебник по информатике для 11 класса',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 66,
        rackId: 103, // DA F, Rack 3
        title: 'Программирование на Python',
        author: 'Программист П.П.',
        subject: 'Информатика',
        description: 'Учебник по программированию на Python',
        totalCopies: 5,
        availableCopies: 4,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 67,
        rackId: 104, // DA F, Rack 4
        title: 'Базы данных',
        author: 'Базаданных Б.Б.',
        subject: 'Информатика',
        description: 'Учебник по базам данных',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 68,
        rackId: 105, // DA F, Rack 5
        title: 'Ревизор',
        author: 'Николай Гоголь',
        subject: null,
        genre: 'Комедия',
        description: 'Комедия о чиновниках и взяточничестве',
        totalCopies: 6,
        availableCopies: 5,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 69,
        rackId: 106, // DA F, Rack 6
        title: 'Тарас Бульба',
        author: 'Николай Гоголь',
        subject: null,
        genre: 'Повесть',
        description: 'Повесть о казаках и их борьбе',
        totalCopies: 5,
        availableCopies: 4,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      // TB A - добавляем 8 книг (уже есть 2)
      Book(
        id: 70,
        rackId: 121, // TB A, Rack 1
        title: 'Литература 9 класс',
        author: 'Литературовед Л.Л.',
        subject: 'Литература',
        description: 'Учебник по литературе для 9 класса',
        totalCopies: 5,
        availableCopies: 4,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 71,
        rackId: 122, // TB A, Rack 2
        title: 'Литература 11 класс',
        author: 'Литературовед Л.Л.',
        subject: 'Литература',
        description: 'Учебник по литературе для 11 класса',
        totalCopies: 5,
        availableCopies: 4,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 72,
        rackId: 123, // TB A, Rack 3
        title: 'Русская литература XIX века',
        author: 'Классик К.К.',
        subject: 'Литература',
        description: 'Хрестоматия по русской литературе XIX века',
        totalCopies: 6,
        availableCopies: 5,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 73,
        rackId: 124, // TB A, Rack 4
        title: 'Русская литература XX века',
        author: 'Современник С.С.',
        subject: 'Литература',
        description: 'Хрестоматия по русской литературе XX века',
        totalCopies: 5,
        availableCopies: 4,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 74,
        rackId: 126, // TB A, Rack 6
        title: 'Обломов',
        author: 'Иван Гончаров',
        subject: null,
        genre: 'Роман',
        description: 'Роман о русском помещике Обломове',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 75,
        rackId: 127, // TB A, Rack 7
        title: 'Гроза',
        author: 'Александр Островский',
        subject: null,
        genre: 'Драма',
        description: 'Драма о жизни в провинциальном городе',
        totalCopies: 5,
        availableCopies: 4,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 76,
        rackId: 128, // TB A, Rack 8
        title: 'Горе от ума',
        author: 'Александр Грибоедов',
        subject: null,
        genre: 'Комедия',
        description: 'Комедия в стихах о московском обществе',
        totalCopies: 6,
        availableCopies: 5,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 77,
        rackId: 129, // TB A, Rack 9
        title: 'Недоросль',
        author: 'Денис Фонвизин',
        subject: null,
        genre: 'Комедия',
        description: 'Комедия о воспитании и образовании',
        totalCopies: 5,
        availableCopies: 4,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      // TB B - добавляем 9 книг (уже есть 1)
      Book(
        id: 78,
        rackId: 141, // TB B, Rack 1
        title: 'Право 9 класс',
        author: 'Правовед П.П.',
        subject: 'Право',
        description: 'Учебник по праву для 9 класса',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 79,
        rackId: 142, // TB B, Rack 2
        title: 'Право 11 класс',
        author: 'Правовед П.П.',
        subject: 'Право',
        description: 'Учебник по праву для 11 класса',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 80,
        rackId: 143, // TB B, Rack 3
        title: 'Конституционное право',
        author: 'Конституционер К.К.',
        subject: 'Право',
        description: 'Учебник по конституционному праву',
        totalCopies: 3,
        availableCopies: 2,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 81,
        rackId: 144, // TB B, Rack 4
        title: 'Гражданское право',
        author: 'Гражданин Г.Г.',
        subject: 'Право',
        description: 'Учебник по гражданскому праву',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 82,
        rackId: 146, // TB B, Rack 6
        title: 'Уголовное право',
        author: 'Уголовник У.У.',
        subject: 'Право',
        description: 'Учебник по уголовному праву',
        totalCopies: 3,
        availableCopies: 2,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 83,
        rackId: 147, // TB B, Rack 7
        title: 'Трудовое право',
        author: 'Трудовик Т.Т.',
        subject: 'Право',
        description: 'Учебник по трудовому праву',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 84,
        rackId: 148, // TB B, Rack 8
        title: 'Семейное право',
        author: 'Семейник С.С.',
        subject: 'Право',
        description: 'Учебник по семейному праву',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 85,
        rackId: 149, // TB B, Rack 9
        title: 'Административное право',
        author: 'Администратор А.А.',
        subject: 'Право',
        description: 'Учебник по административному праву',
        totalCopies: 3,
        availableCopies: 2,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 86,
        rackId: 150, // TB B, Rack 10
        title: 'Экологическое право',
        author: 'Эколог Э.Э.',
        subject: 'Право',
        description: 'Учебник по экологическому праву',
        totalCopies: 3,
        availableCopies: 2,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      // TB C - добавляем 4 книги (уже есть 6)
      Book(
        id: 87,
        rackId: 161, // TB C, Rack 1
        title: 'Алиса в Зазеркалье',
        author: 'Льюис Кэрролл',
        subject: null,
        genre: 'Сказка',
        description: 'Продолжение приключений Алисы',
        totalCopies: 5,
        availableCopies: 4,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 88,
        rackId: 162, // TB C, Rack 2
        title: 'Планета людей',
        author: 'Антуан де Сент-Экзюпери',
        subject: null,
        genre: 'Автобиография',
        description: 'Автобиографическая повесть о лётчиках',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 89,
        rackId: 163, // TB C, Rack 3
        title: 'Двадцать лет спустя',
        author: 'Александр Дюма',
        subject: null,
        genre: 'Приключенческий роман',
        description: 'Продолжение приключений мушкетёров',
        totalCopies: 4,
        availableCopies: 3,
        onHandCopies: 1,
        coverImagePath: null,
      ),
      Book(
        id: 90,
        rackId: 164, // TB C, Rack 4
        title: 'Виконт де Бражелон',
        author: 'Александр Дюма',
        subject: null,
        genre: 'Приключенческий роман',
        description: 'Завершение трилогии о мушкетёрах',
        totalCopies: 3,
        availableCopies: 2,
        onHandCopies: 1,
        coverImagePath: null,
      ),
    ];
    await _saveList('books', books, (b) => b.toMap());

    // Initialize empty loans list
    await _saveList('loans', <Loan>[], (l) => l.toMap());

    await _prefs!.setBool('db_initialized', true);
  }

  Future<void> _createDB(Database db, int version) async {
    // Buildings table
    await db.execute('''
      CREATE TABLE buildings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT NOT NULL UNIQUE
      )
    ''');

    // Shelves table
    await db.execute('''
      CREATE TABLE shelves (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        building_id INTEGER NOT NULL,
        letter TEXT NOT NULL,
        FOREIGN KEY (building_id) REFERENCES buildings (id)
      )
    ''');

    // Racks table
    await db.execute('''
      CREATE TABLE racks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shelf_id INTEGER NOT NULL,
        number INTEGER NOT NULL,
        FOREIGN KEY (shelf_id) REFERENCES shelves (id)
      )
    ''');

    // Books table
    await db.execute('''
      CREATE TABLE books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rack_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        subject TEXT,
        genre TEXT,
        description TEXT,
        total_copies INTEGER NOT NULL DEFAULT 1,
        available_copies INTEGER NOT NULL DEFAULT 1,
        on_hand_copies INTEGER NOT NULL DEFAULT 0,
        cover_image_path TEXT,
        FOREIGN KEY (rack_id) REFERENCES racks (id)
      )
    ''');

    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT,
        role TEXT NOT NULL,
        email TEXT,
        phone TEXT
      )
    ''');

    // Favorites table
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        user_id TEXT NOT NULL,
        FOREIGN KEY (book_id) REFERENCES books (id)
      )
    ''');

    // Loans table
    await db.execute('''
      CREATE TABLE loans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        borrower_name TEXT NOT NULL,
        book_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        issue_date TEXT NOT NULL,
        return_date TEXT,
        librarian_id INTEGER,
        FOREIGN KEY (book_id) REFERENCES books (id),
        FOREIGN KEY (librarian_id) REFERENCES users (id)
      )
    ''');

    // Insert default buildings
    await db.insert('buildings', Building(name: 'Домалак Ана', code: 'DA').toMap());
    await db.insert('buildings', Building(name: 'Толе Би', code: 'TB').toMap());

    // Insert default librarian
    await db.insert('users', User(
      username: 'admin',
      password: 'admin123',
      role: UserRole.librarian,
    ).toMap());

    // Initialize sample data
    await _initializeSampleData(db);
  }

  Future<void> _initializeSampleData(Database db) async {
    final buildingMaps = await db.query('buildings');
    if (buildingMaps.isEmpty) return;

    final daBuildingMap = buildingMaps.firstWhere((b) => b['code'] == 'DA');
    final daBuildingId = daBuildingMap['id'] as int;
    final tbBuildingMap = buildingMaps.firstWhere((b) => b['code'] == 'TB');
    final tbBuildingId = tbBuildingMap['id'] as int;

    // Create shelves for DA building
    final shelvesDA = ['A', 'B', 'C', 'D', 'E', 'F'];
    final shelfIds = <int>[];
    for (var letter in shelvesDA) {
      final shelfId = await db.insert('shelves', {'building_id': daBuildingId, 'letter': letter});
      shelfIds.add(shelfId);
      
      // Create racks for each shelf (1-5)
      for (int i = 1; i <= 5; i++) {
        await db.insert('racks', {'shelf_id': shelfId, 'number': i});
      }
    }

    // Create shelves for TB building
    final shelvesTB = ['A', 'B', 'C'];
    final shelfIdsTB = <int>[];
    for (var letter in shelvesTB) {
      final shelfId = await db.insert('shelves', {'building_id': tbBuildingId, 'letter': letter});
      shelfIdsTB.add(shelfId);
      
      // Create racks for each shelf (1-5)
      for (int i = 1; i <= 5; i++) {
        await db.insert('racks', {'shelf_id': shelfId, 'number': i});
      }
    }

    // Get rack IDs for books (теперь полок только 5, используем номера 1-5)
    final rackA1 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[0], 1]);
    final rackA2 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[0], 2]);
    final rackA3 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[0], 3]);
    final rackA4 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[0], 4]);
    final rackA5 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[0], 5]);
    final rackB1 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[1], 1]);
    final rackB2 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[1], 2]);
    final rackB3 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[1], 3]);
    final rackB4 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[1], 4]);
    final rackB5 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[1], 5]);
    final rackC1 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[2], 1]);
    final rackC2 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[2], 2]);
    final rackC3 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[2], 3]);
    final rackC4 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[2], 4]);
    final rackC5 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[2], 5]);
    final rackD1 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[3], 1]);
    final rackD2 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[3], 2]);
    final rackD3 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[3], 3]);
    final rackD4 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[3], 4]);
    final rackD5 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[3], 5]);
    final rackE1 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[4], 1]);
    final rackE2 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[4], 2]);
    final rackE3 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[4], 3]);
    final rackE4 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[4], 4]);
    final rackE5 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[4], 5]);
    final rackF1 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[5], 1]);
    final rackF2 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[5], 2]);
    final rackF3 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[5], 3]);
    final rackF4 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[5], 4]);
    final rackF5 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIds[5], 5]);
    final rackTBA1 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIdsTB[0], 1]);
    final rackTBA2 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIdsTB[0], 2]);
    final rackTBA3 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIdsTB[0], 3]);
    final rackTBA4 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIdsTB[0], 4]);
    final rackTBA5 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIdsTB[0], 5]);
    final rackTBB1 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIdsTB[1], 1]);
    final rackTBB2 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIdsTB[1], 2]);
    final rackTBB3 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIdsTB[1], 3]);
    final rackTBB4 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIdsTB[1], 4]);
    final rackTBB5 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIdsTB[1], 5]);
    final rackTBC1 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIdsTB[2], 1]);
    final rackTBC2 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIdsTB[2], 2]);
    final rackTBC3 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIdsTB[2], 3]);
    final rackTBC4 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIdsTB[2], 4]);
    final rackTBC5 = await db.query('racks', where: 'shelf_id = ? AND number = ?', whereArgs: [shelfIdsTB[2], 5]);

    // Insert books
    final books = [
      {
        'rack_id': rackA1.first['id'],
        'title': 'Учебник «Алгебра 10 класс»',
        'author': 'Иванов И.И.',
        'subject': 'Математика',
        'description': 'Учебник по алгебре для 10 класса',
        'total_copies': 2,
        'available_copies': 1,
        'on_hand_copies': 1,
      },
      {
        'rack_id': rackA1.first['id'],
        'title': 'Геометрия 10-11 класс',
        'author': 'Петров П.П.',
        'subject': 'Математика',
        'description': 'Учебник по геометрии для старших классов',
        'total_copies': 3,
        'available_copies': 2,
        'on_hand_copies': 1,
      },
      {
        'rack_id': rackB1.first['id'],
        'title': 'История Казахстана',
        'author': 'Сидоров С.С.',
        'subject': 'История',
        'description': 'Учебник по истории Казахстана',
        'total_copies': 5,
        'available_copies': 4,
        'on_hand_copies': 1,
      },
      {
        'rack_id': rackB1.first['id'],
        'title': 'Всемирная история',
        'author': 'Кузнецов К.К.',
        'subject': 'История',
        'description': 'Учебник по всемирной истории',
        'total_copies': 4,
        'available_copies': 3,
        'on_hand_copies': 1,
      },
      {
        'rack_id': rackC1.first['id'],
        'title': 'Физика 10 класс',
        'author': 'Новikov Н.Н.',
        'subject': 'Физика',
        'description': 'Учебник по физике для 10 класса',
        'total_copies': 3,
        'available_copies': 2,
        'on_hand_copies': 1,
      },
      {
        'rack_id': rackC1.first['id'],
        'title': 'Химия 10 класс',
        'author': 'Морозов М.М.',
        'subject': 'Химия',
        'description': 'Учебник по химии для 10 класса',
        'total_copies': 4,
        'available_copies': 3,
        'on_hand_copies': 1,
      },
      {
        'rack_id': rackD1.first['id'],
        'title': 'Биология 10 класс',
        'author': 'Волков В.В.',
        'subject': 'Биология',
        'description': 'Учебник по биологии для 10 класса',
        'total_copies': 3,
        'available_copies': 2,
        'on_hand_copies': 1,
      },
      {
        'rack_id': rackD1.first['id'],
        'title': 'География Казахстана',
        'author': 'Орлов О.О.',
        'subject': 'География',
        'description': 'Учебник по географии Казахстана',
        'total_copies': 5,
        'available_copies': 4,
        'on_hand_copies': 1,
      },
      {
        'rack_id': rackE1.first['id'],
        'title': 'Казахский язык 10 класс',
        'author': 'Абдуллаев А.А.',
        'subject': 'Казахский язык',
        'description': 'Учебник по казахскому языку',
        'total_copies': 6,
        'available_copies': 5,
        'on_hand_copies': 1,
      },
      {
        'rack_id': rackE1.first['id'],
        'title': 'Русский язык 10 класс',
        'author': 'Смирнова С.С.',
        'subject': 'Русский язык',
        'description': 'Учебник по русскому языку',
        'total_copies': 5,
        'available_copies': 4,
        'on_hand_copies': 1,
      },
      {
        'rack_id': rackF1.first['id'],
        'title': 'Английский язык 10 класс',
        'author': 'Brown J.',
        'subject': 'Английский язык',
        'description': 'Учебник по английскому языку',
        'total_copies': 4,
        'available_copies': 3,
        'on_hand_copies': 1,
      },
      {
        'rack_id': rackF1.first['id'],
        'title': 'Информатика 10 класс',
        'author': 'Техников Т.Т.',
        'subject': 'Информатика',
        'description': 'Учебник по информатике',
        'total_copies': 3,
        'available_copies': 2,
        'on_hand_copies': 1,
      },
      {
        'rack_id': rackTBA1.first['id'],
        'title': 'Литература Казахстана',
        'author': 'Писатель П.П.',
        'subject': 'Литература',
        'description': 'Учебник по казахской литературе',
        'total_copies': 4,
        'available_copies': 3,
        'on_hand_copies': 1,
      },
      {
        'rack_id': rackTBA1.first['id'],
        'title': 'Мировая литература',
        'author': 'Классик К.К.',
        'subject': 'Литература',
        'description': 'Учебник по мировой литературе',
        'total_copies': 5,
        'available_copies': 4,
        'on_hand_copies': 1,
      },
      {
        'rack_id': rackTBB1.first['id'],
        'title': 'Основы права',
        'author': 'Юристов Ю.Ю.',
        'subject': 'Право',
        'description': 'Учебник по основам права',
        'total_copies': 3,
        'available_copies': 2,
        'on_hand_copies': 1,
      },
      // Художественная литература
      {
        'rack_id': await _getRackId(db, shelfIds[0], 2), // DA A, Rack 2
        'title': 'Абай жолы',
        'author': 'Мухтар Ауэзов',
        'subject': null,
        'description': 'Роман-эпопея о жизни и творчестве Абая Кунанбаева',
        'total_copies': 5,
        'available_copies': 4,
        'on_hand_copies': 1,
      },
      {
        'rack_id': await _getRackId(db, shelfIds[0], 10),
        'title': 'Путь Абая',
        'author': 'Мухтар Ауэзов',
        'subject': null,
        'description': 'Эпопея о великом казахском поэте и мыслителе',
        'total_copies': 4,
        'available_copies': 3,
        'on_hand_copies': 1,
      },
      {
        'rack_id': await _getRackId(db, shelfIds[0], 3), // DA A, Rack 3
        'title': 'Война и мир',
        'author': 'Лев Толстой',
        'subject': null,
        'description': 'Роман-эпопея о русском обществе эпохи войн против Наполеона',
        'total_copies': 3,
        'available_copies': 2,
        'on_hand_copies': 1,
      },
      {
        'rack_id': await _getRackId(db, shelfIds[0], 20),
        'title': 'Преступление и наказание',
        'author': 'Фёдор Достоевский',
        'subject': null,
        'description': 'Психологический роман о преступлении и его последствиях',
        'total_copies': 4,
        'available_copies': 3,
        'on_hand_copies': 1,
      },
      {
        'rack_id': await _getRackId(db, shelfIds[1], 2), // DA B, Rack 2
        'title': 'Мастер и Маргарита',
        'author': 'Михаил Булгаков',
        'subject': null,
        'description': 'Философский роман о добре и зле, любви и предательстве',
        'total_copies': 5,
        'available_copies': 4,
        'on_hand_copies': 1,
      },
      {
        'rack_id': await _getRackId(db, shelfIds[1], 10),
        'title': 'Евгений Онегин',
        'author': 'Александр Пушкин',
        'subject': null,
        'description': 'Роман в стихах о любви и жизни русского дворянства',
        'total_copies': 6,
        'available_copies': 5,
        'on_hand_copies': 1,
      },
      {
        'rack_id': await _getRackId(db, shelfIds[2], 2), // DA C, Rack 2
        'title': 'Гарри Поттер и философский камень',
        'author': 'Дж. К. Роулинг',
        'subject': null,
        'description': 'Первая книга серии о юном волшебнике',
        'total_copies': 7,
        'available_copies': 6,
        'on_hand_copies': 1,
      },
      {
        'rack_id': await _getRackId(db, shelfIds[2], 10),
        'title': 'Властелин колец',
        'author': 'Дж. Р. Р. Толкин',
        'subject': null,
        'description': 'Эпическая фантастическая трилогия о Средиземье',
        'total_copies': 4,
        'available_copies': 3,
        'on_hand_copies': 1,
      },
      {
        'rack_id': await _getRackId(db, shelfIds[3], 2), // DA D, Rack 2
        'title': '1984',
        'author': 'Джордж Оруэлл',
        'subject': null,
        'description': 'Антиутопический роман о тоталитарном обществе',
        'total_copies': 5,
        'available_copies': 4,
        'on_hand_copies': 1,
      },
      {
        'rack_id': await _getRackId(db, shelfIds[3], 10),
        'title': 'Скотный двор',
        'author': 'Джордж Оруэлл',
        'subject': null,
        'description': 'Аллегорическая повесть о революции и власти',
        'total_copies': 4,
        'available_copies': 3,
        'on_hand_copies': 1,
      },
      {
        'rack_id': await _getRackId(db, shelfIds[4], 2), // DA E, Rack 2
        'title': 'Анна Каренина',
        'author': 'Лев Толстой',
        'subject': null,
        'description': 'Роман о трагической любви и общественных нравах',
        'total_copies': 4,
        'available_copies': 3,
        'on_hand_copies': 1,
      },
      {
        'rack_id': await _getRackId(db, shelfIds[4], 10),
        'title': 'Отцы и дети',
        'author': 'Иван Тургенев',
        'subject': null,
        'description': 'Роман о конфликте поколений в России XIX века',
        'total_copies': 5,
        'available_copies': 4,
        'on_hand_copies': 1,
      },
      {
        'rack_id': await _getRackId(db, shelfIds[5], 10), // DA F, Rack 10
        'title': 'Герой нашего времени',
        'author': 'Михаил Лермонтов',
        'subject': null,
        'description': 'Психологический роман о русском офицере',
        'total_copies': 4,
        'available_copies': 3,
        'on_hand_copies': 1,
      },
      {
        'rack_id': await _getRackId(db, shelfIds[5], 10),
        'title': 'Мёртвые души',
        'author': 'Николай Гоголь',
        'subject': null,
        'description': 'Поэма о похождениях Чичикова и русском обществе',
        'total_copies': 5,
        'available_copies': 4,
        'on_hand_copies': 1,
      },
      {
        'rack_id': await _getRackId(db, shelfIdsTB[2], 5), // TB C, Rack 5
        'title': 'Алиса в Стране чудес',
        'author': 'Льюис Кэрролл',
        'subject': null,
        'description': 'Сказка о приключениях девочки Алисы',
        'total_copies': 6,
        'available_copies': 5,
        'on_hand_copies': 1,
      },
      {
        'rack_id': await _getRackId(db, shelfIdsTB[2], 5),
        'title': 'Маленький принц',
        'author': 'Антуан де Сент-Экзюпери',
        'subject': null,
        'description': 'Философская сказка о дружбе, любви и смысле жизни',
        'total_copies': 8,
        'available_copies': 7,
        'on_hand_copies': 1,
      },
      {
        'rack_id': await _getRackId(db, shelfIdsTB[2], 15), // TB C, Rack 15
        'title': 'Три мушкетёра',
        'author': 'Александр Дюма',
        'subject': null,
        'description': 'Приключенческий роман о дружбе и чести',
        'total_copies': 5,
        'available_copies': 4,
        'on_hand_copies': 1,
      },
      {
        'rack_id': await _getRackId(db, shelfIdsTB[2], 15),
        'title': 'Граф Монте-Кристо',
        'author': 'Александр Дюма',
        'subject': null,
        'description': 'Роман о мести и справедливости',
        'total_copies': 4,
        'available_copies': 3,
        'on_hand_copies': 1,
      },
      {
        'rack_id': await _getRackId(db, shelfIdsTB[2], 20), // TB C, Rack 20
        'title': 'Шерлок Холмс',
        'author': 'Артур Конан Дойл',
        'subject': null,
        'description': 'Сборник детективных рассказов о знаменитом сыщике',
        'total_copies': 6,
        'available_copies': 5,
        'on_hand_copies': 1,
      },
      {
        'rack_id': await _getRackId(db, shelfIdsTB[2], 20),
        'title': 'Дон Кихот',
        'author': 'Мигель де Сервантес',
        'subject': null,
        'description': 'Роман о рыцаре печального образа и его верном оруженосце',
        'total_copies': 4,
        'available_copies': 3,
        'on_hand_copies': 1,
      },
    ];

    for (var book in books) {
      await db.insert('books', book);
    }
  }

  Future<int> _getRackId(Database db, int shelfId, int rackNumber) async {
    final racks = await db.query(
      'racks',
      where: 'shelf_id = ? AND number = ?',
      whereArgs: [shelfId, rackNumber],
    );
    return racks.first['id'] as int;
  }

  // Building methods
  Future<int> insertBuilding(Building building) async {
    if (kIsWeb) {
      final list = _getList('buildings', (map) => Building.fromMap(map));
      final maxId = list.isEmpty ? 0 : (list.map((e) => e.id ?? 0).reduce((a, b) => (a ?? 0) > (b ?? 0) ? a : b) ?? 0);
      final newBuilding = Building(id: (maxId + 1), name: building.name, code: building.code);
      list.add(newBuilding);
      await _saveList('buildings', list, (b) => b.toMap());
      return newBuilding.id!;
    }
    final db = await database;
    return await db.insert('buildings', building.toMap());
  }

  Future<List<Building>> getAllBuildings() async {
    if (kIsWeb) {
      return _getList('buildings', (map) => Building.fromMap(map));
    }
    final db = await database;
    final maps = await db.query('buildings');
    return maps.map((map) => Building.fromMap(map)).toList();
  }

  // Shelf methods
  Future<int> insertShelf(Shelf shelf) async {
    if (kIsWeb) {
      final list = _getList('shelves', (map) => Shelf.fromMap(map));
      final maxId = list.isEmpty ? 0 : (list.map((e) => e.id ?? 0).reduce((a, b) => (a ?? 0) > (b ?? 0) ? a : b) ?? 0);
      final newShelf = Shelf(id: (maxId + 1), buildingId: shelf.buildingId, letter: shelf.letter);
      list.add(newShelf);
      await _saveList('shelves', list, (s) => s.toMap());
      return newShelf.id!;
    }
    final db = await database;
    return await db.insert('shelves', shelf.toMap());
  }

  Future<List<Shelf>> getShelvesByBuilding(int buildingId) async {
    if (kIsWeb) {
      final all = _getList('shelves', (map) => Shelf.fromMap(map));
      return all.where((s) => s.buildingId == buildingId).toList();
    }
    final db = await database;
    final maps = await db.query(
      'shelves',
      where: 'building_id = ?',
      whereArgs: [buildingId],
    );
    return maps.map((map) => Shelf.fromMap(map)).toList();
  }

  // Rack methods
  Future<int> insertRack(Rack rack) async {
    if (kIsWeb) {
      final list = _getList('racks', (map) => Rack.fromMap(map));
      final maxId = list.isEmpty ? 0 : (list.map((e) => e.id ?? 0).reduce((a, b) => (a ?? 0) > (b ?? 0) ? a : b) ?? 0);
      final newRack = Rack(id: (maxId + 1), shelfId: rack.shelfId, number: rack.number);
      list.add(newRack);
      await _saveList('racks', list, (r) => r.toMap());
      return newRack.id!;
    }
    final db = await database;
    return await db.insert('racks', rack.toMap());
  }

  Future<List<Rack>> getRacksByShelf(int shelfId) async {
    if (kIsWeb) {
      final all = _getList('racks', (map) => Rack.fromMap(map));
      return all.where((r) => r.shelfId == shelfId).toList();
    }
    final db = await database;
    final maps = await db.query(
      'racks',
      where: 'shelf_id = ?',
      whereArgs: [shelfId],
    );
    return maps.map((map) => Rack.fromMap(map)).toList();
  }

  // Book methods
  Future<int> insertBook(Book book) async {
    if (kIsWeb) {
      final list = _getList('books', (map) => Book.fromMap(map));
      final maxId = list.isEmpty ? 0 : (list.map((e) => e.id ?? 0).reduce((a, b) => (a ?? 0) > (b ?? 0) ? a : b) ?? 0);
      final newBook = Book(
        id: (maxId + 1),
        rackId: book.rackId,
        title: book.title,
        author: book.author,
        subject: book.subject,
        description: book.description,
        totalCopies: book.totalCopies,
        availableCopies: book.availableCopies,
        onHandCopies: book.onHandCopies,
        coverImagePath: book.coverImagePath,
      );
      list.add(newBook);
      await _saveList('books', list, (b) => b.toMap());
      return newBook.id!;
    }
    final db = await database;
    return await db.insert('books', book.toMap());
  }

  Future<List<Book>> getAllBooks() async {
    try {
      if (kIsWeb) {
        final list = _getList('books', (map) => Book.fromMap(map));
        return list;
      }
      final db = await database;
      final maps = await db.query('books');
      return maps.map((map) => Book.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Book>> searchBooks(String query) async {
    final allBooks = await getAllBooks();
    final lowerQuery = query.toLowerCase();
    return allBooks.where((book) {
      return book.title.toLowerCase().contains(lowerQuery) ||
          book.author.toLowerCase().contains(lowerQuery) ||
          (book.subject?.toLowerCase().contains(lowerQuery) ?? false) ||
          (book.genre?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  Future<List<Book>> searchBooksByCode(String code) async {
    if (code.length < 4) return [];
    
    final buildingCode = code.substring(0, 2);
    final shelfLetter = code.substring(3, 4);
    final rackNumber = int.tryParse(code.substring(4)) ?? 0;

    final buildings = await getAllBuildings();
    final building = buildings.firstWhere(
      (b) => b.code == buildingCode,
      orElse: () => Building(name: '', code: ''),
    );
    if (building.id == null) return [];

    final shelves = await getShelvesByBuilding(building.id!);
    final shelf = shelves.firstWhere(
      (s) => s.letter == shelfLetter,
      orElse: () => Shelf(buildingId: 0, letter: ''),
    );
    if (shelf.id == null) return [];

    final racks = await getRacksByShelf(shelf.id!);
    final rack = racks.firstWhere(
      (r) => r.number == rackNumber,
      orElse: () => Rack(shelfId: 0, number: 0),
    );
    if (rack.id == null) return [];

    final allBooks = await getAllBooks();
    return allBooks.where((book) => book.rackId == rack.id).toList();
  }

  Future<Book?> getBookById(int id) async {
    final allBooks = await getAllBooks();
    try {
      return allBooks.firstWhere((book) => book.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> updateBook(Book book) async {
    if (kIsWeb) {
      final list = _getList('books', (map) => Book.fromMap(map));
      final index = list.indexWhere((b) => b.id == book.id);
      if (index != -1) {
        list[index] = book;
        await _saveList('books', list, (b) => b.toMap());
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.update(
      'books',
      book.toMap(),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  Future<int> deleteBook(int id) async {
    if (kIsWeb) {
      final list = _getList('books', (map) => Book.fromMap(map));
      list.removeWhere((b) => b.id == id);
      await _saveList('books', list, (b) => b.toMap());
      return 1;
    }
    final db = await database;
    return await db.delete(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Book>> getPopularBooks() async {
    try {
      final allBooks = await getAllBooks();
      if (allBooks.isEmpty) return [];
      allBooks.sort((a, b) => b.onHandCopies.compareTo(a.onHandCopies));
      return allBooks.take(10).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Book>> getBooksBySubject(String subject) async {
    final allBooks = await getAllBooks();
    return allBooks.where((book) => book.subject == subject).toList();
  }

  Future<List<Book>> getBooksByAuthor(String author) async {
    final allBooks = await getAllBooks();
    return allBooks.where((book) => book.author == author).toList();
  }

  Future<void> markBookIssue(int bookId) async {
    final book = await getBookById(bookId);
    if (book != null && book.availableCopies > 0) {
      await updateBook(book.copyWith(
        availableCopies: book.availableCopies - 1,
        onHandCopies: book.onHandCopies + 1,
      ));
    }
  }

  Future<void> markBookReturn(int bookId) async {
    final book = await getBookById(bookId);
    if (book != null && book.onHandCopies > 0) {
      await updateBook(book.copyWith(
        availableCopies: book.availableCopies + 1,
        onHandCopies: book.onHandCopies - 1,
      ));
    }
  }

  // User methods
  Future<int> insertUser(User user) async {
    if (kIsWeb) {
      final list = _getList('users', (map) => User.fromMap(map));
      final maxId = list.isEmpty ? 0 : (list.map((e) => e.id ?? 0).reduce((a, b) => (a ?? 0) > (b ?? 0) ? a : b) ?? 0);
      final newUser = User(
        id: (maxId + 1),
        username: user.username,
        password: user.password,
        role: user.role,
        email: user.email,
        phone: user.phone,
      );
      list.add(newUser);
      await _saveList('users', list, (u) => u.toMap());
      return newUser.id!;
    }
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserByUsername(String username) async {
    if (kIsWeb) {
      final list = _getList('users', (map) => User.fromMap(map));
      try {
        return list.firstWhere((u) => u.username == username);
      } catch (e) {
        return null;
      }
    }
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User?> authenticateLibrarian(String username, String password) async {
    final user = await getUserByUsername(username);
    if (user != null && user.role == UserRole.librarian && user.password == password) {
      return user;
    }
    return null;
  }

  // Favorite methods
  Future<int> addFavorite(Favorite favorite) async {
    if (kIsWeb) {
      final list = _getList('favorites', (map) => Favorite.fromMap(map));
      if (list.any((f) => f.bookId == favorite.bookId && f.userId == favorite.userId)) {
        return 0;
      }
      final maxId = list.isEmpty ? 0 : (list.map((e) => e.id ?? 0).reduce((a, b) => (a ?? 0) > (b ?? 0) ? a : b) ?? 0);
      final newFavorite = Favorite(id: (maxId + 1), bookId: favorite.bookId, userId: favorite.userId);
      list.add(newFavorite);
      await _saveList('favorites', list, (f) => f.toMap());
      return newFavorite.id!;
    }
    final db = await database;
    return await db.insert('favorites', favorite.toMap());
  }

  Future<int> removeFavorite(int bookId, String userId) async {
    if (kIsWeb) {
      final list = _getList('favorites', (map) => Favorite.fromMap(map));
      final initialLength = list.length;
      list.removeWhere((f) => f.bookId == bookId && f.userId == userId);
      final removed = initialLength - list.length;
      await _saveList('favorites', list, (f) => f.toMap());
      return removed > 0 ? 1 : 0;
    }
    final db = await database;
    return await db.delete(
      'favorites',
      where: 'book_id = ? AND user_id = ?',
      whereArgs: [bookId, userId],
    );
  }

  Future<bool> isFavorite(int bookId, String userId) async {
    if (kIsWeb) {
      final list = _getList('favorites', (map) => Favorite.fromMap(map));
      return list.any((f) => f.bookId == bookId && f.userId == userId);
    }
    final db = await database;
    final maps = await db.query(
      'favorites',
      where: 'book_id = ? AND user_id = ?',
      whereArgs: [bookId, userId],
    );
    return maps.isNotEmpty;
  }

  Future<List<Book>> getFavoriteBooks(String userId) async {
    if (kIsWeb) {
      final favorites = _getList('favorites', (map) => Favorite.fromMap(map));
      final favoriteBookIds = favorites.where((f) => f.userId == userId).map((f) => f.bookId).toList();
      final allBooks = await getAllBooks();
      return allBooks.where((book) => favoriteBookIds.contains(book.id)).toList();
    }
    final db = await database;
    final maps = await db.query(
      'favorites',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    
    final bookIds = maps.map((map) => map['book_id'] as int).toList();
    if (bookIds.isEmpty) return [];
    
    final placeholders = bookIds.map((_) => '?').join(',');
    final bookMaps = await db.query(
      'books',
      where: 'id IN ($placeholders)',
      whereArgs: bookIds,
    );
    return bookMaps.map((map) => Book.fromMap(map)).toList();
  }

  // Helper method to get full location info for a book
  Future<Map<String, dynamic>?> getBookLocation(int bookId) async {
    final book = await getBookById(bookId);
    if (book == null) return null;

    // Find rack by book's rackId
    Rack? rack;
    if (kIsWeb) {
      final allRacks = _getList('racks', (map) => Rack.fromMap(map));
      try {
        rack = allRacks.firstWhere((r) => r.id == book.rackId);
      } catch (e) {
        return null;
      }
    } else {
      final db = await database;
      final rackMaps = await db.query('racks', where: 'id = ?', whereArgs: [book.rackId]);
      if (rackMaps.isEmpty) return null;
      rack = Rack.fromMap(rackMaps.first);
    }

    // Find shelf by rack's shelfId
    Shelf? shelf;
    if (kIsWeb) {
      final allShelves = _getList('shelves', (map) => Shelf.fromMap(map));
      try {
        shelf = allShelves.firstWhere((s) => s.id == rack!.shelfId);
      } catch (e) {
        return null;
      }
    } else {
      final db = await database;
      final shelfMaps = await db.query('shelves', where: 'id = ?', whereArgs: [rack!.shelfId]);
      if (shelfMaps.isEmpty) return null;
      shelf = Shelf.fromMap(shelfMaps.first);
    }

    if (shelf == null) return null;

    // Find building by shelf's buildingId
    final buildings = await getAllBuildings();
    final building = buildings.firstWhere(
      (b) => b.id == shelf!.buildingId,
      orElse: () => buildings.first,
    );

    return {
      'building': building,
      'shelf': shelf,
      'rack': rack,
      'book': book,
    };
  }

  // Loan methods - запись выдачи книг
  Future<int> recordLoan(Loan loan) async {
    if (kIsWeb) {
      final list = _getList('loans', (map) => Loan.fromMap(map));
      final maxId = list.isEmpty ? 0 : (list.map((e) => e.id ?? 0).reduce((a, b) => (a ?? 0) > (b ?? 0) ? a : b) ?? 0);
      final newLoan = Loan(
        id: (maxId + 1),
        borrowerName: loan.borrowerName,
        bookId: loan.bookId,
        quantity: loan.quantity,
        issueDate: loan.issueDate,
        returnDate: loan.returnDate,
        librarianId: loan.librarianId,
      );
      list.add(newLoan);
      await _saveList('loans', list, (l) => l.toMap());
      
      // Обновляем количество доступных и выданных книг
      final book = await getBookById(loan.bookId);
      if (book != null) {
        await updateBook(book.copyWith(
          availableCopies: book.availableCopies - loan.quantity,
          onHandCopies: book.onHandCopies + loan.quantity,
        ));
      }
      
      return newLoan.id!;
    }
    final db = await database;
    final loanId = await db.insert('loans', loan.toMap());
    
    // Обновляем количество доступных и выданных книг
    final book = await getBookById(loan.bookId);
    if (book != null) {
      await updateBook(book.copyWith(
        availableCopies: book.availableCopies - loan.quantity,
        onHandCopies: book.onHandCopies + loan.quantity,
      ));
    }
    
    return loanId;
  }

  Future<List<Loan>> getAllLoans() async {
    if (kIsWeb) {
      return _getList('loans', (map) => Loan.fromMap(map));
    }
    final db = await database;
    final maps = await db.query('loans', orderBy: 'issue_date DESC');
    return maps.map((map) => Loan.fromMap(map)).toList();
  }

  Future<List<Loan>> getLoansByBorrower(String borrowerName) async {
    if (kIsWeb) {
      final allLoans = _getList('loans', (map) => Loan.fromMap(map));
      return allLoans.where((loan) => loan.borrowerName == borrowerName).toList();
    }
    final db = await database;
    final maps = await db.query(
      'loans',
      where: 'borrower_name = ?',
      whereArgs: [borrowerName],
      orderBy: 'issue_date DESC',
    );
    return maps.map((map) => Loan.fromMap(map)).toList();
  }

  Future<List<Loan>> getActiveLoans() async {
    if (kIsWeb) {
      final allLoans = _getList('loans', (map) => Loan.fromMap(map));
      return allLoans.where((loan) => loan.returnDate == null).toList();
    }
    final db = await database;
    final maps = await db.query(
      'loans',
      where: 'return_date IS NULL',
      orderBy: 'issue_date DESC',
    );
    return maps.map((map) => Loan.fromMap(map)).toList();
  }

  Future<List<Loan>> getLoansByBook(int bookId) async {
    if (kIsWeb) {
      final allLoans = _getList('loans', (map) => Loan.fromMap(map));
      return allLoans.where((loan) => loan.bookId == bookId).toList();
    }
    final db = await database;
    final maps = await db.query(
      'loans',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'issue_date DESC',
    );
    return maps.map((map) => Loan.fromMap(map)).toList();
  }

  Future<int> returnLoan(int loanId, int? returnedQuantity) async {
    if (kIsWeb) {
      final list = _getList('loans', (map) => Loan.fromMap(map));
      final index = list.indexWhere((l) => l.id == loanId);
      if (index == -1) return 0;
      
      final loan = list[index];
      final quantityToReturn = returnedQuantity ?? loan.quantity;
      final returnDate = DateTime.now();
      
      // Если возвращается не все количество, создаем новую запись для оставшегося количества
      if (quantityToReturn < loan.quantity && loan.returnDate == null) {
        final remainingLoan = loan.copyWith(
          id: null,
          quantity: loan.quantity - quantityToReturn,
        );
        final maxId = list.isEmpty ? 0 : (list.map((e) => e.id ?? 0).reduce((a, b) => (a ?? 0) > (b ?? 0) ? a : b) ?? 0);
        list.add(remainingLoan.copyWith(id: maxId + 1));
      }
      
      // Обновляем текущую запись
      if (quantityToReturn == loan.quantity) {
        list[index] = loan.copyWith(returnDate: returnDate);
      } else {
        list[index] = loan.copyWith(
          quantity: quantityToReturn,
          returnDate: returnDate,
        );
      }
      
      await _saveList('loans', list, (l) => l.toMap());
      
      // Обновляем количество доступных и выданных книг
      final book = await getBookById(loan.bookId);
      if (book != null) {
        await updateBook(book.copyWith(
          availableCopies: book.availableCopies + quantityToReturn,
          onHandCopies: book.onHandCopies - quantityToReturn,
        ));
      }
      
      return 1;
    }
    final db = await database;
    final loanMaps = await db.query('loans', where: 'id = ?', whereArgs: [loanId]);
    if (loanMaps.isEmpty) return 0;
    
    final loan = Loan.fromMap(loanMaps.first);
    final quantityToReturn = returnedQuantity ?? loan.quantity;
    final returnDate = DateTime.now();
    
    // Если возвращается не все количество, создаем новую запись для оставшегося количества
    if (quantityToReturn < loan.quantity && loan.returnDate == null) {
      final remainingLoan = loan.copyWith(
        id: null,
        quantity: loan.quantity - quantityToReturn,
      );
      await db.insert('loans', remainingLoan.toMap());
    }
    
    // Обновляем текущую запись
    if (quantityToReturn == loan.quantity) {
      await db.update(
        'loans',
        {'return_date': returnDate.toIso8601String()},
        where: 'id = ?',
        whereArgs: [loanId],
      );
    } else {
      await db.update(
        'loans',
        {
          'quantity': quantityToReturn,
          'return_date': returnDate.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [loanId],
      );
    }
    
    // Обновляем количество доступных и выданных книг
    final book = await getBookById(loan.bookId);
    if (book != null) {
      await updateBook(book.copyWith(
        availableCopies: book.availableCopies + quantityToReturn,
        onHandCopies: book.onHandCopies - quantityToReturn,
      ));
    }
    
    return 1;
  }

  Future<Loan?> getLoanById(int id) async {
    if (kIsWeb) {
      final list = _getList('loans', (map) => Loan.fromMap(map));
      try {
        return list.firstWhere((loan) => loan.id == id);
      } catch (e) {
        return null;
      }
    }
    final db = await database;
    final maps = await db.query('loans', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Loan.fromMap(maps.first);
  }
}
