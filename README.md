# Rc Auto Třebešín

Aplikace pro ovládání RC auta.

# Jak to funguje?

- Aplikace komunikuje pomocí bluetooth do modulu HC-05, který je připojen k arduinu.
- Tento modul přijímá příkazy a podle nich ovládá RC auto.

# Featury

- Ovladání pomocí tlačítek
- Ovládání pomocí gyroskopu

## Kompilování

Odstraňte klíče originálního autora tím, že přepíšete ['signingConfig signingConfigs.release'](https://github.com/tpkowastaken/autojidelna/blob/28096713e958f0e1e4f3cf8e49aaefbeeedbb5f2/android/app/build.gradle#L71-L72) na `signingConfig signingConfigs.debug`, odstraněním [signing Keys](https://github.com/tpkowastaken/autojidelna/blob/5d0587befd74fd58315ccc131894feb8588b09fe/android/app/build.gradle#L27-L31) a odstraněním [signing Configs](https://github.com/tpkowastaken/autojidelna/blob/5d0587befd74fd58315ccc131894feb8588b09fe/android/app/build.gradle#L60-L67).

Pro systém android stačí mít nainstalovaný [Flutter](https://docs.flutter.dev/get-started/install) a poté `flutter build apk` pro android na windows nebo `flutter build ipa` pro ios na macbooku. Aplikaci na IOS můžete nainstalovat pomocí [tohoto návodu](https://chrunos.com/install-ipa-on-iphone/)
