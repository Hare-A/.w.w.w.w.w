-- Esquema mínimo del walking skeleton. Solo corre cuando el volumen db-data está vacío.
CREATE TABLE IF NOT EXISTS items (
  id         SERIAL PRIMARY KEY,
  title      VARCHAR(120) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
