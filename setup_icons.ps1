$apps = @(
    @{ Path="zudo_b2c"; Color="#2D5A27" },
    @{ Path="zudo_b2b"; Color="#E65100" },
    @{ Path="zudo_delivery"; Color="#283593" }
)

foreach ($app in $apps) {
    $dir = $app.Path
    $color = $app.Color
    
    # Copy logo
    if (!(Test-Path "$dir\assets")) { New-Item -ItemType Directory -Force -Path "$dir\assets" | Out-Null }
    Copy-Item "logo_transparent.png" -Destination "$dir\assets\logo_transparent.png" -Force
    
    if (!(Test-Path "$dir\android\app\src\main\res\drawable")) { New-Item -ItemType Directory -Force -Path "$dir\android\app\src\main\res\drawable" | Out-Null }
    Copy-Item "logo_transparent.png" -Destination "$dir\android\app\src\main\res\drawable\ic_notification.png" -Force

    # Update pubspec.yaml
    $pubspecPath = "$dir\pubspec.yaml"
    $pubspec = Get-Content $pubspecPath -Raw
    
    if ($pubspec -notmatch "flutter_launcher_icons:") {
        $pubspec = $pubspec -replace "dev_dependencies:", "dev_dependencies:`n  flutter_launcher_icons: ^0.13.1"
        $pubspec += "`nflutter_launcher_icons:`n  android: `"launcher_icon`"`n  ios: true`n  image_path: `"assets/logo_transparent.png`"`n  adaptive_icon_background: `"$color`"`n  adaptive_icon_foreground: `"assets/logo_transparent.png`"`n"
        Set-Content -Path $pubspecPath -Value $pubspec
    }

    # Update AndroidManifest.xml
    $manifestPath = "$dir\android\app\src\main\AndroidManifest.xml"
    if (Test-Path $manifestPath) {
        $manifest = Get-Content $manifestPath -Raw
        if ($manifest -notmatch "default_notification_icon") {
            $metaData = "<meta-data android:name=`"com.google.firebase.messaging.default_notification_icon`" android:resource=`"@drawable/ic_notification`" />`n        <activity"
            $manifest = $manifest -replace "<activity", $metaData
            Set-Content -Path $manifestPath -Value $manifest
        }
    }
}
