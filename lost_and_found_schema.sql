-- =====================================================
-- PHINMA COC Lost and Found System - MySQL schema
-- 15 tables, matches phinma_coc_lost_and_found_erd.drawio
-- =====================================================

CREATE DATABASE IF NOT EXISTS lost_and_found_db
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE lost_and_found_db;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS notification, item_return, claim_evidence, item_match, claim,
  disposal, item_status_history, item_image, lost_report, item, users,
  location, category, department, role;
SET FOREIGN_KEY_CHECKS = 1;

-- ---------- Access & organization ----------

CREATE TABLE role (
  role_id     INT AUTO_INCREMENT PRIMARY KEY,
  role_name   VARCHAR(50) NOT NULL UNIQUE,
  description VARCHAR(255) NULL
) ENGINE=InnoDB;

CREATE TABLE department (
  department_id   INT AUTO_INCREMENT PRIMARY KEY,
  department_name VARCHAR(100) NOT NULL,
  department_code VARCHAR(20) NULL UNIQUE
) ENGINE=InnoDB;

-- ---------- Lookups ----------

CREATE TABLE category (
  category_id   INT AUTO_INCREMENT PRIMARY KEY,
  category_name VARCHAR(100) NOT NULL UNIQUE,
  description   VARCHAR(255) NULL
) ENGINE=InnoDB;

CREATE TABLE location (
  location_id   INT AUTO_INCREMENT PRIMARY KEY,
  location_name VARCHAR(100) NOT NULL,
  location_type ENUM('found_spot','storage') NOT NULL DEFAULT 'found_spot',
  building      VARCHAR(100) NULL,
  room          VARCHAR(50) NULL,
  description   VARCHAR(255) NULL
) ENGINE=InnoDB;

-- ---------- Users ----------

CREATE TABLE users (
  user_id       INT AUTO_INCREMENT PRIMARY KEY,
  role_id       INT NOT NULL,
  department_id INT NULL,
  user_type     ENUM('student','faculty','staff','guest') NOT NULL DEFAULT 'student',
  id_number     VARCHAR(30) NULL UNIQUE,
  full_name     VARCHAR(150) NOT NULL,
  email         VARCHAR(150) NOT NULL UNIQUE,
  phone         VARCHAR(30) NULL,
  password_hash VARCHAR(255) NOT NULL,
  year_level    VARCHAR(20) NULL,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_users_role       FOREIGN KEY (role_id)       REFERENCES role(role_id)             ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_users_department FOREIGN KEY (department_id) REFERENCES department(department_id) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------- Found items & disposal ----------

CREATE TABLE item (
  item_id             INT AUTO_INCREMENT PRIMARY KEY,
  item_code           VARCHAR(30) NOT NULL UNIQUE,
  category_id         INT NOT NULL,
  found_location_id   INT NOT NULL,
  storage_location_id INT NULL,
  reported_by         INT NOT NULL,
  title               VARCHAR(150) NOT NULL,
  description         TEXT NULL,
  brand               VARCHAR(100) NULL,
  color               VARCHAR(50) NULL,
  found_id_number     VARCHAR(30) NULL,
  date_found          DATE NOT NULL,
  status              ENUM('found','in_storage','claimed','returned','disposed') NOT NULL DEFAULT 'found',
  is_valuable         BOOLEAN NOT NULL DEFAULT FALSE,
  created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_item_status (status),
  INDEX idx_item_date_found (date_found),
  INDEX idx_item_found_id_number (found_id_number),
  CONSTRAINT fk_item_category         FOREIGN KEY (category_id)         REFERENCES category(category_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_item_found_location   FOREIGN KEY (found_location_id)   REFERENCES location(location_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_item_storage_location FOREIGN KEY (storage_location_id) REFERENCES location(location_id) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_item_reported_by      FOREIGN KEY (reported_by)         REFERENCES users(user_id)        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE item_image (
  item_image_id INT AUTO_INCREMENT PRIMARY KEY,
  item_id       INT NOT NULL,
  file_path     VARCHAR(255) NOT NULL,
  is_primary    BOOLEAN NOT NULL DEFAULT FALSE,
  uploaded_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_item_image_item FOREIGN KEY (item_id) REFERENCES item(item_id) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE item_status_history (
  item_status_history_id INT AUTO_INCREMENT PRIMARY KEY,
  item_id     INT NOT NULL,
  changed_by  INT NOT NULL,
  old_status  ENUM('found','in_storage','claimed','returned','disposed') NULL,
  new_status  ENUM('found','in_storage','claimed','returned','disposed') NOT NULL,
  remarks     VARCHAR(255) NULL,
  changed_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_history_item (item_id, changed_at),
  CONSTRAINT fk_history_item FOREIGN KEY (item_id)    REFERENCES item(item_id)  ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_history_user FOREIGN KEY (changed_by) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE disposal (
  disposal_id     INT AUTO_INCREMENT PRIMARY KEY,
  item_id         INT NOT NULL UNIQUE,
  approved_by     INT NOT NULL,
  disposal_method ENUM('donated','recycled','discarded') NOT NULL,
  donated_to      VARCHAR(150) NULL,
  disposed_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  remarks         VARCHAR(255) NULL,
  CONSTRAINT fk_disposal_item FOREIGN KEY (item_id)     REFERENCES item(item_id)  ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_disposal_user FOREIGN KEY (approved_by) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------- Lost reports & matching ----------

CREATE TABLE lost_report (
  lost_report_id     INT AUTO_INCREMENT PRIMARY KEY,
  user_id            INT NOT NULL,
  category_id        INT NOT NULL,
  title              VARCHAR(150) NOT NULL,
  description        TEXT NULL,
  brand              VARCHAR(100) NULL,
  color              VARCHAR(50) NULL,
  last_seen_location VARCHAR(150) NULL,
  date_lost          DATE NOT NULL,
  status             ENUM('open','matched','closed') NOT NULL DEFAULT 'open',
  created_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_lost_status (status),
  CONSTRAINT fk_lost_user     FOREIGN KEY (user_id)     REFERENCES users(user_id)        ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_lost_category FOREIGN KEY (category_id) REFERENCES category(category_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE item_match (
  item_match_id  INT AUTO_INCREMENT PRIMARY KEY,
  lost_report_id INT NOT NULL,
  item_id        INT NOT NULL,
  matched_by     INT NULL,
  match_score    DECIMAL(5,2) NULL,
  match_status   ENUM('suggested','confirmed','rejected') NOT NULL DEFAULT 'suggested',
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_match_pair (lost_report_id, item_id),
  CONSTRAINT fk_match_lost FOREIGN KEY (lost_report_id) REFERENCES lost_report(lost_report_id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_match_item FOREIGN KEY (item_id)        REFERENCES item(item_id)               ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_match_user FOREIGN KEY (matched_by)     REFERENCES users(user_id)              ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------- Claims & returns ----------

CREATE TABLE claim (
  claim_id             INT AUTO_INCREMENT PRIMARY KEY,
  item_id              INT NOT NULL,
  claimant_id          INT NOT NULL,
  lost_report_id       INT NULL,
  description_provided TEXT NOT NULL,
  claim_status         ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  reviewed_by          INT NULL,
  reviewed_at          DATETIME NULL,
  remarks              VARCHAR(255) NULL,
  created_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_claim_status (claim_status),
  CONSTRAINT fk_claim_item     FOREIGN KEY (item_id)        REFERENCES item(item_id)               ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_claim_claimant FOREIGN KEY (claimant_id)    REFERENCES users(user_id)              ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_claim_lost     FOREIGN KEY (lost_report_id) REFERENCES lost_report(lost_report_id) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_claim_reviewer FOREIGN KEY (reviewed_by)    REFERENCES users(user_id)              ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE claim_evidence (
  claim_evidence_id INT AUTO_INCREMENT PRIMARY KEY,
  claim_id          INT NOT NULL,
  evidence_type     ENUM('photo','receipt','id','serial_number','other') NOT NULL,
  file_path         VARCHAR(255) NULL,
  details           TEXT NULL,
  CONSTRAINT fk_evidence_claim FOREIGN KEY (claim_id) REFERENCES claim(claim_id) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE item_return (
  item_return_id    INT AUTO_INCREMENT PRIMARY KEY,
  claim_id          INT NOT NULL UNIQUE,
  released_by       INT NOT NULL,
  received_by_name  VARCHAR(150) NOT NULL,
  id_presented      VARCHAR(50) NOT NULL,
  returned_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  signature_path    VARCHAR(255) NULL,
  CONSTRAINT fk_return_claim FOREIGN KEY (claim_id)    REFERENCES claim(claim_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_return_user  FOREIGN KEY (released_by) REFERENCES users(user_id)  ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------- Notifications ----------

CREATE TABLE notification (
  notification_id   INT AUTO_INCREMENT PRIMARY KEY,
  user_id           INT NOT NULL,
  notification_type ENUM('item_found','match_found','claim_update','item_returned','general') NOT NULL DEFAULT 'general',
  message           TEXT NOT NULL,
  related_item_id   INT NULL,
  related_claim_id  INT NULL,
  is_read           BOOLEAN NOT NULL DEFAULT FALSE,
  sent_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_notif_user_read (user_id, is_read),
  CONSTRAINT fk_notif_user  FOREIGN KEY (user_id)          REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_notif_item  FOREIGN KEY (related_item_id)  REFERENCES item(item_id)  ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_notif_claim FOREIGN KEY (related_claim_id) REFERENCES claim(claim_id) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------- Starter data ----------

INSERT INTO role (role_name, description) VALUES
  ('admin', 'System administrator'),
  ('staff', 'Guard or discipline office staff'),
  ('user',  'Student, faculty, or other regular user');

INSERT INTO category (category_name) VALUES
  ('School ID'), ('Phone'), ('Wallet'), ('Keys'), ('Bag'), ('Umbrella'),
  ('Tumbler'), ('Calculator'), ('Uniform'), ('Books'), ('Other');
