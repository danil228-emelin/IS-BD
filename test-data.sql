TRUNCATE TABLE incidents RESTART IDENTITY CASCADE;
TRUNCATE TABLE cargoes RESTART IDENTITY CASCADE;
TRUNCATE TABLE cargo_requests RESTART IDENTITY CASCADE;
TRUNCATE TABLE labels RESTART IDENTITY CASCADE;
TRUNCATE TABLE cargo_status RESTART IDENTITY CASCADE;
TRUNCATE TABLE locations RESTART IDENTITY CASCADE;
TRUNCATE TABLE orders RESTART IDENTITY CASCADE;
TRUNCATE TABLE users RESTART IDENTITY CASCADE;
TRUNCATE TABLE roles RESTART IDENTITY CASCADE;


DO
$$
    DECLARE
        label_id          INT;
        order_ids         INT[] := '{}';
        location_ids      INT[] := '{}';
        cargo_statuses_id INT;
        i                 INT;
        temp_id           INT;
        client_id         INT;
        role_id           INT;
    BEGIN
        INSERT INTO roles (role_name)
        VALUES ('CLIENT')
        RETURNING id INTO role_id;

        INSERT INTO users(username, role_oid, password)
        VALUES ('USER', role_id, '123')
        RETURNING id INTO client_id;

        INSERT INTO locations (name, address, type)
        VALUES ('Moscow Warehouse', 'Moscow, Russia', 'STOCK')
        RETURNING id INTO temp_id;
        location_ids := array_append(location_ids, temp_id);

        INSERT INTO locations (name, address, type)
        VALUES ('Berlin Warehouse', 'Berlin, Germany', 'STOCK')
        RETURNING id INTO temp_id;
        location_ids := array_append(location_ids, temp_id);

        FOR i IN 1..1000
            LOOP
                INSERT INTO orders (client_oid, delivery_date)
                VALUES (client_id, NOW() + (i || ' days')::INTERVAL)
                RETURNING id INTO temp_id;
                order_ids := array_append(order_ids, temp_id);
            END LOOP;

        FOR i IN 1..100000
            LOOP
                INSERT INTO cargo_status (location_oid, update_time, cargo_status)
                VALUES (location_ids[1], NOW(), 'IN_STOCK')
                RETURNING id
                    INTO cargo_statuses_id;

                INSERT INTO labels (sscc_code)
                VALUES (LPAD(i::TEXT, 18, '0'))
                RETURNING id
                    INTO label_id;

                INSERT INTO cargoes (name,
                                     destination_center_oid,
                                     reception_center_oid,
                                     cargo_type,
                                     cargo_status_oid,
                                     weight,
                                     label_oid,
                                     order_oid)
                VALUES ('Cargo ' || i,
                        location_ids[(i % 2) + 1],
                        location_ids[(i % 2) + 1],
                        CASE WHEN i % 2 = 0 THEN 'Electronics' ELSE 'Furniture' END,
                        cargo_statuses_id,
                        (10 + (i % 50)),
                        label_id,
                        order_ids[(i % 1000) + 1]);
            END LOOP;
    END
$$;
