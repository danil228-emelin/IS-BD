-- Create trigger function for setting creation_date
CREATE OR REPLACE FUNCTION set_user_creation_date() 
RETURNS TRIGGER AS $$
BEGIN
    -- Set creation_date to current timestamp if not provided
    IF NEW.creation_date IS NULL THEN
        NEW.creation_date := NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatically setting creation_date on insert
CREATE TRIGGER trg_set_user_creation_date
BEFORE INSERT ON users
FOR EACH ROW
EXECUTE FUNCTION set_user_creation_date();


-- Create trigger function for setting registration_date
CREATE OR REPLACE FUNCTION set_cargo_registration_date() 
RETURNS TRIGGER AS $$
BEGIN
    -- Set registration_date to current timestamp if not provided
    IF NEW.registration_date IS NULL THEN
        NEW.registration_date := NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatically setting registration_date on insert
CREATE TRIGGER trg_set_cargo_registration_date
BEFORE INSERT ON cargoes
FOR EACH ROW
EXECUTE FUNCTION set_cargo_registration_date();

-- Create trigger function for setting occurrence_date
CREATE OR REPLACE FUNCTION set_incident_occurrence_date() 
RETURNS TRIGGER AS $$
BEGIN
    -- Set occurrence_date to current timestamp if not provided
    IF NEW.occurrence_date IS NULL THEN
        NEW.occurrence_date := NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatically setting occurrence_date on insert
CREATE TRIGGER trg_set_incident_occurrence_date
BEFORE INSERT ON incidents
FOR EACH ROW
EXECUTE FUNCTION set_incident_occurrence_date();


-- Create trigger function to set delivery_date 7 days after creation
CREATE OR REPLACE FUNCTION set_order_delivery_date() 
RETURNS TRIGGER AS $$
BEGIN
    -- Set delivery_date to 7 days after creation_date if not provided
    IF NEW.delivery_date IS NULL THEN
        NEW.delivery_date := NEW.creation_date + INTERVAL '7 days';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically set delivery_date when inserting an order
-- This trigger ensures that the delivery_date is automatically set to 7 days after the creation_date when a new order is inserted if the delivery_date is not explicitly provided.
CREATE TRIGGER trg_set_order_delivery_date
BEFORE INSERT ON orders
FOR EACH ROW
EXECUTE FUNCTION set_order_delivery_date();



-- Create trigger function to log cargo status changes
CREATE OR REPLACE FUNCTION log_cargo_status_change() 
RETURNS TRIGGER AS $$
BEGIN
    -- Log the old and new status in cargo_status_log table if the status changes
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO cargo_status_log (cargo_oid, old_status, new_status)
        VALUES (NEW.cargo_oid, OLD.status, NEW.status);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for logging status changes after update
-- For the cargo_statuses table, we will create a trigger to log every change of the status field into a separate log table.Keep story of all changes
CREATE TRIGGER trg_log_cargo_status_change
AFTER UPDATE ON cargo_statuses
FOR EACH ROW
EXECUTE FUNCTION log_cargo_status_change();


-- Create trigger function to clean up order_cargo on order deletion
CREATE OR REPLACE FUNCTION clean_order_cargo() 
RETURNS TRIGGER AS $$
BEGIN
    -- Delete corresponding rows in order_cargo when an order is deleted
    DELETE FROM order_cargo WHERE order_oid = OLD.id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for cleaning up order_cargo after order deletion
-- When an order is deleted, we should also delete the corresponding entries from the order_cargo table to maintain referential integrity.
CREATE TRIGGER trg_clean_order_cargo
AFTER DELETE ON orders
FOR EACH ROW
EXECUTE FUNCTION clean_order_cargo();


-- Create trigger function to check cargo weight limit
CREATE OR REPLACE FUNCTION check_cargo_weight() 
RETURNS TRIGGER AS $$
BEGIN
    -- Check if the cargo weight exceeds 1000 kg
    IF NEW.weight > 1000 THEN
        RAISE EXCEPTION 'Cargo weight exceeds the limit (1000 kg)';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to validate cargo weight before inserting or updating
-- This trigger ensures that no cargo with a weight exceeding 1000 kg is inserted or updated in the cargoes table.
CREATE TRIGGER trg_check_cargo_weight
BEFORE INSERT OR UPDATE ON cargoes
FOR EACH ROW
EXECUTE FUNCTION check_cargo_weight();
