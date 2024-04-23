import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveScope,
    ],
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _handleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        final authHeaders = await googleUser.authHeaders;
        final authenticateClient = GoogleAuthClient(authHeaders);
        final driveApi = drive.DriveApi(authenticateClient);

        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => MainScreen(driveApi: driveApi),
        ));
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error signing in: $error'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Google Sign-In")),
      body: Center(
        child: ElevatedButton(
          onPressed: _handleSignIn,
          child: Text("Sign in with Google"),
        ),
      ),
    );
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class MainScreen extends StatelessWidget {
  final drive.DriveApi driveApi;

  MainScreen({required this.driveApi});

  Future<void> _seeFiles() async {
    final result = await driveApi.files.list();
    for (var file in result.files!) {
      print(file.name);
    }
  }

  Future<void> _uploadFiles() async {
    final file = drive.File();
    file.name = 'my_file.txt';
    final content = 'Hello, world!';
    final media = http.ByteStream.fromBytes(content.codeUnits);
    await driveApi.files.create(
      file,
      uploadMedia: drive.Media(media, content.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Main Screen"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _seeFiles,
              child: Text("See Files"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadFiles,
              child: Text("Upload Files"),
            ),
          ],
        ),
      ),
    );
  }
}