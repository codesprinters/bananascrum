###########################
Fakturowanie w Banana Scrum
###########################

**Status: obowiązujący**

Rodzaje faktury
===============

Wystawiamy z systemu są trzy rodzaje faktur:

* Polskie faktury VAT (z VAT 22%), z opisem wyłącznie w języku polskim,
* Polskie faktury VAT (z VAT 22%), z opisem w dwóch językach,
* Faktury handlowe (bez VAT), z opisem dwujęzycznym.

Schemat numeracji: 

* BS/xxxx/MM/RR/P dla polskich faktur VAT (niezależnie od tego czy jedno, czy
  dwujęzyczne).
* BS/xxxx/MM/RR/K dla faktur handlowych.

Objaśnienie schematu:

xxxx : kolejny numer w miesiącu
MM : numer miesiąca (01, 02 - zawsze dwie cyfry)
RR : dwie ostatnie cyfry numeru roku
P lub K : wyróżnik 

**dla P i K są osobne serie numeracji w każdym miesiącu**

Uwaga: o numeracji decyduje to, czy klient dostaje VAT czy nie, nie formatka
zastosowanej faktury albo to, czy jest jedno czy dwujęzyczna. 

Kto otrzymuje jakie faktury
===========================

O tym, kto otrzyma jaką fakturę decydują dwa parametry:

* typ klienta: firma lub osoba prywatna
* lokalizacja klienta: Polska, inny kraj UE, inny kraj poza UE

Poniżej wymienione jacy klienci otrzymają jaką fakturę:

+---------------------+-------------+---------------+
| Definicja faktur    | Firma       | Prywatny      |
+=====================+=============+===============+
| Polska              | FVAT 22%    | FVAT 22%      |
+---------------------+-------------+---------------+
| Inny kraj UE        | Handlowa zw | FVAT 2jęz 22% |
+---------------------+-------------+---------------+
| Kraj poza UE        | Handlowa zw | Handlowa zw   |
+---------------------+-------------+---------------+


Opis usługi
===========

Na fakturze musi być umieszczony opis usługi oraz kod PKWiU. 

Opis usługi w języku polskim: "Abonament miesięczny za korzystanie z Banana Scrum."

Opis usługi w języku angielskim: "Banana Scrum monthly subscription"

Na fakturze handlowej (na zagarnice) oraz polskiej VAT dla zagranicznych osób
prywatnych jako nazwę usługi umieszczamy opis w obydwu językach.

Format: (OPIS USLUGI - NAZWA PLANU - DATY ) ENG / (OPIS USLUGI - NAZWA PLANU -
DATY ) PL 

Identyfikator płatności
=======================

Na fakturze w polu "Uwagi" umieszczamy identyfikator płatności. Np. "Thank you
for your payment, payment ID xxx" i tu numer transkacji. Ma to umożliwić
jednoznaczne wiązanie faktur z transakcjami PayPal lub kartowymi i w ten
sposób ułatwić życiem klientom.

Dane zbierane od klientów
=========================

Od wszystkich klientów pobieramy następujące informacje:

- adres: dwa pola na ulicę (czasami występują jakieś budynki i kompleksy
  biurowe itp.), Miasto, Kod poczt., Kraj, Stan/Region (opcjonalnie)
- telefon kontaktowy: jeden numer, ze wskazaniem rodzaju (mobile,
  stacjonarny),
- adres e-mail do kontaktu (adres e-mail kreatora konta lub adminów).


Od firm z Polski pobieramy:

- nazwa firmy,
- osoba kontaktowa,
- NIP (validacja).


Od firm z UE pobieramy:

- nazwa firmy,
- osoba kontaktowa,
- "EU VAT tax #" (obowiązkowo).


Od firm spoza UE pobieramy:

- nazwa firmy,
- osoba kontaktowa,
- tax number (opcjonalnie).


Od osób prywatnych pobieramy imię i nazwisko (jako jedno pole).
 oraz oczywiście kraj.

Źródła
======

Poniżej opinie doradcy podatkowego, Mirosława Kucharskiego (Untaxa):

**1. Czy konieczne będzie wystawianie faktur papierowych (to istotne, bo jeśli tak sprzedaż z terenu Polski po prostu odpada)?**

**2. Czy będą inne faktury dla klientów krajowych a inne dla zagranicznych?**

Na dzień dzisiejszy zgodnie z prawem należy wystawiać faktury w formie
papierowej i je  wysyłać do kontrahenta. Może to być jeden rodzaj faktury w
dwóch językach lub oddzielne faktury dla podmiotów polskich i oddzielne dla
zagranicznych. Dla polskich firm wystawiamy faktury zwykłe jak do tej pory w
języku polskim w polskiej walucie (można też w euro) ze stawką VAT 22 %.

Dla podmiotów zagranicznych do Unii i poza UE np USA itp najlepiej wystawiać
jest faktury dwujęzyczne po polsku i angielsku. Po polsku dlatego że w
przypadku kontroli z US każą każdą fakturę po angielsku tłumaczyć na język
polski przez biegłego tłumacza ( przepisy Ordynacji Podatkowej). Na takiej
fakturze musi być dodatkowo wpisany NIP europejski kontrahenta z UE oraz
informacja że usługa ta jest opodatkowana u nabywcy usługi - w jego kraju
(kwestie opodatkowania opisze w oddzielnym mailu)

Nie jest zgodne z prawem stosowanie linków internetowych z których nabywca
usługi może sobie ściągnąć fakturę (bynajmniej w Polsce). Pomimo że jest to
nie zgodne z prawem wiele firm to praktykuje najczęściej firmy sprzedające
doładowania do kart telefonicznych. Problem polega na tym że ewentualna kara
jest dotkliwsza dla nabywcy faktury niż dla wystawcy. Wystawca bowiem wystawił
fakturę (chociaż nie prawidłowo) odprowadził podatek VAT w prawidłowej
wysokości i w prawidłowej stawce zatem nie naraził Skarb Państwa na stratę.
Nabywca natomiast nie ma prawa odliczyć podatku VAT z takiej faktury bowiem
kopia tej faktury (u nabywcy) nigdy nie jest identyczna (graficznie) jak
oryginał - w załączeniu przesyłam pismo US w identycznej sprawie.

Wystawianie faktur z innego kraju gdzie jest  dopuszczalne wysyłanie faktur w
plikach pdf pociaga za sobą obowiazek zarejestrowania działalności
gospodarczej w taki kraju i tam rozliczanie się z podatków.

Oczywiście istnieje możliwość wystawianie e-faktur jest to co prawda
pracochłonne - rejestracja w US, prawidłowe wystawianie przesyłanie i
archiwizowanie faktur, podpis elektroniczny itp. ale jest możliwe. W takim
przypadku bez problemu moglibyście Państwo przesyłać e-faktury. Używanie
e-faktur opłacalne jest w przypadku wystawiania dużej ilości faktur i ich
nabywcy muszą sie zgodzić odbierać je w ten sposób. Jeżeli są Państwo
zainteresowani warunkami i wymogami przy wystawianiu e-faktur to mogę to dla
Państwa przygotować

Mirosław Kucharski

**3. kwestia stosowania kasy fiskalnej.**

W przypadku sprzedaży usług dla osób fizycznych ( dot. Polski i UE) sprzedaż
taka powyżej 40.000 zł w danym roku powoduje obowiązek zainstalowania kasy
fiskalnej. Można tego uniknąć w przypadku kiedy sprzedaż usług będzie odbywać
sie elektronicznie za pośrednictwem Internetu i zapłata za poszczególne
zlecenie będzie dokonywana za pośrednictwem banku lub poczty. Ważne jest aby w
każdej chwili można było zidentyfikować wykonaną usługę najlepiej na podstawie
paragonu, rachunku lub faktury i przypisać do takiego dokumentu odpowiadającą
mu kwotę na rachunku bankowy - ale myślę że w Państwa przypadku nie powinno z
tym być problemu. 

Mirosław Kucharski

** 4. Opodatkowanie stawką VAT usług elektronicznych.** 

Ogólna zasada opodatkowania VAT usług świadczonych przez Państwa przedstawia
sie nastepująco.

Sprzedaż dla polskich podmiotów i osób fizycznych stawka 22%

Sprzedaż dla zagranicznych podmiotów i osób fizycznych (dotyczy UE) - nie
podlega opodatkowaniu w Polsce tylko w kraju UE właściwym dla nabywcy usługi
(pod warunkiem że tam zostanie opodatkowana jako import usług)

Sprzedaż dla zagranicznych podmiotów i osób fizycznych - nie podlega
opodatkowaniu w Polsce podobnie jak pkt. wyżej przy czym nie musimy sprawdzać
czy nabywca opodatkuje ją za granicą.

Jeżeli chcą Państwo bardzo szczegółowo poznać ten temat to mogę to dla Państwa
jutro przygotować jeżeli natomiast nie jest to bardzo pilne to napiszę to i
wytłumaczę po 9 sierpnia. 

Proszę o odpowiedz i ewentualne inne pytania w każdym zakresie dotyczące
Państwa usług.

Pozdrawiam Mirosław Kucharski
