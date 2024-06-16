# Feature list

Multiple User related:
- Benutzereinstellungen (e.g. Standardwerte)
- devise user accounts

Misc:
- Event Typen: Aufgabe, Geburtstag, Reminder
- Blockierte Aufgaben
- Legende (mit Farben)
- Blockierte Zeiten hinzufügen (nachts, auf arbeit) (background job um die alle zu erstellen)
- task in bestimmte "zone" schedulen, z.B. nur Mo-Fr von 15 - 18 Uhr, schedule between times
- update action validation is not being displayed in the form
- statistik mit erledigten aufgaben
- Tasks duplizieren
- make bulk updating of yearly tasks possible
- validation does not work for events with recurrence
- make it possible to schedule event during work (e.g. Friseur)
- oben links unter Kalender hinweis wie viele unerledigte tasks rescheduled werden msüsen
- tasks mit abhängigkeiten (blocking etc.)
- deadlines
- rückgängig machen, warnung vorm löschen
- timeslots überhaupt notwendig?
- fix time fix date
- unite timeslot and event model
- add validation error messages on new form
- arzttermin während arbeitszeit schedulen
- add image to event
- set default values for event attributes done and fixed (for both false)
- description wird noch nicht formatiert
- neuen index view mit sortierfunktion, filterfunktion und suchfunktion
- time picker does not work on firefox
- replace Time.now by Time.current
- timeslot validation (now two timeslots at the same time)
- ki button der aus description title, priority und duration ableitet
- copy paste board für emojis, z.B. warning emoji https://emojipedia.org/warning
- add fixed attribute to yearly events
- reload schedue when a task is marked as done
- respect current ordering when creating new event and update it (e.g. Weiterbildung priorität)
- automatic rescheduling after a task has been marked as done
- make it possible to mark specific events with color
- priorities in today view direkt bearbeiten
- low priority events ausblenden
- display only events with prio > 90

Simple:
- erledigte Tasks anzeigen

DONE:
- group views: mark/exclude event which are in the past #DONE
- importer is missing group id, occurrence #DONE
- at done_at timestamp #DONE
- scheduling strategy (priority, duration) #DONE
- geburtstage einfärben #DONE
- Sequenz hinzufügen: jährlich, täglich, wöchentlich, alle 2 oder 3 Tage etc.. #DONE
- einstellmöglichkeit für dauer der recurrence #DONE
- reschedule tasks #DONE
- destroy timeslots with size 0 #DONE
- destroy all past timeslots #DONE
- logic that makes sure events and timeslots do not overlap #DONE
- add a method that does not only reschedule past events, but reschedules all non-recurring events #DONE
- Tasks bestimmten Projekten zuordnen und tasks eines bestimmten Projekts ganz oben schedulen mit neuem button #DONE
- done tasks entfernen und reschedulen #DONE
- add file upload to events #DONE
- löschen icon in today view #DONE
- events mit hoher priorität irgendwie kennzeichnen, prio 90-100 besonders hervorheben #DONE
- skip fixed events from being rescheduled #DONE

# Helper

Time.zone.parse("#{date_param} #{time_param}")

# Bugs

- importer scheduled Tasks mit Datum und Uhrzeit auf "sofort"
