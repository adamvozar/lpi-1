Bonus 1
=======

**Riešenie odovzdávajte podľa
[pokynov na konci tohoto zadania](#technické-detaily-riešenia)
do stredy 1.5. 23:59:59.**

Súbory potrebné pre toto cvičenie si môžete stiahnuť ako jeden zip
[`bonus01.zip`](https://github.com/FMFI-UK-1-AIN-412/lpi/archive/bonus01.zip).

Plánovanie (2b)
---------------

Vyriešte úlohu o gazdovi, koze, kapuste a vlku
([Wikipedia](https://en.wikipedia.org/w/index.php?title=Wolf,_goat_and_cabbage_puzzle),
[XKCD #1134](https://xkcd.com/1134/))
**pomocu SAT solvera**.
Implementujte metódu `vyries` triedy `VlkKozaKapusta`, ktorá dostane
ako argumenty počiatočný stav a počet krokov, koľko má mať nájdené riešenie – _plán_.

Počiatočný stav je reprezentovaný ako slovník tvaru

```python
{ "vlk": "vlavo", "koza": "vlavo", "kapusta": "vpravo", "gazda": "vlavo" }
```
Môžete predpokladať, že počiatočný stav je korektný vzhľadom na podmienky úlohy.

Vaša metóda vráti zoznam akcií (reťazcov), ktoré hovoria, koho má gazda previezť.
`"vlk"` znamená že prevezie vlka atď., `"gazda"` znamená, že sa prevezie sám.
Ak sa úloha nedá vyriešiť na daný počet krokov, metóda vráti prázdny zoznam.

### Reprezentácia

Potrebujeme nejak reprezentovať stavy v jednotlivých krokoch, možné akcie a to, v ktorom
kroku sa ktorá akcia vykonala.

**Stavy** môžeme reprezentovať 4 stavovými premennými (`vlavo_vlk`, `vlavo_koza`,
`vlavo_kapusta` a `vlavo_gazda`). Keďže sa tieto menia z kroku na krok,
výrokové premenné, ktoré použijeme, budú ešte parametrizované číslom kroku:

- `vlavo_X_K` bude pravdivá, ak `X` je na ľavom brehu v kroku `K`.

Podobne budeme reprezentovať **akcie**: máme 8 akcií (
`prevez_dolava_vlk`, `prevez_dolava_koza`, `prevez_dolava_kapusta`, `prevez_dolava_gazda`
`prevez_doprava_vlk`, `prevez_doprava_koza`, `prevez_doprava_kapusta`, `prevez_doprava_gazda`
), ale keďže potrebujeme reprezentovať, v ktorom kroku
ktorú z nich vykonáme, premenné budú znovu mať číslo kroku ako parameter:

- `prevez_dolava_X_K` bude pravdivá, ak v `K`-tom kroku prevezie gazda objekt `X` doľava
  (`prevez_dolava_gazda_K` znamená, že sa preváža sám),
- `prevez_doprava_X_K` bude pravdivá, ak v `K`-tom kroku prevezie gazda objekt `X` doprava.

Poznámka: stačili by nám aj 4 premenné tvaru `prevez_X_K`, akurát by sa trochu
komplikovanejšie písali formuly pre ich podmienky a efekty.

Všimnite si, že pre plán dlhý `N` krokov máme `N` akcií (`0` až `N-1`)
a `N+1` stavov (`0` až `N`):
```
stav_0 --akcia_0->  stav_1 --akcia_1-> ... stav_N-1 --akcia_N-1-> stav_N
```

Vo vstupe pre SAT solver sú premenné reprezentované číslami, takže pomôžu
správne pomocné funkcie a konštanty, ktoré uľahčia preklad z mien stavových
premenných a akcií do čísel a naopak.
Ak hľadáme plán dĺžky `N`,
potrebujeme `4*(N+1)` výrokových premenných pre stavové premenné
tvaru `vlavo_X_K` pre 0 ≤ `K` ≤ `N`
a `2*4*N` premenných pre akcie
tvaru `prevez_KAM_X_K` pre 0 ≤ `K` < `N`.

Zadanie pre SAT solver bude zložené z formúl popisujúcich:
- počiatočný stav,
- koncový stav,
- vykonanie práve jednej akcie v každom kroku,
- podmienky a efekty akcií,
- zotrvačnosť stavových premenných (frame problem) nezmenených akciou,
- obmedzenia úlohy.

### Počiatočný a koncový stav

**Počiatočný stav** popíšeme ako konjunkciu hodnôt stavových premenných v 0-tom kroku.
Napríklad počiatočný stav z vyššie uvedeného pythonovského slovníka
popisuje formula:
```
vlavo_vlk_0 ∧ vlavo_koza_0 ∧ ¬vlavo_kapusta_0 ∧ vlavo_gazda_0
```
Podobne popíšeme želaný **koncový stav** (všetci sú na pravom brehu)
ako konjunkciu hodnôt stavových premenných v `N`-tom kroku:
```
¬vlavo_vlk_N ∧ ¬vlavo_koza_N ∧ ¬vlavo_kapusta_N ∧ ¬vlavo_gazda_N
```

### Vykonanie práve jednej akcie

Vykonanie **práve jednej akcie** v každom kroku zabezpečíme formulami:
- aspoň jedna akcia v `K`-tom kroku:

    ```
    prevez_dolava_vlk_K ∨ ... ∨ prevez_dolava_gazda_K
      ∨ prevez_doprava_vlk_K ∨ ... ∨ prevez_doprava_gazda_K
    ```

- najviac jedna akcia v `K`-tom kroku:
  klauzuly `¬prevez_KAM1_X1_K ∨ ¬prevez_KAM2_X2_K` pre všetky páry
  navzájom rôznych dvojíc smerov `KAM1`, `KAM2` ∈ {`dolava`, `doprava`}
  a prevážaných objektov `X1`, `X2` ∈ {`vlk`, …, `gazda`}.

### Podmienky a efekty akcií

**Podmienky**, za ktorých možno akciu vykonať,
sú jej **nutnými** podmienkami –
ak sa akcia vykoná, museli pred jej vykonaním platiť.
Vyjadríme to implikáciami `akcia_K → (podmienka_1_K ∧ ... ∧ podmienka_p_K)`.
(Čo by znamenala opačná implikácia, teda ak by sme podmienky zapísali
ako postačujúce?)
Napríklad podmienkou prevezenia kapusty doprava v `K`-tom kroku je,
že sa kapusta v `K`-tom kroku nachádza vľavo a nachádza sa tam aj gazda
(kapusta sa sama neprevezie).
Zapíšeme ju teda
```
prevez_doprava_kapusta_K → (vlavo_kapusta_K ∧ vlavo_gazda_K)
```
Podmienky akcií musíme zapísať pre každý krok `K` od 0 po `N-1`.
V našom prípade sú všetky podmienky akcií
jednoduchými variáciami uvedeného príkladu:
pre každé `K`, 0 ≤ `K` < `N`, a každé `X` ∈ {`vlk`, …, `gazda`}:
```
prevez_doprava_X_K → (vlavo_X_K ∧ vlavo_gazda_K)
prevez_dolava_X_K → (¬vlavo_X_K ∧ ¬vlavo_gazda_K)
```

Akcia je **postačujúcou** podmienkou svojich **efektov**,
teda zmien stavových premenných
(nový stav určite nastane po vykonaní akcie,
ale môže nastať aj z iných príčin).
Zapíšeme ich teda implikáciami
`akcia_K → (efekt_1_K+1 ∧ ... ∧ efekt_p_K+1)` –
všimnite si, že efekt sa prejaví v `K+1`-om kroku.
Napríklad efektom prevezenia kapusty doprava v `K`-tom kroku je,
že kapusta a gazda sa v `K+1`-om kroku nachádzajú vpravo:
```
prevez_doprava_kapusta_K → (¬vlavo_kapusta_K+1 ∧ ¬vlavo_gazda_K+1)
```
Efekty akcií (rovnako ako ich podmienky) musíme zapísať pre
každý krok `K` od 0 po `N-1`.
V našej úlohe sa dajú generovať podobne jednoducho ako podmienky akcií.

### Zotrvačnosť stavových premenných

Pri popise efektov akcie je pohodlné zapisovať
iba zmeny stavových premenných.
SAT solveru však treba vysvetliť aj **zotrvačnosť stavových premenných**
(frame problem),
teda to, že stavové premenné neovplyvnené akciou
sa medzi `K`-tym a `K+1`-ým krokom nezmenia.
Môžeme to spraviť napríklad tak, že pre každú akciu a každý
krok priamo popíšeme, že hodnoty akciou neovplyvnených premenných
sa prenášajú do ďalšieho kroku.

Zvyčajne je ale stručnejšie zapísať,
že nutnou podmienkou zmeny stavovej premennej medzi
`K`-tym a `K+1`-ým krokom je vykonanie niektorej z akcií,
ktorá má túto zmenu ako efekt (tieto formuly sa nazývajú
explanatory axioms, lebo vysvetľujú, ktoré akcie zapríčinili efekt).
Napríklad kapusta sa premiestni zľava doprava
iba vykonaním akcie jej prevozu doprava:
```
(vlavo_kapusta_K ∧ ¬vlavo_kapusta_K+1) → prevez_doprava_kapusta_K
```
Nezabudnite, že treba opísať aj opačné prevozy:
```
(¬vlavo_kapusta_K ∧ vlavo_kapusta_K+1) → prevez_dolava_kapusta_K
```
Ak by niektorú zmenu spôsobovalo viacero akcií,
spojíme ich v konzekvente (na pravej strane) implikácie
disjunkciou (niektorá z nich sa musí vykonať, ale nie všetky).

### Obmedzenia úlohy

**Obmedzenia úlohy** (čo nemôže ostať bez gazdu na tom istom brehu)
sa dajú buď zahrnúť do predpokladov akcií,
ale tiež ľahko napísať pre každý stav `K`.
Napríklad formula
```
¬(vlavo_vlk_K ∧ vlavo_koza_K ∧ ¬vlavo_gazda_K)
```
hovorí, že sa nesmie stať, aby vlk a koza boli v `K`-tom kroku
vľavo bez gazdu
(také ohodnotenie výrokových premenných nesplní našu teóriu).

## Technické detaily riešenia

Riešenie odovzdajte do vetvy `bonus01` v správnom adresári.

### Python
Odovzdávajte (modifikujte) súbor [`VlkKozaKapusta.py`](python/VlkKozaKapusta.py).
Program [`vlkKozaKapustaTest.py`](python/vlkKozaKapustaTest.py)
musí s vašou knižnicou korektne zbehnúť.

Ak chcete v pythone použiť knižnicu z [examples/sat](../../../examples/sat), nemusíte
si ju kopírovať do aktuálneho adresára, stačí ak na začiatok svojej knižnice
pridáte:
```python
import os
import sys
sys.path[0:0] = [os.path.join(sys.path[0], '..', '..', '..', 'examples/sat')]
import sat
```

### Java
Odovzdávajte (modifikujte) súbor [`VlkKozaKapusta.java`](java/VlkKozaKapusta.java).
Program [`VlkKozaKapustaTest.java`](java/VlkKozaKapustaTest.java)
musí s vašou knižnicou korektne zbehnúť.

Odovzdávanie riešení v iných jazykoch konzultujte s cvičiacimi.
