# Slackless — Walking Skeleton

## ¿Qué es un walking skeleton?

Es la versión mínima de un sistema que **atraviesa todas las capas** (interfaz → API → base de datos), se levanta con un solo comando y todavía no tiene lógica de negocio. Sirve para comprobar desde el primer día que las piezas se hablan entre sí, y para que cada nueva historia de usuario se construya sobre una base que ya funciona.

Stack (ADR 0001 y convención de nombres del ADR 0004): React 19 + Vite + TypeScript · NestJS 11 (Node 22) + TypeScript · PostgreSQL 16 con el driver `pg` (patrón Repository, SQL parametrizado, sin ORM) · Vitest + Supertest · Docker Compose v2.

## Requisitos

- Docker Desktop (o Docker Engine) con Compose v2.
- Node.js 22 y npm, **solo para la primera vez** (generar los `package-lock.json`) y para correr tests/typecheck fuera de Docker.

## Arranque rápido

La primera vez hay que generar los `package-lock.json` (los Dockerfile usan `npm ci`, que los exige):

```bash
(cd backend && npm install) && (cd frontend && npm install)
```

Después:

```bash
cp .env.example .env && docker compose up --build
```

Abre http://localhost:5173. Los tres paneles de estado deben ponerse en verde.

## URLs

| Qué | URL |
|---|---|
| App (frontend) | http://localhost:5173 |
| Salud de la API (a través del proxy de Vite) | http://localhost:5173/api/health |
| Salud de la API (directo) | http://localhost:3000/api/health |
| Salud + datos de la base (ruta de la guía) | http://localhost:3000/health/db |
| Listar / crear items | `GET` / `POST` http://localhost:3000/api/items |
| PostgreSQL | `localhost:5432` (usuario y base en `.env`) |

## Estructura

```
.
├── docker-compose.yml
├── .env.example
├── db/init/                  # 01_schema.sql y 02_seed.sql (solo corren con el volumen vacío)
├── backend/
│   ├── src/main.ts           # arranque, lee env y cierra ordenado con SIGTERM/SIGINT
│   ├── src/app_module.ts     # raíz de composición: une módulos y el filtro de errores
│   ├── src/config/env.ts     # lee y valida variables de entorno
│   ├── src/common/           # ValidationError + filtro (ValidationError -> 400, resto -> 500)
│   ├── src/db/               # DbService: pool de pg + check() de conexión
│   ├── src/modules/health/   # GET /api/health y GET /health/db
│   ├── src/modules/items/    # model, repository (SQL), service (reglas), controller (HTTP)
│   └── test/items.test.ts    # 4 tests con repositorio en memoria
└── frontend/
    ├── vite.config.ts        # proxy /api -> API_PROXY_TARGET
    └── src/                  # main.tsx, app.tsx, api.ts, styles.css
```

Capas estrictas: el controller no tiene reglas ni SQL · el servicio no conoce HTTP ni SQL y depende de la interfaz `ItemRepository` · el repositorio no valida reglas · el frontend solo habla con la API desde `api.ts`.

## Comandos útiles

```bash
docker compose logs -f api        # logs en vivo (o db, web)
docker compose ps                 # estado de los servicios
docker compose exec db psql -U app -d walking_skeleton -c "SELECT * FROM items;"
docker compose exec api npm test  # tests dentro del contenedor
docker compose down               # apaga (los datos se conservan)
docker compose down -v            # apaga Y borra la base (el seed vuelve a correr)
```

Fuera de Docker: `cd backend && npm run typecheck && npm test`.

> **Si agregas una dependencia** (`npm install algo` en `backend/` o `frontend/`), reconstruye la imagen: `docker compose up --build`. Si no, el contenedor sigue con el volumen `node_modules` viejo. Si persiste, `docker compose down -v` y vuelve a construir.

> **Hot-reload en Windows/macOS:** si el frontend no recarga al guardar, pon `WATCH_POLLING=true` en `.env`.

## Backend contra la base compartida del equipo (guía, paso B)

El mismo backend corre sin Docker contra la base remota `g2-team-4-db`:

```bash
cd backend
cp .env.example .env     # completa DB_HOST, DB_PORT y DB_PASSWORD
npm run build && npm run start
curl -i http://localhost:3000/health/db
```

En el log debe aparecer `Conexión OK -> base "g2-team-4-db" como usuario "g2_team_4_user"`. El `.env` nunca se sube a Git.

## Cómo adaptarlo a tu proyecto

1. **Renombra el módulo `items`** por la entidad de la primera historia de usuario (por ejemplo `team`/`equipo` para HU-03): carpeta, archivos (`snake_case`, ADR 0004), tabla en `db/init/01_schema.sql`, rutas y textos del frontend.
2. **Mantén `/api/health`**: es lo que usan el panel de estado y el healthcheck de Docker.
3. **Registra un ADR** con las decisiones de este esqueleto que no estén en el ADR 0001 (por ejemplo: `pg` con patrón Repository en lugar de ORM, Vitest + Supertest para pruebas, Docker Compose en desarrollo).
