# Start Rails server for App Pump
$env:Path = "C:\Ruby33-x64\bin;" + $env:Path
$env:DATABASE_URL = "postgres://postgres:admin@127.0.0.1:5432/app_pump_dev"
Set-Location $PSScriptRoot
Write-Host "Starting Rails server..."
Write-Host "Open http://127.0.0.1:3000 or http://localhost:3000 in your browser"
Write-Host "Press Ctrl+C to stop"
bundle exec rails s -b 0.0.0.0
