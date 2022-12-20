import 'package:age_calculator/age_calculator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('Birthdays');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          colorScheme: ColorScheme.fromSwatch().copyWith(
            primary: Color(0xFFADA2FF),
          ),
          textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme)),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  var isSearch = false;
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool? yearKnown = false;
  DateTime dateTime = DateTime.now();
  DateTime date = DateTime.now();
  bool isFabVisible = true;

  List<Map<String, dynamic>> Items = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  //
  void _refresh() {
    final data = _birthdays.keys.map((key) {
      final item = _birthdays.get(key);
      return {
        "key": key,
        "name": item['name'],
        "eventName": item['eventName'],
        "date": item['date'],
      };
    }).toList();

    setState(() {
      Items = data.toList();
      print(Items.length);
      print(Items);
    });
  }

  final _birthdays = Hive.box('Birthdays');

  Future<void> _createEvent(Map<String, dynamic> newItem) async {
    await _birthdays.add(newItem);
    print("length is ${_birthdays.length}");
    _refresh();
  }

  Future<void> _updateEvent(int key, Map<String, dynamic> updateItem) async {
    await _birthdays.put(key, updateItem);
    _refresh();
  }

  Future<void> _delete(int itemkey) async {
    await _birthdays.delete(itemkey);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: isFabVisible
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFADA2FF),
              onPressed: () {
                BottomSheet(context, null);
              },
              child: Icon(Icons.add),
            )
          : null,
      appBar: widget.isSearch == false
          ? AppBar(
              elevation: 0,
              actions: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      widget.isSearch = true;
                    });
                  },
                  child: Icon(
                    Icons.search,
                  ),
                ),
              ],
              title: const Text(
                'Birthdays',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : AppBar(
              elevation: 0,
              title: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: TextField(
                  cursorColor: Color(
                    0xFFADA2FF,
                  ),
                ),
              ),
              actions: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      widget.isSearch = false;
                    });
                  },
                  child: Icon(
                    Icons.close,
                  ),
                ),
              ],
            ),
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.forward) {
            if (!isFabVisible)
              setState(() {
                isFabVisible = true;
              });
          } else if (notification.direction == ScrollDirection.reverse) {
            if (isFabVisible)
              setState(() {
                isFabVisible = false;
              });
          }

          return true;
        },
        child: Scrollbar(
          showTrackOnHover: true,
          child: ListView.builder(
              itemCount: Items.length,
              itemBuilder: (_, index) {
                final instant = Items[index];
                final formatedDate = DateFormat.yMMMd().format(instant['date']);
                final age = ((AgeCalculator.age(instant['date'])).years);
                var diff;
                if (DateTime.now().month == instant['date'].month &&
                        DateTime.now().day >= instant['date'].day ||
                    DateTime.now().month > instant['date'].month) {
                  diff = (DateTime(DateTime.now().year + 1,
                                  instant['date'].month, instant['date'].day)
                              .difference(DateTime.now())
                              .inHours /
                          24)
                      .round();
                } else {
                  diff = (DateTime(DateTime.now().year, instant['date'].month,
                                  instant['date'].day)
                              .difference(DateTime.now())
                              .inHours /
                          24)
                      .round();
                }
                return Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Slidable(
                    startActionPane: ActionPane(
                      motion: StretchMotion(),
                      children: [
                        SlidableAction(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomLeft: Radius.circular(
                              10,
                            ),
                          ),
                          onPressed: ((context) {
                            print(index);
                            BottomSheet(
                                context,
                                (instant[
                                    'key'])); // 0 1 2 3 4 // 0 > 4-0=4 // 1 > 4-1=3
                          }),
                          backgroundColor: Color(0xFFBCCEF8),
                          icon: Icons.edit,
                        ),
                        SlidableAction(
                          onPressed: ((context) {
                            _delete(instant['key']);
                          }),
                          backgroundColor: Color.fromARGB(255, 65, 72, 88),
                          icon: Icons.delete,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 5,
                            offset: Offset(0, 5),
                            color: Color(0xFFBCCEF8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: AssetImage('assets/dp.png'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width: 20,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      instant['name'],
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${diff} Days for ${instant['eventName']}',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      formatedDate,
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text('Turns'),
                                Text(
                                  '${age + 1}',
                                  style: GoogleFonts.getFont(
                                    'Lato',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 30,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
        ),
      ),
    );
  }

  Future<dynamic> BottomSheet(BuildContext context, int? itemKey) {
    TextEditingController _name = TextEditingController();
    TextEditingController _eventName = TextEditingController();

    if (itemKey != null) {
      final finditem = Items.firstWhere((element) => element['key'] == itemKey);
      _name.text = finditem['name'];
      _eventName.text = finditem['eventName'];
      // date = finditem['date'];
    }

    return showModalBottomSheet<dynamic>(
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        context: context,
        builder: (context) {
          return Wrap(
            children: [
              SizedBox(
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Icon(
                              Icons.close,
                              color: Color(0xFFADA2FF),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                        child: Column(
                          children: [
                            TextField(
                              controller: _name,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                labelText: 'Name',
                              ),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            TextField(
                              controller: _eventName,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                labelText: 'Event',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 200,
                        child: Column(
                          children: [
                            datePicker(),
                          ],
                        ),
                      ),
                      Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            StatefulBuilder(builder: (context, setState) {
                              return Checkbox(
                                activeColor: Color(0xFFADA2FF),
                                value: yearKnown,
                                onChanged: (newbool) {
                                  setState(() {
                                    yearKnown = newbool;
                                  });
                                },
                              );
                            }),
                            Text('Check if you don\'t know the year'),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (itemKey == null) {
                            _createEvent({
                              "name": _name.text,
                              "eventName": _eventName.text,
                              "date": date,
                            });
                          }

                          if (itemKey != null) {
                            _updateEvent(itemKey, {
                              "name": _name.text,
                              "eventName": _eventName.text,
                              "date": date,
                            });
                          }

                          _name.text = '';
                          _eventName.text = '';

                          Navigator.of(context).pop();
                        },
                        child: Text(itemKey == null ? 'Add' : 'Update'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        });
  }

  Widget datePicker() => Flexible(
        child: CupertinoDatePicker(
          initialDateTime: dateTime,
          mode: CupertinoDatePickerMode.date,
          onDateTimeChanged: (dateTime) => setState(
            () {
              date = dateTime;
              print(date);
            },
          ),
        ),
      );
}
