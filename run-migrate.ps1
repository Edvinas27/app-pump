# Run Rails migrations (adds Ruby to PATH if needed)
$rubyPath = "C:\Ruby33-x64\bin"
if (Test-Path $rubyPath) {
    $env:Path = "$rubyPath;$env:Path"
}
Set-Location $PSScriptRoot
bundle exec rails db:migrate
