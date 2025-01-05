CREATE
    OR REPLACE FUNCTION get_cargo_tracking_info(order_key INT)
    RETURNS TABLE
            (
                order_id          INT,
                cargo_name        VARCHAR(32),
                current_status    VARCHAR(32),
                location_name     VARCHAR(63),
                update_time       TIMESTAMP,
                address           TEXT,
                delivery_deadline TIMESTAMP,
                deviation_level   TEXT,
                is_delivered      BOOLEAN
            )
AS
$$
DECLARE
    del_date TIMESTAMP;
    deviation
             INTERVAL;
    status_record
             RECORD;
BEGIN
    SELECT delivery_date
    INTO del_date
    FROM orders
    WHERE id = order_key;

    FOR status_record IN
        SELECT c.name          AS cargo_name,
               cs.cargo_status AS current_status,
               l.name          AS location_name,
               l.address       AS address,
               cs.update_time
        FROM cargoes c
                 JOIN cargo_status cs ON c.cargo_status_oid = cs.id
                 JOIN locations l ON cs.location_oid = l.id
        WHERE c.order_oid = order_key
        LOOP
            deviation := NOW() - del_date;
            IF
                deviation <= INTERVAL '0 days' THEN
                deviation_level := 'ON_TIME';
            ELSIF
                deviation <= INTERVAL '3 days' THEN
                deviation_level := 'MINOR_DELAY';
            ELSIF
                deviation <= INTERVAL '7 days' THEN
                deviation_level := 'MEDIUM_DELAY';
            ELSE
                deviation_level := 'CRITICAL_DELAY';
            END IF;
            is_delivered
                := (status_record.current_status = 'DELIVERED');

            RETURN QUERY SELECT order_key,
                                status_record.cargo_name,
                                status_record.current_status,
                                status_record.location_name,
                                status_record.update_time,
                                status_record.address,
                                del_date,
                                deviation_level,
                                is_delivered;
        END LOOP;
END;
$$
    LANGUAGE plpgsql;