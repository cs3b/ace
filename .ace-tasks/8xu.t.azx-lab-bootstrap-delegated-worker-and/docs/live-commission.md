# Current live commission

Aktualne zlecenie Kapitana (2026-10-31, po wydaniu ace-overseer 0.28.0): przygotuj projekt ACE w /lab/ace przez jeden pełny cykl delegacji. Ta instrukcja zastępuje wcześniejszą decyzję w HITL 8xu80c i stare zadanie o lokalnym bundle. Operacyjny runtime jest wspólny, opublikowany, przypięty do /opt/ace/releases/ffa64e23419eb3cf15ee0f15ba28b4843bcc98d0; ACE_TOOLCHAIN=installed obowiązuje wszystkich wykonawców. Nie tworzyć projektowego bundle operacyjnego i nie nadpisywać śledzonych binstubów. Twoja rola: task i trzy bezpośrednie podtaski, osobny worker przygotowania, niezależny verifier, następnie potwierdzony start Overseera ACE z eyes. Konfigurację i ewentualne naprawy wykonuje worker, nie Ty. Po delegacji kończysz turę, wracasz na zmianę obserwowanego stanu. Nie uruchamiaj projektu przed zakończeniem przygotowania i niezależnej weryfikacji. Zachowaj niezwiązane zmiany. Kryterium odbioru: rzeczywiste przydziały i raporty, wybudzenie po raporcie, pierwszy turn i eyes Overseera ACE oraz pięć minut bez dodatkowych tur przy niezmienionym stanie.


Issued to discovered coordinator w3:p1 after its first turn interpreted an older
HITL decision as current. This supersession is explicit; no worker or project
agent existed at issuance. Eyes were already active with17pending baseline
revisions. This is a live behavioral finding, not a claim of a completed cycle.
