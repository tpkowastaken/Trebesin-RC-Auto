# Rc Auto Třebešín

Aplikace pro ovládání RC auta.

# Jak to funguje?

- Aplikace komunikuje pomocí bluetooth do modulu HC-05, který je připojen k arduinu.
- Tento modul přijímá příkazy a podle nich ovládá RC auto.

# Jak auto nastavit?

- Ve složce arduino máte k dispozici dva sketche, jeden pro komunikaci s HC-05 modulem - nastavení jména a hesla
- Druhý sketch je pro ovládání auta, ten nahrajte do arduina

# Featury

- Ovladání pomocí tlačítek
- Ovládání pomocí gyroskopu

## Kompilování

Odstraňte klíče originálního autora tím, že přepíšete ['signingConfig signingConfigs.release'](https://github.com/tpkowastaken/Trebesin-RC-Auto/blob/d9893d8529f044708468c7ea1e8bf63dbc0ed8fe/android/app/build.gradle#L69) na `signingConfig signingConfigs.debug`, odstraněním [signing Keys](https://github.com/tpkowastaken/Trebesin-RC-Auto/blob/d9893d8529f044708468c7ea1e8bf63dbc0ed8fe/android/app/build.gradle#L24-L28) a odstraněním [signing Configs](https://github.com/tpkowastaken/Trebesin-RC-Auto/blob/d9893d8529f044708468c7ea1e8bf63dbc0ed8fe/android/app/build.gradle#L59-L66).

Pro systém android stačí mít nainstalovaný [Flutter](https://docs.flutter.dev/get-started/install) a poté `flutter build apk` pro android na windows nebo `flutter build ipa` pro ios na macbooku. Aplikaci na IOS můžete nainstalovat pomocí [tohoto návodu](https://chrunos.com/install-ipa-on-iphone/)
