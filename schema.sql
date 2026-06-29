    CONSTRAINT fk_inventory_variant FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id) ON DELETE CASCADE
);

-- =====================================================
-- 7. PRODUCT IMAGES
-- =====================================================
CREATE TABLE product_images (
    image_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL,
    image_url TEXT NOT NULL,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_image_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

-- =====================================================
-- 8. SELLER LISTINGS (Tracks Marketplace Resellers)
-- =====================================================
CREATE TABLE seller_listings (
    listing_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id UUID NOT NULL,
    product_id UUID NOT NULL,
    quantity INTEGER DEFAULT 1,
    asking_price DECIMAL(12,2) NOT NULL,
    condition VARCHAR(30) CHECK (condition IN ('LIKE_NEW', 'EXCELLENT', 'GOOD', 'FAIR', 'POOR', 'FOR_PARTS')),
    approval_status VARCHAR(20) DEFAULT 'PENDING' CHECK (approval_status IN ('PENDING', 'APPROVED', 'REJECTED')),
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'SOLD', 'REMOVED')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_listing_seller FOREIGN KEY (seller_id) REFERENCES users(user_id),
    CONSTRAINT fk_listing_product FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- PERFORMANCE INDEXES
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_brand ON products(brand_id);
CREATE INDEX idx_variants_product ON product_variants(product_id);
CREATE INDEX idx_inventory_variant ON inventory(variant_id);
