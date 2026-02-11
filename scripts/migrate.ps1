$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot
$compose = Join-Path $root "docker/docker-compose.yml"

# ensure docker is reachable
docker info | Out-Null

$files = Get-ChildItem -Path (Join-Path $root "migrations") -Filter "*.sql" | Sort-Object Name

foreach ($f in $files) {
  Write-Host "==> Applying $($f.Name)"

  docker compose -f $compose exec -T postgres `
    psql -U postgres -d instagram -v ON_ERROR_STOP=1 -f "/migrations/$($f.Name)"

  if ($LASTEXITCODE -ne 0) { throw "❌ Failed applying $($f.Name)" }
}

Write-Host "✅ All migrations applied."
