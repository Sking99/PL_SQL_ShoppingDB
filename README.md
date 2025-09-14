**Shop Database (MySQL/PLSQL)**

  This project defines a simple e-commerce database schema in MySQL with support for products, customers, carts, orders, and auditing. 
  It also includes a stored procedure for handling order placement with transaction control.

**📂 Database Setup**

 ** Create Database**
  
  CREATE DATABASE IF NOT EXISTS shop;
  USE shop;


**Tables Created**

  product → stores product details (SKU, name, price, stock, created timestamp).
  customer → stores customer information and loyalty points.
  cart → represents a shopping cart tied to a customer with expiry.
  cart_item → items added into a cart with product references.
  order → customer orders, including subtotal, discounts, and totals.
  order_item → line items for each order with quantity and price.
  audit_log → records system activity for debugging and auditing.

**🚀 Features**

  - Enforces data integrity via constraints (CHECK, UNIQUE, FOREIGN KEY).
  - Includes transaction-safe stored procedure for placing orders.
  - Provides audit logging for future tracking.
  - Preloaded with sample products, customers, and cart data.
