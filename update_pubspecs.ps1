$apps = @("zudo_b2c", "zudo_b2b", "zudo_delivery")
foreach ($app in $apps) {
    $pubspecPath = "$app\pubspec.yaml"
    if (Test-Path $pubspecPath) {
        $content = Get-Content $pubspecPath -Raw
        $content = $content -replace 'image_path: "assets/logo_transparent.png"', 'image_path: "assets/app_icon_generated.png"'
        $content = $content -replace 'adaptive_icon_background: "#[0-9A-Fa-f]{6}"', 'adaptive_icon_background: "assets/bg_generated.png"'
        $content = $content -replace 'adaptive_icon_foreground: "assets/logo_transparent.png"', 'adaptive_icon_foreground: "assets/fg_generated.png"'
        Set-Content -Path $pubspecPath -Value $content
    }
}
