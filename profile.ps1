oh-my-posh init pwsh --config "C:\Users\legion\AppData\Local\Programs\oh-my-posh\themes\mckrei.json"| Invoke-Expression
function ipy { python -m IPython $args}

function py { python $args }


function run_uvicorn { uvicorn main:app --port 4422 --reload }


# Определение словаря проектов
$projects = @{
    "WB" = @{
        "reporter" = @{
            "path" = "C:\Users\legion\projects\wb\reporter"
            "alias" = "reporter"
            "server" = @{
                "path" = "/home/api_reports"
                "ip" = "10.20.202.132"
            }
        }
        "datastore" = @{
            "path" = "C:\Users\legion\projects\wb\datastore"
            "alias" = "datastore"
        }
        "solver_search_hub" = @{
            "path" = "C:\Users\legion\projects\wb\solver_search_hub"
            "alias" = "solver"
            "server" = @{
                "path" = "/root/solver_search_hub"
                "ip" = "10.20.202.132"
            }
        }
        "wb_alerts_bot" = @{
            "path" = "C:\Users\legion\projects\wb\wb_alerts_bot"
            "alias" = "wb_alerts_bot"
            "server" = @{
                "path" = "/home/www/alert_bot"
                "ip" = "23.26.248.188"
            }
        }
        "wb_other" = @{
            "path" = "C:\Users\legion\projects\wb\other"
            "alias" = "wb_other"
        }
    }
    "monta" = @{
        "admin" = @{
            "path" = "C:\Users\legion\projects\monta\monta-admin"
            "alias" = "admin"
            "server" = @{
                "path" = "/home/mckrei/projects/monta-admin"
                "ip" = "188.132.197.33"
            }
        }
        "planfact" = @{
            "path" = "C:\Users\legion\projects\monta\planfact"
            "alias" = "pf"
        }
        "monta_other" = @{
            "path" = "C:\Users\legion\projects\monta\brack"
            "alias" = "monta_other"
        }
    }
    "my" = @{
        "lvlup_project_one" = @{
            "path" = "C:\Users\legion\projects\lvlup1"
            "alias" = "lvlup_p1"
        }
        "lvlup_data" = @{
            "path" = "C:\Users\legion\Desktop\lvlup"
            "alias" = "lvlup_data"
        }
        "supwb" = @{
            "path" = "C:\Users\legion\projects\supwb"
            "alias" = "supwb"
        }
        "powershell" = @{
            "path" = "C:\Users\legion\projects\MY PKG\power shell"
            "alias" = "powershell"
        }
    }
}
function project {
    param(
        [string]$command,
        [string]$alias,
        [switch]$r,
        [switch]$h
    )
    if ($h -or $command -eq "") {
        # Вывод справки по доступным командам
        Write-Host "Доступные команды для управления проектами:"
        Write-Host "  ls - Вывод списка всех проектов с информацией о сервере, если доступна."
        Write-Host "  update - Выводит исходный код приложения, где можно добавить новый проект"
        Write-Host "  cd <alias> - Смена текущего каталога на каталог указанного проекта."
        Write-Host "  code <alias> [-r] - Открытие проекта в VS Code." "Флаг -r для подключения к серверу."
        Write-Host "  -h - Вывод этой справки."
        return
    }
    switch ($command) {
        "update" {
            code $PROFILE
        }
        "cd" {
            # Смена текущего каталога на каталог указанного проекта
            $found = $false
            foreach ($domain in $projects.Keys) {
                foreach ($project in $projects[$domain].Values) {
                    if ($project.alias -eq $alias) {
                        Set-Location $project.path
                        $found = $true
                        break
                    }
                }
                if ($found) { break }
            }
            if (-not $found) {
                Write-Host "Проект с алиасом '$alias' не найден."
            }
        }

        "ls" {
            # Вывод списка проектов с информацией о сервере, если есть
            $projects.Keys | ForEach-Object {
                $domain = $_
                Write-Host "${domain}:"
                $projects[$domain].Keys | ForEach-Object {
                    $project = $projects[$domain][$_]
                    if ($project.server) {
                        $serverInfo = " (IP: $($project.server.ip) Path: $($project.server.path))"
                    } else {
                        $serverInfo = ""
                    }
                    Write-Host "  $_ ($($project.alias))$serverInfo"
                }
            }
        }
        "code" {
            # Открытие проекта в VS Code, подключение к серверу если указан флаг -r
            $found = $false
            foreach ($domain in $projects.Keys) {
                foreach ($project in $projects[$domain].Values) {
                    if ($project.alias -eq $alias) {
                        if ($r -and $project.server) {
                            # Если указан флаг -r и доступна информация о сервере
                            $sshRemote = "ssh-remote+"
                            $remoteHost = $project.server.ip
                            $remotePath = $project.server.path
                            $fullRemotePath = "$sshRemote$remoteHost $remotePath"
                            $command = "code --remote " + $fullRemotePath
                            Invoke-Expression $command

                            # Start-Process "code" -ArgumentList "--remote", $fullRemotePath
                        } elseif ($r -and -not $project.server) {
                            # Если указан флаг -r, но информация о сервере отсутствует
                            Write-Host "Настройки сервера для проекта с алиасом '$alias' не найдены."
                        } else {
                            # Если флаг -r не указан
                            code $project.path
                        }
                        $found = $true
                        break
                    }
                }
                if ($found) { break }
            }
            if (-not $found) {
                Write-Host "Проект с алиасом '$alias' не найден."
            }
        }
        default {
            Write-Host "Неподдерживаемая команда. Используйте 'ls', 'cd' или 'code'."
        }
    }
}

# Регистрация автодополнения для алиасов проектов
Register-ArgumentCompleter -CommandName project -ParameterName alias -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    # Собираем все алиасы проектов в один список
    $aliases = @()
    $projects.Values | ForEach-Object {
        $_.Values | ForEach-Object {
            $aliases += $_.alias
        }
    }

    # Фильтруем алиасы, которые начинаются с введенного текста
    $aliases | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        # Возвращаем результаты для автодополнения
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
