import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:googleapis/videointelligence/v1.dart' as videointelligence;
import 'package:googleapis_auth/auth_io.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const String apiKey = String.fromEnvironment('API_KEY');
void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Living Warriors'),
        ),
        body: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final myController = TextEditingController();
  String generatedText = '';
  FlutterTts flutterTts = FlutterTts();
  bool showMoodTracker = false;

  @override
  void dispose() {
    myController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _speak("How are you feeling today?");
  }

  Future<void> generateText() async {
    //final apiKey = Platform.environment['API_KEY'];
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    final content = [Content.text(myController.text)];
    final response = await model.generateContent(content);
    if (response.text == null) {
      throw Exception('Failed to generate text');
    }
    setState(() {
      generatedText = response.text!;
    });
  }

  Future _speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    // Estimate the height of other widgets and subtract from the screen height
    double remainingHeight = screenHeight - 200; // adjust 200 as needed

    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "How are you feeling today? I’d love to hear all about your story. Please share it with me in your own words, just like you’re writing in a diary. Your experiences and feelings are important, and I’m here to listen.",
                  style: TextStyle(fontSize: 30),
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                height: remainingHeight,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          controller: myController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Type your question here',
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(Icons.videocam),
                            onPressed: uploadVideo,
                          ),
                          IconButton(
                            icon: Icon(Icons.mic),
                            onPressed: () {
                              // Add your microphone button click event here
                            },
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: generateText,
                        child: Text('Send'),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(generatedText),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Add a button to show the mood tracker
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showMoodTracker = !showMoodTracker;
                    });
                  },
                  child: Text(showMoodTracker ? 'Hide Mood Tracker' : 'Show Mood Tracker'),
                ),
              ),
            ],
          ),
        ),
        // Show the mood tracker if it's enabled
        if (showMoodTracker) MoodTracker(),
      ],
    );
  }
}

// Mood tracking app
class MoodTracker extends StatefulWidget {
  @override
  _MoodTrackerState createState() => _MoodTrackerState();
}

class _MoodTrackerState extends State<MoodTracker> {
  List<MoodEntry> moodEntries = [];
  String selectedMood = '';
  String notes = '';
  bool showAddDialog = false;
  
  void _showAddMoodDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddMoodDialog(
          onMoodSelected: (mood) {
            //setState(() {
              selectedMood = mood;
            //});
          },
          onNotesChanged: (value) {
           // setState(() {
              //notes = value;
           // });
           this.notes = value;
          },
          onConfirm: addMoodEntry,
          onCancel: () {
            setState(() {
              showAddDialog = false;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mood Tracker'),
         actions: <Widget>[
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              // Close the MoodTracker
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: moodEntries.length,
              itemBuilder: (context, index) {
                return MoodEntryItem(
                  entry: moodEntries[index],
                  onDelete: () {
                    setState(() {
                      moodEntries.removeAt(index);
                    });
                  },
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _showAddMoodDialog,
                child: Text('Add Mood'),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMoodDialog,
        child: Icon(Icons.add),
      ),
    );
  }

  void addMoodEntry(String mood, String notes) {
    setState(() {
      moodEntries.add(MoodEntry(
        date: DateTime.now().toString(),
        mood: mood,
        notes: notes,
      ));
      showAddDialog = false;
    });
  }
}

class MoodEntryItem extends StatelessWidget {
  final MoodEntry entry;
  final VoidCallback onDelete;

  MoodEntryItem({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('${entry.mood}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${entry.date}'),
            if (entry.notes?.isNotEmpty ?? false)
              Text('Notes: ${entry.notes}'),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class MoodEntry {
  final String date;
  final String mood;
  final String? notes;

  MoodEntry({required this.date, required this.mood, this.notes});
}

class AddMoodDialog extends StatefulWidget {
  final Function(String mood) onMoodSelected;
  final Function(String notes) onNotesChanged;
  final Function(String mood, String notes) onConfirm;
  final Function() onCancel;

  AddMoodDialog({
    required this.onMoodSelected,
    required this.onNotesChanged,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  _AddMoodDialogState createState() => _AddMoodDialogState();
}

class _AddMoodDialogState extends State<AddMoodDialog> {

  final List<String> moods = ['Happy', 'Sad', 'Anxious', 'Neutral'];
  String? selectedMood;
  TextEditingController notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Mood'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            value: selectedMood,
            hint: Text('Select Mood'),
            items: moods.map((mood) {
              return DropdownMenuItem<String>(
                value: mood,
                child: Text(mood),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedMood = value;
                widget.onMoodSelected(value!);
              });
            },
          ),
          SizedBox(height: 16.0),
          TextField(
            controller: notesController,
            decoration: InputDecoration(
              labelText: 'Notes',
            ),
            onChanged: (value) {
              widget.onNotesChanged(value);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onConfirm(selectedMood!, notesController.text);
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}

Future<File> recordVideo() async {
  final pickedFile = await ImagePicker().pickVideo(source: ImageSource.camera);
   if (pickedFile != null) {
    return File(pickedFile.path);
  } else {
    throw Exception('No file selected');
  }
}

Future<void> uploadVideo() async {
  //final picker = ImagePicker();
  // To select a video from the gallery
  //final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
  
  // Or to record a video using the camera
  //final pickedFile = await picker.pickVideo(source: ImageSource.camera);
try {
  final pickedFile = await ImagePicker().pickVideo(source: ImageSource.camera);
  String filePath = pickedFile!.path;
  if (filePath != null) {
      // Define your videoUrl and apiKey
      String videoUrl = filePath;
      // Call analyzeVideo function
      await analyzeVideo(videoUrl);
    } else {
      print('No video selected.');
    }
} catch (e) {
  print('Error picking video: $e');
}
    

    

      
}

Future<void> analyzeVideo(String videoUrl) async {
  // Load the service account credentials from a JSON file
  final _credentials = ServiceAccountCredentials.fromJson(json.decode(File('/wise-diagram-173016-980bb4b527a5.json').readAsStringSync()));
  
  // Create an authenticated HTTP client using the service account credentials
  final _scopes = ['https://www.googleapis.com/auth/cloud-platform'];
  final _client = await clientViaServiceAccount(_credentials, _scopes);

  // Initialize the VideoIntelligenceApi
  final videoApi = videointelligence.CloudVideoIntelligenceApi(_client);

  // Annotate a video (example URI of a video file)
  final request = videointelligence.GoogleCloudVideointelligenceV1AnnotateVideoRequest(
    inputUri: videoUrl,
    features: ['LABEL_DETECTION'],
  );

  final annotateOperation = await videoApi.videos.annotate(request);

  // Store the operation ID
  final operationId = annotateOperation.name;

  // Polling the operation status using the operation ID
  final operationName = 'projects/wise-diagram-173016/locations/us-west1/operations/$operationId';
  final operation = await videoApi.projects.locations.operations.get(operationName);

  // Check operation status
  if (operation != null && operation.done == true) {
    // The operation was completed successfully
    // Process the result
  } else {
    // The operation is still running
  }

  // Call fetchData function
  // await fetchData();
}

Future<void> fetchData() async {
  final response = await http.get(Uri.parse('http://localhost:3000/proxy'));
  if (response.statusCode == 200) {
    // Handle the response
    final data = json.decode(response.body);
    print(data);
  } else {
    throw Exception('Failed to load data');
  }
}