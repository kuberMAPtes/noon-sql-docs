/*
피드 관련 원활한 테스트를 위한 sql문에 대한 설명입니다.
1. members : 각기 다른 member를 20개 INSERT 합니다.

2. building : 각기 다른 building을 100개 INSERT 합니다.

3, feed : member_1 ~ member_10이 building_id = 10000 ~ 10009에서 작성한 피드 100개를 INSERT 합니다.
이때. main_feed = true feed_id = XXXX1, activated = false은 feed_id = XXXX5일때 설정하였습니다.

4. feed_attachment : feed_id = 10000 ~ 10009 에서 첨부 파일을 적용하였습니다.
i = 1에서부터 서서히 증가하면서 i % 6 == 0 일 때 blurred_file을 적용, i % 10 == 0 일 때 activated = false로 설정하였습니다.

5. zzim : member_1, member_2에 대하여 zzim을 적용하였습니다.
1) member_1 : feed_id % 2 == 0 일 때 LIKE, feed_id % 3 == 0 일 때 BOOKMARK, building_id % 5 == 0 일 때 SUBSCRIPTION
2) member_2 : feed_id % 5 == 0 일 때 LIKE, feed_id % 7 == 0 일 때 BOOKMARK, building_id % 3 == 0 일 때 SUBSCRIPTION

6. tag : 10개의 서로 다른 태그를 INSERT 하였습니다.

7. tag_feed : 각 피드마다 3개의 태그를 적용하였습니다. 중복된 태그에 대해서는 고려하지 않았습니다.
i = 1에서부터 서서히 증가하면서 (i - 1) % 10, (i + 3) % 10, (i + 4) % 10에 대하여 tag_id를 기준으로 순서대로 적용하였습니다.

8. feed_comment : member_1 ~ member_10이 feed_id = 10000 ~ 10009에 작성하였습니다. 
i = 1에서부터 서서히 증가하면서 i % 7 == 0 에 대하여 activated = false를 적용하였습니다.
*/

# use database
use test_db;

# init
DROP PROCEDURE IF EXISTS insert_sample_members;
DROP PROCEDURE IF EXISTS insert_sample_buildings;
DROP PROCEDURE IF EXISTS insert_sample_feeds;
DROP PROCEDURE IF EXISTS insert_sample_zzims;
DROP PROCEDURE IF EXISTS insert_sample_feed_attachments;
DROP PROCEDURE IF EXISTS insert_sample_tags;
DROP PROCEDURE IF EXISTS insert_sample_tag_feeds;
DROP PROCEDURE IF EXISTS insert_sample_feed_comments;

DROP TABLE IF EXISTS tag_feed;
DROP TABLE IF EXISTS tag;
DROP TABLE IF EXISTS feed_attachment;
DROP TABLE IF EXISTS feed_comment;
DROP TABLE IF EXISTS zzim;
DROP TABLE IF EXISTS feed;
DROP TABLE IF EXISTS members;
DROP TABLE IF EXISTS building;


# building
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

# members
CREATE TABLE members (
	member_id VARCHAR(20) PRIMARY KEY,
    member_role ENUM('MEMBER','ADMIN') NOT NULL DEFAULT 'MEMBER',
    nickname VARCHAR(30) UNIQUE NOT NULL,
    pwd VARCHAR(30) NOT NULL,
	phone_number VARCHAR(20) UNIQUE NOT NULL,
    unlock_time DATETIME NULL DEFAULT '0001-01-01 01:01:01',
    profile_photo_url TEXT NULL,
    profile_intro VARCHAR(200) NULL ,
    dajung_score INT NOT NULL DEFAULT 0,
    signed_off BOOLEAN NOT NULL DEFAULT FALSE,
	building_subscription_public_range ENUM('PUBLIC','FOLLOWER_ONLY','MUTUAL_ONLY','PRIVATE'),
    all_feed_public_range ENUM('PUBLIC','FOLLOWER_ONLY','MUTUAL_ONLY','PRIVATE'),
    member_profile_public_range ENUM('PUBLIC','FOLLOWER_ONLY','MUTUAL_ONLY','PRIVATE'),
    receiving_all_notification_allowed BOOLEAN NOT NULL DEFAULT FALSE
    );
    
CREATE INDEX idx_members_member_id ON members(member_id);
CREATE INDEX idx_members_nickname ON members(nickname);

# feed
CREATE TABLE feed (
	feed_id INT PRIMARY KEY AUTO_INCREMENT,
	writer_id VARCHAR(20) NOT NULL,
	building_id INT NULL,
	main_activated BOOLEAN NOT NULL DEFAULT FALSE, 
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

# zzime
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

# feed_comment
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

# feed_attachment
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

# tag
CREATE TABLE tag (
	tag_id INT PRIMARY KEY AUTO_INCREMENT,
    tag_text VARCHAR(100) NOT NULL UNIQUE
);
ALTER TABLE tag AUTO_INCREMENT = 10000;
CREATE INDEX idx_tag_tag_text ON tag(tag_text);

# tag_feed
CREATE TABLE tag_feed (
    tag_feed_id INT PRIMARY KEY AUTO_INCREMENT,
    feed_id INT NOT NULL,
    tag_id INT NOT NULL,
    FOREIGN KEY (feed_id) REFERENCES feed(feed_id),
    FOREIGN KEY (tag_id) REFERENCES tag(tag_id)
);
ALTER TABLE tag_feed AUTO_INCREMENT = 10000;

# procedure : insert_sample_members()
DELIMITER $$

CREATE PROCEDURE insert_sample_members()
BEGIN
    DECLARE i INT DEFAULT 1;

    WHILE i <= 20 DO
        INSERT INTO members (
            member_id, 
            member_role, 
            nickname, 
            pwd, 
            phone_number, 
            unlock_time, 
            profile_photo_url, 
            profile_intro, 
            dajung_score, 
            signed_off, 
            building_subscription_public_range, 
            all_feed_public_range, 
            member_profile_public_range, 
            receiving_all_notification_allowed
        ) VALUES (
            CONCAT('member_', i), -- member_id
            'MEMBER', -- member_role
            CONCAT('nickname_', i), -- nickname
            'password', -- pwd
            CONCAT('010-0000-00', LPAD(MOD(i, 100), 2, '0')), -- phone_number
            '0001-01-01 01:01:01', -- unlock_time
            NULL, -- profile_photo_url
            NULL, -- profile_intro
            0, -- dajung_score
            FALSE, -- signed_off
            'PUBLIC', -- building_subscription_public_range
            'PUBLIC', -- all_feed_public_range
            'PUBLIC', -- member_profile_public_range
            TRUE -- receiving_all_notification_allowed
        );
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

# procedure : insert_sample_buildings()
DELIMITER $$

CREATE PROCEDURE insert_sample_buildings()
BEGIN
    DECLARE i INT DEFAULT 1;

    WHILE i <= 100 DO
        INSERT INTO building (
            building_name,
            profile_activated,
            road_addr,
            longitude,
            latitude,
            feed_ai_summary
        ) VALUES (
            CONCAT('Building_', i), -- building_name
            FALSE, -- profile_activated (FALSE)
            CONCAT('Address_', i), -- road_addr
            127.0 + i / 1000, -- longitude (예시 값)
            37.0 + i / 1000, -- latitude (예시 값)
            CONCAT('Feed AI Summary for building ', i) -- feed_ai_summary
        );
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

# procedure : insert_sample_feeds()
DELIMITER $$

CREATE PROCEDURE insert_sample_feeds()
BEGIN
    DECLARE i INT DEFAULT 1;
    
    WHILE i <= 100 DO
        INSERT INTO feed (
            writer_id,
            building_id,
            main_activated,
            title,
            feed_text,
            feed_category,
            view_cnt,
            activated
        ) VALUES (
            CONCAT('member_', (i - 1) DIV 10 + 1), -- writer_id
            (i % 10) + 10000, -- building_id
            CASE -- main_activated
                WHEN (i % 10 = 1) THEN TRUE
                ELSE FALSE
            END,
            CONCAT('Title_', i), -- title
            CONCAT('Feed text for feed ', i), -- feed_text
            MOD(i + 11, 9) + 1, -- feed_category 
            i, -- view_cnt
            IF(i % 10 != 5, TRUE, FALSE)
        );
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

# procedure : insert_sample_zzims() 
DELIMITER $$

CREATE PROCEDURE insert_sample_zzims()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE feed_id INT DEFAULT 10000;
	DECLARE building_id INT DEFAULT 10000;
    
    WHILE i <= 100 DO
		IF (feed_id % 2 = 0) THEN
			INSERT INTO zzim (member_id, feed_id, building_id, subscription_provider_id, zzim_type, activated) 
            VALUES ('member_1', feed_id, NULL, NULL, 'LIKE', TRUE);
        END IF;
        
		IF (feed_id % 3 = 0) THEN
			INSERT INTO zzim (member_id, feed_id, building_id, subscription_provider_id, zzim_type, activated) 
            VALUES ('member_1', feed_id, NULL, NULL, 'BOOKMARK', TRUE);
        END IF;
        
		IF (feed_id % 5 = 0) THEN
			INSERT INTO zzim (member_id, feed_id, building_id, subscription_provider_id, zzim_type, activated) 
            VALUES ('member_2', feed_id, NULL, NULL, 'LIKE', TRUE);
        END IF;
        
		IF (feed_id % 7 = 0) THEN
			INSERT INTO zzim (member_id, feed_id, building_id, subscription_provider_id, zzim_type, activated) 
            VALUES ('member_2', feed_id, NULL, NULL, 'BOOKMARK', TRUE);
        END IF;
        
		IF (building_id % 5 = 0) THEN
			INSERT INTO zzim (member_id, feed_id, building_id, subscription_provider_id, zzim_type, activated) 
            VALUES ('member_1', NULL, building_id, 'member_10', 'SUBSCRIPTION', TRUE);
        END IF;
        
		IF (building_id % 11 = 0) THEN
			INSERT INTO zzim (member_id, feed_id, building_id, subscription_provider_id, zzim_type, activated) 
            VALUES ('member_2', NULL, building_id, 'member_10', 'SUBSCRIPTION', TRUE);
        END IF;
        
        SET i = i + 1;
        SET feed_id = feed_id + 1;
        SET building_id = building_id + 1;
    END WHILE;
END$$

DELIMITER ;

# procedure : insert_sample_feed_attachments()
DELIMITER $$

CREATE PROCEDURE insert_sample_feed_attachments()
BEGIN
    DECLARE i INT DEFAULT 1;

    WHILE i <= 100 DO
        INSERT INTO feed_attachment (
            feed_id,
            file_url,
            file_type,
            blurred_file_url,
            activated
        ) VALUES (
            10000 + mod(i - 1, 10), -- feed_id (10000 ~ 10099)
            CONCAT('https://example.com/file_', i, '.jpg'), -- file_url
            MOD(i, 2) + 1, -- file_type
            IF(i % 6 != 0, NULL, CONCAT('https://example.com/blurred_file_', i, '.jpg')), -- blurred_file_url
            IF(i % 10 != 0, TRUE, FALSE) -- activated
        );
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

# procedure : insert_sample_tags() 
DELIMITER $$

CREATE PROCEDURE insert_sample_tags()
BEGIN
	INSERT INTO tag (tag_text) VALUES ('행복');
    INSERT INTO tag (tag_text) VALUES ('슬픔');
    INSERT INTO tag (tag_text) VALUES ('축축함');
    INSERT INTO tag (tag_text) VALUES ('우울');
    INSERT INTO tag (tag_text) VALUES ('배부름');
    INSERT INTO tag (tag_text) VALUES ('따듯함');
    INSERT INTO tag (tag_text) VALUES ('낙관');
    INSERT INTO tag (tag_text) VALUES ('밥');
    INSERT INTO tag (tag_text) VALUES ('알바');
    INSERT INTO tag (tag_text) VALUES ('도움');
END$$

DELIMITER ;

# procedure : insert_sample_tag_feeds()
DELIMITER $$

CREATE PROCEDURE insert_sample_tag_feeds()
BEGIN
    DECLARE i INT DEFAULT 1;
    
    WHILE i <= 100 DO
        INSERT INTO tag_feed (feed_id, tag_id) VALUES (
            i + 9999,
            10000 + mod(i - 1, 10)
        );
        SET i = i + 1;
    END WHILE;
    
    SET i = 1;
	WHILE i <= 100 DO
        INSERT INTO tag_feed (feed_id, tag_id) VALUES (
            i + 9999,
            10000 + mod(i + 3, 10)
        );
        SET i = i + 1;
    END WHILE;
	
    SET i = 1;
	WHILE i <= 100 DO
        INSERT INTO tag_feed (feed_id, tag_id) VALUES (
            i + 9999,
            10000 + mod(i + 4, 10)
        );
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

# procedure : insert_sample_feed_comments()
DELIMITER $$

CREATE PROCEDURE insert_sample_feed_comments()
BEGIN
    DECLARE i INT DEFAULT 1;

    WHILE i <= 100 DO
        INSERT INTO feed_comment (
            feed_id,
            commenter_id,
            comment_text,
            written_time,
            activated
        ) VALUES (
            10000 + mod(i - 1, 10), -- feed_id
            CONCAT('member_', (i - 1) DIV 10 + 1), -- commenter_id
            CONCAT('Comment text for comment ', i), -- comment_text
            NOW(), -- written_time
            IF(i % 7 != 0, TRUE, FALSE) -- activated
        );
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

CALL insert_sample_members();
CALL insert_sample_buildings();
CALL insert_sample_feeds();
CALL insert_sample_zzims();
CALL insert_sample_feed_attachments();
CALL insert_sample_tags();
CALL insert_sample_tag_feeds();
CALL insert_sample_feed_comments();

SELECT * FROM members;
SELECT * FROM building;
SELECT * FROM feed;
SELECT * FROM zzim;
SELECT * FROM feed_attachment;
SELECT * FROM tag;
SELECT * FROM tag_feed;
SELECT * FROM feed_comment;