import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

PageStorageKey diagnosisKey = const PageStorageKey("diagnosis");
final PageStorageBucket diagnosisBucket = PageStorageBucket();

PageStorageKey visitKey = const PageStorageKey("visit");
final PageStorageBucket visitBucket = PageStorageBucket();

List<PainPoint> points = [];

const List<String> imagePaths = [
  'images/delete.png',
  'images/piercing.png',
  'images/burning.png',
  'images/cramp.png',
];

const List<String> modeNames = [
  'Delete',
  'Piercing',
  'Burning',
  'Cramp',
];

// -----------------------------------------
// FIRST PATIENT PAGE
// HERE PATIENT CAN CHOOSE WHETHER THEY WANT
// TO MAKE A VISIT OR SEE PREVIOUS DIAGNOSIS
// -----------------------------------------

class PatientPage extends StatelessWidget {
  const PatientPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient page"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
          child: Container(
        padding: const EdgeInsets.all(50),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PatientVisitPage()));
                },
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.fromLTRB(30, 20, 30, 20)),
                child: Text(
                  "New Visit",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Container(
                height: 30,
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PatientDiagnosisInput()));
                },
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.fromLTRB(30, 20, 30, 20)),
                child: Text("See Diagnosis",
                    style: Theme.of(context).textTheme.headlineSmall),
              ),
            ]),
      )),
    );
  }
}

// -----------------------------------------
// DIAGNOSIS CODE INPUT PAGE
// -----------------------------------------

class PatientDiagnosisInput extends StatefulWidget {
  const PatientDiagnosisInput({super.key});

  @override
  State<StatefulWidget> createState() => PatientDiagnosisInputState();
}

class PatientDiagnosisInputState extends State<PatientDiagnosisInput> {
  final TextEditingController codeController = TextEditingController();

  void submit(String code) {
    // verify if the code is valid
    code.replaceAll(RegExp(r"\s"), "");
    try {
      int.parse(code);
    } on FormatException catch (_) {
      showErrorDialog();
      return;
    }

    if (code.length != 6) {
      showErrorDialog();
      return;
    }
    diagnosisBucket.writeState(context, code,
        identifier: ValueKey(diagnosisKey));
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const PatientDiagnosisPage()));
  }

  void showErrorDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Error"),
            content: const Text("Invalid code"),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK"))
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    TextField inputField = TextField(
        keyboardType: TextInputType.number,
        onSubmitted: submit,
        controller: codeController,
        decoration: const InputDecoration(
            border: OutlineInputBorder(), hintText: "Enter the patient code"));

    return PageStorage(
        bucket: diagnosisBucket,
        key: diagnosisKey,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Diagnosis"),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.fromLTRB(50, 0, 50, 0),
                  child: inputField,
                ),
                ElevatedButton(
                    onPressed: () {
                      submit(codeController.text);
                    },
                    child: const Text("Submit"))
              ],
            ),
          ),
        ));
  }
}

// -----------------------------------------
// DIAGNOSIS PAGE
// -----------------------------------------

class PatientDiagnosisPage extends StatefulWidget {
  const PatientDiagnosisPage({super.key});

  @override
  State<PatientDiagnosisPage> createState() => PatientDiagnosisPageState();
}

class PatientDiagnosisPageState extends State<PatientDiagnosisPage> {
  @override
  Widget build(BuildContext context) {
    //TODO: get diagnosis
    String diagnosis = "some example text afjighar";

    return PageStorage(
        bucket: diagnosisBucket,
        key: diagnosisKey,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Diagnosis"),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: Center(
            child: Column(
              children: <Widget>[
                const Text(
                    "If the doctor provided a diagnosis, it'll be visible below."),
                Expanded(
                    child: Container(
                  padding: const EdgeInsets.all(30),
                  color: Theme.of(context).canvasColor,
                  child: Text(diagnosis),
                )),
                ElevatedButton(
                    onPressed: () {
                      // jank :/
                      Navigator.pop(context); // to code input
                      Navigator.pop(context); // to patient page
                      Navigator.pop(context); // to main page
                    },
                    child: const Text("Back"))
              ],
            ),
          ),
        ));
  }
}

// -----------------------------------------
// NEW VISIT PAGE
// -----------------------------------------

enum PainType {
  piercing,
  burning,
  cramp;

  int get value => index + 1;
  static PainType get(int val) {
    return PainType.values.firstWhere((x) => x.value == val);
  }
}

class PainPoint {
  PainType type;
  Offset pos;
  PainPoint({required this.type, required this.pos});
}

class PatientVisitPage extends StatefulWidget {
  const PatientVisitPage({super.key});

  @override
  State<PatientVisitPage> createState() => PatientVisitPageState();
}

class ClickableBody extends CustomPainter {
  ClickableBody({required this.images, required this.lastTapTime});

  final Map<PainType, ui.Image> images;
  final int lastTapTime;

  @override
  void paint(Canvas canvas, Size size) {
    for (PainPoint point in points) {
      canvas.drawImage(images[point.type] as ui.Image,
          point.pos - const Offset(8, 8), Paint());
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return (oldDelegate as ClickableBody).lastTapTime != lastTapTime;
  }
}

class PatientVisitPageState extends State<PatientVisitPage> {
  int mode = 0;
  Map<PainType, ui.Image> images = {};
  bool isLoaded = false;
  Offset lastTap = const Offset(0, 0);

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<Null> init() async {
    images[PainType.piercing] = await loadSingleImage('images/piercing.png');
    images[PainType.burning] = await loadSingleImage('images/burning.png');
    images[PainType.cramp] = await loadSingleImage('images/cramp.png');
  }

  Future<ui.Image> loadSingleImage(String path) async {
    final ByteData data = await rootBundle.load(path);
    return loadImage(Uint8List.view(data.buffer));
  }

  Future<ui.Image> loadImage(Uint8List img) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(img, (ui.Image img) {
      setState(() {
        isLoaded = true;
      });
      return completer.complete(img);
    });
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Where does it hurt?"),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Column(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                        4,
                        (index) => ElevatedButton(
                            onPressed: () {
                              setState(() {
                                mode = index;
                              });
                              final SnackBar bar = SnackBar(
                                content: Text("Mode: ${modeNames[index]}"),
                              );
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(bar);
                            },
                            child: Image(
                              image: AssetImage(imagePaths[index]),
                            )))),
                GestureDetector(
                  child: Container(
                    color: Colors.white,
                    child: CustomPaint(
                      foregroundPainter: ClickableBody(
                          images: images,
                          lastTapTime: DateTime.now().millisecondsSinceEpoch),
                      child: const Image(
                        image: AssetImage("images/human.jpg"),
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                  onTapDown: (TapDownDetails details) {
                    if (mode == 0 && points.isNotEmpty) {
                      // remove closest point
                      Offset target = details.localPosition;
                      PainPoint closest = points.reduce((a, b) =>
                          (a.pos - target).distance < (b.pos - target).distance
                              ? a
                              : b);
                      if ((closest.pos - target).distance <= 30) {
                        points.remove(closest);
                      }
                    } else if (mode != 0) {
                      points.add(PainPoint(
                          type: PainType.get(mode),
                          pos: details.localPosition));
                    }
                    setState(() {
                      lastTap = details.localPosition;
                    });
                  },
                ),
                Container(
                  height: 50,
                ),
                Container(
                  padding: const EdgeInsets.all(30),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context,
                        MaterialPageRoute(builder: (context) => const PatientVisitCodePage()));
                    }, 
                    child: const Text("Next")),
                ),
              ],
            )
          ],
        ));
  }
}

// -----------------------------------------
// VISIT CODE PAGE
// -----------------------------------------

class PatientVisitCodePage extends StatefulWidget {
  const PatientVisitCodePage({super.key});

  @override
  State<PatientVisitCodePage> createState() => PatientVisitCodePageState();
}

class PatientVisitCodePageState extends State<PatientVisitCodePage> {
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // TODO: get code from backend
    String code = "123456";
    return PageStorage(
        bucket: visitBucket,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Your code"),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: Center(
            child: Column(
              children: [
                const Text("Your code is"),
                Text(
                  code,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                Container(
                  padding: const EdgeInsets.all(15),
                  child: TextField(
                    keyboardType: TextInputType.number,
                    onSubmitted: (String s) {},
                    controller: ageController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(), hintText: "Enter age (optional)")
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(15),
                  child: TextField(
                    keyboardType: TextInputType.text,
                    onSubmitted: (String s) {},
                    controller: heightController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(), hintText: "Enter height (optional)")
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(15),
                  child: TextField(
                    keyboardType: TextInputType.text,
                    onSubmitted: (String s) {},
                    controller: genderController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(), hintText: "Enter gender (optional)")
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    child: TextField(
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top,
                      onSubmitted: (String s) {},
                      controller: notesController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(), hintText: "Enter additional notes (optional)"
                      )
                    ),
                  )
                )
              ],
            ),
          ),
        )
      );
  }
}
