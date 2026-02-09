# How to Add Firebase to Your Project

You have all the code ready, but you need to connect this app to your Firebase project online. Follow these steps:

## Step 1: Install Firebase Tools (If not installed)
Open your terminal and run:
```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

## Step 2: Login to Firebase
```bash
firebase login
```

## Step 3: Configure the App
Run this command in your project folder (I have found your project ID: `mss-dc20b`):
```bash
flutterfire configure --project=mss-dc20b --platforms=android,ios
```

1.  Use the arrow keys to select your Firebase project.
2.  Press **Enter**.
3.  Use the arrow keys and Spacebar to select platforms (Android, iOS).
4.  Press **Enter**.

This will automatically generate a file called `lib/firebase_options.dart`.

## Step 4: Run the App
Once `firebase_options.dart` is created, you can run the app:
```bash
flutter run
```
