# Configuring HC-05

- nahrajte daný sketch do Arduino
- otevřte sériovou konzoli s rychlostí 9600
- jako sériovou konzoli můžete zvolit např. [Putty](https://www.putty.org/), [Termite](https://www.compuphase.com/software_termite.htm) nebo [Arduino IDE](https://www.arduino.cc/en/software) nebo [tera term](https://robotics.stackexchange.com/questions/2056/bluetooth-module-hc-05-giving-error-0#answer-3072)
- ve vaší konzoli nastavte cr-lf (carriage return - line feed) a 9600 baudů a local echo
- vložte příkaz `AT` a odešlete pro zkontrolování komunikace
- vložte příkaz `AT+NAME=[nové jméno zařízení bez diakritiky a mezer]` a odešlete pro změnu jména zařízení
- vložte příkaz `AT+PSWD=[nové heslo]` a odešlete pro změnu hesla
- změny můžete zkontrolovat příkazem `AT+NAME?` a `AT+PSWD?`

- [více info](./HC-0305_serial_module_AT_commamd_set_201104_revised.pdf)
