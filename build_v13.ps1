cd "c:\Chaitanya\Automation\notes\notely_app_new"
& "C:\Users\chait\flutter\bin\flutter.bat" clean
& "C:\Users\chait\flutter\bin\flutter.bat" pub get
& "C:\Users\chait\flutter\bin\flutter.bat" build appbundle --release
Write-Host "Build completed!" -ForegroundColor Green
