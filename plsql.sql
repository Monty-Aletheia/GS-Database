SET SERVEROUTPUT ON;

// 2. Procedures e Funções (30 Pontos)

// ===========================================
// =       Function Calculo/Validate        =
// ===========================================

CREATE OR REPLACE FUNCTION validate_email(p_email VARCHAR2)
RETURN BOOLEAN
IS
    l_match BOOLEAN;
    l_count INTEGER;
BEGIN
    l_match := REGEXP_LIKE(p_email, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    
    IF NOT l_match THEN
        RETURN FALSE;
    END IF;
    
    SELECT COUNT(*)
    INTO l_count
    FROM tb_users
    WHERE email = p_email;

    IF l_count > 0 THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
/

CREATE OR REPLACE FUNCTION calculate_estimated_consumption(p_power_rating DOUBLE PRECISION, p_hours DOUBLE PRECISION)
RETURN DOUBLE PRECISION
IS
BEGIN
    RETURN (p_power_rating / 1000) * p_hours;
END;
/

CREATE OR REPLACE FUNCTION validate_unique_firebase_id(p_firebase_id VARCHAR2)
RETURN BOOLEAN
IS
    l_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO l_count
    FROM tb_users
    WHERE firebase_id = p_firebase_id;

    IF l_count > 0 THEN
        RETURN FALSE;  
    ELSE
        RETURN TRUE;  
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
/


// ===========================================
// =            Validate Inserts             =
// ===========================================

CREATE OR REPLACE PROCEDURE validate_tb_devices(
    p_name VARCHAR2,
    p_category VARCHAR2,
    p_model VARCHAR2,
    p_power_rating DOUBLE PRECISION
)
IS
    invalid_data EXCEPTION;
    l_count INTEGER;
BEGIN
    IF p_name IS NULL OR LENGTH(p_name) < 3 THEN
        RAISE invalid_data;
    END IF;
    
    SELECT COUNT(*)
    INTO l_count
    FROM tb_devices
    WHERE name = p_name;

    IF l_count > 0 THEN
        RAISE invalid_data;
    END IF;

    IF p_category IS NULL OR LENGTH(p_category) < 3 THEN
        RAISE invalid_data;
    END IF;

    IF p_model IS NULL OR LENGTH(p_model) < 3 THEN
        RAISE invalid_data;
    END IF;

    IF p_power_rating IS NULL OR p_power_rating <= 0 THEN
        RAISE invalid_data;
    END IF;

EXCEPTION
    WHEN invalid_data THEN
        RAISE_APPLICATION_ERROR(-20001, 'Dados inválidos fornecidos para tb_devices.');
END;
/

CREATE OR REPLACE PROCEDURE validate_tb_users(
    p_name VARCHAR2,
    p_password VARCHAR2,
    p_email VARCHAR2,
    p_firebase_id VARCHAR2
)
IS
    invalid_data EXCEPTION;
BEGIN
    IF p_name IS NULL OR LENGTH(p_name) < 3 THEN
        RAISE invalid_data;
    END IF;

    IF p_password IS NULL OR LENGTH(p_password) < 6 THEN
        RAISE invalid_data;
    END IF;

    IF NOT validate_email(p_email) THEN
        RAISE invalid_data;
    END IF;

    IF NOT validate_unique_firebase_id(p_firebase_id) THEN
        RAISE invalid_data;
    END IF;

EXCEPTION
    WHEN invalid_data THEN
        RAISE_APPLICATION_ERROR(-20002, 'Dados inválidos fornecidos para tb_users.');
END;
/

CREATE OR REPLACE PROCEDURE validate_user_devices(
    p_device_id RAW,
    p_user_id RAW,
    p_consumption DOUBLE PRECISION,
    p_estimated_usage_hours DOUBLE PRECISION
)
IS
    invalid_data EXCEPTION;
BEGIN
    IF p_device_id IS NULL THEN
        RAISE invalid_data;
    END IF;

    IF p_user_id IS NULL THEN
        RAISE invalid_data;
    END IF;

    IF p_estimated_usage_hours IS NULL OR p_estimated_usage_hours <= 0 THEN
        RAISE invalid_data;
    END IF;

EXCEPTION
    WHEN invalid_data THEN
        RAISE_APPLICATION_ERROR(-20003, 'Dados inválidos fornecidos para user_devices.');
END;
/

// ===========================================
// =           Inserts Procedures            =
// ===========================================

CREATE OR REPLACE PROCEDURE insert_tb_devices(
    p_name VARCHAR2,
    p_category VARCHAR2,
    p_model VARCHAR2,
    p_power_rating DOUBLE PRECISION,
    o_id OUT RAW
)
IS
BEGIN
    validate_tb_devices(p_name, p_category, p_model, p_power_rating);

    INSERT INTO tb_devices (id, name, category, model, power_rating, created_at, updated_at)
    VALUES (SYS_GUID(), p_name, p_category, p_model, p_power_rating, SYSTIMESTAMP, SYSTIMESTAMP)
    RETURNING id INTO o_id;
END;
/

CREATE OR REPLACE PROCEDURE insert_tb_users(
    p_name VARCHAR2,
    p_password VARCHAR2,
    p_email VARCHAR2,
    p_firebase_id VARCHAR2,
    o_id OUT RAW
)
IS
BEGIN
    validate_tb_users(p_name, p_password, p_email, p_firebase_id);

    INSERT INTO tb_users (id, name, password, email, firebase_id, created_at, updated_at)
    VALUES (SYS_GUID(), p_name, p_password, p_email, p_firebase_id, SYSTIMESTAMP, SYSTIMESTAMP)
    RETURNING id INTO o_id;
END;
/

CREATE OR REPLACE PROCEDURE insert_user_devices(
    p_device_id RAW,
    p_user_id RAW,
    p_power_rating DOUBLE PRECISION,
    p_estimated_usage_hours DOUBLE PRECISION,
    o_id OUT RAW
)
IS
    l_consumption DOUBLE PRECISION;
BEGIN
    validate_user_devices(p_device_id, p_user_id, NULL, p_estimated_usage_hours);

    l_consumption := calculate_estimated_consumption(p_power_rating, p_estimated_usage_hours);

    INSERT INTO user_devices (id, device_id, user_id, consumption, created_at, estimated_usage_hours, updated_at)
    VALUES (SYS_GUID(), p_device_id, p_user_id, l_consumption, SYSTIMESTAMP, p_estimated_usage_hours, SYSTIMESTAMP)
    RETURNING id INTO o_id;
END;
/

// ===========================================
// =              Insert Values              =
// ===========================================

DECLARE
    v_id RAW(16);
    v_device_id RAW(16);
    v_user_id RAW(16);
BEGIN
    -- tb_devices
    insert_tb_devices('Smart Light', 'Lighting', 'Philips Hue', 10.5, v_id);
    insert_tb_devices('Smart Thermostat', 'HVAC', 'Nest Thermostat', 12.0, v_id);
    insert_tb_devices('Smart Plug', 'Energy Management', 'TP-Link Kasa', 2.5, v_id);
    insert_tb_devices('Smart Camera', 'Security', 'Arlo Pro', 5.0, v_id);
    insert_tb_devices('Smart Speaker', 'Audio', 'Amazon Echo', 8.0, v_id);
    insert_tb_devices('Smart TV', 'Entertainment', 'Samsung QLED', 150.0, v_id);
    insert_tb_devices('Smart Lock', 'Security', 'August Smart Lock', 3.0, v_id);
    insert_tb_devices('Smart Fridge', 'Appliances', 'LG ThinQ', 200.0, v_id);
    insert_tb_devices('Smart Washer', 'Appliances', 'Samsung Washer', 500.0, v_id);
    insert_tb_devices('Smart Vacuum', 'Cleaning', 'iRobot Roomba', 50.0, v_id);

    -- tb_users
    insert_tb_users('Alice Johnson', 'password123', 'alice.johnson@example.com', 'firebase1', v_id);
    insert_tb_users('Bob Smith', 'securepass', 'bob.smith@example.com', 'firebase2', v_id);
    insert_tb_users('Charlie Brown', 'mypassword', 'charlie.brown@example.com', 'firebase3', v_id);
    insert_tb_users('Diana Prince', 'wonderpass', 'diana.prince@example.com', 'firebase4', v_id);
    insert_tb_users('Eve Adams', 'adamseve', 'eve.adams@example.com', 'firebase5', v_id);
    insert_tb_users('Frank Wright', 'wrightpass', 'frank.wright@example.com', 'firebase6', v_id);
    insert_tb_users('Grace Hopper', 'navypass', 'grace.hopper@example.com', 'firebase7', v_id);
    insert_tb_users('Hank Pym', 'antman123', 'hank.pym@example.com', 'firebase8', v_id);
    insert_tb_users('Irene Adler', 'sherlockholmes', 'irene.adler@example.com', 'firebase9', v_id);
    insert_tb_users('John Watson', 'doctorpass', 'john.watson@example.com', 'firebase10', v_id);

    -- tb_user_devices
    SELECT id INTO v_device_id FROM tb_devices WHERE name = 'Smart Light' AND ROWNUM = 1;
    SELECT id INTO v_user_id FROM tb_users WHERE name = 'Alice Johnson' AND ROWNUM = 1;
    insert_user_devices( v_device_id, v_user_id, 10.5, 5, v_id);

    SELECT id INTO v_device_id FROM tb_devices WHERE name = 'Smart Thermostat' AND ROWNUM = 1;
    SELECT id INTO v_user_id FROM tb_users WHERE name = 'Bob Smith' AND ROWNUM = 1;
    insert_user_devices( v_device_id, v_user_id, 12.0, 3, v_id);

    SELECT id INTO v_device_id FROM tb_devices WHERE name = 'Smart Plug' AND ROWNUM = 1;
    SELECT id INTO v_user_id FROM tb_users WHERE name = 'Charlie Brown' AND ROWNUM = 1;
    insert_user_devices( v_device_id, v_user_id, 2.5, 24, v_id);

    SELECT id INTO v_device_id FROM tb_devices WHERE name = 'Smart Camera' AND ROWNUM = 1;
    SELECT id INTO v_user_id FROM tb_users WHERE name = 'Diana Prince' AND ROWNUM = 1;
    insert_user_devices( v_device_id, v_user_id, 5.0, 12, v_id);

    SELECT id INTO v_device_id FROM tb_devices WHERE name = 'Smart Speaker' AND ROWNUM = 1;
    SELECT id INTO v_user_id FROM tb_users WHERE name = 'Eve Adams' AND ROWNUM = 1;
    insert_user_devices( v_device_id, v_user_id, 8.0, 4, v_id);

    SELECT id INTO v_device_id FROM tb_devices WHERE name = 'Smart TV' AND ROWNUM = 1;
    SELECT id INTO v_user_id FROM tb_users WHERE name = 'Frank Wright' AND ROWNUM = 1;
    insert_user_devices( v_device_id, v_user_id, 150.0, 2, v_id);

    SELECT id INTO v_device_id FROM tb_devices WHERE name = 'Smart Lock' AND ROWNUM = 1;
    SELECT id INTO v_user_id FROM tb_users WHERE name = 'Grace Hopper' AND ROWNUM = 1;
    insert_user_devices( v_device_id, v_user_id, 3.0, 8, v_id);

    SELECT id INTO v_device_id FROM tb_devices WHERE name = 'Smart Fridge' AND ROWNUM = 1;
    SELECT id INTO v_user_id FROM tb_users WHERE name = 'Hank Pym' AND ROWNUM = 1;
    insert_user_devices( v_device_id, v_user_id, 200.0, 24, v_id);

    SELECT id INTO v_device_id FROM tb_devices WHERE name = 'Smart Washer' AND ROWNUM = 1;
    SELECT id INTO v_user_id FROM tb_users WHERE name = 'Irene Adler' AND ROWNUM = 1;
    insert_user_devices( v_device_id, v_user_id, 500.0, 3, v_id);

    SELECT id INTO v_device_id FROM tb_devices WHERE name = 'Smart Vacuum' AND ROWNUM = 1;
    SELECT id INTO v_user_id FROM tb_users WHERE name = 'John Watson' AND ROWNUM = 1;
    insert_user_devices( v_device_id, v_user_id, 50.0, 2, :v_id);
END;

/

// ===========================================
// =             Procedure JSON              =
// ===========================================

CREATE OR REPLACE PROCEDURE export_tb_devices_to_json (
    p_json OUT CLOB  
)
IS
BEGIN
    SELECT JSON_ARRAYAGG(
               JSON_OBJECT(
                   'id' VALUE id,
                   'name' VALUE name,
                   'category' VALUE category,
                   'model' VALUE model,
                   'power_rating' VALUE power_rating
               )
           )
    INTO p_json
    FROM tb_devices;

EXCEPTION
    WHEN OTHERS THEN
        p_json := '{"error": "Erro ao gerar JSON."}';
END;

/

DECLARE
    v_json CLOB;
BEGIN
    export_tb_devices_to_json(v_json);
    DBMS_OUTPUT.PUT_LINE(v_json);
END;
/

// ===========================================
// =                Selects                  =
// ===========================================

SELECT * FROM tb_users;
SELECT * FROM tb_devices;
SELECT * FROM user_devices;
