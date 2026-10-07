# AyuGram iOS — план порта

Основано на публичном коде AyuGram4A (`com.radolyn.ayugram`, последний коммит в публичном репо — июль 2023)
и Telegram-iOS (app 12.9.2, Xcode 26.2, Bazel 8.4.2). Если у команды есть более свежий внутренний код
Android — сверить список фич с ним.

## Что делает AyuGram на Android (≈5 тыс. строк своего кода)

| Модуль | Что делает | Куда встроен в Telegram |
|---|---|---|
| `AyuConfig` | все настройки (SharedPreferences `ayuconfig`) | везде |
| Ghost-хук | блокирует/подменяет запросы перед отправкой | `ConnectionsManager.sendRequestInternal` |
| `AyuGhostUtils`, `AyuState` | ручное «прочитать», разовые разрешения | `ConnectionsManager`, `ChatActivity` |
| `AyuMessagesController` + Room DB | сохраняет удалённые и все ревизии правок (+медиа) | `MessagesController` (updates), `MessagesStorage`, `SecretChatHelper` |
| `AyuMessageHistory`, `AyuMessageCell` | экран истории правок, пометки «удалено/изменено» | `ChatActivity`, `ChatMessageCell` |
| `AyuFilter` | regex-фильтры сообщений (скрыть рекламу) | `ChatActivity`, `DialogCell` |
| `AyuSyncController` | синхронизация прочтений/истории через свой сервер (WebSocket) | `ConnectionsManager` |
| Настройки UI | `AyuGramPreferencesActivity` и др. | `LaunchActivity`, `DrawerLayoutAdapter` |

Ghost mode на Android — это 4 флага: `sendReadPackets`, `sendOnlinePackets`, `sendUploadProgress`,
`sendOfflinePacketAfterOnline` (+ `markReadAfterSend`, `useScheduledMessages`).

## Где то же самое в Telegram-iOS

| Фича | Android | iOS (`submodules/TelegramCore/Sources/…`) |
|---|---|---|
| Единая точка запросов | `ConnectionsManager.sendRequestInternal` | `Network/Network.swift` → `Network.request(_:)` (стр. ~1158) |
| «Прочитано» | `messages.readHistory`, `channels.readHistory` | `State/SynchronizePeerReadState.swift` (стр. ~254, ~284) |
| Прочие read-запросы | `readMessageContents`, `readDiscussion`, `readEncryptedHistory` | `TelegramEngine/Messages/ApplyMaxReadIndexInteractively.swift`, `ReplyThreadHistory.swift`, `State/ManagedSynchronizeConsumeMessageContentsOperations.swift`, `State/ManagedConsumePersonalMessagesActions.swift` |
| Онлайн | `account.updateStatus` | `State/ManagedAccountPresence.swift` → `updatePresence(_:)` |
| «Печатает…» | `messages.setTyping` | `State/ManagedLocalInputActivities.swift` (стр. ~184, ~193) |
| Удаление сообщений | `MessagesController` (~стр. 15190) | `State/AccountStateManagementUtils.swift`: `case .DeleteMessages` / `.DeleteMessagesWithGlobalIds` (стр. ~4442) — **до** `_internal_deleteMessages` сообщение ещё в Postbox, его можно прочитать `transaction.getMessage(id)` |
| Правки | `MessagesStorage` (~стр. 13546) | там же: `case .EditMessage(id, message)` (стр. ~4488), `previousMessage` доступен внутри `transaction.updateMessage` |
| Хранилище | Room (SQLite) | отдельная SQLite в app group или свой namespace в Postbox |
| Настройки UI | `AyuGramPreferencesActivity` | `submodules/SettingsUI` (ItemListController) |

На iOS лучше перехватывать не в `Network.request` целиком (там уже сериализованный `Buffer`), а в
конкретных местах выше — их немного, и так проще поддерживать при мерже апстрима.

## Порядок работ

**Этап 0 — сборка и тестовый контур (сейчас)**
1. Форк Telegram-iOS → репо AyuGram iOS, отдельный `api_id` для iOS.
2. Применить `patches/0001-app-group-fallback.patch` (без него переподписанный Sauce Labs билд
   падает на старте с «Error 2», см. `AppDelegate.swift`, проверка `maybeAppGroupUrl`).
3. Положить `codemagic.yaml` в корень, завести группы переменных `telegram_api`, `saucelabs`.
4. Первый зелёный билд → IPA в Sauce Labs → логин и отправка сообщения на реальном устройстве.

**Этап 1 — MVP (то, ради чего ставят AyuGram)** — `patches/0002-ghost-mode-and-deleted-messages.patch`
1. ✅ `AyuSettings` (`TelegramCore/Sources/Ayu/AyuSettings.swift`) — те же ключи и дефолты, что на Android.
2. ✅ Ghost mode: read / typing — общий перехват в `Network.request` и `requestWithAdditionalInfo`
   (`Ayu/AyuGhost.swift`); online — `ManagedAccountPresence`; «оффлайн после отправки».
   ⏳ `markReadAfterSend` и кнопка «прочитать» вручную — ещё нет.
3. ✅ Удалённые сообщения не стираются из Postbox, а помечаются `AyuDeletedMessageAttribute`
   (`Ayu/AyuDeletedMessages.swift`, хук в `replayFinalState`), в чате — 🧹 перед временем.
4. ✅ Экран «AyuGram» в Настройках (`SettingsUI/Sources/AyuGramSettingsController.swift`), строки пока
   на английском без локализации.

**Этап 2**
- история правок + экран ревизий; сохранение медиа удалённых сообщений (с настройками по типам чатов);
- regex-фильтры; локальный Premium; кнопка «прочитать» в ghost-режиме.

**Этап 3**
- AyuSync (тот же протокол, что на Android/Desktop), экспорт, брендинг, иконка.

## Чек-лист для Sauce Labs (каждый билд)

- [ ] приложение запускается (нет «Error 2»), логин по номеру проходит
- [ ] отправка/получение сообщений, медиа, push (push после переподписи может не работать — это ожидаемо)
- [ ] ghost on: у собеседника нет «прочитано», «онлайн», «печатает»
- [ ] ghost off: всё как в обычном Telegram
- [ ] собеседник удаляет сообщение → оно остаётся с пометкой
- [ ] собеседник редактирует → видна история

## Известные риски

- Sauce Labs переподписывает IPA своими профилями: App Groups, push, iCloud, Siri могут не работать.
  Патч из этапа 0 закрывает запуск; расширения (виджет, share, notification service) работать не будут.
- Билд с fake-codesigning использует bundle id `ph.telegra.Telegraph` — только для тестов. Для релиза
  нужен свой bundle id и Apple Developer аккаунт.
- Чистая сборка Telegram на Mac mini M2 долгая (порядка часа и больше), кэш Bazel ускоряет повторные.
- Ghost mode и сохранение самоуничтожающихся сообщений нарушают API ToS Telegram → только сайдлоад,
  риск блокировки `api_id`.
