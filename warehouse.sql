-- 1. Tạo Schema Gold Layer
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'gold')
BEGIN
    EXEC('CREATE SCHEMA gold');
END;
GO

-- 2. Tạo các Bảng Dimension (Chiều phân tích)

-- Dim_Date
CREATE TABLE gold.Dim_Date (
    date_key INT PRIMARY KEY, -- Dạng YYYYMMDD (ví dụ: 20260923)
    full_date DATE NOT NULL,
    day INT NOT NULL,
    month INT NOT NULL,
    quarter INT NOT NULL,
    year INT NOT NULL
);

-- Dim_Product
CREATE TABLE gold.Dim_Product (
    product_key VARCHAR(64) PRIMARY KEY, -- Surrogate Key (Hash MD5)
    product_id INT NOT NULL,
    product_name NVARCHAR(255) NOT NULL,
    category_id INT,
    category_name NVARCHAR(100),
    segment_id INT,
    segment_name NVARCHAR(100),
    class_id INT,
    class_name NVARCHAR(100),
    size VARCHAR(20),
    color NVARCHAR(50),
    price DECIMAL(18, 2),
    cogs DECIMAL(18, 2),
    status VARCHAR(20) DEFAULT 'ACTIVE'
);

-- Dim_Geography
CREATE TABLE gold.Dim_Geography (
    zip VARCHAR(20) PRIMARY KEY,
    city NVARCHAR(100),
    region NVARCHAR(100)
);

-- Dim_Customer
CREATE TABLE gold.Dim_Customer (
    customer_key VARCHAR(64) PRIMARY KEY,
    customer_id INT NOT NULL,
    zip VARCHAR(20),
    signup_date DATE,
    gender NVARCHAR(10),
    age_group VARCHAR(20),
    acquisition_channel NVARCHAR(50),
    CONSTRAINT FK_Customer_Geography FOREIGN KEY (zip) REFERENCES gold.Dim_Geography(zip)
);

-- Dim_Promotion
CREATE TABLE gold.Dim_Promotion (
    promo_key VARCHAR(64) PRIMARY KEY,
    promo_id INT NOT NULL,
    promo_name NVARCHAR(255),
    promo_type NVARCHAR(50),
    discount_value DECIMAL(18, 2),
    start_date DATE,
    end_date DATE,
    applicable_category NVARCHAR(100),
    promo_channel NVARCHAR(50),
    stackable_flag BIT,
    min_order_value DECIMAL(18, 2)
);

-- 3. Tạo các Bảng Fact (Sự kiện đo lường)

-- Fact_Sales_Order_Items
CREATE TABLE gold.Fact_Sales_Order_Items (
    sales_item_key VARCHAR(64) PRIMARY KEY,
    order_id INT NOT NULL,
    date_key INT NOT NULL,
    product_key VARCHAR(64) NOT NULL,
    customer_key VARCHAR(64) NOT NULL,
    promo_key VARCHAR(64) NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(18, 2) NOT NULL,
    unit_cost DECIMAL(18, 2) NOT NULL,
    discount_amount DECIMAL(18, 2) DEFAULT 0,
    gross_revenue DECIMAL(18, 2) NOT NULL,
    net_revenue DECIMAL(18, 2) NOT NULL,
    cost_amount DECIMAL(18, 2) NOT NULL,
    gross_profit DECIMAL(18, 2) NOT NULL,
    CONSTRAINT FK_Sales_Date FOREIGN KEY (date_key) REFERENCES gold.Dim_Date(date_key),
    CONSTRAINT FK_Sales_Product FOREIGN KEY (product_key) REFERENCES gold.Dim_Product(product_key),
    CONSTRAINT FK_Sales_Customer FOREIGN KEY (customer_key) REFERENCES gold.Dim_Customer(customer_key),
    CONSTRAINT FK_Sales_Promo FOREIGN KEY (promo_key) REFERENCES gold.Dim_Promotion(promo_key)
);

-- Fact_Inventory_Snapshots
CREATE TABLE gold.Fact_Inventory_Snapshots (
    snapshot_key VARCHAR(64) PRIMARY KEY,
    date_key INT NOT NULL,
    product_key VARCHAR(64) NOT NULL,
    stock_on_hand INT NOT NULL,
    units_received INT DEFAULT 0,
    units_sold INT DEFAULT 0,
    inventory_value DECIMAL(18, 2) NOT NULL,
    stockout_days INT DEFAULT 0,
    days_of_supply INT,
    sell_through_rate DECIMAL(5, 4),
    overstock_flag BIT DEFAULT 0,
    reorder_flag BIT DEFAULT 0,
    CONSTRAINT FK_Inv_Date FOREIGN KEY (date_key) REFERENCES gold.Dim_Date(date_key),
    CONSTRAINT FK_Inv_Product FOREIGN KEY (product_key) REFERENCES gold.Dim_Product(product_key)
);

-- Fact_Returns
CREATE TABLE gold.Fact_Returns (
    return_key VARCHAR(64) PRIMARY KEY,
    return_id INT NOT NULL,
    order_id INT NOT NULL,
    date_key INT NOT NULL,
    product_key VARCHAR(64) NOT NULL,
    customer_key VARCHAR(64) NOT NULL,
    return_reason NVARCHAR(255),
    return_quantity INT NOT NULL,
    refund_amount DECIMAL(18, 2) NOT NULL,
    CONSTRAINT FK_Ret_Date FOREIGN KEY (date_key) REFERENCES gold.Dim_Date(date_key),
    CONSTRAINT FK_Ret_Product FOREIGN KEY (product_key) REFERENCES gold.Dim_Product(product_key),
    CONSTRAINT FK_Ret_Customer FOREIGN KEY (customer_key) REFERENCES gold.Dim_Customer(customer_key)
);
GO