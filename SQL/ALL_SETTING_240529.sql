###############################################################프로시저##############################################################
#테이블 삭제 프로시저
CALL drop_tb('building', 'mydb');
#모든 테이블 삭제 프로시저
CALL drop_all_tb('mydb');
#왜래키 조회 프로시저
CALL get_all_foreign_keys('mydb');
#모든 왜래키 삭제 프로시저
CALL drop_all_foreign_keys('mydb');
################################################################# 세팅 관련 명령어 ##############################################################
# 업데이트 권한 주기
SET SQL_SAFE_UPDATES = 0;
# 디비 보기
SELECT DATABASE();
# 디비 사용
USE mydb;
# 테이블 보기
show tables;
# 버전 검사
SELECT VERSION();
# 키워드인지 검사
SELECT * FROM information_schema.keywords WHERE word = 'title';
# CREATE문 확인
DESCRIBE building;
SHOW CREATE TABLE building;-- OK
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
DROP PROCEDURE drop_tb;
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

-- 모든 테이블 삭제 프로시저 호출 예제
CALL drop_all_tb('mydb');

-- 필요에 따라 프로시저 삭제
DROP PROCEDURE IF EXISTS drop_all_tb;
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
#프로시저 삭제 (원하는 경우)
DROP PROCEDURE get_all_foreign_keys;
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