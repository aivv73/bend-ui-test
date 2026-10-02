# Bend UI test

Библиотека отправляет клавиши, клики и запрос закрытия в окно вашего форка Bend по `WindowRef`.
Ссылка получается через `Window.export_ref`. Владелец `Window` остаётся у приложения.

```python
import Base
import ./uitest.bend as UITest

def drive(+ref: WindowRef) -> IO(Unit):
  do IO<Unit>:
    keyed : Unit <- IO.try(Unit, UITest.key(ref, 97))
    clicked : Unit <- IO.try(Unit, UITest.click(ref, 24, 18))
    closing : Unit <- IO.try(Unit, UITest.request_close(ref))
    alive : Bool <- IO.try(Bool, UITest.alive(ref))
    IO.print(Bool.show(alive))
```

`97` соответствует `a`. Каждый вызов `key` и `click` отправляет нажатие и отпускание.
`request_close` передаёт приложению `Close{}`. Приложение само закрывает свой `Window`.
После успешной отправки приложение обрабатывает события через `Window.frame`.

## Запустить пример

Нужен [форк aivv73/bend](https://github.com/aivv73/bend) с `WindowRef`, `Window.export_ref` и `Window.capture`.
Также нужны Bun, Clang и заголовки libX11. Окна работают в native Linux с X11 или Xwayland.

Если checkout форка находится в соседней папке `../bend`, команды запускаются сразу.
Для другого расположения задайте `BEND_ROOT`.

```bash
export BEND_ROOT=/absolute/path/to/bend
mkdir -p .build
./scripts/bend examples/smoke.bend -o .build/smoke
./.build/smoke
```

Пример открывает окно, отправляет события и закрывает его. Ожидаемый вывод `UITest smoke: OK`.
Если форк уже установлен как исполняемый `bend`, задайте `BEND_BIN=/absolute/path/to/bend`.
Обычный установленный Bend без `WindowRef` не подходит.

## Проверить библиотеку

```bash
./scripts/test
```

При наличии Xvfb скрипт создаёт отдельный виртуальный дисплей.
Иначе он использует `DISPLAY`. Можно задать путь к Xvfb через `XVFB_BIN`.
Для проверок без окон используйте `./scripts/test --no-window`.

Полный прогон проверяет три закона с `--verdict`, JavaScript в Bun и Node, отдельную сборку каждой операции и реальные события двух окон.
Тест клавиш перебирает все коды текущей раскладки через настоящий декодер форка.
Тест также проверяет `Window.capture`, границы кликов, кооперативное закрытие и устаревшие ссылки.
Для проверки памяти запустите `SANITIZE=1 ./scripts/test`. Этот режим включает AddressSanitizer и UndefinedBehaviorSanitizer.

Подробные типы, коды ошибок и ограничения описаны в [справочнике API](docs/api.md).
Выбор реализации и граница доказательств описаны в [описании устройства](docs/design.md).
