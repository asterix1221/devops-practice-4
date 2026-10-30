$ErrorActionPreference = 'Stop'

function Invoke-DockerChecked {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$DockerArgs
    )

    & docker @DockerArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Команда docker завершилась с кодом ${LASTEXITCODE}: docker $($DockerArgs -join ' ')"
    }
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw 'Docker CLI не найден. Установи и запусти Docker Desktop, затем повтори команду.'
}

Invoke-DockerChecked -DockerArgs @('version')
$engineType = (& docker info --format '{{.OSType}}').Trim()
if ($LASTEXITCODE -ne 0 -or $engineType -ne 'linux') {
    throw 'Docker daemon недоступен или не использует Linux-контейнеры. Запусти Docker Desktop и включи Linux containers.'
}

$image = 'devops-pr4-flask:local-check'
$container = 'pr4-flask-local-check'
Invoke-DockerChecked -DockerArgs @('build', '--pull', '-t', $image, '.')
Invoke-DockerChecked -DockerArgs @('run', '--rm', '--entrypoint', 'python', $image, '-m', 'unittest', 'discover', '-s', 'tests', '-v')

& docker rm -f $container 2>$null | Out-Null
try {
    Invoke-DockerChecked -DockerArgs @('run', '-d', '--name', $container, '-p', '127.0.0.1:18083:5000', $image)
    $healthy = $false
    for ($attempt = 1; $attempt -le 30; $attempt++) {
        try {
            $response = Invoke-RestMethod -Uri 'http://127.0.0.1:18083/health' -TimeoutSec 3
            if ($response.status -eq 'ok') {
                $healthy = $true
                break
            }
        }
        catch {
            # The container may still be starting; retry below.
        }
        Start-Sleep -Seconds 2
    }

    if (-not $healthy) {
        & docker logs $container
        throw 'Контейнер не прошёл HTTP-проверку /health.'
    }

    Write-Host 'Проверка пройдена: модульные тесты успешны, endpoint /health вернул status=ok.' -ForegroundColor Green
}
finally {
    & docker rm -f $container 2>$null | Out-Null
}
