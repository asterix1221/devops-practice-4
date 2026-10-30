# Практическая работа № 4 — DevOps / Jenkins / CI/CD

Проект подготовлен по методичке «Практики DevOps в современных методологиях разработки». Основной файл `Jenkinsfile` реализует усложнённый вариант: реальная сборка Docker-образа Flask, модульные тесты, проверка запущенного контейнера, развёртывание в staging, ручное подтверждение и развёртывание в production. `Jenkinsfile.basic` реализует основной учебный вариант с имитацией сборки, теста и deploy.

> Важно: проектные файлы подготовлены, но успешный запуск Jenkins/Docker должен быть подтверждён на компьютере пользователя. Для сдачи следует приложить реальные скриншоты запуска, а не выдуманные изображения.

## Что нужно установить

1. **Docker Desktop for Windows**: <https://docs.docker.com/desktop/setup/install/windows-install/>. Для этого проекта используй Linux containers и WSL 2 backend.
2. **Git for Windows**: <https://git-scm.com/download/win>.
3. **Zed**: <https://zed.dev/> (если уже установлен, скачивать заново не нужно).
4. Учетная запись GitHub: <https://github.com/>.

Отдельно устанавливать Java и Python в Windows не требуется: Jenkins запускается в контейнере с Java, приложение и его тесты — в контейнере Python.

## 1. Открой проект в Zed

Распакуй архив и открой папку `Практика4_DevOps` в Zed. Файлы `Jenkinsfile`, `Jenkinsfile.basic`, `deploy` и `smoke-tests` должны быть сохранены с окончаниями строк LF. Файл `Jenkinsfile` не должен иметь расширения `.txt`.

## 2. Сначала проверь Flask-приложение локально в Docker

Запусти Docker Desktop и дождись, пока он будет готов. Открой PowerShell 7 в корне проекта и выполни:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\Test-Local.ps1
```

Команда собирает образ, запускает два модульных теста, поднимает временный контейнер и проверяет `/health` на `http://127.0.0.1:18083/health`. В конце временный контейнер удаляется.

## 3. Создай репозиторий GitHub

1. Открой <https://github.com/new>.
2. Назови репозиторий, например `devops-practice-4`, выбери `Public`.
3. Создай пустой репозиторий без README/license/gitignore, потому что файлы уже есть локально.
4. В PowerShell в корне проекта выполни команды ниже, заменив `USERNAME` на свой логин GitHub:

```powershell
git --version
git init -b main
git add .
git commit -m "Complete DevOps practice 4"
git remote add origin https://github.com/USERNAME/devops-practice-4.git
git push -u origin main
```

Если Git ранее не настраивался, задай имя и email коммитов:

```powershell
git config --global user.name "Твоё имя"
git config --global user.email "твой-email@example.com"
```

Убедись, что `Jenkinsfile`, `Jenkinsfile.basic`, `Dockerfile`, `app.py`, `requirements.txt` и `tests/test_app.py` отображаются на GitHub.

## 4. Запусти Jenkins и Docker daemon через Compose

В корне проекта выполни:

```powershell
docker version
docker info --format '{{.OSType}}'
docker compose config --quiet
docker compose up -d --build
```

Вторая команда должна вывести `linux`. Команда `docker compose up -d --build` создаёт Jenkins, отдельный Docker daemon для сборки образов и нужные тома. Первый запуск скачает базовые образы и может занять некоторое время.

Проверь состояние контейнеров:

```powershell
docker compose ps
docker compose logs --tail 80 jenkins
docker compose logs --tail 80 docker
```

Открой <http://localhost:8080>. Если Jenkins запрашивает первоначальный пароль, получи его командой:

```powershell
docker compose exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Выбери `Install suggested plugins`, создай администратора и закончи первоначальную настройку.

## 5. Настрой Pipeline в Jenkins

1. На главной странице нажми **New Item**.
2. Название: `pr4-devops-ci-cd`.
3. Тип: **Pipeline**; нажми **OK**.
4. В разделе **Pipeline** выбери:
   - **Definition**: `Pipeline script from SCM`;
   - **SCM**: `Git`;
   - **Repository URL**: `https://github.com/USERNAME/devops-practice-4.git`;
   - **Credentials**: пусто для публичного репозитория;
   - **Branch Specifier**: `*/main`;
   - **Script Path**: `Jenkinsfile`.
5. Нажми **Save**, затем **Build Now**.

Если преподаватель требует только упрощённый вариант из методички, в `Script Path` укажи `Jenkinsfile.basic` вместо `Jenkinsfile`.

## 6. Что делает усложнённый Pipeline

1. `Build Docker image`: собирает образ Flask-приложения с тегом по номеру сборки.
2. `Unit tests`: запускает `unittest` внутри собранного образа и проверяет ответы `/` и `/health`.
3. `Test running container`: стартует временный контейнер и проверяет HTTP endpoint `/health`; затем временный контейнер удаляется.
4. `Deploy to Staging`: запускает контейнер `pr4-flask-staging` и проверяет его доступность.
5. `Approve Production`: ожидает ручного подтверждения в интерфейсе Jenkins.
6. `Deploy to Production`: после подтверждения запускает production-контейнер и проверяет `/health`.

На этапе `Approve Production` сборка намеренно остановится в ожидании действия. Открой соответствующую сборку и выбери **Proceed**. Для отказа используется **Abort**.

После успешного выполнения проверь:

- приложение staging: <http://localhost:18080/>;
- состояние staging: <http://localhost:18080/health>;
- приложение production: <http://localhost:18082/>;
- состояние production: <http://localhost:18082/health>.

Ожидаемый ответ endpoint `/health`: JSON `{"status":"ok"}`.

## 7. Упрощённый Pipeline

`Jenkinsfile.basic` соответствует варианту задания с имитацией CI/CD. Он проверяет наличие файлов, выполняет `smoke-tests`, запускает `deploy staging`, ждёт ручного подтверждения и запускает `deploy production`. Сами `deploy`-скрипты печатают сообщения; они не создают реальный сервер. Это соответствует основной формулировке методички, где требуется имитировать сборку из GitHub.

## 8. Полезные команды PowerShell

```powershell
# Проверить доступность Docker
docker version
docker info --format '{{.OSType}}'

# Статус и журналы
docker compose ps
docker compose logs -f jenkins
docker compose logs -f docker

# Проверить контейнеры приложения во внутреннем Docker daemon
docker compose exec jenkins docker ps

# Остановить сервисы, сохранив данные в именованных томах
docker compose down

# Повторно запустить
# docker compose up -d
```

Не используй `docker compose down -v`, если хочешь сохранить Jenkins jobs и историю: ключ `-v` удалит тома с данными.

## 9. Типовые ошибки

- **Jenkins не находит ревизию**: проверь, что код действительно отправлен в GitHub, ветка называется `main`, а `Branch Specifier` равен `*/main`.
- **`bash\r: No such file or directory`**: у shell-файлов CRLF. Сохрани их с LF и сделай commit/push.
- **`docker: command not found` в Jenkins**: проверь, что Jenkins был создан из `Dockerfile.jenkins-docker`, затем пересобери: `docker compose up -d --build`.
- **Docker daemon недоступен**: смотри `docker compose logs docker` и `docker compose logs jenkins`; сервис `docker` должен иметь статус `healthy`.
- **Порт занят**: освободи порт `8080`, `18080` или `18082`, либо поменяй маппинг в `compose.yaml` и соответствующий URL в Pipeline.
- **Сборка ждёт слишком долго**: это ожидаемо на этапе `Approve Production`; нужно выбрать `Proceed`.

## 10. Что заскринить для отчёта

1. Файлы проекта в GitHub.
2. Конфигурация Jenkins Job: Git URL, `*/main`, Script Path.
3. Pipeline view после успешного завершения со статусом `SUCCESS`.
4. `Console Output`, где видны Docker build, тесты, staging и production.
5. Момент `Approve Production` и продолжение после `Proceed`.
6. Открытые staging и production URL.

Не вставляй в отчёт фальшивые скриншоты или несуществующий статус `SUCCESS`: сделай реальные скриншоты после запуска на своём компьютере.

## Официальные источники

- Jenkins: установка в Docker — <https://www.jenkins.io/doc/book/installing/docker/>.
- Jenkins Pipeline — <https://www.jenkins.io/doc/book/pipeline/getting-started/>.
- Docker Desktop для Windows — <https://docs.docker.com/desktop/setup/install/windows-install/>.
- GitHub: создание репозитория — <https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-new-repository>.
- Flask: установка и требования — <https://flask.palletsprojects.com/en/stable/installation/>.
- Flask 3.1.3 на PyPI — <https://pypi.org/project/Flask/3.1.3/>.
