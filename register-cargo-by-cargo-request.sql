CREATE
    OR REPLACE PROCEDURE register_cargo(
    cargo_request_id INT,
    weight SMALLINT,
    order_id INT,
    label_oid INT
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    cargo_status_id INT;
    reception_center_id
                    INT;
    destination_center_id
                    INT;
    c_type
                    TEXT;
    req_name
                    TEXT;
BEGIN
    SELECT reception_center_oid, destination_center_oid, cargo_type, name
    INTO reception_center_id, destination_center_id, c_type, req_name
    FROM cargo_requests
    WHERE id = cargo_request_id;

    IF
        NOT FOUND THEN
        RAISE EXCEPTION 'Заявка с id % не найдена', cargo_request_id;
    END IF;

    INSERT INTO cargo_status (location_oid, update_time, cargo_status)
    VALUES (reception_center_id, NOW(), 'IN_STOCK')
    RETURNING id
        INTO cargo_status_id;

    INSERT INTO cargoes (name, destination_center_oid, reception_center_oid, cargo_type,
                         registration_date, cargo_status_oid, weight, label_oid, order_oid)
    VALUES (req_name, destination_center_id, reception_center_id, c_type,
            NOW(), cargo_status_id, weight, label_oid, order_id);
END;
$$;