CREATE DATABASE IF NOT EXISTS shop;
 
USE shop;

CREATE TABLE product (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    sku VARCHAR(64) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    price_cents INT NOT NULL CHECK (price_cents >= 0),
    stock INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
 
CREATE TABLE customer (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    loyalty_cents INT NOT NULL DEFAULT 0
);
 
CREATE TABLE cart (
    cart_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);
 
CREATE TABLE cart_item (
    cart_item_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    cart_id BIGINT NOT NULL,
    product_id INT NOT NULL,
    qty INT NOT NULL CHECK (qty > 0),
    UNIQUE (cart_id, product_id),
    FOREIGN KEY (cart_id) REFERENCES cart(cart_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES product(product_id)
);

CREATE TABLE `order` (
    order_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    subtotal_cents INT NOT NULL,
    discount_cents INT NOT NULL,
    loyalty_applied_cents INT NOT NULL,
    total_cents INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);
 
CREATE TABLE order_item (
    order_item_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    order_id BIGINT NOT NULL,
    product_id INT NOT NULL,
    qty INT NOT NULL CHECK (qty > 0),
    price_cents INT NOT NULL,
    FOREIGN KEY (order_id) REFERENCES `order`(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES product(product_id)
);
 
 CREATE TABLE audit_log (
    audit_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    actor VARCHAR(100) NOT NULL,
    action VARCHAR(100) NOT NULL,
    details JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
 
INSERT INTO customer(email, loyalty_cents) VALUES
    ('test@gmail.com', 500), ('sample@email.com', 0);
 
INSERT INTO product(sku, name, price_cents, stock) VALUES
    ('TEA-001', 'Assam Tea', 450, 50),
    ('MUG-001', 'Ceramic Mug', 600, 10),
    ('DSRT-1', 'Dark Chocolate', 1300, 3);
 
INSERT INTO cart(customer_id, expires_at) VALUES (1, NOW() + INTERVAL 2 DAY);
 
INSERT INTO cart_item(cart_id, product_id, qty) VALUES
    (1, 1, 2),  -- 2x tea
    (1, 3, 2);  -- 2x chocolate (stock is low on purpose)
 
INSERT INTO shop.order (customer_id, subtotal_cents, discount_cents, loyalty_applied_cents, total_cents, created_at)
VALUES (1, 10, 0, 0, 10, NOW());
 
SELECT * FROM shop.order;
 
SELECT * FROM customer;
 
DROP PROCEDURE PLACE_ORDER;
 
DELIMITER $
 
CREATE PROCEDURE PLACE_ORDER(
    IN customer_id VARCHAR(255),
    IN i_product_id INT,
    IN i_qty INT,
    OUT order_id BIGINT
)
BEGIN
    DECLARE v_price INT;
    DECLARE v_stock INT;
    DECLARE v_discount INT DEFAULT 0;
    DECLARE v_total INT DEFAULT 0;
    DECLARE v_order_id BIGINT;
 
    IF i_qty IS NULL OR i_qty <= 0 THEN
        SET i_qty = 1;
    END IF;
 
    START TRANSACTION;
 
    SELECT price_cents, stock INTO v_price, v_stock
    FROM product
    WHERE product_id = i_product_id
    FOR UPDATE; -- lock the row for update
 
    IF v_stock < i_qty THEN
        ROLLBACK;
        RESIGNAL;
    END IF;
 
    SET v_total = v_price * i_qty;
 
    INSERT INTO shop.`order` (customer_id, subtotal_cents, discount_cents, loyalty_applied_cents, total_cents, created_at)
    VALUES (customer_id, v_total, v_discount, 0, v_total, NOW());
 
    SET order_id = LAST_INSERT_ID();
 
    INSERT INTO shop.order_item (order_id, product_id, qty, price_cents)
    VALUES (order_id, i_product_id, i_qty, v_price);
 
    UPDATE product
    SET stock = stock - i_qty
    WHERE product_id = i_product_id;
 
    COMMIT;
END
$
 
DELIMITER ;
 
-- Sample call to test the procedure
SET @NEW_ORDER := NULL;
CALL PLACE_ORDER(2, 1, 2, @NEW_ORDER);
 
-- Cleanup for test
DELETE FROM shop.`order` WHERE order_id IN (1, 2, 3);
SELECT * FROM shop.`order`;
SELECT * FROM shop.order_item;