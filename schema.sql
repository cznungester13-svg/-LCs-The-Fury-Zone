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
-- =========================
-- INVENTORY SYSTEM
-- =========================

-- WAREHOUSES (future-proof: multiple storage locations)
CREATE TABLE warehouses (
    warehouse_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    location TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- INVENTORY (current stock per product variant)
CREATE TABLE inventory (
    inventory_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    variant_id UUID NOT NULL REFERENCES product_variants(variant_id) ON DELETE CASCADE,
    warehouse_id UUID REFERENCES warehouses(warehouse_id),

    quantity INT NOT NULL DEFAULT 0,
    reserved_quantity INT NOT NULL DEFAULT 0,

    updated_at TIMESTAMP DEFAULT NOW(),

    UNIQUE(variant_id, warehouse_id)
);

-- INVENTORY TRANSACTIONS (full audit trail of stock changes)
CREATE TABLE inventory_transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    variant_id UUID NOT NULL REFERENCES product_variants(variant_id),
    warehouse_id UUID REFERENCES warehouses(warehouse_id),

    transaction_type VARCHAR(30) NOT NULL CHECK (
        transaction_type IN (
            'STOCK_IN',
            'STOCK_OUT',
            'RESERVE',
            'RELEASE',
            'ADJUSTMENT',
            'RETURN'
        )
    ),

    quantity INT NOT NULL,

    reference_type VARCHAR(50),  -- e.g. ORDER, RETURN, MANUAL_ADJUSTMENT
    reference_id UUID,

    notes TEXT,

    created_at TIMESTAMP DEFAULT NOW()
);

-- LOW STOCK TRACKING (optional but powerful for admin dashboard)
CREATE TABLE low_stock_alerts (
    alert_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    variant_id UUID NOT NULL REFERENCES product_variants(variant_id),

    threshold INT NOT NULL DEFAULT 5,
    is_resolved BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMP DEFAULT NOW()
);
-- =========================
-- ORDERS SYSTEM
-- =========================

-- ORDERS (main transaction record)
CREATE TABLE orders (
    order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL REFERENCES users(user_id),

    order_number VARCHAR(50) UNIQUE,

    status VARCHAR(30) DEFAULT 'PENDING' CHECK (
        status IN (
            'PENDING',
            'PAID',
            'PROCESSING',
            'SHIPPED',
            'DELIVERED',
            'CANCELLED',
            'REFUNDED'
        )
    ),

    subtotal NUMERIC(10,2) NOT NULL DEFAULT 0,
    tax NUMERIC(10,2) NOT NULL DEFAULT 0,
    shipping_cost NUMERIC(10,2) NOT NULL DEFAULT 0,
    total NUMERIC(10,2) NOT NULL DEFAULT 0,

    shipping_address_id UUID REFERENCES user_addresses(address_id),

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ORDER ITEMS (snapshot of purchased products)
CREATE TABLE order_items (
    order_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    order_id UUID NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,

    product_id UUID REFERENCES products(product_id),
    variant_id UUID REFERENCES product_variants(variant_id),

    product_name VARCHAR(255) NOT NULL,
    variant_name VARCHAR(255),

    quantity INT NOT NULL,
    price NUMERIC(10,2) NOT NULL,

    subtotal NUMERIC(10,2) NOT NULL,

    created_at TIMESTAMP DEFAULT NOW()
);

-- ORDER STATUS HISTORY (full tracking timeline)
CREATE TABLE order_status_history (
    history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    order_id UUID NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,

    status VARCHAR(30) NOT NULL,

    notes TEXT,

    changed_at TIMESTAMP DEFAULT NOW()
);

-- PAYMENTS (Stripe or other processor)
CREATE TABLE payments (
    payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    order_id UUID NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,

    provider VARCHAR(50) DEFAULT 'STRIPE',

    provider_payment_id VARCHAR(255),

    amount NUMERIC(10,2) NOT NULL,

    currency VARCHAR(10) DEFAULT 'USD',

    status VARCHAR(30) DEFAULT 'PENDING' CHECK (
        status IN ('PENDING', 'SUCCEEDED', 'FAILED', 'REFUNDED')
    ),

    created_at TIMESTAMP DEFAULT NOW()
);

-- REFUNDS
CREATE TABLE refunds (
    refund_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    payment_id UUID NOT NULL REFERENCES payments(payment_id) ON DELETE CASCADE,

    amount NUMERIC(10,2) NOT NULL,

    reason TEXT,

    status VARCHAR(30) DEFAULT 'PENDING' CHECK (
        status IN ('PENDING', 'APPROVED', 'REJECTED', 'COMPLETED')
    ),

    created_at TIMESTAMP DEFAULT NOW()
);

-- SELLER PAYOUTS (for marketplace/resale system)
CREATE TABLE seller_payouts (
    payout_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    seller_id UUID NOT NULL,

    order_id UUID REFERENCES orders(order_id),

    amount NUMERIC(10,2) NOT NULL,

    status VARCHAR(30) DEFAULT 'PENDING' CHECK (
        status IN ('PENDING', 'PROCESSING', 'PAID', 'FAILED')
    ),

    payout_method VARCHAR(50),

    created_at TIMESTAMP DEFAULT NOW()
);
-- =========================
-- MARKETPLACE / SELLER SYSTEM
-- =========================

-- SELLER PROFILES (extends users into sellers)
CREATE TABLE seller_profiles (
    seller_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID UNIQUE NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,

    store_name VARCHAR(255),
    store_description TEXT,

    seller_type VARCHAR(20) DEFAULT 'INDIVIDUAL' CHECK (
        seller_type IN ('INDIVIDUAL', 'BUSINESS')
    ),

    rating NUMERIC(3,2) DEFAULT 0,
    total_sales INT DEFAULT 0,

    is_verified BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMP DEFAULT NOW()
);

-- RESALE LISTINGS (user-generated marketplace items)
CREATE TABLE resale_listings (
    listing_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    seller_id UUID NOT NULL REFERENCES seller_profiles(seller_id) ON DELETE CASCADE,

    title VARCHAR(255) NOT NULL,
    description TEXT,

    category_id UUID REFERENCES categories(category_id),

    condition VARCHAR(30) DEFAULT 'USED' CHECK (
        condition IN ('NEW', 'LIKE_NEW', 'GOOD', 'FAIR', 'POOR')
    ),

    price NUMERIC(10,2) NOT NULL,

    status VARCHAR(30) DEFAULT 'PENDING_APPROVAL' CHECK (
        status IN ('PENDING_APPROVAL', 'ACTIVE', 'REJECTED', 'SOLD', 'PAUSED')
    ),

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- LISTING IMAGES
CREATE TABLE listing_images (
    image_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    listing_id UUID NOT NULL REFERENCES resale_listings(listing_id) ON DELETE CASCADE,

    image_url TEXT NOT NULL,
    sort_order INT DEFAULT 0,

    created_at TIMESTAMP DEFAULT NOW()
);

-- LISTING APPROVALS (admin moderation workflow)
CREATE TABLE listing_approvals (
    approval_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    listing_id UUID NOT NULL REFERENCES resale_listings(listing_id) ON DELETE CASCADE,

    admin_id UUID REFERENCES users(user_id),

    status VARCHAR(30) DEFAULT 'PENDING' CHECK (
        status IN ('PENDING', 'APPROVED', 'REJECTED')
    ),

    notes TEXT,

    reviewed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- SELLER BALANCES (earnings tracking before payout)
CREATE TABLE seller_balances (
    balance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    seller_id UUID NOT NULL REFERENCES seller_profiles(seller_id),

    available_balance NUMERIC(10,2) DEFAULT 0,
    pending_balance NUMERIC(10,2) DEFAULT 0,

    updated_at TIMESTAMP DEFAULT NOW()
);

-- COMMISSIONS (platform fee tracking)
CREATE TABLE commissions (
    commission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    order_id UUID REFERENCES orders(order_id),
    listing_id UUID REFERENCES resale_listings(listing_id),

    seller_id UUID NOT NULL REFERENCES seller_profiles(seller_id),

    amount NUMERIC(10,2) NOT NULL,
    rate NUMERIC(5,2) NOT NULL, -- percentage fee

    created_at TIMESTAMP DEFAULT NOW()
);
-- =========================
-- ADMIN & SYSTEM SETTINGS
-- =========================

-- SYSTEM SETTINGS (global configuration for platform)
CREATE TABLE system_settings (
    setting_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    key VARCHAR(100) UNIQUE NOT NULL,
    value TEXT,

    description TEXT,

    updated_at TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW()
);

-- ANALYTICS EVENTS (for tracking user behavior)
CREATE TABLE analytics_events (
    event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID REFERENCES users(user_id) ON DELETE SET NULL,

    event_type VARCHAR(100) NOT NULL, 
    -- examples: VIEW_PRODUCT, ADD_TO_CART, CHECKOUT_STARTED, PURCHASE_COMPLETED

    metadata JSONB DEFAULT '{}'::jsonb,

    created_at TIMESTAMP DEFAULT NOW()
);

-- ADMIN ACTION LOGS (more detailed than audit_logs)
CREATE TABLE admin_actions (
    action_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    admin_id UUID REFERENCES users(user_id),

    action_type VARCHAR(100) NOT NULL,
    -- examples: APPROVE_LISTING, DELETE_PRODUCT, BAN_USER, REFUND_ORDER

    target_type VARCHAR(100),
    target_id UUID,

    notes TEXT,

    created_at TIMESTAMP DEFAULT NOW()
);

-- FEATURE FLAGS (turn features on/off without redeploying)
CREATE TABLE feature_flags (
    flag_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(100) UNIQUE NOT NULL,
    is_enabled BOOLEAN DEFAULT FALSE,

    description TEXT,

    updated_at TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW()
);

-- NOTIFICATION TEMPLATES (for email/SMS system later)
CREATE TABLE notification_templates (
    template_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(100) UNIQUE NOT NULL,

    subject TEXT,
    body TEXT,

    channel VARCHAR(30) DEFAULT 'EMAIL' CHECK (
        channel IN ('EMAIL', 'SMS', 'IN_APP')
    ),

    created_at TIMESTAMP DEFAULT NOW()
);

-- PLATFORM METRICS SNAPSHOT (optional pre-aggregated stats)
CREATE TABLE platform_metrics (
    metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    metric_date DATE NOT NULL,

    total_users INT DEFAULT 0,
    total_orders INT DEFAULT 0,
    total_revenue NUMERIC(12,2) DEFAULT 0,
    total_listings INT DEFAULT 0,

    created_at TIMESTAMP DEFAULT NOW(),

    UNIQUE(metric_date)
);
