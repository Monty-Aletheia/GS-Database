CREATE TABLE tb_devices
(
    id                    RAW(16)       NOT NULL,
    name                  VARCHAR2(255) NOT NULL,
    category              VARCHAR2(255),
    model                 VARCHAR2(255),
    power_rating          DOUBLE PRECISION,
    created_at            TIMESTAMP NOT NULL,
    updated_at            TIMESTAMP,
    CONSTRAINT pk_tb_devices PRIMARY KEY (id)
);

CREATE TABLE tb_users
(
    id          RAW(16)       NOT NULL,
    name        VARCHAR2(255) NOT NULL,
    password    VARCHAR2(255) NOT NULL,
    email       VARCHAR2(255) NOT NULL,
    firebase_id VARCHAR2(255),
    created_at  TIMESTAMP NOT NULL,
    updated_at  TIMESTAMP,
    CONSTRAINT pk_tb_users PRIMARY KEY (id),
    CONSTRAINT uc_tb_users_email UNIQUE (email),
    CONSTRAINT uc_tb_users_firebaseid UNIQUE (firebase_id)
);

CREATE TABLE user_devices
(
    id                    RAW(16)       NOT NULL,
    device_id             RAW(16)       NOT NULL,
    user_id               RAW(16)       NOT NULL,
    consumption           DOUBLE PRECISION NOT NULL,
    created_at            TIMESTAMP NOT NULL,
    estimated_usage_hours DOUBLE PRECISION NOT NULL,
    updated_at            TIMESTAMP,
    CONSTRAINT pk_user_devices PRIMARY KEY (id),
    CONSTRAINT fk_usedev_on_device FOREIGN KEY (device_id) REFERENCES tb_devices (id),
    CONSTRAINT fk_usedev_on_user FOREIGN KEY (user_id) REFERENCES tb_users (id)
);
