
# 디비 사용
USE test_db;
# 업데이트 권한을 준다.
#SET SQL_SAFE_UPDATES = 0;

DROP PROCEDURE IF EXISTS delete_all_rows;
DROP PROCEDURE IF EXISTS drop_tb;
DROP PROCEDURE IF EXISTS drop_all_tb;
DROP PROCEDURE IF EXISTS get_all_foreign_keys;
DROP PROCEDURE IF EXISTS drop_all_foreign_keys;
DROP PROCEDURE IF EXISTS insert_sample_members;
DROP PROCEDURE IF EXISTS insert_sample_buildings;
DROP PROCEDURE IF EXISTS insert_sample_feeds;
DROP PROCEDURE IF EXISTS insert_sample_zzims;
DROP PROCEDURE IF EXISTS insert_sample_feed_attachments;
DROP PROCEDURE IF EXISTS insert_sample_tags;
DROP PROCEDURE IF EXISTS insert_sample_tag_feeds;
DROP PROCEDURE IF EXISTS insert_sample_feed_comments;
DROP PROCEDURE IF EXISTS insert_sample_notifications;
DROP PROCEDURE IF EXISTS insert_sample_reports;
DROP PROCEDURE IF EXISTS insert_sample_member_relationships;
DROP PROCEDURE IF EXISTS insert_sample_chat_applies;
DROP PROCEDURE IF EXISTS insert_sample_chatrooms;
DROP PROCEDURE IF EXISTS insert_sample_chat_entrances;
DROP PROCEDURE IF EXISTS insert_multiple_sample_buildings;
DROP PROCEDURE IF EXISTS insert_multiple_sample_members;
DROP PROCEDURE IF EXISTS insert_multiple_sample_feeds;
#################################################################모든 행 삭제 프로시저 정의################################################
DELIMITER $$

CREATE PROCEDURE delete_all_rows()
BEGIN
    -- 외래 키 제약 조건을 비활성화합니다.
    SET FOREIGN_KEY_CHECKS = 0;
    
    -- 각 테이블의 모든 행을 삭제합니다.
    DELETE FROM chat_entrance;
    DELETE FROM chatroom;
    DELETE FROM chat_apply;
    DELETE FROM member_relationship;
    DELETE FROM report;
    DELETE FROM notification;
    DELETE FROM feed_comment;
    DELETE FROM tag_feed;
    DELETE FROM tag;
    DELETE FROM feed_attachment;
    DELETE FROM feed;
    DELETE FROM building;
    DELETE FROM members;
    DELETE FROM zzim;

    -- 외래 키 제약 조건을 다시 활성화합니다.
    SET FOREIGN_KEY_CHECKS = 1;
END$$

DELIMITER ;

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
#프로시저 삭제 (원하는 경우)
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
#################################################################왜래키 조회 프로시저#########################################################
DELIMITER $$

CREATE PROCEDURE get_all_foreign_keys(IN schema_name VARCHAR(64))
BEGIN
    SELECT 
        CONSTRAINT_NAME, TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
    FROM 
        information_schema.KEY_COLUMN_USAGE
    WHERE 
        TABLE_SCHEMA = schema_name AND 
        REFERENCED_TABLE_NAME IS NOT NULL;
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

##############################################################멤버 예시 데이터 입력#################################################
DELIMITER $$

CREATE PROCEDURE insert_sample_members()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE base_id INT;
    DECLARE random_phone VARCHAR(20);

    -- 테이블에서 현재 가장 큰 member_id의 숫자 부분을 가져옵니다. 테이블이 비어있으면 0을 기본값으로 사용합니다.
    SELECT IFNULL(MAX(CAST(SUBSTRING(member_id, 8) AS UNSIGNED)), 0) INTO base_id FROM members;

    WHILE i <= 100 DO
        -- 랜덤한 휴대폰 번호 생성
        SET random_phone = CONCAT('010-', LPAD(FLOOR(RAND() * 10000), 4, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0'));

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
            CONCAT('member_', base_id + i), -- member_id
            'MEMBER', -- member_role
            CONCAT('nickname_', base_id + i), -- nickname
            'password', -- pwd
            random_phone, -- phone_number
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

##################################################################회원 데이터 3000명 넣기#########################################################
DELIMITER $$

CREATE PROCEDURE insert_multiple_sample_members()
BEGIN
    DECLARE i INT DEFAULT 1;

    WHILE i <= 30 DO
        CALL insert_sample_members();
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

##############################################빌딩 예시 데이터 입력###############################################################
DELIMITER $$

CREATE PROCEDURE insert_sample_buildings()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE base_id INT;

    -- 테이블에서 현재 가장 큰 building_id 값을 가져옵니다.
    SELECT IFNULL(MAX(building_id), 9999) INTO base_id FROM building;

    WHILE i <= 100 DO
        INSERT INTO building (
            building_name,
            profile_activated,
            road_addr,
            longitude,
            latitude,
            feed_ai_summary
        ) VALUES (
            CONCAT('Building_', base_id  + i), -- building_name
			FALSE, -- profile_activated (FALSE)
            CONCAT('Address_', base_id  + i), -- road_addr
            127.0 + (base_id + i) / 1000, -- longitude (예시 값)
            37.0 + (base_id + i) / 1000, -- latitude (예시 값)
            CONCAT('Feed AI Summary for building ', base_id + i) -- feed_ai_summary
        );
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

##########################################################빌딩 데이터 3000개 넣기##############################################################
##빌딩
DELIMITER $$

CREATE PROCEDURE insert_multiple_sample_buildings()
BEGIN
    DECLARE i INT DEFAULT 1;

    WHILE i <= 30 DO
        CALL insert_sample_buildings();
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;
########################################################### 피드 예시 데이터 입력###############################################################
DELIMITER $$

CREATE PROCEDURE insert_sample_feeds()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE base_id INT;
	DECLARE random_writer_id INT;
    DECLARE random_building_id INT;

    -- 테이블에서 현재 가장 큰 feed_id 값을 가져옵니다. 테이블이 비어있으면 9999를 기본값으로 사용합니다.
    SELECT IFNULL(MAX(feed_id), 9999) INTO base_id FROM feed;

    WHILE i <= 100 DO
		SET random_writer_id = FLOOR(1 + (RAND() * 3000));
        SET random_building_id = FLOOR(1 + (RAND() * 3000));
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
            CONCAT('member_', random_writer_id), -- writer_id
            random_building_id + 9999, -- building_id
            CASE
                WHEN i <= 5 THEN TRUE
                ELSE FALSE
            END, -- main_activated (1~5: TRUE, 6~100: FALSE)
            CONCAT('Title_', base_id + i), -- title
            CONCAT('Feed text for feed ', base_id + i), -- feed_text
            CASE 
                WHEN MOD(i, 9) = 0 THEN 'GENERAL'
                WHEN MOD(i, 9) = 1 THEN 'COMPLIMENT'
                WHEN MOD(i, 9) = 2 THEN 'QUESTION'
                WHEN MOD(i, 9) = 3 THEN 'EVENT'
                WHEN MOD(i, 9) = 4 THEN 'POLL'
                WHEN MOD(i, 9) = 5 THEN 'SHARE'
                WHEN MOD(i, 9) = 6 THEN 'HELP_REQUEST'
                WHEN MOD(i, 9) = 7 THEN 'MEGAPHONE'
		WHEN MOD(i, 9) = 8 THEN 'NOTICE'
                ELSE 'GENERAL'
            END, -- feed_category (예시 값)
            base_id + i, -- view_cnt
            TRUE -- activated
        );
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

############################################################피드데이터 10000개 넣기####################################################
##피드
DELIMITER $$

CREATE PROCEDURE insert_multiple_sample_feeds()
BEGIN
    DECLARE i INT DEFAULT 1;

    WHILE i <= 50 DO
        CALL insert_sample_feeds();
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;
#############################################################찜##########################################################
DELIMITER $$

CREATE PROCEDURE insert_sample_zzims()
BEGIN
    DECLARE i INT DEFAULT 1;

    -- 1000명의 회원에게 데이터 삽입
    WHILE i <= 1000 DO
        IF MOD(i, 3) = 0 THEN
            -- subscription 유형의 경우
            INSERT INTO zzim (
                member_id,
                feed_id,
                building_id,
                subscription_provider_id,
                zzim_type,
                activated
            ) VALUES (
                CONCAT('member_', i), -- member_id
                NULL, -- feed_id
                10000 + FLOOR(RAND() * 3000) + 1, -- building_id (10001 ~ 13000)
                IF(RAND() < 0.5, CONCAT('member_', FLOOR(1 + (RAND() * 999))), NULL), -- subscription_provider_id (랜덤으로 존재할 수도 있음)
                'SUBSCRIPTION', -- zzim_type
                TRUE -- activated
            );
        ELSE
            -- like나 bookmark 유형의 경우
            INSERT INTO zzim (
                member_id,
                feed_id,
                building_id,
                subscription_provider_id,
                zzim_type,
                activated
            ) VALUES (
                CONCAT('member_', i), -- member_id
                10000 + FLOOR(RAND() * 3000) + 1, -- feed_id (10001 ~ 13000)
                NULL, -- building_id
                NULL, -- subscription_provider_id
                IF(MOD(i, 2) = 0, 'LIKE', 'BOOKMARK'), -- zzim_type
                TRUE -- activated
            );
        END IF;
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;



#############################################################피드 첨부파일###################################################
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
            i + 9999, -- feed_id (10000 ~ 10099)
            CONCAT('https://example.com/file_', i, '.jpg'), -- file_url
            MOD(i, 2) + 1, -- file_type (1~5 반복)
            IF(i <= 95, NULL, CONCAT('https://example.com/blurred_file_', i, '.jpg')), -- blurred_file_url
            IF(i <= 95, TRUE,FALSE) -- activated (짝수는 TRUE, 홀수는 FALSE)
        );
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;
###########################################################태그################################################################
DELIMITER $$

CREATE PROCEDURE insert_sample_tags()
BEGIN
    DECLARE i INT DEFAULT 1;

    WHILE i <= 100 DO
        INSERT INTO tag (tag_text) VALUES (CONCAT('맛있다_', i));
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

###########################################################태그피드################################################################
DELIMITER $$

CREATE PROCEDURE insert_sample_tag_feeds()
BEGIN
    DECLARE i INT DEFAULT 1;

    WHILE i <= 100 DO
        INSERT INTO tag_feed (
            feed_id,
            tag_id
        ) VALUES (
            i + 9999, -- feed_id (10000 ~ 10099)
            i + 9999 -- tag_id (10000 ~ 10099)
        );
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;


###########################################################피드코멘트################################################################

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
            i + 9999, -- feed_id (10000 ~ 10099)
            CONCAT('member_', i), -- commenter_id (member_1 ~ member_100)
            CONCAT('Comment text for comment ', i), -- comment_text
            NOW(), -- written_time
            IF(i<=95, TRUE, FALSE) -- activated (짝수는 TRUE, 홀수는 FALSE)
        );
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;
###########################################################알림################################################################
DELIMITER $$

CREATE PROCEDURE insert_sample_notifications()
BEGIN
    DECLARE i INT DEFAULT 1;

    WHILE i <= 100 DO
        INSERT INTO notification (
            receiver_id,
            notification_text,
            notification_type
        ) VALUES (
            CONCAT('member_', i), -- receiver_id (member_1 ~ member_100)
            CONCAT('Notification text ', i), -- notification_text
            IF(MOD(i, 2) = 0, 'COMMENT', 'LIKE') -- notification_type (짝수는 COMMENT, 홀수는 LIKE)
        );
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

###########################################################신고################################################################
DELIMITER $$

CREATE PROCEDURE insert_sample_reports()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE report_status VARCHAR(10);

    WHILE i <= 100 DO
    
		SET report_status = CASE MOD(i,3)
			WHEN 0 THEN 'PEND'
            WHEN 1 THEN 'ACCEPT'
            WHEN 2 THEN 'REJECT'	
            END;
    
        INSERT INTO report (
            reporter_id,
            reportee_id,
            report_status,
            report_text,
            reported_time,
            processing_text
            
        ) VALUES (
			CONCAT('member_',i),
            CONCAT('member_',IF(i=100,1,i+1)),
            report_status, -- report_status (1~5 반복) ('PEND', 'ACCEPT', 'REJECT')
            CONCAT('Report text for report ', i), -- report_text
            NOW(), -- reported_time
            IF(report_status IN ('ACCEPT', 'REJECT'), CONCAT('Processing text for report ', i), NULL) -- processing_text (ACCEPT, REJECT일 때만)
        );
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;
###########################################################회원관계################################################################
DELIMITER $$

CREATE PROCEDURE insert_sample_member_relationships()
BEGIN
    DECLARE i INT DEFAULT 1;

    WHILE i <= 100 DO
        INSERT INTO member_relationship (
            from_id,
            to_id,
            relationship_type,
            activated
        ) VALUES (
			CONCAT('member_',i),
            CONCAT('member_',IF(i=100,1,i+1)),
            IF(MOD(i, 2) = 0, 'FOLLOW','BLOCK'), -- relationship_type 
            IF(MOD(i, 2) = 0, TRUE, FALSE) -- activated (짝수는 TRUE, 홀수는 FALSE)
        );
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;
###########################################################채팅신청################################################################
DELIMITER $$

CREATE PROCEDURE insert_sample_chat_applies()
BEGIN
    DECLARE i INT DEFAULT 1;

    WHILE i <= 100 DO
        INSERT INTO chat_apply (
            applicant_id,
            respondent_id,
            apply_message,
            reject_message
        ) VALUES (
			CONCAT('member_',i),
            CONCAT('member_',IF(i=100,1,i+1)),
            CONCAT('Apply message ', i), -- apply_message
            CONCAT('Reject message ', i) -- reject_message
        );
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

###########################################################채팅방################################################################
DELIMITER $$

CREATE PROCEDURE insert_sample_chatrooms()
BEGIN
    DECLARE i INT DEFAULT 1;

    WHILE i <= 100 DO
        INSERT INTO chatroom (
            chatroom_creator_id,
            building_id,
            chatroom_name,
            chatroom_type,
            activated
        ) VALUES (
            CONCAT('member_', i), -- chatroom_creator_id (member_1 ~ member_100)
            i + 9999, -- building_id (10000 ~ 10099)
            CONCAT('채팅방_', i), -- chatroom_name
            'GROUP_CHATTING', -- chatroom_type (짝수는 PRIVATE_CHATTING, 홀수는 GROUP_CHATTING)
            TRUE -- activated
        );
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

###########################################################채팅입장################################################################
DELIMITER $$

CREATE PROCEDURE insert_sample_chat_entrances()
BEGIN
    DECLARE i INT DEFAULT 1;

    WHILE i <= 100 DO
        INSERT INTO chat_entrance (
            chatroom_id,
            chatroom_member_id,
            chatroom_member_type,
            chatroom_entered_time,
            kicked,
            activated
        ) VALUES (
            i + 9999, -- chatroom_id (10000 ~ 10099)
            CONCAT('member_', i), -- chatroom_member_id 1~100
            'OWNER', -- chatroom_member_type 
            NOW(), -- chatroom_entered_time
            FALSE, -- kicked
            TRUE -- activated
        );
        SET i = i + 1;
    END WHILE;
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
    receiving_all_notification_allowed BOOLEAN
    );
    
CREATE INDEX idx_members_member_id ON members(member_id);
CREATE INDEX idx_members_nickname ON members(nickname);
    
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
    notification_type ENUM('COMMENT','LIKE') NOT NULL,
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


CALL insert_multiple_sample_members();
SELECT *
FROM members
ORDER BY CAST(SUBSTRING(member_id, 8) AS SIGNED);
CALL insert_multiple_sample_buildings();
SELECT * FROM building;
CALL insert_multiple_sample_feeds();
SELECT * FROM feed;
CALL insert_sample_zzims();
SELECT * FROM zzim;
CALL insert_sample_feed_attachments();
SELECT * FROM feed_attachment;
CALL insert_sample_tags();
SELECT * FROM tag;
CALL insert_sample_tag_feeds();
SELECT * FROM tag_feed;
CALL insert_sample_feed_comments();
SELECT * FROM feed_comment;
CALL insert_sample_notifications();
SELECT * FROM notification;
CALL insert_sample_reports();
SELECT * FROM report;
CALL insert_sample_member_relationships();
SELECT * FROM member_relationship;
CALL insert_sample_chat_applies();
SELECT * FROM chat_apply;
CALL insert_sample_chatrooms();
SELECT * FROM chatroom;
CALL insert_sample_chat_entrances();
SELECT * FROM chat_entrance;






