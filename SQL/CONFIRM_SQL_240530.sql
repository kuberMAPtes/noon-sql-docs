
# 디비 사용
USE test_db;
# 업데이트 권한을 준다.
SET SQL_SAFE_UPDATES = 0;

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
DROP PROCEDURE IF EXISTS delete_all_rows;
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

    WHILE i <= 100 DO
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
            'noon0716', -- pwd
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
##############################################빌딩 예시 데이터 입력###############################################################
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
#############################################################찜##########################################################
DELIMITER $$

CREATE PROCEDURE insert_sample_zzims()
BEGIN
    DECLARE i INT DEFAULT 2;
    DECLARE random_provider_id VARCHAR(255);

    -- 먼저 member_1의 건물 구독 데이터 삽입
    INSERT INTO zzim (
        member_id,
        feed_id,
        building_id,
        subscription_provider_id,
        zzim_type,
        activated
    ) VALUES (
        'member_1', -- member_id
        NULL, -- feed_id
        10099, -- building_id (10099)
        'member_100', -- subscription_provider_id
        'SUBSCRIPTION', -- zzim_type
        TRUE -- activated
    );

    -- 50명의 회원은 50개의 피드 ID를 가지고, 빌딩 ID는 NULL
    WHILE i <= 51 DO
        INSERT INTO zzim (
            member_id,
            feed_id,
            building_id,
            subscription_provider_id,
            zzim_type,
            activated
        ) VALUES (
            CONCAT('member_', i), -- member_id
            9999 + i, -- feed_id (10001 ~ 10050)
            NULL, -- building_id
            NULL, -- subscription_provider_id
            IF(MOD(i,2)=0,'LIKE','BOOKMARK'), -- zzim_type (예시 값)
            TRUE -- activated
        );
        SET i = i + 1;
    END WHILE;

    -- 49명의 회원은 49개의 빌딩 ID를 가지고, 피드 ID는 NULL
    WHILE i <= 100 DO
        IF RAND() < 0.5 THEN
            SET random_provider_id = CONCAT('member_', i); -- member_id와 동일
        ELSE
            SET random_provider_id = CONCAT('member_', FLOOR(1 + (RAND() * 99))); -- 랜덤
        END IF;
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
            9999 + i, -- building_id (10051 ~ 10099)
            random_provider_id, -- subscription_provider_id
            'SUBSCRIPTION', -- zzim_type (예시 값)
            TRUE -- activated
        );
        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;


########################################################### 피드 예시 데이터 입력###############################################################
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
            CONCAT('member_', i), -- writer_id
            (i-1) + 10000, -- building_id
            CASE
                WHEN i <= 5 THEN TRUE
                ELSE FALSE
            END, -- main_activated (0~5: TRUE, 5~100: FALSE)
            CONCAT('Title_', i), -- title
            CONCAT('Feed text for feed ', i), -- feed_text
            MOD(i-1,9)+1, -- feed_category (예시 값)
            i, -- view_cnt
            IF(i <= 95, TRUE, FALSE) -- activated
        );
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
            CASE 
				WHEN MOD(i,3)=0 THEN 'COMMENT'
                WHEN MOD(i,3)=1 THEN 'LIKE'
                WHEN MOD(i,3)=2 THEN 'REPORT'
                END
            -- notification_type (짝수는 COMMENT, 홀수는 LIKE)
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
            reject_message,
	    activated
        ) VALUES (
			CONCAT('member_',i),
            CONCAT('member_',IF(i=100,1,i+1)),
            CONCAT('Apply message ', i), -- apply_message
            CONCAT('Reject message ', i), -- reject_message
	    TRUE
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
            chatroom_dajung_temp_min,
            activated
        ) VALUES (
            CONCAT('member_', i), -- chatroom_creator_id (member_1 ~ member_100)
            i + 9999, -- building_id (10000 ~ 10099)
            CONCAT('채팅방_', i), -- chatroom_name
            'GROUP_CHATTING',
            0,-- chatroom_type (짝수는 PRIVATE_CHATTING, 홀수는 GROUP_CHATTING)
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
	member_id VARCHAR(50) PRIMARY KEY,
    member_role ENUM('MEMBER','ADMIN') NOT NULL DEFAULT 'MEMBER',
    nickname VARCHAR(50) UNIQUE NOT NULL,
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
member_id VARCHAR(50),
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
    activated BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (applicant_id) REFERENCES members(member_id),
    FOREIGN KEY (respondent_id) REFERENCES members(member_id)
);
ALTER TABLE chat_apply AUTO_INCREMENT = 10000;
-- chatroom 테이블 생성
CREATE TABLE chatroom (
    chatroom_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    chatroom_creator_id VARCHAR(20) NOT NULL,
    building_id INT,
    chatroom_name VARCHAR(50) NOT NULL,
    chatroom_type ENUM('PRIVATE_CHATTING','GROUP_CHATTING') NOT NULL,
    chatroom_dajung_temp_min FLOAT DEFAULT 0,
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
    chatroom_member_id VARCHAR(50) NOT NULL,
    chatroom_member_type ENUM('MEMBER','OWNER') NOT NULL DEFAULT 'MEMBER',
    chatroom_entered_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    kicked BOOLEAN NOT NULL DEFAULT FALSE,
    activated BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (chatroom_id) REFERENCES chatroom(chatroom_id),
    FOREIGN KEY (chatroom_member_id) REFERENCES members(member_id)
);
ALTER TABLE chat_entrance AUTO_INCREMENT = 10000;

CALL insert_sample_members();
CALL insert_sample_buildings();
CALL insert_sample_feeds();
CALL insert_sample_zzims();
CALL insert_sample_feed_attachments();
CALL insert_sample_tags();
CALL insert_sample_tag_feeds();
CALL insert_sample_feed_comments();
CALL insert_sample_notifications();
CALL insert_sample_reports();
CALL insert_sample_member_relationships();
CALL insert_sample_chat_applies();
CALL insert_sample_chatrooms();
CALL insert_sample_chat_entrances();
### 멤버
UPDATE members SET nickname="웃음꽃피네",pwd="noon0716",phone_number="010-4543-1211",unlock_time="0001-01-01 01:01:01",profile_intro="반가워나는멤버1",dajung_score=89,member_profile_public_range="MUTUAL_ONLY" WHERE member_id="member_1";
UPDATE members SET member_role="MEMBER", nickname="잠금된닝겐10", pwd="noon0716",phone_number="010-1234-5842",unlock_time="2024-07-30 01:01:01",profile_intro="반가워나는잠금된멤버10", dajung_score=10,member_profile_public_range="PUBLIC" WHERE member_id="member_10";
UPDATE members SET nickname="특별한닝겐2",pwd="noon0716",phone_number="010-4543-1541",unlock_time="0101-01-01 01:01:01",profile_intro="반가워나는멤버2",dajung_score=85,member_profile_public_range="FOLLOWER_ONLY" WHERE member_id="member_2";
UPDATE members SET nickname="고독한사나이" WHERE member_id="member_2";
UPDATE members SET nickname="행복한미소" WHERE member_id="member_3";
UPDATE members SET nickname="눈물의왕자" WHERE member_id="member_4";
UPDATE members SET nickname="진지한철학자" WHERE member_id="member_5";
UPDATE members SET nickname="유쾌한모험가" WHERE member_id="member_6";
UPDATE members SET nickname="평온한바람" WHERE member_id="member_7";
UPDATE members SET nickname="슬픈기억" WHERE member_id="member_8";
UPDATE members SET nickname="신나는하루" WHERE member_id="member_9";
UPDATE members SET nickname="어두운밤" WHERE member_id="member_10";
UPDATE members SET nickname="웃기는사람" WHERE member_id="member_11";
UPDATE members SET nickname="조용한순간" WHERE member_id="member_12";
UPDATE members SET nickname="즐거운추억" WHERE member_id="member_13";
UPDATE members SET nickname="가슴아픈이야기" WHERE member_id="member_14";
UPDATE members SET nickname="낙천적인사람" WHERE member_id="member_15";
UPDATE members SET nickname="진지한사색" WHERE member_id="member_16";
UPDATE members SET nickname="행복의빛" WHERE member_id="member_17";
UPDATE members SET nickname="눈물의연못" WHERE member_id="member_18";
UPDATE members SET nickname="기분좋은날" WHERE member_id="member_19";
UPDATE members SET nickname="어두운그림자" WHERE member_id="member_20";
UPDATE members SET nickname="개그맨" WHERE member_id="member_21";
UPDATE members SET nickname="심오한이야기" WHERE member_id="member_22";
UPDATE members SET nickname="환한미소" WHERE member_id="member_23";
UPDATE members SET nickname="쓸쓸한밤" WHERE member_id="member_24";
UPDATE members SET nickname="웃긴사연" WHERE member_id="member_25";
UPDATE members SET nickname="심각한토론" WHERE member_id="member_26";
UPDATE members SET nickname="희망의불빛" WHERE member_id="member_27";
UPDATE members SET nickname="슬픈추억" WHERE member_id="member_28";
UPDATE members SET nickname="활기찬아침" WHERE member_id="member_29";
UPDATE members SET nickname="침울한날" WHERE member_id="member_30";
UPDATE members SET nickname="재밌는이야기" WHERE member_id="member_31";
UPDATE members SET nickname="고요한사색" WHERE member_id="member_32";
UPDATE members SET nickname="기쁨의순간" WHERE member_id="member_33";
UPDATE members SET nickname="눈물의기억" WHERE member_id="member_34";
UPDATE members SET nickname="즐거운여행" WHERE member_id="member_35";
UPDATE members SET nickname="깊은상념" WHERE member_id="member_36";
UPDATE members SET nickname="웃음가득" WHERE member_id="member_37";
UPDATE members SET nickname="비통한이별" WHERE member_id="member_38";
UPDATE members SET nickname="기쁜하루" WHERE member_id="member_39";
UPDATE members SET nickname="어두운밤하늘" WHERE member_id="member_40";
UPDATE members SET nickname="코믹한사건" WHERE member_id="member_41";
UPDATE members SET nickname="엄숙한의식" WHERE member_id="member_42";
UPDATE members SET nickname="행복한시간" WHERE member_id="member_43";
UPDATE members SET nickname="눈물의강" WHERE member_id="member_44";
UPDATE members SET nickname="웃음의전사" WHERE member_id="member_45";
UPDATE members SET nickname="깊은생각" WHERE member_id="member_46";
UPDATE members SET nickname="즐거운시간" WHERE member_id="member_47";
UPDATE members SET nickname="비통한기억" WHERE member_id="member_48";
UPDATE members SET nickname="행복의순간" WHERE member_id="member_49";
UPDATE members SET nickname="어두운기억" WHERE member_id="member_50";
UPDATE members SET nickname="웃기는이야기" WHERE member_id="member_51";
UPDATE members SET nickname="진지한시간" WHERE member_id="member_52";
UPDATE members SET nickname="행복한추억" WHERE member_id="member_53";
UPDATE members SET nickname="눈물의시간" WHERE member_id="member_54";
UPDATE members SET nickname="코믹한모험" WHERE member_id="member_55";
UPDATE members SET nickname="엄숙한순간" WHERE member_id="member_56";
UPDATE members SET nickname="행복의날" WHERE member_id="member_57";
UPDATE members SET nickname="슬픔의끝" WHERE member_id="member_58";
UPDATE members SET nickname="재밌는추억" WHERE member_id="member_59";
UPDATE members SET nickname="깊은사유" WHERE member_id="member_60";
UPDATE members SET nickname="행복한웃음" WHERE member_id="member_61";
UPDATE members SET nickname="눈물의밤" WHERE member_id="member_62";
UPDATE members SET nickname="유쾌한이야기" WHERE member_id="member_63";
UPDATE members SET nickname="진지한대화" WHERE member_id="member_64";
UPDATE members SET nickname="기쁨의추억" WHERE member_id="member_65";
UPDATE members SET nickname="비통한눈물" WHERE member_id="member_66";
UPDATE members SET nickname="웃음의날" WHERE member_id="member_67";
UPDATE members SET nickname="심각한순간" WHERE member_id="member_68";
UPDATE members SET nickname="행복의추억" WHERE member_id="member_69";
UPDATE members SET nickname="눈물의순간" WHERE member_id="member_70";
UPDATE members SET nickname="코믹한사연" WHERE member_id="member_71";
UPDATE members SET nickname="깊은단상" WHERE member_id="member_72";
UPDATE members SET nickname="기쁜순간" WHERE member_id="member_73";
UPDATE members SET nickname="슬픔의밤" WHERE member_id="member_74";
UPDATE members SET nickname="유쾌한순간" WHERE member_id="member_75";
UPDATE members SET nickname="진지한생각" WHERE member_id="member_76";
UPDATE members SET nickname="행복한기억" WHERE member_id="member_77";
UPDATE members SET nickname="눈물의날" WHERE member_id="member_78";
UPDATE members SET nickname="재밌는순간" WHERE member_id="member_79";
UPDATE members SET nickname="깊은밤" WHERE member_id="member_80";
UPDATE members SET nickname="웃음의순간" WHERE member_id="member_81";
UPDATE members SET nickname="심각한상황" WHERE member_id="member_82";
UPDATE members SET nickname="행복의기억" WHERE member_id="member_83";
UPDATE members SET nickname="눈물의이야기" WHERE member_id="member_84";
UPDATE members SET nickname="코믹한웃음" WHERE member_id="member_85";
UPDATE members SET nickname="깊은밤하늘" WHERE member_id="member_86";
UPDATE members SET nickname="기쁨의날" WHERE member_id="member_87";
UPDATE members SET nickname="슬픔의이별" WHERE member_id="member_88";
UPDATE members SET nickname="유쾌한하루" WHERE member_id="member_89";
UPDATE members SET nickname="진지한토론" WHERE member_id="member_90";
UPDATE members SET nickname="행복한모임" WHERE member_id="member_91";
UPDATE members SET nickname="눈물의추억" WHERE member_id="member_92";
UPDATE members SET nickname="웃음의모험" WHERE member_id="member_93";
UPDATE members SET nickname="심각한생각" WHERE member_id="member_94";
UPDATE members SET nickname="행복한만남" WHERE member_id="member_95";
UPDATE members SET nickname="눈물의만남" WHERE member_id="member_96";
UPDATE members SET nickname="코믹한순간" WHERE member_id="member_97";
UPDATE members SET nickname="깊은대화" WHERE member_id="member_98";
UPDATE members SET nickname="기쁨의만남" WHERE member_id="member_99";
UPDATE members SET nickname="슬픔의기억" WHERE member_id="member_100";
UPDATE members SET profile_photo_url="https://picsum.photos/id/237/200/300" WHERE member_id="member_1";
UPDATE members SET profile_photo_url="https://picsum.photos/id/1/200/300" WHERE member_id="member_20";
UPDATE members SET profile_photo_url="https://picsum.photos/id/0/5000/3333" WHERE member_id="member_21";
UPDATE members SET profile_photo_url="https://picsum.photos/id/10/2500/1667" WHERE member_id="member_22";
UPDATE members SET profile_photo_url="https://picsum.photos/id/11/2500/1667" WHERE member_id="member_23";
UPDATE members SET profile_photo_url="https://picsum.photos/id/12/2500/1667" WHERE member_id="member_24";
UPDATE members SET profile_photo_url="https://picsum.photos/id/16/2500/1667" WHERE member_id="member_25";
UPDATE members SET profile_photo_url="https://picsum.photos/id/17/2500/1667" WHERE member_id="member_26";
UPDATE members SET profile_photo_url="https://picsum.photos/id/15/2500/1667" WHERE member_id="member_27";
UPDATE members SET profile_photo_url="https://picsum.photos/id/19/2500/1667" WHERE member_id="member_28";
UPDATE members SET profile_photo_url="https://picsum.photos/id/18/2500/1667" WHERE member_id="member_29";
UPDATE members SET profile_photo_url="https://picsum.photos/id/20/3670/2462" WHERE member_id="member_30";
UPDATE members SET profile_photo_url="https://picsum.photos/id/21/3008/2008" WHERE member_id="member_31";
UPDATE members SET profile_photo_url="https://picsum.photos/id/22/4434/3729" WHERE member_id="member_32";
UPDATE members SET profile_photo_url="https://picsum.photos/id/23/3887/4899" WHERE member_id="member_33";
UPDATE members SET profile_photo_url="https://picsum.photos/id/25/5000/3333" WHERE member_id="member_34";
UPDATE members SET profile_photo_url="https://picsum.photos/id/24/4855/1803" WHERE member_id="member_35";
UPDATE members SET profile_photo_url="https://picsum.photos/id/26/4209/2769" WHERE member_id="member_36";
UPDATE members SET profile_photo_url="https://picsum.photos/id/27/3264/1836" WHERE member_id="member_37";
UPDATE members SET profile_photo_url="https://picsum.photos/id/28/4928/3264" WHERE member_id="member_38";
UPDATE members SET profile_photo_url="https://picsum.photos/id/29/4000/2670" WHERE member_id="member_39";
UPDATE members SET profile_photo_url="https://picsum.photos/id/51/5000/3333" WHERE member_id="member_50";
UPDATE members SET profile_photo_url="https://picsum.photos/id/52/1280/853" WHERE member_id="member_51";
UPDATE members SET profile_photo_url="https://picsum.photos/id/53/1280/1280" WHERE member_id="member_52";
UPDATE members SET profile_photo_url="https://picsum.photos/id/55/4608/3072" WHERE member_id="member_53";
UPDATE members SET profile_photo_url="https://picsum.photos/id/56/2880/1920" WHERE member_id="member_54";
UPDATE members SET profile_photo_url="https://picsum.photos/id/57/2448/3264" WHERE member_id="member_55";
UPDATE members SET profile_photo_url="https://picsum.photos/id/58/1280/853" WHERE member_id="member_56";
UPDATE members SET profile_photo_url="https://picsum.photos/id/59/2464/1632" WHERE member_id="member_57";
UPDATE members SET profile_photo_url="https://picsum.photos/id/60/1920/1200" WHERE member_id="member_58";
UPDATE members SET profile_photo_url="https://picsum.photos/id/61/3264/2448" WHERE member_id="member_59";
UPDATE members SET profile_photo_url="https://picsum.photos/id/62/2000/1333" WHERE member_id="member_60";
UPDATE members SET profile_photo_url="https://picsum.photos/id/63/5000/2813" WHERE member_id="member_61";
UPDATE members SET profile_photo_url="https://picsum.photos/id/64/4326/2884" WHERE member_id="member_62";
UPDATE members SET profile_photo_url="https://picsum.photos/id/65/4912/3264" WHERE member_id="member_63";
UPDATE members SET profile_photo_url="https://picsum.photos/id/66/3264/2448" WHERE member_id="member_64";
UPDATE members SET profile_photo_url="https://picsum.photos/id/67/2848/4288" WHERE member_id="member_65";
UPDATE members SET profile_photo_url="https://picsum.photos/id/68/4608/3072" WHERE member_id="member_66";
UPDATE members SET profile_photo_url="https://picsum.photos/id/69/4912/3264" WHERE member_id="member_67";
UPDATE members SET profile_photo_url="https://picsum.photos/id/70/3011/2000" WHERE member_id="member_68";
UPDATE members SET profile_photo_url="https://picsum.photos/id/71/5000/3333" WHERE member_id="member_69";
UPDATE members SET profile_photo_url="https://picsum.photos/id/72/3000/2000" WHERE member_id="member_70";
UPDATE members SET profile_photo_url="https://picsum.photos/id/73/5000/3333" WHERE member_id="member_71";
UPDATE members SET profile_photo_url="https://picsum.photos/id/74/4288/2848" WHERE member_id="member_72";
UPDATE members SET profile_photo_url="https://picsum.photos/id/75/1999/2998" WHERE member_id="member_73";
UPDATE members SET profile_photo_url="https://picsum.photos/id/76/4912/3264" WHERE member_id="member_74";
UPDATE members SET profile_photo_url="https://picsum.photos/id/77/1631/1102" WHERE member_id="member_75";
UPDATE members SET profile_photo_url="https://picsum.photos/id/78/1584/2376" WHERE member_id="member_76";
UPDATE members SET profile_photo_url="https://picsum.photos/id/79/2000/3011" WHERE member_id="member_77";
UPDATE members SET profile_photo_url="https://picsum.photos/id/80/3888/2592" WHERE member_id="member_78";
UPDATE members SET profile_photo_url="https://picsum.photos/id/90/3000/1992" WHERE member_id="member_79";
UPDATE members SET profile_photo_url="https://picsum.photos/id/51/5000/3333" WHERE member_id="member_80";
UPDATE members SET profile_photo_url="https://picsum.photos/id/237/200/300" WHERE member_id="member_90";


### 빌딩
UPDATE building SET building_name = '역삼타워', profile_activated = TRUE, road_addr = '서울시 강남구 역삼동 101-1', longitude = 127.0350, latitude = 37.4979, feed_ai_summary = '강남 중심에 위치한 모던한 타워' WHERE building_id = 10000;
UPDATE building SET building_name = '테헤란로빌딩', profile_activated = TRUE, road_addr = '서울시 강남구 역삼동 102-2', longitude = 127.0360, latitude = 37.4989, feed_ai_summary = '현대적인 설계를 자랑하는 빌딩' WHERE building_id = 10001;
UPDATE building SET building_name = '프라임센터', profile_activated = TRUE, road_addr = '서울시 강남구 역삼동 103-3', longitude = 127.0370, latitude = 37.4999, feed_ai_summary = '편리한 교통을 갖춘 업무용 센터' WHERE building_id = 10002;
UPDATE building SET building_name = '미래타워', profile_activated = TRUE, road_addr = '서울시 강남구 역삼동 104-4', longitude = 127.0380, latitude = 37.5009, feed_ai_summary = '녹지 공간과 함께하는 미래 지향적 타워' WHERE building_id = 10003;
UPDATE building SET building_name = '글로벌센터', profile_activated = TRUE, road_addr = '서울시 강남구 역삼동 105-5', longitude = 127.0390, latitude = 37.5019, feed_ai_summary = '국제적인 비즈니스 허브' WHERE building_id = 10004;
UPDATE building SET building_name = '하이테크빌딩', profile_activated = TRUE, road_addr = '서울시 강남구 역삼동 106-6', longitude = 127.0400, latitude = 37.5029, feed_ai_summary = '첨단 기술을 갖춘 하이테크 빌딩' WHERE building_id = 10005;
UPDATE building SET building_name = '역삼스퀘어', profile_activated = TRUE, road_addr = '서울시 강남구 역삼동 107-7', longitude = 127.0410, latitude = 37.5039, feed_ai_summary = '비즈니스와 문화의 중심 스퀘어' WHERE building_id = 10006;
UPDATE building SET building_name = '강남비즈타워', profile_activated = TRUE, road_addr = '서울시 강남구 역삼동 108-8', longitude = 127.0420, latitude = 37.5049, feed_ai_summary = '비즈니스에 최적화된 타워' WHERE building_id = 10007;
UPDATE building SET building_name = 'IT밸리', profile_activated = TRUE, road_addr = '서울시 강남구 역삼동 109-9', longitude = 127.0430, latitude = 37.5059, feed_ai_summary = 'IT 기업들을 위한 전문 밸리' WHERE building_id = 10008;
UPDATE building SET building_name = '크리에이티브타워', profile_activated = TRUE, road_addr = '서울시 강남구 역삼동 110-10', longitude = 127.0440, latitude = 37.5069, feed_ai_summary = '창의적 공간을 제공하는 타워' WHERE building_id = 10009;
UPDATE building SET building_name = '비즈니스하우스', profile_activated = TRUE, road_addr = '서울시 강남구 역삼동 111-11', longitude = 127.0450, latitude = 37.5079, feed_ai_summary = '비즈니스의 새로운 기준' WHERE building_id = 10010;
UPDATE building SET building_name = '아트센터', profile_activated = TRUE, road_addr = '서울시 강남구 역삼동 112-12', longitude = 127.0460, latitude = 37.5089, feed_ai_summary = '예술과 업무의 융합 공간' WHERE building_id = 10011;
UPDATE building SET building_name = '스마트타워', profile_activated = TRUE, road_addr = '서울시 강남구 역삼동 113-13', longitude = 127.0470, latitude = 37.5099, feed_ai_summary = '스마트 기술을 갖춘 타워' WHERE building_id = 10012;
UPDATE building SET building_name = '에코타워', profile_activated = TRUE, road_addr = '서울시 강남구 역삼동 114-14', longitude = 127.0480, latitude = 37.5109, feed_ai_summary = '친환경 설계를 자랑하는 타워' WHERE building_id = 10013;
UPDATE building SET building_name = '럭셔리센터', profile_activated = TRUE, road_addr = '서울시 강남구 역삼동 115-15', longitude = 127.0490, latitude = 37.5119, feed_ai_summary = '럭셔리한 비즈니스 센터' WHERE building_id = 10014;
UPDATE building SET building_name = '디지털타워', profile_activated = TRUE, road_addr = '서울시 강남구 역삼동 116-16', longitude = 127.0500, latitude = 37.5129, feed_ai_summary = '디지털 혁신을 위한 타워' WHERE building_id = 10015;
UPDATE building SET building_name = '유니콘빌딩', profile_activated = TRUE, road_addr = '서울시 강남구 역삼동 117-17', longitude = 127.0510, latitude = 37.5139, feed_ai_summary = '유니콘 기업을 위한 빌딩' WHERE building_id = 10016;
UPDATE building SET building_name = '솔라타워', profile_activated = TRUE, road_addr = '서울시 강남구 역삼동 118-18', longitude = 127.0520, latitude = 37.5149, feed_ai_summary = '태양광 에너지를 사용하는 타워' WHERE building_id = 10017;
UPDATE building SET building_name = '리더스센터', profile_activated = TRUE, road_addr = '서울시 강남구 역삼동 119-19', longitude = 127.0530, latitude = 37.5159, feed_ai_summary = '리더들을 위한 비즈니스 센터' WHERE building_id = 10018;
UPDATE building SET building_name = '파이낸스타워', profile_activated = TRUE, road_addr = '서울시 강남구 역삼동 120-20', longitude = 127.0540, latitude = 37.5169, feed_ai_summary = '금융 기업들을 위한 타워' WHERE building_id = 10019;
UPDATE building SET building_name = '에비뉴타워', profile_activated = TRUE, road_addr = '서울시 강남구 역삼동 121-21', longitude = 127.0550, latitude = 37.5179, feed_ai_summary = '쇼핑과 업무가 결합된 타워' WHERE building_id = 10020;
UPDATE building SET building_name = '글로벌하우스', profile_activated = TRUE, road_addr = '서울시 강남구 역삼동 122-22', longitude = 127.0560, latitude = 37.5189, feed_ai_summary = '글로벌 비즈니스 허브' WHERE building_id = 10021;
UPDATE building SET building_name = '넥스트타워', profile_activated = TRUE, road_addr = '서울시 강남구 역삼동 123-23', longitude = 127.0570, latitude = 37.5199, feed_ai_summary = '미래를 준비하는 타워' WHERE building_id = 10022;
UPDATE building SET building_name = '업무타워', profile_activated = TRUE, road_addr = '서울시 강남구 역삼동 124-24', longitude = 127.0580, latitude = 37.5209, feed_ai_summary = '업무 효율성을 극대화한 타워' WHERE building_id = 10023;
UPDATE building SET building_name = '포커스빌딩', profile_activated = TRUE, road_addr = '서울시 강남구 역삼동 125-25', longitude = 127.0590, latitude = 37.5219, feed_ai_summary = '집중 업무 환경 제공' WHERE building_id = 10024;
UPDATE building SET building_name = '스타트업타워', profile_activated = TRUE , road_addr = '서울시 강남구 역삼동 126-26', longitude = 127.0600, latitude = 37.5229, feed_ai_summary = '스타트업을 위한 타워' WHERE building_id = 10025;
UPDATE building SET building_name = '이노베이션타워', profile_activated = TRUE, road_addr = '서울시 강남구 역삼동 127-27', longitude = 127.0610, latitude = 37.5239, feed_ai_summary = '혁신적인 업무 공간' WHERE building_id = 10026;

###찜


### 피드
INSERT INTO feed (writer_id, building_id, main_activated, public_range, title, feed_text, view_cnt, feed_category) VALUES
('member_1', 10001, FALSE, 'FOLLOWER_ONLY', '예시 제목 1-1', '여기는 예시 피드 1-1의 내용입니다.', 100, 'COMPLIMENT'),
('member_1', 10001, FALSE, 'MUTUAL_ONLY', '예시 제목 1-2', '여기는 예시 피드 1-2의 내용입니다.', 100, 'QUESTION'),
('member_1', 10001, FALSE, 'PRIVATE', '예시 제목 1-3', '여기는 예시 피드 1-3의 내용입니다.', 100, 'EVENT'),
('member_1', 10001, FALSE, 'PUBLIC', '예시 제목 1-4', '여기는 예시 피드 1-4의 내용입니다.', 100, 'POLL'),
('member_1', 10001, FALSE, 'PUBLIC', '예시 제목 1-5', '여기는 예시 피드 1-5의 내용입니다.', 100, 'GENERAL'),
('member_1', 10001, FALSE, 'PUBLIC', '예시 제목 1-6', '여기는 예시 피드 1-6의 내용입니다.', 100, 'GENERAL'),
('member_1', 10001, FALSE, 'PUBLIC', '예시 제목 1-7', '여기는 예시 피드 1-7의 내용입니다.', 100, 'GENERAL'),
('member_1', 10001, FALSE, 'PUBLIC', '예시 제목 1-8', '여기는 예시 피드 1-8의 내용입니다.', 100, 'GENERAL'),
('member_1', 10001, FALSE, 'PUBLIC', '예시 제목 1-9', '여기는 예시 피드 1-9의 내용입니다.', 100, 'GENERAL'),
('member_1', 10001, FALSE, 'PUBLIC', '예시 제목 1-10', '여기는 예시 피드 1-10의 내용입니다.', 100, 'GENERAL');
INSERT INTO feed (writer_id, building_id, main_activated, public_range, title, feed_text, view_cnt, feed_category) VALUES
('member_10', 10002, FALSE, 'FOLLOWER_ONLY', '예시 제목 10-1', '여기는 예시 피드 10-1의 내용입니다.', 100, 'COMPLIMENT'),
('member_10', 10002, FALSE, 'MUTUAL_ONLY', '예시 제목 10-2', '여기는 예시 피드 10-2의 내용입니다.', 100, 'QUESTION'),
('member_10', 10002, FALSE, 'PRIVATE', '예시 제목 10-3', '여기는 예시 피드 10-3의 내용입니다.', 100, 'EVENT'),
('member_10', 10002, FALSE, 'PUBLIC', '예시 제목 10-4', '여기는 예시 피드 10-4의 내용입니다.', 100, 'POLL'),
('member_10', 10002, FALSE, 'PUBLIC', '예시 제목 10-5', '여기는 예시 피드 10-5의 내용입니다.', 100, 'GENERAL'),
('member_10', 10002, FALSE, 'PUBLIC', '예시 제목 10-6', '여기는 예시 피드 10-6의 내용입니다.', 100, 'GENERAL'),
('member_10', 10002, FALSE, 'PUBLIC', '예시 제목 10-7', '여기는 예시 피드 10-7의 내용입니다.', 100, 'GENERAL'),
('member_10', 10002, FALSE, 'PUBLIC', '예시 제목 10-8', '여기는 예시 피드 10-8의 내용입니다.', 100, 'GENERAL'),
('member_10', 10002, FALSE, 'PUBLIC', '예시 제목 10-9', '여기는 예시 피드 10-9의 내용입니다.', 100, 'GENERAL'),
('member_10', 10002, FALSE, 'PUBLIC', '예시 제목 10-10', '여기는 예시 피드 10-10의 내용입니다.', 100, 'GENERAL');
INSERT INTO feed (writer_id, building_id, main_activated, public_range, title, feed_text, view_cnt, feed_category) VALUES
('member_100', 10000, FALSE, 'FOLLOWER_ONLY', '예시 제목 100-1', '여기는 예시 피드 100-1의 내용입니다.', 100, 'COMPLIMENT'),
('member_100', 10000, FALSE, 'MUTUAL_ONLY', '예시 제목 100-2', '여기는 예시 피드 100-2의 내용입니다.', 100, 'QUESTION'),
('member_100', 10000, FALSE, 'PRIVATE', '예시 제목 100-3', '여기는 예시 피드 100-3의 내용입니다.', 100, 'EVENT'),
('member_100', 10000, FALSE, 'PUBLIC', '예시 제목 100-4', '여기는 예시 피드 100-4의 내용입니다.', 100, 'POLL'),
('member_100', 10000, FALSE, 'PUBLIC', '예시 제목 100-5', '여기는 예시 피드 100-5의 내용입니다.', 100, 'GENERAL'),
('member_100', 10000, FALSE, 'PUBLIC', '예시 제목 100-6', '여기는 예시 피드 100-6의 내용입니다.', 100, 'GENERAL'),
('member_100', 10000, FALSE, 'PUBLIC', '예시 제목 100-7', '여기는 예시 피드 100-7의 내용입니다.', 100, 'GENERAL'),
('member_100', 10000, FALSE, 'PUBLIC', '예시 제목 100-8', '여기는 예시 피드 100-8의 내용입니다.', 100, 'GENERAL'),
('member_100', 10000, FALSE, 'PUBLIC', '예시 제목 100-9', '여기는 예시 피드 100-9의 내용입니다.', 100, 'GENERAL'),
('member_100', 10000, FALSE, 'PUBLIC', '예시 제목 100-10', '여기는 예시 피드 100-10의 내용입니다.', 100, 'GENERAL');
#찜 아래에 있음
### 피드코멘트 
INSERT INTO feed_comment (feed_id, commenter_id, comment_text, written_time, activated) VALUES
(10000, 'member_2', '여기는 예시 댓글 1의 내용입니다.', NOW(), TRUE),
(10000, 'member_3', '여기는 예시 댓글 2의 내용입니다.', NOW(), TRUE),
(10000, 'member_4', '여기는 예시 댓글 3의 내용입니다.', NOW(), TRUE),
(10000, 'member_5', '여기는 예시 댓글 4의 내용입니다.', NOW(), TRUE),
(10000, 'member_6', '여기는 예시 댓글 5의 내용입니다.', NOW(), TRUE),
(10000, 'member_7', '여기는 예시 댓글 6의 내용입니다.', NOW(), TRUE),
(10000, 'member_8', '여기는 예시 댓글 7의 내용입니다.', NOW(), TRUE),
(10000, 'member_9', '여기는 예시 댓글 8의 내용입니다.', NOW(), TRUE),
(10000, 'member_10', '여기는 예시 댓글 9의 내용입니다.', NOW(), FALSE),
(10000, 'member_11', '여기는 예시 댓글 10의 내용입니다.', NOW(), FALSE);
### 피드어태치
INSERT INTO feed_attachment (feed_id, file_url, file_type, blurred_file_url, activated) VALUES
(10000, 'http://example.com/photo1.jpg', 'PHOTO', 'http://example.com/blurred_photo1.jpg', TRUE),
(10000, 'http://example.com/video1.mp4', 'VIDEO', NULL, TRUE),
(10000, 'http://example.com/photo2.jpg', 'PHOTO', 'http://example.com/blurred_photo2.jpg', TRUE),
(10000, 'http://example.com/video2.mp4', 'VIDEO', NULL, TRUE),
(10000, 'http://example.com/photo3.jpg', 'PHOTO', NULL, TRUE);
### 태그 생략
### 태그피드
INSERT INTO tag_feed (feed_id, tag_id) VALUES
(10000, 10001),
(10000, 10002),
(10000, 10003),
(10000, 10004),
(10000, 10005);
### 노티피케이션
INSERT INTO notification (receiver_id, notification_text, notification_type) VALUES
('member_1', '회원님의 게시물에 댓글이 달렸습니다.', 'COMMENT'),
('member_1', '회원님의 게시물이 좋아요를 받았습니다.', 'LIKE'),
('member_1', '회원님의 신고가 반영되었습니다.', 'REPORT'),
('member_1', '회원님의 게시물에 댓글이 달렸습니다.', 'COMMENT'),
('member_1', '회원님의 게시물이 좋아요를 받았습니다.', 'LIKE'),
('member_1', '회원님의 신고가 반영되었습니다.', 'REPORT'),
('member_1', '회원님의 게시물에 댓글이 달렸습니다.', 'COMMENT'),
('member_1', '회원님의 게시물이 좋아요를 받았습니다.', 'LIKE'),
('member_1', '회원님의 신고가 반영되었습니다.', 'REPORT'),
('member_1', '회원님의 게시물에 댓글이 달렸습니다.', 'COMMENT');

### 리포트
INSERT INTO report (reporter_id, reportee_id, report_status, report_text, reported_time, processing_text) VALUES
('member_1', 'member_3', 'PEND', '회원님이 부적절한 게시물을 올렸습니다. 그래서 신고했습니다.', NOW(), NULL),
('member_1', 'member_4', 'ACCEPT', '회원님이 부적절한 댓글을 작성했습니다. 그래서 신고했습니다.', NOW(), '좋습니다. 반영합니다.'),
('member_1', 'member_5', 'REJECT', '회원님이 스팸 메시지를 보냈습니다. 그래서 신고했습니다.', NOW(), '그런 정황이 드러나지 않아서 반영이 어려울 것같습니다'),
('member_1', 'member_6', 'PEND', '회원님이 부적절한 사진을 올렸습니다. 그래서 신고했습니다.', NOW(), NULL),
('member_1', 'member_7', 'ACCEPT', '회원님이 부적절한 언행을 했습니다. 그래서 신고했습니다.', NOW(), '좋습니다. 반영합니다.'),
('member_1', 'member_8', 'REJECT', '회원님이 부적절한 영상을 올렸습니다. 그래서 신고했습니다.', NOW(), '그런 정황이 드러나지 않아서 반영이 어려울 것같습니다'),
('member_1', 'member_9', 'PEND', '회원님이 부적절한 행동을 했습니다. 그래서 신고했습니다.', NOW(), NULL),
('member_1', 'member_10', 'ACCEPT', '회원님이 부적절한 파일을 공유했습니다. 그래서 신고했습니다.', NOW(), '좋습니다. 반영합니다.'),
('member_1', 'member_11', 'REJECT', '회원님이 부적절한 광고를 올렸습니다. 그래서 신고했습니다.', NOW(), '그런 정황이 드러나지 않아서 반영이 어려울 것같습니다'),
('member_1', 'member_12', 'PEND', '회원님이 부적절한 내용을 작성했습니다. 그래서 신고했습니다.', NOW(), NULL);
### 멤버관계 생략
### 챗어플라이
INSERT INTO chat_apply (applicant_id, respondent_id, apply_message, reject_message,activated) VALUES
('member_2', 'member_1', '안녕하세요, 채팅 신청드립니다.', NULL,TRUE),
('member_3', 'member_1', '안녕하세요, 채팅하고 싶습니다.', '죄송합니다, 채팅이 어렵습니다.',FALSE),
('member_4', 'member_1', '채팅 신청합니다.', NULL,TRUE),
('member_5', 'member_1', '채팅 가능할까요?', '채팅이 어렵습니다. 죄송합니다.',TRUE),
('member_6', 'member_1', '채팅 요청 드립니다.', NULL,TRUE),
('member_7', 'member_1', '채팅하고 싶습니다.', '현재 채팅이 어렵습니다.',FALSE),
('member_8', 'member_1', '채팅 부탁드립니다.', NULL,TRUE),
('member_9', 'member_1', '채팅 가능하신가요?', '죄송합니다, 지금은 채팅이 어렵습니다.',FALSE),
('member_10', 'member_1', '채팅 신청합니다.', NULL,TRUE),
('member_11', 'member_1', '채팅 원합니다.', '현재 채팅이 불가능합니다.',FALSE);

### 챗룸
-- 첫 10개 채팅방 (GROUP_CHATTING 타입)
INSERT INTO chatroom (chatroom_creator_id, building_id, chatroom_name, chatroom_type, chatroom_dajung_temp_min, activated) VALUES
('member_1', 10000, '채팅방 1', 'GROUP_CHATTING', 0, TRUE),
('member_1', 10000, '채팅방 2', 'GROUP_CHATTING', 0, FALSE),
('member_1', 10000, '채팅방 3', 'GROUP_CHATTING', 0, TRUE),
('member_1', 10000, '채팅방 4', 'GROUP_CHATTING', 0, TRUE),
('member_1', 10000, '채팅방 5', 'GROUP_CHATTING', 0, FALSE),
('member_1', 10000, '채팅방 6', 'GROUP_CHATTING', 0, TRUE),
('member_1', 10000, '채팅방 7', 'GROUP_CHATTING', 0, TRUE),
('member_1', 10000, '채팅방 8', 'GROUP_CHATTING', 0, FALSE),
('member_1', 10000, '채팅방 9', 'GROUP_CHATTING', 99, TRUE),
('member_1', 10000, '채팅방 10', 'GROUP_CHATTING', 99, FALSE);

-- 나머지 10개 채팅방 (PRIVATE_CHATTING 타입)
INSERT INTO chatroom (chatroom_creator_id, building_id, chatroom_name, chatroom_type, chatroom_dajung_temp_min, activated) VALUES
('member_1', 10000, '프라이빗 채팅방 1', 'PRIVATE_CHATTING', 0, TRUE),
('member_1', 10000, '프라이빗 채팅방 2', 'PRIVATE_CHATTING', 0, FALSE),
('member_1', 10000, '프라이빗 채팅방 3', 'PRIVATE_CHATTING', 0, TRUE),
('member_1', 10000, '프라이빗 채팅방 4', 'PRIVATE_CHATTING', 0, FALSE),
('member_1', 10000, '프라이빗 채팅방 5', 'PRIVATE_CHATTING', 0, TRUE),
('member_1', 10000, '프라이빗 채팅방 6', 'PRIVATE_CHATTING', 0, FALSE),
('member_1', 10000, '프라이빗 채팅방 7', 'PRIVATE_CHATTING', 0, TRUE),
('member_1', 10000, '프라이빗 채팅방 8', 'PRIVATE_CHATTING', 0, FALSE),
('member_1', 10000, '프라이빗 채팅방 9', 'PRIVATE_CHATTING', 0, TRUE),
('member_1', 10000, '프라이빗 채팅방 10', 'PRIVATE_CHATTING', 0, FALSE);

### 챗 인트런스
INSERT INTO chat_entrance (chatroom_id, chatroom_member_id, chatroom_member_type, chatroom_entered_time, kicked, activated) VALUES
(10100, 'member_1', 'OWNER', NOW(), FALSE, TRUE),
(10101, 'member_1', 'OWNER', NOW(), FALSE, TRUE),
(10102, 'member_1', 'OWNER', NOW(), FALSE, TRUE),
(10103, 'member_1', 'OWNER', NOW(), FALSE, TRUE),
(10104, 'member_1', 'OWNER', NOW(), FALSE, TRUE),
(10105, 'member_1', 'OWNER', NOW(), FALSE, TRUE),
(10106, 'member_1', 'OWNER', NOW(), FALSE, TRUE),
(10107, 'member_1', 'OWNER', NOW(), FALSE, TRUE),
(10108, 'member_1', 'OWNER', NOW(), FALSE, TRUE),
(10109, 'member_1', 'OWNER', NOW(), FALSE, TRUE);

-- 각 채팅방에 member_2부터 member_10까지의 MEMBER들 추가
-- 10100 채팅방
INSERT INTO chat_entrance (chatroom_id, chatroom_member_id, chatroom_member_type, chatroom_entered_time, kicked, activated) VALUES
(10100, 'member_2', 'MEMBER', NOW(), FALSE, TRUE),
(10100, 'member_3', 'MEMBER', NOW(), FALSE, TRUE),
(10100, 'member_4', 'MEMBER', NOW(), FALSE, TRUE),
(10100, 'member_5', 'MEMBER', NOW(), FALSE, TRUE),
(10100, 'member_6', 'MEMBER', NOW(), FALSE, TRUE),
(10100, 'member_7', 'MEMBER', NOW(), FALSE, TRUE),
(10100, 'member_8', 'MEMBER', NOW(), FALSE, TRUE),
(10100, 'member_100', 'MEMBER', NOW(), FALSE, TRUE),
(10100, 'member_10', 'MEMBER', NOW(), FALSE, TRUE);

-- 10101 채팅방
INSERT INTO chat_entrance (chatroom_id, chatroom_member_id, chatroom_member_type, chatroom_entered_time, kicked, activated) VALUES
(10101, 'member_2', 'MEMBER', NOW(), FALSE, TRUE),
(10101, 'member_3', 'MEMBER', NOW(), FALSE, TRUE),
(10101, 'member_4', 'MEMBER', NOW(), FALSE, TRUE),
(10101, 'member_5', 'MEMBER', NOW(), FALSE, TRUE),
(10101, 'member_6', 'MEMBER', NOW(), FALSE, TRUE),
(10101, 'member_7', 'MEMBER', NOW(), FALSE, TRUE),
(10101, 'member_8', 'MEMBER', NOW(), FALSE, TRUE),
(10101, 'member_100', 'MEMBER', NOW(), FALSE, TRUE),
(10101, 'member_10', 'MEMBER', NOW(), FALSE, TRUE);

-- 10102 채팅방
INSERT INTO chat_entrance (chatroom_id, chatroom_member_id, chatroom_member_type, chatroom_entered_time, kicked, activated) VALUES
(10102, 'member_2', 'MEMBER', NOW(), FALSE, TRUE),
(10102, 'member_3', 'MEMBER', NOW(), FALSE, TRUE),
(10102, 'member_4', 'MEMBER', NOW(), FALSE, TRUE),
(10102, 'member_5', 'MEMBER', NOW(), FALSE, TRUE),
(10102, 'member_6', 'MEMBER', NOW(), FALSE, TRUE),
(10102, 'member_7', 'MEMBER', NOW(), FALSE, TRUE),
(10102, 'member_8', 'MEMBER', NOW(), FALSE, TRUE),
(10102, 'member_100', 'MEMBER', NOW(), FALSE, TRUE),
(10102, 'member_10', 'MEMBER', NOW(), FALSE, TRUE);

-- 10103 채팅방
INSERT INTO chat_entrance (chatroom_id, chatroom_member_id, chatroom_member_type, chatroom_entered_time, kicked, activated) VALUES
(10103, 'member_2', 'MEMBER', NOW(), FALSE, TRUE),
(10103, 'member_3', 'MEMBER', NOW(), FALSE, TRUE),
(10103, 'member_4', 'MEMBER', NOW(), FALSE, TRUE),
(10103, 'member_5', 'MEMBER', NOW(), FALSE, TRUE),
(10103, 'member_6', 'MEMBER', NOW(), FALSE, TRUE),
(10103, 'member_7', 'MEMBER', NOW(), FALSE, TRUE),
(10103, 'member_8', 'MEMBER', NOW(), FALSE, TRUE),
(10103, 'member_100', 'MEMBER', NOW(), FALSE, TRUE),
(10103, 'member_10', 'MEMBER', NOW(), FALSE, TRUE);

-- 10104 채팅방
INSERT INTO chat_entrance (chatroom_id, chatroom_member_id, chatroom_member_type, chatroom_entered_time, kicked, activated) VALUES
(10104, 'member_2', 'MEMBER', NOW(), FALSE, TRUE),
(10104, 'member_3', 'MEMBER', NOW(), FALSE, TRUE),
(10104, 'member_4', 'MEMBER', NOW(), FALSE, TRUE),
(10104, 'member_5', 'MEMBER', NOW(), FALSE, TRUE),
(10104, 'member_6', 'MEMBER', NOW(), FALSE, TRUE),
(10104, 'member_7', 'MEMBER', NOW(), FALSE, TRUE),
(10104, 'member_8', 'MEMBER', NOW(), FALSE, TRUE),
(10104, 'member_100', 'MEMBER', NOW(), FALSE, TRUE),
(10104, 'member_10', 'MEMBER', NOW(), FALSE, TRUE);

##95이상 activated가 false 되어있는데 꼭 그런 것은 아님!(그럴 때도 있지만)
UPDATE feed_attachment SET blurred_file_url = NULL WHERE attachment_id=10096;
UPDATE feed_attachment SET blurred_file_url = NULL WHERE attachment_id=10098;
UPDATE feed SET building_id = NULL WHERE feed_category = 'NOTICE';
INSERT INTO member_relationship(member_relationship_id,from_id,to_id,relationship_type,activated) VALUES
(10100,'member_1','member_3','BLOCK',1);
INSERT INTO member_relationship(from_id,to_id,relationship_type,activated) VALUES
('member_1','member_15','BLOCK',1);
INSERT INTO member_relationship (from_id, to_id, relationship_type, activated)
VALUES
 ('member_1', 'member_50', 'FOLLOW', true),
 ('member_1', 'member_51', 'FOLLOW', true),
 ('member_1', 'member_52', 'FOLLOW', true),
 ('member_1', 'member_53', 'FOLLOW', true),
 ('member_1', 'member_54', 'FOLLOW', true),
 ('member_1', 'member_55', 'FOLLOW', true),
 ('member_1', 'member_56', 'FOLLOW', true),
 ('member_1', 'member_57', 'FOLLOW', true),
 ('member_1', 'member_58', 'FOLLOW', true),
 ('member_1', 'member_59', 'FOLLOW', true),
 ('member_1', 'member_60', 'FOLLOW', true),
 ('member_1', 'member_61', 'FOLLOW', true),
 ('member_1', 'member_62', 'FOLLOW', true),
 ('member_20', 'member_1', 'FOLLOW', true),
 ('member_21', 'member_1', 'FOLLOW', true),
 ('member_22', 'member_1', 'FOLLOW', true),
 ('member_23', 'member_1', 'FOLLOW', true),
 ('member_24', 'member_1', 'FOLLOW', true),
 ('member_25', 'member_1', 'FOLLOW', true),
 ('member_26', 'member_1', 'FOLLOW', true),
 ('member_27', 'member_1', 'FOLLOW', true),
 ('member_28', 'member_1', 'FOLLOW', true),
 ('member_29', 'member_1', 'FOLLOW', true),
 ('member_1', 'member_63', 'FOLLOW', true),
 ('member_1', 'member_64', 'FOLLOW', true),
 ('member_1', 'member_65', 'FOLLOW', true),
 ('member_1', 'member_66', 'FOLLOW', true),
 ('member_1', 'member_67', 'FOLLOW', true),
 ('member_1', 'member_68', 'FOLLOW', true),
 ('member_1', 'member_69', 'FOLLOW', true),
 ('member_1', 'member_70', 'FOLLOW', true),
 ('member_1', 'member_71', 'FOLLOW', true),
 ('member_1', 'member_72', 'FOLLOW', true),
 ('member_1', 'member_73', 'FOLLOW', true),
 ('member_1', 'member_74', 'FOLLOW', true),
 ('member_1', 'member_75', 'FOLLOW', true),
 ('member_1', 'member_76', 'FOLLOW', true),
 ('member_1', 'member_77', 'FOLLOW', true),
 ('member_1', 'member_78', 'FOLLOW', true),
 ('member_1', 'member_79', 'FOLLOW', true),
 ('member_1', 'member_80', 'FOLLOW', true);


### 1. 건물 합치기 기능을 위해 필요한 쿼리(임시)


### 관리자 계정 추가
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
            'admin_1' ,
            'ADMIN',
            '나는관리자',
            'noon0716',
            '010-1111-1111',
            '0001-01-01 01:01:01',
            'https://kr.object.ncloudstorage.com/noon-images/Image8.jpg',
            NULL,
            0,
            FALSE,
            'PUBLIC',
            'PUBLIC',
            'PUBLIC',
            TRUE
        );

### 프로필이 활성화된 건물 추가
UPDATE building SET profile_activated = 1 WHERE building_id = 10099;


### 피드 첨부파일 수정(Object Storage로 url을 실제로 대입), 일단 10개만 테스트
DELETE FROM feed_attachment; 
INSERT INTO feed_attachment (attachment_id, feed_id, file_url, file_type, blurred_file_url, activated) VALUES (10000, 10000, 'https://kr.object.ncloudstorage.com/noon-images/Image12.jpg', 'PHOTO', NULL, 1), (10001, 10001, 'https://kr.object.ncloudstorage.com/noon-images/Image7.jpg', 'PHOTO', NULL, 1), (10002, 10002, 'https://kr.object.ncloudstorage.com/noon-images/Image3.jpg', 'PHOTO', NULL, 1), (10003, 10003, 'https://kr.object.ncloudstorage.com/noon-images/Image1.jpg', 'PHOTO', NULL, 1), (10004, 10004, 'https://kr.object.ncloudstorage.com/noon-images/Image5.jpg', 'PHOTO', NULL, 1),(10005, 10005, 'https://kr.object.ncloudstorage.com/noon-images/Imgae6.jpg', 'PHOTO', NULL, 1),(10006, 10006, 'https://kr.object.ncloudstorage.com/noon-images/Image2.jpg', 'PHOTO', NULL, 1),(10007, 10007, 'https://kr.object.ncloudstorage.com/noon-images/Image8.jpg', 'PHOTO', NULL, 1),(10008, 10008, 'https://kr.object.ncloudstorage.com/noon-images/Image9.jpg', 'PHOTO', NULL, 1),(10009, 10009, 'https://kr.object.ncloudstorage.com/noon-images/Image10.jpg', 'PHOTO', NULL, 1),(10010, 10010, 'https://kr.object.ncloudstorage.com/noon-images/Image11.jpg', 'PHOTO', NULL, 1),(10011, 10011, 'https://kr.object.ncloudstorage.com/noon-images/Image4.jpg', 'PHOTO', NULL, 1);
SELECT * FROM feed_attachment;


### 건물 구독 목록 데이터 추가
INSERT INTO zzim (member_id, feed_id, building_id, subscription_provider_id, zzim_type, activated) 
VALUES
("member_5", null, 10000, null, "SUBSCRIPTION", 1),
("member_5", null, 10001, null, "SUBSCRIPTION", 1),
("member_5", null, 10002, null, "SUBSCRIPTION", 1),
("member_5", null, 10003, null, "SUBSCRIPTION", 1),
("member_5", null, 10004, null, "SUBSCRIPTION", 1),
("member_5", null, 10005, null, "SUBSCRIPTION", 1),
("member_5", null, 10006, null, "SUBSCRIPTION", 1),
("member_5", null, 10007, null, "SUBSCRIPTION", 1),
("member_5", null, 10008, null, "SUBSCRIPTION", 1),
("member_5", null, 10009, null, "SUBSCRIPTION", 1),
("member_5", null, 10010, null, "SUBSCRIPTION", 1),
("member_5", null, 10011, null, "SUBSCRIPTION", 1),
("member_5", null, 10012, null, "SUBSCRIPTION", 1),
("member_5", null, 10013, null, "SUBSCRIPTION", 1),
("member_5", null, 10014, null, "SUBSCRIPTION", 1),
("member_5", null, 10015, null, "SUBSCRIPTION", 1),
("member_5", null, 10016, null, "SUBSCRIPTION", 1),
("member_5", null, 10017, null, "SUBSCRIPTION", 1),
("member_5", null, 10018, null, "SUBSCRIPTION", 1),
("member_5", null, 10019, null, "SUBSCRIPTION", 1),
("member_5", null, 10020, null, "SUBSCRIPTION", 1),
("member_5", null, 10021, null, "SUBSCRIPTION", 1),
("member_5", null, 10022, null, "SUBSCRIPTION", 1),
("member_5", null, 10023, null, "SUBSCRIPTION", 1),
("member_5", null, 10024, null, "SUBSCRIPTION", 1),
("member_5", null, 10025, null, "SUBSCRIPTION", 1);
INSERT INTO zzim (member_id, feed_id, building_id, subscription_provider_id, zzim_type, activated) 
VALUES
("member_4", null, 10000, null, "SUBSCRIPTION", 1),
("member_4", null, 10001, null, "SUBSCRIPTION", 1),
("member_4", null, 10002, null, "SUBSCRIPTION", 1),
("member_4", null, 10003, null, "SUBSCRIPTION", 1),
("member_4", null, 10004, null, "SUBSCRIPTION", 1),
("member_4", null, 10005, null, "SUBSCRIPTION", 1),
("member_4", null, 10006, null, "SUBSCRIPTION", 1),
("member_4", null, 10007, null, "SUBSCRIPTION", 1),
("member_4", null, 10008, null, "SUBSCRIPTION", 1),
("member_4", null, 10009, null, "SUBSCRIPTION", 1),
("member_4", null, 10010, null, "SUBSCRIPTION", 1),
("member_4", null, 10011, null, "SUBSCRIPTION", 1),
("member_4", null, 10012, null, "SUBSCRIPTION", 1),
("member_4", null, 10013, null, "SUBSCRIPTION", 1),
("member_4", null, 10014, null, "SUBSCRIPTION", 1),
("member_4", null, 10015, null, "SUBSCRIPTION", 1),
("member_4", null, 10016, null, "SUBSCRIPTION", 1),
("member_4", null, 10017, null, "SUBSCRIPTION", 1),
("member_4", null, 10018, null, "SUBSCRIPTION", 1),
("member_4", null, 10019, null, "SUBSCRIPTION", 1),
("member_4", null, 10020, null, "SUBSCRIPTION", 1),
("member_4", null, 10021, null, "SUBSCRIPTION", 1),
("member_4", null, 10022, null, "SUBSCRIPTION", 1),
("member_4", null, 10023, null, "SUBSCRIPTION", 1),
("member_4", null, 10024, null, "SUBSCRIPTION", 1),
("member_4", null, 10025, null, "SUBSCRIPTION", 1);
INSERT INTO zzim (member_id, feed_id, building_id, subscription_provider_id, zzim_type, activated) 
VALUES
("member_3", null, 10000, null, "SUBSCRIPTION", 1),
("member_3", null, 10001, null, "SUBSCRIPTION", 1),
("member_3", null, 10002, null, "SUBSCRIPTION", 1),
("member_3", null, 10003, null, "SUBSCRIPTION", 1),
("member_3", null, 10004, null, "SUBSCRIPTION", 1),
("member_3", null, 10005, null, "SUBSCRIPTION", 1),
("member_3", null, 10006, null, "SUBSCRIPTION", 1),
("member_3", null, 10007, null, "SUBSCRIPTION", 1),
("member_3", null, 10008, null, "SUBSCRIPTION", 1),
("member_3", null, 10009, null, "SUBSCRIPTION", 1),
("member_3", null, 10010, null, "SUBSCRIPTION", 1),
("member_3", null, 10011, null, "SUBSCRIPTION", 1),
("member_3", null, 10012, null, "SUBSCRIPTION", 1),
("member_3", null, 10013, null, "SUBSCRIPTION", 1),
("member_3", null, 10014, null, "SUBSCRIPTION", 1),
("member_3", null, 10015, null, "SUBSCRIPTION", 1),
("member_3", null, 10016, null, "SUBSCRIPTION", 1),
("member_3", null, 10017, null, "SUBSCRIPTION", 1),
("member_3", null, 10018, null, "SUBSCRIPTION", 1),
("member_3", null, 10019, null, "SUBSCRIPTION", 1),
("member_3", null, 10020, null, "SUBSCRIPTION", 1),
("member_3", null, 10021, null, "SUBSCRIPTION", 1),
("member_3", null, 10022, null, "SUBSCRIPTION", 1),
("member_3", null, 10023, null, "SUBSCRIPTION", 1),
("member_3", null, 10024, null, "SUBSCRIPTION", 1),
("member_3", null, 10025, null, "SUBSCRIPTION", 1);
INSERT INTO zzim (member_id, feed_id, building_id, subscription_provider_id, zzim_type, activated) 
VALUES
("member_2", null, 10000, null, "SUBSCRIPTION", 1),
("member_2", null, 10001, null, "SUBSCRIPTION", 1),
("member_2", null, 10002, null, "SUBSCRIPTION", 1),
("member_2", null, 10003, null, "SUBSCRIPTION", 1),
("member_2", null, 10004, null, "SUBSCRIPTION", 1),
("member_2", null, 10005, null, "SUBSCRIPTION", 1),
("member_2", null, 10006, null, "SUBSCRIPTION", 1),
("member_2", null, 10007, null, "SUBSCRIPTION", 1),
("member_2", null, 10008, null, "SUBSCRIPTION", 1),
("member_2", null, 10009, null, "SUBSCRIPTION", 1),
("member_2", null, 10010, null, "SUBSCRIPTION", 1),
("member_2", null, 10011, null, "SUBSCRIPTION", 1),
("member_2", null, 10012, null, "SUBSCRIPTION", 1),
("member_2", null, 10013, null, "SUBSCRIPTION", 1),
("member_2", null, 10014, null, "SUBSCRIPTION", 1),
("member_2", null, 10015, null, "SUBSCRIPTION", 1),
("member_2", null, 10016, null, "SUBSCRIPTION", 1),
("member_2", null, 10017, null, "SUBSCRIPTION", 1),
("member_2", null, 10018, null, "SUBSCRIPTION", 1),
("member_2", null, 10019, null, "SUBSCRIPTION", 1),
("member_2", null, 10020, null, "SUBSCRIPTION", 1),
("member_2", null, 10021, null, "SUBSCRIPTION", 1),
("member_2", null, 10022, null, "SUBSCRIPTION", 1),
("member_2", null, 10023, null, "SUBSCRIPTION", 1),
("member_2", null, 10024, null, "SUBSCRIPTION", 1),
("member_2", null, 10025, null, "SUBSCRIPTION", 1);


INSERT INTO zzim (member_id, feed_id, building_id, subscription_provider_id, zzim_type, activated) 
VALUES
("member_70", null, 10089, "member_70", "SUBSCRIPTION", 1),
("member_71", null, 10089, "member_71", "SUBSCRIPTION", 1),
("member_72",null,10089,"member_70","SUBSCRIPTION",1),
("member_73",null,10089,"member_70","SUBSCRIPTION",1),
("member_74",null,10089,"member_70","SUBSCRIPTION",1),
("member_75",null,10089,"member_70","SUBSCRIPTION",1),
("member_76",null,10089,"member_70","SUBSCRIPTION",1),
("member_77",null,10089,"member_70","SUBSCRIPTION",1);


### 건물별 피드 데이터 추가
INSERT INTO feed (writer_id, building_id, main_activated, public_range, title, feed_text, view_cnt, written_time, feed_category, modified, activated) VALUES
('member_1', 10089, 1, 'PUBLIC', 'Title_10100', 'Feed text for feed 10100', 100, CURRENT_TIMESTAMP, 'GENERAL', 0, 1),
('member_2', 10089, 0, 'PUBLIC', 'Title_10101', 'Feed text for feed 10101', 100, CURRENT_TIMESTAMP, 'GENERAL', 0, 1),
('member_3', 10089, 0, 'PUBLIC', 'Title_10102', 'Feed text for feed 10102', 100, CURRENT_TIMESTAMP, 'GENERAL', 0, 1),
('member_4', 10089, 0, 'PUBLIC', 'Title_10103', 'Feed text for feed 10103', 100, CURRENT_TIMESTAMP, 'GENERAL', 0, 1),
('member_5', 10089, 0, 'PUBLIC', 'Title_10104', 'Feed text for feed 10104', 100, CURRENT_TIMESTAMP, 'GENERAL', 0, 1);



### 피드 요약을 위한 피드 데이터 추가
INSERT into feed ( writer_id, building_id, main_activated, public_range, title, feed_text, view_cnt, written_time, feed_category, modified, activated) VALUES
('member_78', 10089, 0, 'PUBLIC', 'Title_101', '이 건물 1층 보배반점이 맛있어요 다들 가봐요', 0, '2024-06-05 10:39:38', 'GENERAL', 0, 1),
('member_22', 10089, 0, 'PUBLIC', 'Title_102', '크림짬뽕이 짱이에요 그리고 커피도 공짜로 줍니다ㅎ', 0, '2024-06-05 10:39:38', 'GENERAL', 0, 1),
('member_13', 10089, 0, 'PUBLIC', 'Title_103', '근데 짬뽕14000원은 너무 비싸지 않나?', 0, '2024-06-05 10:39:38', 'GENERAL', 0, 1),
('member_67', 10089, 0, 'PUBLIC', 'Title_104', '김철수 왔다감', 0, '2024-06-05 10:39:38', 'GENERAL', 0, 1),
('member_39', 10089, 0, 'PUBLIC', 'Title_105', '근처에 커피 잘 내리는 곳 추천좀', 0, '2024-06-05 10:39:38', 'GENERAL', 0, 1),
('member_56', 10089, 0, 'PUBLIC', 'Title_106', '이거 뭐야', 0, '2024-06-05 10:39:38', 'GENERAL', 0, 1),
('member_81', 10089, 0, 'PUBLIC', 'Title_107', '헤헿헤헿', 0, '2024-06-05 10:39:38', 'GENERAL', 0, 1),
('member_23', 10089, 0, 'PUBLIC', 'Title_108', '다들 뭐해요', 0, '2024-06-05 10:39:38', 'GENERAL', 0, 1),
('member_45', 10089, 0, 'PUBLIC', 'Title_100', '보배반점 맛있어요 특히 크림짬뽕이 맛있음', 0, '2024-06-05 10:39:38', 'GENERAL', 0, 1);

### 건물의 채팅방 추가
INSERT INTO chatroom (chatroom_creator_id, building_id, chatroom_name, chatroom_type, chatroom_dajung_temp_min, activated) VALUES
('member_1', 10089, '채팅방 1', 'GROUP_CHATTING', 0, TRUE),
('member_1', 10089, '채팅방 2', 'GROUP_CHATTING', 0, TRUE),
('member_1', 10089, '채팅방 3', 'GROUP_CHATTING', 0, TRUE),
('member_1', 10089, '채팅방 4', 'GROUP_CHATTING', 0, TRUE),
('member_1', 10089, '채팅방 5', 'GROUP_CHATTING', 0, TRUE);


### 프로필이 활성화 되어있는 건물 추가
UPDATE building
SET profile_activated = 1
WHERE building_id BETWEEN 10050 AND 10099;

SELECT * FROM members;
SELECT * FROM building;
SELECT * FROM zzim;
SELECT * FROM feed;
SELECT * FROM feed_attachment;
SELECT * FROM tag;
SELECT * FROM tag_feed;
SELECT * FROM feed_comment;
SELECT * FROM notification;
SELECT * FROM report;
SELECT * FROM member_relationship;
SELECT * FROM chat_apply;
SELECT * FROM chatroom;
SELECT * FROM chat_entrance;
