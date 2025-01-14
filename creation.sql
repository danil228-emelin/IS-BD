CREATE TABLE IF NOT EXISTS roles
(
    id        SERIAL PRIMARY KEY,
    role_name VARCHAR(32) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS users
(
    id       SERIAL PRIMARY KEY,
    username VARCHAR(32) UNIQUE NOT NULL,
    role_oid INTEGER            NOT NULL,
    password TEXT               NOT NULL,
    CONSTRAINT fk_role FOREIGN KEY (role_oid) REFERENCES roles (id),
    CHECK (username <> '')
);

CREATE TABLE IF NOT EXISTS locations
(
    id      SERIAL PRIMARY KEY,
    name    VARCHAR(63) UNIQUE NOT NULL,
    address TEXT               NOT NULL,
    type    VARCHAR(32)        NOT NULL default 'STOCK',
    CHECK (name <> '')
);

CREATE TABLE IF NOT EXISTS cargo_status
(
    id           SERIAL PRIMARY KEY,
    location_oid INTEGER     NOT NULL,
    update_time  TIMESTAMP   NOT NULL,
    cargo_status VARCHAR(32) NOT NULL,
    CONSTRAINT fk_location FOREIGN KEY (location_oid) REFERENCES locations (id)
);

CREATE
    OR REPLACE FUNCTION update_cargo_status_time()
    RETURNS TRIGGER AS
$$
BEGIN
    NEW.update_time
        := NOW();
    RETURN NEW;
END;
$$
    LANGUAGE plpgsql;

CREATE TRIGGER update_cargo_status_time_trigger
    BEFORE UPDATE
    ON cargo_status
    FOR EACH ROW
EXECUTE FUNCTION update_cargo_status_time();

CREATE TABLE IF NOT EXISTS labels
(
    id              SERIAL PRIMARY KEY,
    sscc_code       VARCHAR(18) UNIQUE NOT NULL,
    generation_date TIMESTAMP          NOT NULL DEFAULT now(),
    CHECK (sscc_code ~ '^\d{18}$')
);

CREATE TABLE IF NOT EXISTS cargo_requests
(
    id                     SERIAL PRIMARY KEY,
    name                   VARCHAR(32),
    reception_center_oid   INTEGER     NOT NULL,
    destination_center_oid INTEGER     NOT NULL,
    creation_date          TIMESTAMP   NOT NULL DEFAULT now(),
    owner_oid              INTEGER     NOT NULL,
    cargo_type             VARCHAR(32) NOT NULL,
    CONSTRAINT fk_reception_center FOREIGN KEY (reception_center_oid) REFERENCES locations (id),
    CONSTRAINT fk_destination_center FOREIGN KEY (destination_center_oid) REFERENCES locations (id),
    CONSTRAINT fk_user FOREIGN KEY (owner_oid) REFERENCES users (id),
    CHECK (name <> '')
);

CREATE TABLE IF NOT EXISTS cargoes
(
    id                     SERIAL PRIMARY KEY,
    name                   VARCHAR(32) NOT NULL,
    destination_center_oid INTEGER     NOT NULL,
    reception_center_oid   INTEGER     NOT NULL,
    cargo_type             VARCHAR(32) NOT NULL,
    registration_date      TIMESTAMP   NOT NULL DEFAULT now(),
    cargo_status_oid       INTEGER     NOT NULL,
    weight                 SMALLINT    NOT NULL,
    label_oid              INTEGER     NOT NULL,
    order_oid              INTEGER     NOT NULL,
    CONSTRAINT fk_destination_location FOREIGN KEY (destination_center_oid) REFERENCES locations (id),
    CONSTRAINT fk_source_location FOREIGN KEY (reception_center_oid) REFERENCES locations (id),
    CONSTRAINT fk_cargo_status FOREIGN KEY (cargo_status_oid) REFERENCES cargo_status (id),
    CONSTRAINT fk_label FOREIGN KEY (label_oid) REFERENCES labels (id),
    CONSTRAINT fk_order FOREIGN KEY (order_oid) REFERENCES orders (id),
    CONSTRAINT unique_cargo_status UNIQUE (cargo_status_oid),
    CONSTRAINT unique_label UNIQUE (label_oid)
);

CREATE TABLE IF NOT EXISTS orders
(
    id            SERIAL PRIMARY KEY,
    client_oid    INTEGER   NOT NULL,
    creation_date TIMESTAMP NOT NULL DEFAULT now(),
    delivery_date TIMESTAMP,
    CONSTRAINT fk_user_order FOREIGN KEY (client_oid) REFERENCES users (id)
);

CREATE TABLE IF NOT EXISTS incidents
(
    id              SERIAL PRIMARY KEY,
    cargo_oid       INTEGER     NOT NULL,
    type            VARCHAR(32) NOT NULL,
    description     TEXT        NOT NULL,
    occurrence_date TIMESTAMP   NOT NULL DEFAULT now(),
    CONSTRAINT fk_cargo_incident FOREIGN KEY (cargo_oid) REFERENCES cargoes (id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS notifications
(
    id          SERIAL PRIMARY KEY,
    description TEXT    NOT NULL,
    is_positive BOOLEAN NOT NULL,
    owner_oid   INTEGER NOT NULL,
    CONSTRAINT fk_destination FOREIGN KEY (owner_oid) REFERENCES users (id)
);