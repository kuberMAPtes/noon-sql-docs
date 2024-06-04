DROP PROCEDURE IF EXISTS drop_tb;
DROP PROCEDURE IF EXISTS drop_all_tb;
DROP PROCEDURE IF EXISTS drop_all_foreign_keys;

#################################################################테이블 삭제 프로시저 정의###############################################################
DELIMITER $$

CREATE PROCEDURE drop_tb(IN tableName VARCHAR(255), IN schemaName VARCHAR(255))
BEGIN
    DECLARE drop_command VARCHAR(512);

    -- 테이블 존재 여부 확인 및 동적 DROP TABLE 쿼리 준비
    SET @sql_check = CONCAT('SELECT COUNT(*) INTO @exists FROM information_schema.tables WHERE table_schema = "', schemaName, '" AND table_name = "', tableName, '"');
    PREPARE stmt FROM @sql_check;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    -- 테이블이 존재하면 삭제
    IF @exists > 0 THEN
        SET @drop_command = CONCAT('DROP TABLE ', schemaName, '.', tableName);
        -- 디버깅을 위한 동적 SQL 출력
        SELECT @drop_command;
        PREPARE stmt FROM @drop_command;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END$$

DELIMITER ;

#################################################################모든 테이블 삭제 프로시저 정의###############################################################
DELIMITER $$

CREATE PROCEDURE drop_all_tb(IN schemaName VARCHAR(255))
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE tableName VARCHAR(255);
    DECLARE cur CURSOR FOR 
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = schemaName;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
    OPEN cur;
    
    read_loop: LOOP
        FETCH cur INTO tableName;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- 각 테이블에 대해 drop_tb_if_exists 프로시저 호출
        CALL drop_tb(tableName, schemaName);
    END LOOP;
    
    CLOSE cur;
END$$

DELIMITER ;

#################################################################왜래키 삭제 프로시저 정의######################################################
DELIMITER $$

CREATE PROCEDURE drop_all_foreign_keys(schema_name VARCHAR(64))
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE drop_command VARCHAR(1024);
    DECLARE cur CURSOR FOR
        SELECT 
            CONCAT('ALTER TABLE `', TABLE_SCHEMA, '`.`', TABLE_NAME, '` DROP FOREIGN KEY `', CONSTRAINT_NAME, '`;') AS drop_command
        FROM 
            information_schema.KEY_COLUMN_USAGE 
        WHERE 
            TABLE_SCHEMA = schema_name 
            AND REFERENCED_TABLE_NAME IS NOT NULL;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO drop_command;
        IF done THEN
            LEAVE read_loop;
        END IF;

        SET @drop_command = drop_command;
        PREPARE stmt FROM @drop_command;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END LOOP;

    CLOSE cur;
END$$

DELIMITER ;

#############################################################모든 테이블 삭제 함수 실행#################################################
CALL drop_all_foreign_keys('test_db');
CALL drop_all_tb('test_db');

##############################################################CREATE TABLE########################################################
CREATE TABLE building (
    building_id INT PRIMARY KEY AUTO_INCREMENT,
    building_name VARCHAR(100),
    profile_activated BOOLEAN,
    road_addr VARCHAR(100),
    longitude DOUBLE,
    latitude DOUBLE,
    feed_ai_summary VARCHAR(100)
);
ALTER TABLE building AUTO_INCREMENT = 10000;
CREATE INDEX idx_building_building_name ON building(building_name);
CREATE INDEX idx_buliding_road_addr ON building(road_addr);
CREATE INDEX idx_building_longitude ON building(longitude);
CREATE INDEX idx_building_latitude ON building(latitude);

CREATE TABLE members (
	member_id VARCHAR(20) PRIMARY KEY,
    member_role ENUM('MEMBER','ADMIN') NOT NULL DEFAULT 'MEMBER',
    nickname VARCHAR(30) UNIQUE NOT NULL,
    pwd VARCHAR(100) NOT NULL,
	phone_number VARCHAR(20) UNIQUE NOT NULL,
    unlock_time DATETIME NULL DEFAULT '0001-01-01 01:01:01',
    profile_photo_url TEXT NULL,
    profile_intro VARCHAR(200) NULL ,
    dajung_score INT NOT NULL DEFAULT 0,
    signed_off BOOLEAN NOT NULL DEFAULT FALSE,
	building_subscription_public_range ENUM('PUBLIC','FOLLOWER_ONLY','MUTUAL_ONLY','PRIVATE') DEFAULT 'PUBLIC',
    all_feed_public_range ENUM('PUBLIC','FOLLOWER_ONLY','MUTUAL_ONLY','PRIVATE') DEFAULT 'PUBLIC',
    member_profile_public_range ENUM('PUBLIC','FOLLOWER_ONLY','MUTUAL_ONLY','PRIVATE') DEFAULT 'PUBLIC',
    receiving_all_notification_allowed BOOLEAN NOT NULL DEFAULT FALSE
    );
    
CREATE INDEX idx_members_member_id ON members(member_id);
CREATE INDEX idx_members_nickname ON members(nickname);
    
    CREATE TABLE feed (
feed_id INT PRIMARY KEY AUTO_INCREMENT,
writer_id VARCHAR(20) NOT NULL,
building_id INT NULL,
main_activated BOOLEAN NULL,
public_range ENUM('PUBLIC','FOLLOWER_ONLY','MUTUAL_ONLY','PRIVATE') NOT NULL DEFAULT 'PUBLIC',
title VARCHAR(40) NOT NULL,
feed_text VARCHAR(4000) NOT NULL,
view_cnt BIGINT NOT NULL,
written_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
feed_category ENUM('GENERAL','COMPLIMENT','QUESTION','EVENT','POLL','SHARE','HELP_REQUEST','MEGAPHONE','NOTICE') NOT NULL DEFAULT 'GENERAL',
modified BOOLEAN NOT NULL DEFAULT FALSE,
activated BOOLEAN NOT NULL DEFAULT TRUE,
FOREIGN KEY (building_id) REFERENCES building(building_id),
FOREIGN KEY (writer_id) REFERENCES members(member_id)
);
ALTER TABLE feed AUTO_INCREMENT = 10000;
CREATE INDEX idx_feed_title ON feed(title);
CREATE INDEX idx_feed_feed_text ON feed(feed_text(100));


CREATE TABLE zzim (
zzim_id INT PRIMARY KEY AUTO_INCREMENT,
member_id VARCHAR(20),
feed_id INT NULL,
building_id INT NULL,
subscription_provider_id VARCHAR(20) NULL,
zzim_type ENUM('LIKE','BOOKMARK','SUBSCRIPTION') NOT NULL,
activated BOOLEAN NOT NULL,
FOREIGN KEY (member_id) REFERENCES members(member_id),
FOREIGN KEY (feed_id) REFERENCES feed(feed_id),
FOREIGN KEY (building_id) REFERENCES building(building_id),
FOREIGN KEY (subscription_provider_id) REFERENCES members(member_id)
);
ALTER TABLE zzim AUTO_INCREMENT = 10000;
CREATE INDEX idx_zzim_zzim_type ON zzim(zzim_type);

CREATE TABLE feed_comment (
    comment_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    feed_id INT NOT NULL,
    commenter_id VARCHAR(20) NOT NULL,
    comment_text VARCHAR(4000) NOT NULL,
    written_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    activated BOOLEAN NOT NULL,
    FOREIGN KEY (feed_id) REFERENCES feed(feed_id),
    FOREIGN KEY (commenter_id) REFERENCES members(member_id)
);
ALTER TABLE feed_comment AUTO_INCREMENT = 10000;
CREATE TABLE feed_attachment (
	attachment_id INT PRIMARY KEY AUTO_INCREMENT,
    feed_id INT NOT NULL,
	file_url TEXT NOT NULL,
    file_type ENUM('PHOTO','VIDEO') NOT NULL,
    blurred_file_url VARCHAR(15000) NULL,
    activated BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (feed_id) REFERENCES feed(feed_id)
    );
ALTER TABLE feed_attachment AUTO_INCREMENT = 10000;
CREATE TABLE tag (
	tag_id INT PRIMARY KEY AUTO_INCREMENT,
    tag_text VARCHAR(100) NOT NULL UNIQUE
);
ALTER TABLE tag AUTO_INCREMENT = 10000;
CREATE INDEX idx_tag_tag_text ON tag(tag_text);

CREATE TABLE tag_feed (
    tag_feed_id INT PRIMARY KEY AUTO_INCREMENT,
    feed_id INT NOT NULL,
    tag_id INT NOT NULL,
    FOREIGN KEY (feed_id) REFERENCES feed(feed_id),
    FOREIGN KEY (tag_id) REFERENCES tag(tag_id)
);
ALTER TABLE tag_feed AUTO_INCREMENT = 10000;
CREATE TABLE notification (
    notification_id INT PRIMARY KEY AUTO_INCREMENT,
    receiver_id VARCHAR(20) NOT NULL,
    notification_text VARCHAR(300) NOT NULL,
    notification_type ENUM('COMMENT','LIKE','REPORT') NOT NULL,
    FOREIGN KEY (receiver_id) REFERENCES members(member_id)
);
ALTER TABLE notification AUTO_INCREMENT = 10000;
CREATE TABLE report (
    report_id INT PRIMARY KEY AUTO_INCREMENT,
    reporter_id VARCHAR(20) NOT NULL,
    reportee_id VARCHAR(20) NOT NULL,
    report_status ENUM('PEND', 'ACCEPT', 'REJECT') NOT NULL DEFAULT 'PEND',
    report_text VARCHAR(1000) NOT NULL,
    reported_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processing_text VARCHAR(1000) NULL,
    FOREIGN KEY (reporter_id) REFERENCES members(member_id),
    FOREIGN KEY (reportee_id) REFERENCES members(member_id)
);# report_status 1 대기 2 승인 3 반려
ALTER TABLE report AUTO_INCREMENT = 10000;
CREATE TABLE member_relationship (
    member_relationship_id INT PRIMARY KEY AUTO_INCREMENT,
    from_id VARCHAR(20) NOT NULL,
    to_id VARCHAR(20) NOT NULL,
    relationship_type ENUM('FOLLOW','BLOCK') NOT NULL,
    activated BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (from_id) REFERENCES members(member_id),
    FOREIGN KEY (to_id) REFERENCES members(member_id)
);# relationship_type 1 팔로우 2 차단
ALTER TABLE member_relationship AUTO_INCREMENT = 10000;
-- chat_apply 테이블 생성
CREATE TABLE chat_apply (
    chat_apply_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    applicant_id VARCHAR(20) NOT NULL,
    respondent_id VARCHAR(20) NOT NULL,
    apply_message VARCHAR(400),
    reject_message VARCHAR(400),
    FOREIGN KEY (applicant_id) REFERENCES members(member_id),
    FOREIGN KEY (respondent_id) REFERENCES members(member_id)
);
ALTER TABLE chat_apply AUTO_INCREMENT = 10000;
-- chatroom 테이블 생성
CREATE TABLE chatroom (
    chatroom_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    chatroom_creator_id VARCHAR(20) NOT NULL,
    building_id INT NOT NULL,
    chatroom_name VARCHAR(50) NOT NULL,
    chatroom_type ENUM('PRIVATE_CHATTING','GROUP_CHATTING') NOT NULL,
    chatroom_dajung_temp_min FLOAT NOT NULL DEFAULT 0,
    activated BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (chatroom_creator_id) REFERENCES members(member_id),
    FOREIGN KEY (building_id) REFERENCES building(building_id) -- Assuming building table exists
);
ALTER TABLE chatroom AUTO_INCREMENT = 10000;
CREATE INDEX idx_chatroom_chatroom_name ON chatroom(chatroom_name);

-- chat_entrance 테이블 생성
CREATE TABLE chat_entrance (
    chat_entrance_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    chatroom_id INT NOT NULL,
    chatroom_member_id VARCHAR(20) NOT NULL,
    chatroom_member_type ENUM('MEMBER','OWNER') NOT NULL DEFAULT 'MEMBER',
    chatroom_entered_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    kicked BOOLEAN NOT NULL DEFAULT FALSE,
    activated BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (chatroom_id) REFERENCES chatroom(chatroom_id),
    FOREIGN KEY (chatroom_member_id) REFERENCES members(member_id)
);
ALTER TABLE chat_entrance AUTO_INCREMENT = 10000;
