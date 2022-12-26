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
            primary: const Color(0xFFADA2FF),
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
  String searchText = '';

  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  //
  void _refresh() {
    final data = _birthdays.keys.map((key) {
      final item = _birthdays.get(key);

      //calculate date
      var diff;
      if (DateTime.now().month == item['date'].month &&
              DateTime.now().day >= item['date'].day ||
          DateTime.now().month > item['date'].month) {
        diff = ((DateTime(DateTime.now().year + 1, item['date'].month,
                    item['date'].day)
                .difference(DateTime.now())
                .inDays) +
            1);
      } else {
        diff =
            (DateTime(DateTime.now().year, item['date'].month, item['date'].day)
                    .difference(DateTime.now())
                    .inDays) +
                1;
      }
      //
      return {
        "key": key,
        "name": item['name'],
        "eventName": item['eventName'],
        "date": item['date'],
        "toNextDay": diff == 365 ? 0 : diff,
        "yearKnown": item['yearKnown'],
      };
    }).toList();

    setState(() {
      items = data.toList();
      items.sort((a, b) {
        return a['toNextDay'].compareTo(b['toNextDay']);
      });
    });
  }

  final _birthdays = Hive.box('Birthdays');

  Future<void> _createEvent(Map<String, dynamic> newItem) async {
    await _birthdays.add(newItem);
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
      // bottomNavigationBar: CurvedNavigationBar(
      //   height: 60,
      //   backgroundColor: Colors.transparent,
      //   color: Color(0xFFADA2FF),
      //   items: [
      //     Icon(
      //       Icons.home,
      //       color: Colors.white,
      //     ),
      //     Icon(
      //       Icons.add,
      //       color: Colors.white,
      //     ),
      //     Icon(
      //       Icons.settings,
      //       color: Colors.white,
      //     ),
      //   ],
      //   onTap: (index) {
      //     if (index == 1) {
      //       BottomSheet(context, null);
      //     }
      //   },
      // ),
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
                  child: const Icon(
                    Icons.search,
                  ),
                ),
              ],
              title: const Text(
                'Upcoming',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
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
                  onChanged: (value) {
                    searchText = value;
                    _refresh();
                  },
                  cursorColor: const Color(
                    0xFFADA2FF,
                  ),
                ),
              ),
              actions: [
                GestureDetector(
                  onTap: () {
                    searchText = '';
                    _refresh();
                    setState(() {
                      widget.isSearch = false;
                    });
                  },
                  child: const Icon(
                    Icons.close,
                  ),
                ),
              ],
            ),
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.forward) {
            if (!isFabVisible) {
              setState(() {
                isFabVisible = true;
              });
            }
          } else if (notification.direction == ScrollDirection.reverse) {
            if (isFabVisible) {
              setState(() {
                isFabVisible = false;
              });
            }
          }

          return true;
        },
        child: Scrollbar(
          showTrackOnHover: true,
          child: items.isNotEmpty
              ? ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    if (items.isEmpty) {
                      return const Image(
                        image: AssetImage('assets/empty.png'),
                        fit: BoxFit.cover,
                      );
                    }
                    final instant = items[index];
                    final formatedDate =
                        DateFormat.yMMMd().format(instant['date']);
                    final age = ((AgeCalculator.age(instant['date'])).years);
                    if (instant['name']
                        .toString()
                        .toLowerCase()
                        .contains(searchText)) {
                      return Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Slidable(
                          startActionPane: ActionPane(
                            motion: const StretchMotion(),
                            children: [
                              SlidableAction(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  bottomLeft: Radius.circular(
                                    10,
                                  ),
                                ),
                                onPressed: ((context) {
                                  BottomSheet(context, (instant['key']));
                                }),
                                backgroundColor: const Color(0xFFBCCEF8),
                                icon: Icons.edit,
                              ),
                              SlidableAction(
                                onPressed: ((context) {
                                  _delete(instant['key']);
                                }),
                                backgroundColor:
                                    const Color.fromARGB(255, 65, 72, 88),
                                icon: Icons.delete,
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(
                                  blurRadius: 4,
                                  color: Color(0xFFBCCEF8),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                                image:
                                                    AssetImage('assets/dp.png'),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        width: 20,
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: 200,
                                            child: Text(
                                              instant['name'],
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                              width: 200,
                                              child: instant['toNextDay'] == 0
                                                  ? Text(
                                                      '${instant['eventName']} is Today',
                                                      style: const TextStyle(
                                                          fontSize: 12),
                                                    )
                                                  : instant['toNextDay'] == 1
                                                      ? Text(
                                                          '${instant['eventName']} is Tomorrow',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 12),
                                                        )
                                                      : Text(
                                                          '${instant['toNextDay']} Days for ${instant['eventName']}',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 12),
                                                        )),
                                          Text(
                                            instant['yearKnown']
                                                ? DateFormat.MMMd()
                                                    .format(instant['date'])
                                                : formatedDate,
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  instant['yearKnown'] == false
                                      ? Column(
                                          children: [
                                            const Text('Turns'),
                                            Text(
                                              '${age + 1}',
                                              style: GoogleFonts.getFont(
                                                'Lato',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 30,
                                              ),
                                            )
                                          ],
                                        )
                                      : Column(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
                      return Container();
                    }
                  },
                )
              : const Center(
                  child: Image(
                    image: AssetImage('assets/empty.png'),
                    fit: BoxFit.cover,
                  ),
                ),
        ),
      ),
    );
  }

  Future<dynamic> BottomSheet(BuildContext context, int? itemKey) {
    TextEditingController _name = TextEditingController();
    TextEditingController _eventName = TextEditingController();
    bool error = false;

    date = DateTime.now();

    if (itemKey != null) {
      final finditem = items.firstWhere((element) => element['key'] == itemKey);
      _name.text = finditem['name'];
      _eventName.text = finditem['eventName'];
      yearKnown = finditem['yearKnown'];
      date = finditem['date'];
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
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: const Icon(
                              Icons.close,
                              color: Color(0xFFADA2FF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Column(
                        children: [
                          StatefulBuilder(
                            builder: (context, setState) {
                              return TextField(
                                controller: _name,
                                decoration: InputDecoration(
                                  enabledBorder: const OutlineInputBorder(
                                      borderSide:
                                          //error == true
                                          // ?
                                          BorderSide(color: Color(0xFFADA2FF))
                                      //     : BorderSide(
                                      //         color: Colors.re,
                                      //       ),
                                      ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  labelText: 'Name',
                                ),
                              );
                            },
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          TextField(
                            controller: _eventName,
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: error == true
                                    ? const BorderSide(color: Colors.red)
                                    : const BorderSide(
                                        color: Color(0xFFADA2FF),
                                      ),
                              ),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              labelText: 'Event',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 200,
                        child: Column(
                          children: [
                            datePicker(),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          StatefulBuilder(builder: (context, setState) {
                            return Checkbox(
                              activeColor: const Color(0xFFADA2FF),
                              value: yearKnown,
                              onChanged: (newbool) {
                                setState(() {
                                  yearKnown = newbool;
                                });
                              },
                            );
                          }),
                          const Text('Check if you don\'t know the year'),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (_name.text.isEmpty) {
                            setState(() {
                              error = true;
                            });
                          } else {
                            if (itemKey == null) {
                              _createEvent({
                                "name": _name.text,
                                "eventName": _eventName.text,
                                "date": date,
                                "yearKnown": yearKnown,
                              });
                            }

                            if (itemKey != null) {
                              _updateEvent(itemKey, {
                                "name": _name.text,
                                "eventName": _eventName.text,
                                "date": date,
                                "yearKnown": yearKnown,
                              });
                            }

                            _name.text = '';
                            _eventName.text = '';

                            Navigator.of(context).pop();
                          }
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
          initialDateTime: date,
          mode: CupertinoDatePickerMode.date,
          onDateTimeChanged: (dateTime) => setState(
            () {
              date = dateTime;
            },
          ),
        ),
      );
}
