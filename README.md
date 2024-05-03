# Feature list

- Benutzereinstellungen (e.g. Standardwerte)
- Event Typen: Aufgabe, Geburtstag, Reminder
- Sequenz hinzufügen: jährlich, täglich, wöchentlich, alle 2 oder 3 Tage etc..
- Blockierte Aufgaben
- Legende (mit Farben)
- Blockierte Zeiten hinzufügen (nachts, auf arbeit) (background job um die alle zu erstellen)
- reschedule tasks
- task in bestimmte "zone" schedulen, z.B. nur Mo-Fr von 15 - 18 Uhr, schedule between times
- destroy timeslots with size 0
- destroy all past timeslots
- update action validation is not being displayed in the form
- statistik mit erledigten aufgaben
- Tasks duplizieren
- make bulk updating of yearly tasks possible
- validation does not work for events with recurrence
- einstellmöglichkeit für dauer der recurrence
- make it possible to schedule event during work (e.g. Friseur)
- oben links unter Kalender hinweis wie viele unerledigte tasks rescheduled werden msüsen
- tasks mit abhängigkeiten (blocking etc.)
- erledigte Tasks anzeigen
- deadlines
- rückgängig machen, warnung vorm löschen
- logic that makes sure events and timeslots do not overlap
- timeslots überhaupt notwendig?
- fix time fix date
- importer is missing group id, occurrence ## DONE
- group views: mark/exclude event which are in the past ## DONE
- unite timeslot and event model
- add validation error messages on new form
- arzttermin während arbeitszeit schedulen
- add a method that does not only reschedule past events, but reschedules all non-recurring events
- geburtstage einfärben ## DONE
- add image to event
- set default values for event attributes done and fixed (for both false)
- description wird noch nicht formatiert
- neuen index view mit sortierfunktion, filterfunktion und suchfunktion
- scheduling strategy (priority, duration)
- devise user accounts
- time picker does not work on firefox
- replace Time.now by Time.current
- timeslot validation (now two timeslots at the same time)




# Helper

Time.zone.parse("#{date_param} #{time_param}")