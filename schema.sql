CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    full_name VARCHAR(255),
    role VARCHAR(20) DEFAULT 'CUSTOMER',
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE departments (
    department_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE categories (
    category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    department_id UUID REFERENCES departments(department_id),
    name VARCHAR(255) NOT NULL
);
CREATE TABLE brands (
    brand_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE products (
    product_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    title VARCHAR(255) NOT NULL,
    description TEXT,

    sku VARCHAR(100) UNIQUE,
    slug VARCHAR(255) UNIQUE,

    category_id UUID REFERENCES categories(category_id),
    brand_id UUID REFERENCES brands(brand_id),

    seller_type VARCHAR(20) NOT NULL CHECK (seller_type IN ('STORE', 'RESELLER')),
    seller_id UUID REFERENCES users(user_id),

    price NUMERIC(10,2) NOT NULL,
    compare_at_price NUMERIC(10,2),

    condition VARCHAR(50),

    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE product_images (
    image_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(product_id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    position INT DEFAULT 0
);
CREATE TABLE inventory (
    inventory_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(product_id) ON DELETE CASCADE,
    quantity INT DEFAULT 0,
    reserved_quantity INT DEFAULT 0
);
CREATE TABLE carts (
    cart_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE cart_items (
    cart_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cart_id UUID REFERENCES carts(cart_id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(product_id),
    quantity INT DEFAULT 1
);
CREATE TABLE orders (
    order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id),

    status VARCHAR(50) DEFAULT 'PENDING',

    total_amount NUMERIC(10,2) NOT NULL,

    created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE order_items (
    order_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(product_id),

    quantity INT NOT NULL,
    price NUMERIC(10,2) NOT NULL
);
CREATE TABLE payments (
    payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(order_id),

    stripe_payment_intent TEXT,
    amount NUMERIC(10,2),

    status VARCHAR(50) DEFAULT 'PENDING',

    created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE shipments (
    shipment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(order_id),

    carrier VARCHAR(100),
    tracking_number TEXT,

    status VARCHAR(50) DEFAULT 'PENDING',

    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE reviews (
    review_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(product_id),
    user_id UUID REFERENCES users(user_id),

    rating INT CHECK (rating BETWEEN 1 AND 5),
    title VARCHAR(255),
    review TEXT,

    created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE wishlists (
    wishlist_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id)
);

CREATE TABLE wishlist_items (
    wishlist_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wishlist_id UUID REFERENCES wishlists(wishlist_id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(product_id)
);
CREATE TABLE coupons (
    coupon_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL,

    discount_type VARCHAR(20),
    discount_amount NUMERIC(10,2),

    start_date TIMESTAMP,
    end_date TIMESTAMP,

    usage_limit INT
);
CREATE TABLE seller_payouts (
    payout_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id UUID REFERENCES users(user_id),

    order_id UUID REFERENCES orders(order_id),

    amount NUMERIC(10,2),

    status VARCHAR(50) DEFAULT 'PENDING',

    paid_at TIMESTAMP
);
CREATE TABLE notifications (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id),

    title VARCHAR(255),
    message TEXT,

    is_read BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE audit_logs (
    log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,

    action TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

