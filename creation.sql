CREATE TYPE state AS ENUM ('STOCK', 'DELIVIRING',);

-- PENDING(Зарегистрирован но еще не добавлен) 
-- IN_TRANSIT(в Пути)
-- ARRIVIED(Приехал в пункт доставки)
-- DELIVERED(Доставлен)
-- DELAYED(Изменение сроков доставки)
-- DAMAGED(Изменение температуры, поломка)
-- CANCELLED отменен
-- WAITING_PICKUP(ожидает пока его заберут)
-- RETURNED(Возвращен обратно отправителю)

CREATE type cargo_status ENUM ('PENDING','IN_TRANSIT','ARRIVIED','DELIVERED','DELAYED','DAMAGED','CANCELLED','WAITING_PICKUP','RETURNED');


CREATE type cargo_type ENUM ('FRAGILE','PERISHABLE','HAZARDOUS','OVERSIZED','STANDART','REFRIGERATED','LIQUID','ELECTRONIC');

CREATE type incidents ENUM ('DAMAGED','LOST','SPOILAGED','MISDELIVERED','CUSTOMS_HOLD','BROKEN_SEALS');


CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    role_name VARCHAR(32) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(32) UNIQUE NOT NULL,
    role_oid INTEGER NOT NULL,
    password TEXT NOT NULL,
    CONSTRAINT fk_role FOREIGN KEY (role_oid) REFERENCES roles(id) ON DELETE CASCADE,
    CHECK (name <> '')
);

CREATE TABLE IF NOT EXISTS locations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(63) UNIQUE NOT NULL,
    address TEXT NOT NULL,
    state state NOT NULL default 'STOCK',
    CHECK (name <> '')
);
-- Доработал состояние груза.Обсудить 
CREATE TABLE IF NOT EXISTS cargo_statuses (
    id SERIAL PRIMARY KEY,
    name VARCHAR(63) UNIQUE NOT NULL,
    location_oid INTEGER NOT NULL,
    update_time TIMESTAMP NOT NULL,
    cargo_status cargo_status NOT NULL,
    CONSTRAINT fk_location FOREIGN KEY (location_oid) REFERENCES locations(id) ON DELETE CASCADE,
    CHECK (name <> '')
);
-- Поддержка sscc_code и чем должен быть sscc_code_file. Обсудить
CREATE TABLE IF NOT EXISTS labels (
    id SERIAL PRIMARY KEY,
    sscc_code VARCHAR(64) UNIQUE NOT NULL,
    sscc_code_file VARCHAR(64) NOT NULL,
    generation_date TIMESTAMP NOT NULL,
    CHECK (sscc_code <> ''),
    CHECK (sscc_code_file <> ''),
);

-- Зачем оно нужно
CREATE TABLE IF NOT EXISTS cargo_requests (
    id SERIAL PRIMARY KEY,
    reception_center_oid INTEGER NOT NULL,
    creation_date TIMESTAMP NOT NULL,
    user_oid INTEGER NOT NULL,
    CONSTRAINT fk_reception_center FOREIGN KEY (reception_center_oid) REFERENCES locations(id) ON DELETE CASCADE,
    CONSTRAINT fk_user FOREIGN KEY (user_oid) REFERENCES users(id) ON DELETE CASCADE
);
-- Зачем он нужен?
CREATE TABLE IF NOT EXISTS cargoes (
    id SERIAL PRIMARY KEY,
    destination_location_center_oid INTEGER NOT NULL,
    source_location_oid INTEGER NOT NULL,
    cargo_type cargo_type NOT NULL,
    registration_date TIMESTAMP NOT NULL,
    cargo_status_oid INTEGER NOT NULL,
    weight SMALLINT NOT NULL,
    label_oid INTEGER NOT NULL,
    CONSTRAINT fk_destination_location FOREIGN KEY (destination_location_center_oid) REFERENCES locations(id) ON DELETE CASCADE,
    CONSTRAINT fk_source_location FOREIGN KEY (source_location_oid) REFERENCES locations(id) ON DELETE CASCADE,
    CONSTRAINT fk_cargo_status FOREIGN KEY (cargo_status_oid) REFERENCES cargo_statuses(id) ON DELETE CASCADE,
    CONSTRAINT fk_label FOREIGN KEY (label_oid) REFERENCES labels(id) ON DELETE CASCADE,
    CONSTRAINT unique_cargo_status UNIQUE (cargo_status_oid)
);

CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    user_oid INTEGER NOT NULL,
    creation_date TIMESTAMP NOT NULL,
    delivery_date TIMESTAMP NOT NULL,
    CONSTRAINT fk_user_order FOREIGN KEY (user_oid) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS order_cargo (
    order_oid INTEGER NOT NULL,
    cargo_oid INTEGER NOT NULL,
    PRIMARY KEY (order_oid, cargo_oid),
    CONSTRAINT fk_order FOREIGN KEY (order_oid) REFERENCES orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_cargo FOREIGN KEY (cargo_oid) REFERENCES cargoes(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS incidents (
    id SERIAL PRIMARY KEY,
    cargo_oid INTEGER NOT NULL,
    incidents incidents NOT NULL,
    description TEXT NOT NULL,
    occurrence_date TIMESTAMP NOT NULL,
    CONSTRAINT fk_cargo_incident FOREIGN KEY (cargo_oid) REFERENCES cargoes(id) ON DELETE CASCADE
);
