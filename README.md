## Разработка процессорной системы с архитектурой RISC-V в рамках курса лабораторных работ по дисциплине «Архитектура процессорных систем»

Используя SystemVerilog на основе FPGA с нуля, последовательно, создавалась [система](https://github.com/l1sok/APS_RV/blob/main/riscv_unit.sv), под управлением однотактного процессора с архитектурой RISC-V, поддерживающего набор инструкций RV32I, управляющего периферийными устройствами и программируемого на языке высокого уровня C++. Использовалась отладочная плата Nexys A7.

![](https://github.com/l1sok/APS_RV/blob/main/fig_04.drawio.png)


## Этапы разработки:


<details>
<summary> АЛУ </summary>

 
 Разработка [АЛУ](https://github.com/l1sok/APS_RV/tree/main/ALU) на основе мультиплексора. Содержит 7 используемых операций.
 </details>
 
<details>
<summary> Память </summary>
 
 Созданы элементы [памяти](https://github.com/l1sok/APS_RV/blob/main/memory) для будущего процессора: память команд, память данных и регистровый файл.
  </details>
  
<details>
<summary> Простейшее программируемое устройство </summary>
   
Для более грубокого погружение в процесс разработано [простейшее программируемое устройство](https://github.com/l1sok/APS_RV/blob/main/CYBERcobra.sv) и написана программа на машинном коде для нее.
![image](https://github.com/user-attachments/assets/d5029942-d42d-460d-be29-9676e41a2fc7)

</details> 
<details>
<summary> Декодер инструкций </summary>
 
Разработано управляющее устройство - [декодер](https://github.com/l1sok/APS_RV/tree/main/decoder), поддерживающее RV32I - стандартный набор целочисленных инструкций RISC-V.
</details>

<details>
<summary> Тракт данных </summary>
 
Объединение готовых модулей АЛУ, декодера, регистрового файла, памяти инструкций и [основной памяти](https://github.com/l1sok/APS_RV/blob/main/memory/data_mem.sv) в [ядро](https://github.com/l1sok/APS_RV/blob/main/riscv_core.sv). Также разработан и интегрирован в ядро [Модуль загрузки и сохранения](https://github.com/l1sok/APS_RV/blob/main/riscv_lsu.sv) для корректного выполнения инструкций с загрузкой и сохранением данных.
 </details>
 
<details>
<summary> Подсистема прерываний </summary>
 
  Разработан [контроллер прерываний](https://github.com/l1sok/APS_RV/blob/main/interrupt/interrupt_controller.sv), который поддерживает [приоритетные прерывания](https://github.com/l1sok/APS_RV/blob/main/interrupt/daisy_chain.sv). Для корректной работы подсистемы также интегрирован  [CSR-контроллер].(https://github.com/l1sok/APS_RV/tree/main/crs).
  </details>
  
<details>
<summary>Периферийные устройства</summary>

Создание и подключение к общей шине и подсистеме прерывания контроллеры [периферийных устройств](https://github.com/l1sok/APS_RV/tree/main/peripheral): переключатели, светодиоды, семисегментные дисплеи, таймер и контроллер uart.
   </details>

 <details>
<summary>Программирование</summary>
  
  Добавление возможности [программирования](https://github.com/l1sok/APS_RV/blob/main/memory/rw_instr_mem.sv) системы с помощью языка высокого уровня.
  Создание [программатора](https://github.com/l1sok/APS_RV/tree/main/bluster), позволяющего перезаписывать память инструкций без загрузчика.
   </details>
   
<details>
<summary>Оценка производительности</summary>
 Проверка производительности с помощью специализированного ПО (Coremark).
 
![](https://github.com/l1sok/APS_RV/blob/main/coremark.jpg)
 Результат процессора: ~3.45 кормарка, что сопоставимо по производительности с микроконтроллерами Arduino.
 </details>
