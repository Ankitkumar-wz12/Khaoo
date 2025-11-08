/*
  # Khaoo E-commerce Database Schema

  1. New Tables
    - `categories`
      - `id` (uuid, primary key)
      - `name` (text, unique) - Category name (Snacks, Dairy Products)
      - `slug` (text, unique) - URL-friendly identifier
      - `description` (text) - Category description
      - `created_at` (timestamptz) - Creation timestamp
    
    - `products`
      - `id` (uuid, primary key)
      - `name` (text) - Product name
      - `slug` (text, unique) - URL-friendly identifier
      - `description` (text) - Product description
      - `price` (decimal) - Product price
      - `image_url` (text) - Product image URL
      - `category_id` (uuid, foreign key) - References categories
      - `is_best_seller` (boolean) - Featured product flag
      - `rating` (decimal) - Product rating (0-5)
      - `stock` (integer) - Available quantity
      - `created_at` (timestamptz) - Creation timestamp
    
    - `cart_items`
      - `id` (uuid, primary key)
      - `user_id` (uuid) - References auth.users
      - `product_id` (uuid, foreign key) - References products
      - `quantity` (integer) - Item quantity
      - `created_at` (timestamptz) - Creation timestamp
      - `updated_at` (timestamptz) - Last update timestamp
    
    - `profiles`
      - `id` (uuid, primary key, references auth.users)
      - `full_name` (text) - User's full name
      - `created_at` (timestamptz) - Creation timestamp

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users to manage their own cart items
    - Add policies for public read access to products and categories
    - Add policies for users to manage their own profiles
*/

-- Create categories table
CREATE TABLE IF NOT EXISTS categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  slug text UNIQUE NOT NULL,
  description text DEFAULT '',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Categories are viewable by everyone"
  ON categories FOR SELECT
  USING (true);

-- Create products table
CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text UNIQUE NOT NULL,
  description text DEFAULT '',
  price decimal(10,2) NOT NULL,
  image_url text NOT NULL,
  category_id uuid REFERENCES categories(id) ON DELETE CASCADE,
  is_best_seller boolean DEFAULT false,
  rating decimal(2,1) DEFAULT 0,
  stock integer DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Products are viewable by everyone"
  ON products FOR SELECT
  USING (true);

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text DEFAULT '',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Create cart_items table
CREATE TABLE IF NOT EXISTS cart_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id uuid REFERENCES products(id) ON DELETE CASCADE,
  quantity integer DEFAULT 1,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, product_id)
);

ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own cart items"
  ON cart_items FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own cart items"
  ON cart_items FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own cart items"
  ON cart_items FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own cart items"
  ON cart_items FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Insert sample categories
INSERT INTO categories (name, slug, description) VALUES
  ('Snacks', 'snacks', 'Delicious snacks for every craving'),
  ('Dairy Products', 'dairy-products', 'Fresh dairy products delivered to your door')
ON CONFLICT (slug) DO NOTHING;

-- Insert sample products
INSERT INTO products (name, slug, description, price, image_url, category_id, is_best_seller, rating, stock) 
SELECT 
  'Potato Chips - Classic Salted',
  'potato-chips-classic',
  'Crispy golden potato chips with the perfect amount of salt. Perfect for snacking anytime!',
  2.99,
  'https://images.pexels.com/photos/4061279/pexels-photo-4061279.jpeg?auto=compress&cs=tinysrgb&w=800',
  (SELECT id FROM categories WHERE slug = 'snacks'),
  true,
  4.5,
  100
WHERE NOT EXISTS (SELECT 1 FROM products WHERE slug = 'potato-chips-classic');

INSERT INTO products (name, slug, description, price, image_url, category_id, is_best_seller, rating, stock)
SELECT
  'Chocolate Cookies',
  'chocolate-cookies',
  'Rich chocolate cookies with chocolate chips. A sweet treat for chocolate lovers!',
  3.49,
  'https://images.pexels.com/photos/230325/pexels-photo-230325.jpeg?auto=compress&cs=tinysrgb&w=800',
  (SELECT id FROM categories WHERE slug = 'snacks'),
  true,
  4.7,
  150
WHERE NOT EXISTS (SELECT 1 FROM products WHERE slug = 'chocolate-cookies');

INSERT INTO products (name, slug, description, price, image_url, category_id, is_best_seller, rating, stock)
SELECT
  'Fresh Milk - 1 Liter',
  'fresh-milk-1l',
  'Farm-fresh full cream milk. Rich in calcium and nutrients.',
  1.99,
  'https://images.pexels.com/photos/236010/pexels-photo-236010.jpeg?auto=compress&cs=tinysrgb&w=800',
  (SELECT id FROM categories WHERE slug = 'dairy-products'),
  true,
  4.8,
  200
WHERE NOT EXISTS (SELECT 1 FROM products WHERE slug = 'fresh-milk-1l');

INSERT INTO products (name, slug, description, price, image_url, category_id, is_best_seller, rating, stock)
SELECT
  'Greek Yogurt',
  'greek-yogurt',
  'Creamy Greek yogurt packed with protein. Perfect for breakfast or snacks.',
  4.99,
  'https://images.pexels.com/photos/1435735/pexels-photo-1435735.jpeg?auto=compress&cs=tinysrgb&w=800',
  (SELECT id FROM categories WHERE slug = 'dairy-products'),
  true,
  4.6,
  80
WHERE NOT EXISTS (SELECT 1 FROM products WHERE slug = 'greek-yogurt');

INSERT INTO products (name, slug, description, price, image_url, category_id, is_best_seller, rating, stock)
SELECT
  'Cheese Crackers',
  'cheese-crackers',
  'Crunchy crackers with real cheese flavor. Great for parties!',
  2.49,
  'https://images.pexels.com/photos/6544378/pexels-photo-6544378.jpeg?auto=compress&cs=tinysrgb&w=800',
  (SELECT id FROM categories WHERE slug = 'snacks'),
  false,
  4.3,
  120
WHERE NOT EXISTS (SELECT 1 FROM products WHERE slug = 'cheese-crackers');

INSERT INTO products (name, slug, description, price, image_url, category_id, is_best_seller, rating, stock)
SELECT
  'Butter - Unsalted',
  'butter-unsalted',
  'Premium quality unsalted butter made from fresh cream.',
  5.49,
  'https://images.pexels.com/photos/4109998/pexels-photo-4109998.jpeg?auto=compress&cs=tinysrgb&w=800',
  (SELECT id FROM categories WHERE slug = 'dairy-products'),
  false,
  4.4,
  60
WHERE NOT EXISTS (SELECT 1 FROM products WHERE slug = 'butter-unsalted');