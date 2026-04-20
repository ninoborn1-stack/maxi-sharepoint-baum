# Maxi SharePoint Baum — Team-Webapp

Interaktive SharePoint-Ordnerstruktur mit Echtzeit-Kollaboration:
Status pro Ordner (Erledigt / In Arbeit / Ausstehend), Bearbeiter-Zuweisung,
Lösch-Flag, Notizen, **Kommentare pro Ordner** und **globaler Team-Chat**.

- **Hosting:** GitHub Pages (statisches HTML)
- **Backend:** Supabase (Auth + Realtime Postgres)
- **Stack:** Pure HTML/CSS/JS, Lucide Icons, `@supabase/supabase-js` via CDN

## Setup (einmalig)

1. Im Supabase-Projekt `mwwkdegdjjncamznyofq` den Inhalt von [`schema.sql`](schema.sql)
   in den **SQL Editor** kopieren und ausführen. Legt Tabellen, RLS-Policies,
   Realtime-Publication und die 5 User-Accounts an.
2. GitHub-Pages im Repo aktivieren (Settings → Pages → Source: `main` / `/`).

## Login

Die App kennt fünf feste Accounts. Login per **Name + Passwort** (intern
gemappt auf `<slug>@maxi.local`). Start-Passwort für alle: **`maxi2026`**.

- Christian Bund
- Hamster
- Stefan Thölking
- Maxi Wever
- Nino

## Struktur

```
index.html        – App (UI, Auth, Realtime)
tree-data.js      – statische SharePoint-Ordnerstruktur (~2 MB)
schema.sql        – einmalig im Supabase SQL Editor ausführen
```
