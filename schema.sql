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
-- =========================
-- USERS & SECURITY
-- =========================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- USERS TABLE
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    full_name VARCHAR(255),
    phone VARCHAR(30),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- USER PROFILES (extended info)
CREATE TABLE user_profiles (
    profile_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    avatar_url TEXT,
    bio TEXT,
    date_of_birth DATE,
    preferences JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ADDRESSES
CREATE TABLE user_addresses (
    address_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    label VARCHAR(50), -- Home, Work, etc.
    line1 VARCHAR(255) NOT NULL,
    line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'USA',
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ROLES (admin, seller, customer)
CREATE TABLE roles (
    role_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) UNIQUE NOT NULL
);

-- USER ROLES (many-to-many)
CREATE TABLE user_roles (
    user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    role_id UUID REFERENCES roles(role_id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

-- AUDIT LOGS (admin tracking system actions)
CREATE TABLE audit_logs (
    log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id),
    action TEXT NOT NULL,
    entity_type VARCHAR(100),
    entity_id UUID,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- NOTIFICATIONS
CREATE TABLE notifications (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    type VARCHAR(50),
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);
-- =========================
-- CATALOG SYSTEM
-- =========================

-- DEPARTMENTS (top-level store sections)
CREATE TABLE departments (
    department_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- CATEGORIES (belong to departments)
CREATE TABLE categories (
    category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    department_id UUID NOT NULL REFERENCES departments(department_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(department_id, name)
);

-- SUBCATEGORIES (optional deeper structure)
CREATE TABLE subcategories (
    subcategory_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID NOT NULL REFERENCES categories(category_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(category_id, name)
);

-- BRANDS
CREATE TABLE brands (
    brand_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- PRODUCTS (core listing table)
CREATE TABLE products (
    product_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID NOT NULL REFERENCES categories(category_id),
    subcategory_id UUID REFERENCES subcategories(subcategory_id),

    brand_id UUID REFERENCES brands(brand_id),

    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE,
    description TEXT,

    base_price NUMERIC(10,2) NOT NULL DEFAULT 0,
    cost_price NUMERIC(10,2),

    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (
        status IN ('ACTIVE', 'INACTIVE', 'DRAFT', 'PENDING_APPROVAL')
    ),

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- PRODUCT VARIANTS (size, color, etc.)
CREATE TABLE product_variants (
    variant_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,

    sku VARCHAR(100) UNIQUE,
    variant_name VARCHAR(255), -- e.g. "Red / Large"

    price NUMERIC(10,2),
    attributes JSONB DEFAULT '{}'::jsonb, -- flexible (color, size, etc.)

    created_at TIMESTAMP DEFAULT NOW()
);

-- PRODUCT IMAGES
CREATE TABLE product_images (
    image_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(product_id) ON DELETE CASCADE,
    variant_id UUID REFERENCES product_variants(variant_id) ON DELETE CASCADE,

    image_url TEXT NOT NULL,
    alt_text VARCHAR(255),
    sort_order INT DEFAULT 0,

    created_at TIMESTAMP DEFAULT NOW()
);

-- PRODUCT TAGS
CREATE TABLE product_tags (
    tag_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL
);

-- PRODUCT TAG MAP
CREATE TABLE product_tag_map (
    product_id UUID REFERENCES products(product_id) ON DELETE CASCADE,
    tag_id UUID REFERENCES product_tags(tag_id) ON DELETE CASCADE,
    PRIMARY KEY (product_id, tag_id)
);

-- PRODUCT ATTRIBUTES (flexible specs system)
CREATE TABLE product_attributes (
    attribute_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(product_id) ON DELETE CASCADE,

    key VARCHAR(100),
    value TEXT
);
