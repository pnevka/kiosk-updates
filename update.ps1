# Скрипт обновления для киоска КДЦ Тимоново
# Запускать от имени администратора!

$version = "1.0.1"
$downloadUrl = "https://github.com/pnevka/kiosk-updates/releases/download/v$version/kiosk-v$version.zip"
$installPath = "C:\kiosk-updates"
$tempPath = "$env:TEMP\kiosk-update"

Write-Host "=== Обновление киоска до версии $version ===" -ForegroundColor Green

# Останавливаем приложение
Write-Host "Остановка приложения..." -ForegroundColor Yellow
Stop-Process -Name "kiosk" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Создаем временную папку
Write-Host "Загрузка обновления..." -ForegroundColor Yellow
if (Test-Path $tempPath) {
    Remove-Item $tempPath -Recurse -Force
}
New-Item -ItemType Directory -Path $tempPath | Out-Null

# Скачиваем обновление
$zipFile = "$tempPath\kiosk-update.zip"
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile

# Распаковываем
Write-Host "Распаковка..." -ForegroundColor Yellow
Expand-Archive -Path $zipFile -DestinationPath $tempPath -Force

# Копируем файлы
Write-Host "Копирование файлов..." -ForegroundColor Yellow
Copy-Item -Path "$tempPath\*" -Destination $installPath -Recurse -Force

# Очищаем
Remove-Item $tempPath -Recurse -Force
Remove-Item $zipFile -Force

Write-Host "Обновление завершено!" -ForegroundColor Green
Write-Host "Приложение будет перезапущено..." -ForegroundColor Green
Start-Sleep -Seconds 2

# Запускаем обновленное приложение
Start-Process "$installPath\kiosk.exe"
