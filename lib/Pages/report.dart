import 'dart:convert';
import 'dart:io';

import 'package:baseerapp/Pages/ReportSuccessfullySubmited.dart';
import 'package:baseerapp/Pages/SignupPage.dart';
import 'package:baseerapp/pages/HomePage.dart';
import 'package:baseerapp/pages/MonitorPage.dart';
// import 'package:baseerapp/pages/my_textfield.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart';
import 'package:flutter_session_manager/flutter_session_manager.dart';

import 'components/my_textfield.dart';

dynamic email = "", admin = "";
Future<void> loadSessionVariable(context) async {
  email = await SessionManager().get("email");
  admin = await SessionManager().get("admin");
}

final nameController = TextEditingController();

List<String> shirt = ['White', 'Black', 'Blue', 'Red'];
String? selectedColor = 'White';
XFile? pickedFile;
List<XFile>? pickedFileList;
var response;
String images_save_directory = "";
final client = http.Client();
int uploaded_images_count = 0;

class Report extends StatefulWidget {
  Report({Key? key}) : super(key: key);
  @override
  State<Report> createState() => _ReportState();
}

CameraTargetBounds boundingbox = CameraTargetBounds(LatLngBounds(
    northeast: LatLng(27.6683619, 85.3101895),
    southwest: LatLng(27.6683619, 85.3101895)));
String originaltasknumber = '';
LatLng mapcenter = const LatLng(21.41814863010781, 39.81368911279372);

List<LatLng> polylinepointsList = [];

List<Polyline> polylineList = [
  // const Polyline(
  //     polylineId: PolylineId("1"),
  //     points: [
  //       LatLng(31.110484, 72.384598),
  //       LatLng(31.110484, 75.384598),
  //       LatLng(35.110484, 79.384598)
  //     ],
  //     color: Colors.green)
];

Set<Marker> markers = Set();
List<Marker> markersList = [
  // const Marker(
  //   markerId: MarkerId('Marker1'),
  //   position: LatLng(32.195476, 74.2023563),
  //   // infoWindow: InfoWindow(title: 'Business 1'),
  //   // icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
  // ),
  // const Marker(
  //   markerId: MarkerId('Marker2'),
  //   position: LatLng(31.110484, 72.384598),
  //   // infoWindow: InfoWindow(title: 'Business 2'),
  //   // icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
  // ),
];

late GoogleMapController mapController;

class _ReportState extends State<Report> {
  @override
  void initState() {
    super.initState();
    loadSessionVariable(context);
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    polylinepointsList = [];
    polylineList = [];
    polylineList.clear();
    setState(() {});
    // getroute().then((listMap) {
    //   setState(() {});
    // });
  }

  int _selectedIndex = 1;
  List<XFile>? _mediaFileList;

  void _setImageFileListFromFile(XFile? value) {
    _mediaFileList = value == null ? null : <XFile>[value];
  }

  dynamic _pickImageError;
  bool isVideo = false;

  VideoPlayerController? _controller;
  VideoPlayerController? _toBeDisposed;
  String? _retrieveDataError;

  final ImagePicker _picker = ImagePicker();
  final TextEditingController maxWidthController = TextEditingController();
  final TextEditingController maxHeightController = TextEditingController();
  final TextEditingController qualityController = TextEditingController();

  Future<void> submitreport(context) async {
    // 1
    if (nameController.text.length < 3) {
      showDialog(
          context: context,
          builder: (context) {
            return const AlertDialog(title: Text("Please enter child name."));
          });
    } else {
      if (pickedFile != null) {
        sendToServer(
            file: File(pickedFile!.path),
            filename: pickedFile!.name,
            token: '',
            filedata: await pickedFile!.readAsBytes(),
            images_save_directory: "",
            expected_images_count: 1);
      }
      if (pickedFileList!.isNotEmpty) {
        request_images_save_directory(
          // 2
          name: nameController.text,
          color: selectedColor ?? "none",
          email: email,
        ).then((images_save_directory) async => {
              for (final pickedFile1 in pickedFileList!)
                {
                  sendToServer(
                          // 3
                          file: File(pickedFile1.path),
                          filename: pickedFile1.name,
                          token: '',
                          filedata: await pickedFile1.readAsBytes(),
                          images_save_directory: images_save_directory,
                          expected_images_count: pickedFileList!.length)
                      .whenComplete(() {
                    uploaded_images_count++;
                    if (uploaded_images_count == pickedFileList!.length) {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>
                              const ReportSuccessfullySubmited()));
                      // showDialog(
                      //     context: context,
                      //     builder: (context) {
                      //       return const AlertDialog(
                      //           title: Text("All images Uploaded Successfully"));
                      //     }).then((val) {
                      //   print("object");
                      // });
                    }
                  })
                }
            });
      }
    }
  }

  Future<String> request_images_save_directory({
    String name = "name",
    String color = "none",
    String email = "a@a.a",
  }) async {
    final uri;
    double report_lat = 0;
    double report_lng = 0;
    if (markersList.isNotEmpty) {
      report_lat = markersList[0].position.latitude;
      report_lng = markersList[0].position.longitude;
    }
    if (kIsWeb) {
      uri = Uri.parse(
          "http://127.0.0.1:13000/requestdirectory?name=$name&color=$color&email=$email&report_lat=$report_lat&report_lng=$report_lng");
    } else {
      uri = Uri.parse(
          "http://10.0.2.2:13000/requestdirectory?name=$name&color=$color&email=$email&report_lat=$report_lat&report_lng=$report_lng");
    }
    http.Response response = await client.post(uri);
    images_save_directory = jsonDecode(response.body)["images_save_directory"];
    return jsonDecode(response.body)["images_save_directory"];
  }

  Future<String> sendToServer(
      {required File file,
      required String filename,
      required String token,
      required Uint8List filedata,
      required String images_save_directory,
      required int expected_images_count}) async {
    ///MultiPart request
    http.MultipartRequest request;
    Map<String, String> headers = {
      "Authorization": "Bearer $token",
      "Content-type": "multipart/form-data"
    };
    String color = selectedColor.toString();
    String name = nameController.text;
    final String url;
    var response;

    if (kIsWeb) {
      url =
          'http://127.0.0.1:13000/submitimage?name=$name&color=$color&email=a@a.a&images_save_directory=$images_save_directory&expected_images_count=$expected_images_count';
      response = await http.post(Uri.parse(url), body: base64.encode(filedata));
    } else {
      response = http.MultipartRequest(
        'POST',
        Uri.parse(
            "http://10.0.2.2:13000/submitimage?name=$name&color=$color&email=a@a.a&images_save_directory=$images_save_directory&expected_images_count=$expected_images_count"),
      );
      response.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
      ));
      response.headers.addAll(headers);
      // var res = await response.send();
      // print("This is response:" + res.toString());
    }

    return jsonDecode(response.body)["images_save_directory"];
  }

  Future<void> _onImageButtonPressed(
    ImageSource source, {
    required BuildContext context,
    bool isMultiImage = false,
    bool isMedia = false,
  }) async {
    if (context.mounted) {
      if (isMultiImage) {
        try {
          pickedFileList = isMedia
              ? await _picker.pickMultipleMedia()
              : await _picker.pickMultiImage();
          setState(() {
            _mediaFileList = pickedFileList;
          });
        } catch (e) {
          setState(() {
            _pickImageError = e;
          });
        }
      } else {
        try {
          pickedFile = await _picker.pickImage(
            source: source,
          );
          setState(() {
            _setImageFileListFromFile(pickedFile);
          });
        } catch (e) {
          setState(() {
            _pickImageError = e;
          });
        }
      }
    }
  }

  @override
  void deactivate() {
    if (_controller != null) {
      _controller!.setVolume(0.0);
      _controller!.pause();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _disposeVideoController();
    maxWidthController.dispose();
    maxHeightController.dispose();
    qualityController.dispose();
    super.dispose();
  }

  Future<void> _disposeVideoController() async {
    if (_toBeDisposed != null) {
      await _toBeDisposed!.dispose();
    }
    _toBeDisposed = _controller;
    _controller = null;
  }

  Widget _previewImages() {
    final Text? retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (_mediaFileList != null) {
      return Container(
        height: 250,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          key: UniqueKey(),
          itemBuilder: (BuildContext context, int index) {
            return Row(children: [
              kIsWeb
                  ? Image.network(_mediaFileList![index].path)
                  : Image.file(File(_mediaFileList![index].path), errorBuilder:
                      (BuildContext context, Object error,
                          StackTrace? stackTrace) {
                      return const Center(
                          child: Text('This image type is not supported'));
                    }, height: 100),
            ]);
          },
          itemCount: _mediaFileList!.length,
        ),
      );
    } else if (_pickImageError != null) {
      return Text(
        'Pick image error: $_pickImageError',
        textAlign: TextAlign.center,
      );
    } else {
      return const Text(
        'You have not yet picked an image.',
        textAlign: TextAlign.center,
      );
    }
  }

  Widget _handlePreview() {
    return _previewImages();
  }

  Future<void> retrieveLostData() async {
    final LostDataResponse response = await _picker.retrieveLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      isVideo = false;
      setState(() {
        if (response.files == null) {
          _setImageFileListFromFile(response.file);
        } else {
          _mediaFileList = response.files;
        }
      });
    } else {
      _retrieveDataError = response.exception!.code;
    }
  }

  void _onItemTapped(int index) {
    _selectedIndex = index;
    if (index == 0) {
      // If "home" button is tapped (index 0), navigate to the home page
      Navigator.push(
        context as BuildContext,
        MaterialPageRoute(
            builder: (context) => const HomePage()), // Navigate to ReportPage
      );
    } else if (index == 1) {
      // If "Report" button is tapped (index 1), navigate to the Report page
      Navigator.push(
        context as BuildContext,
        MaterialPageRoute(
            builder: (context) => Report()), // Navigate to ReportPage
      );
    } else if (index == 2) {
      // If "Report" button is tapped (index 1), navigate to the Report page
      Navigator.push(
        context as BuildContext,
        MaterialPageRoute(
            builder: (context) => MonitorPage()), // Navigate to ReportPage
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffc60223),
        title: const Center(
          child: Text(
            "Creat Lost Child Report",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontFamily: 'Bona Nova',
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20.0),
            bottomRight: Radius.circular(20.0),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // link to profile
            },
            icon: const Icon(
              Icons.person,
              color: Colors.white, // Change the color to white
            ),
          ),
        ],
      ),

      //-------------------------------body----------------------------
      body: Center(
          child: Center(
              child: SingleChildScrollView(
        child: Column(children: [
          //button

          //empty space in the top
          const SizedBox(height: 50),

          // Text title
          Container(
            alignment: Alignment.centerLeft, // Align text to the left
            child: const Padding(
              padding: EdgeInsets.only(left: 30.0), // Add left padding
              child: Text(
                'Enter child\'s name*',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: 'Bona Nova',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          //empty space after text
          const SizedBox(height: 10),

          // name textfield
          MyTextField(
            controller: nameController, //nameController
            hintText: 'Name',
            obscureText: false,
          ),
          const SizedBox(height: 10),

          Container(
            alignment: Alignment.centerLeft, // Align text to the left
            child: const Padding(
              padding: EdgeInsets.only(left: 30.0), // Add left padding
              child: Text(
                'Enter child\'s t-shirt color*',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: 'Bona Nova',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          //empty space after text
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.circular(25.0), // Rounded border
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(25.0), // Rounded border
                ),
                fillColor: Colors.grey.shade200,
                filled: true,
              ),
              value: selectedColor,
              items: shirt
                  .map((item) =>
                      DropdownMenuItem<String>(value: item, child: Text(item)))
                  .toList(),
              onChanged: (item) => setState(() => selectedColor = item),
            ),
          ),

          const SizedBox(height: 25),

          //insert pictures
          Container(
            alignment: Alignment.centerLeft, // Align text to the left
            child: const Padding(
              padding: EdgeInsets.only(left: 30.0), // Add left padding
              child: Text(
                'Upload child\'s pictures *(minimum of five pictures)',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: 'Bona Nova',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          FutureBuilder<void>(
            future: retrieveLostData(),
            builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                case ConnectionState.waiting:
                  return const Text(
                    'You have not yet picked an image.',
                    textAlign: TextAlign.center,
                  );
                case ConnectionState.done:
                  return _handlePreview();
                case ConnectionState.active:
                  if (snapshot.hasError) {
                    return Text(
                      'Pick image/video error: ${snapshot.error}}',
                      textAlign: TextAlign.center,
                    );
                  } else {
                    return const Text(
                      'You have not yet picked an image.',
                      textAlign: TextAlign.center,
                    );
                  }
              }
            },
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: FloatingActionButton(
                  onPressed: () {
                    _onImageButtonPressed(ImageSource.gallery,
                        context: context);
                  },
                  heroTag: 'image0',
                  tooltip: 'Pick Image from gallery',
                  child: const Icon(Icons.photo),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: FloatingActionButton(
                  onPressed: () {
                    isVideo = false;
                    _onImageButtonPressed(
                      ImageSource.gallery,
                      context: context,
                      isMultiImage: true,
                    );
                  },
                  heroTag: 'image1',
                  tooltip: 'Pick Multiple Image from gallery',
                  child: const Icon(Icons.photo_library),
                ),
              ),
              if (_picker.supportsImageSource(ImageSource.camera))
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: FloatingActionButton(
                    onPressed: () {
                      isVideo = false;
                      _onImageButtonPressed(ImageSource.camera,
                          context: context);
                    },
                    heroTag: 'image2',
                    tooltip: 'Take a Photo',
                    child: const Icon(Icons.camera_alt),
                  ),
                ),
            ],
          ),
          //empty space after text
          const SizedBox(height: 50),
          //upload last seen location of the child

          Container(
            alignment: Alignment.centerLeft, // Align text to the left
            child: const Padding(
              padding: EdgeInsets.only(left: 30.0), // Add left padding
              child: Text(
                'Select child\'s last seen location',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: 'Bona Nova',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),
          // sign in button
          GestureDetector(
            onTap: () async {
              await submitreport(context);
            },
            child: Container(
              padding: const EdgeInsets.all(15),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(color: Colors.grey),
              child: const Text("Submit Rebort"),
            ),
          ),

          //empty space after text
          const SizedBox(height: 30),
          Text(
            "Select child last know location:",
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 30, width: 20),
          Container(
            width: 300,
            height: 300,
            child: GoogleMap(
              onTap: (LatLng latLng) {
                markersList = [
                  Marker(
                    markerId: MarkerId('Marker'),
                    position: latLng,
                    // infoWindow: InfoWindow(title: 'Business 1'),
                    // icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  ),
                ];
                setState(() {});
              },
              myLocationEnabled: true,
              cameraTargetBounds: boundingbox,
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: mapcenter,
                zoom: 6.0,
              ),
              markers: Set.from(markersList),
              polylines: Set.from(polylineList),
            ),
          ),
        ]),
      ))),

      //-------------------------------end of body----------------------------

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xffc60223), // Color of selected item
        unselectedItemColor: Colors.grey, // Color of unselected item
        selectedLabelStyle: const TextStyle(
            color: Color(0xffc60223)), // Style for selected label
        unselectedLabelStyle:
            const TextStyle(color: Colors.grey), // Style for unselected label
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Report',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.document_scanner_outlined),
            label: 'Monitoring',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Text? _getRetrieveErrorWidget() {
    if (_retrieveDataError != null) {
      final Text result = Text(_retrieveDataError!);
      _retrieveDataError = null;
      return result;
    }
    return null;
  }
}

typedef OnPickImageCallback = void Function(
    double? maxWidth, double? maxHeight, int? quality);

class AspectRatioVideo extends StatefulWidget {
  const AspectRatioVideo(this.controller, {super.key});

  final VideoPlayerController? controller;

  @override
  AspectRatioVideoState createState() => AspectRatioVideoState();
}

class AspectRatioVideoState extends State<AspectRatioVideo> {
  VideoPlayerController? get controller => widget.controller;
  bool initialized = false;

  void _onVideoControllerUpdate() {
    if (!mounted) {
      return;
    }
    if (initialized != controller!.value.isInitialized) {
      initialized = controller!.value.isInitialized;
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    controller!.addListener(_onVideoControllerUpdate);
  }

  @override
  void dispose() {
    controller!.removeListener(_onVideoControllerUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (initialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: controller!.value.aspectRatio,
          child: VideoPlayer(controller!),
        ),
      );
    } else {
      return Container();
    }
  }
}
