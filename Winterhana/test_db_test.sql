use test_db;

SELECT * FROM members;
SELECT * FROM building;
SELECT * FROM feed;
SELECT * FROM zzim;
SELECT * FROM feed_attachment;
SELECT * FROM tag;
SELECT * FROM tag_feed;
SELECT * FROM feed_comment;

# member_1이 좋아요를 누른 피드의 목록
SELECT * FROM zzim WHERE zzim_type = 'LIKE' AND member_id = 'member_1';
SELECT f.* FROM feed f INNER JOIN zzim z ON f.feed_id = z.feed_id WHERE z.zzim_type = 'LIKE' AND z.member_id = 'member_1' AND z.activated = true AND f.activated = true;
# JPQL
# SELECT f FROM Feed f INNER JOIN Zzim z ON f.feedId = z.feed.feedId WHERE z.zzimType = 'LIKE' AND f.writer.memberId = :writerId AND f.activated = true

# member_1이 building_id = 10000에서 좋아요를 누른 피드의 목록
SELECT f.feed_id FROM feed f INNER JOIN zzim z ON f.feed_id = z.feed_id WHERE z.zzim_type = 'LIKE' AND f.building_id = 10001 AND z.member_id = 'member_3' AND z.activated = true AND f.activated = true;

# 유저 이름으로 정렬함
SELECT f.* FROM feed f WHERE f.building_id = 10001 AND f.activated = true;

SELECT f.*
FROM feed f
LEFT JOIN (
    SELECT DISTINCT z.feed_id 
    FROM zzim z 
    WHERE z.zzim_type = 'LIKE' 
      AND z.member_id = 'member_10' 
      AND z.activated = true
) liked_feeds
ON f.feed_id = liked_feeds.feed_id
WHERE f.building_id = 10001 
  AND f.activated = true
ORDER BY liked_feeds.feed_id IS NULL, f.written_time;


# member_1이 북마크를 한 피드의 목록
SELECT * FROM zzim WHERE zzim_type = 'BOOKMARK' AND member_id = 'member_1';
SELECT f.* FROM feed f INNER JOIN zzim z ON f.feed_id = z.feed_id WHERE z.zzim_type = 'BOOKMARK' AND z.member_id = 'member_1' AND z.activated = true AND f.activated = true;
# JPQL
# SELECT f FROM Feed f INNER JOIN Zzim z ON f.feedId = z.feedId WHERE z.zzimType = 'BOOKMARK' AND f.writer.memberId = :#{writerId} AND f.activated = true

# member_1이 구독한 건물에 대한 피드 목록
SELECT * FROM zzim WHERE zzim_type = 'SUBSCRIPTION' AND member_id = 'member_1';
SELECT f.* FROM feed f INNER JOIN zzim z ON f.building_id = z.building_id WHERE z.zzim_type = 'SUBSCRIPTION' AND z.member_id = 'member_1' AND z.activated = true AND f.activated = true;
# JPQL
# SELECT f FROM Feed f INNER JOIN Zzim z ON f.building.buildingId = z.buildingId WHERE z.zzimType = 'SUBSCRIPTION' AND z.memberId = :#{#member.memberId} AND f.activated = true AND z.activated = true

# zzim 내의 LIKE/BOOKMARK한 사람 가져오기
SELECT * FROM zzim WHERE feed_id = 10000 AND zzim_type = 'LIKE'; # 피드에 좋아요 누른 사람
SELECT * FROM zzim WHERE feed_id = 10000 AND member_id = 'member_1' AND zzim_type = 'LIKE';
SELECT * FROM zzim WHERE feed_id = 10001 AND member_id = 'member_1' AND zzim_type = 'LIKE';
SELECT * FROM zzim WHERE feed_id = 10001 AND member_id = 'member_1' AND zzim_type = 'BOOKMARK';

# Feed 내에 좋아요를 누른 회원의 목록
SELECT m.* FROM members m INNER JOIN zzim z ON m.member_id = z.member_id WHERE z.feed_id = 10000 and z.zzim_type = 'LIKE'; # 피드에 좋아요 누른 사람 상세 정보

# 태그 내용 가져오기
SELECT t.*
FROM tag_feed f
	INNER JOIN tag t ON f.tag_id = t.tag_id
WHERE feed_id = 10000;

SELECT t.*
FROM tag t
INNER JOIN tag_feed f ON f.tag_id = t.tag_id
WHERE feed_id = 10000;

SELECT * FROM feed WHERE building_id = 10000 AND activated = true;

# 건물별 조회수가 높은 게시물 상위 5개
SELECT feed_id, title, view_cnt from feed  WHERE building_id = 10000 ORDER BY view_cnt desc limit 5;

# 태그별 게시물 수 상위 5개
SELECT r.tag_text, COUNT(*) as count FROM (SELECT t.tag_text FROM tag t INNER JOIN tag_feed tf ON t.tag_id = tf.tag_id INNER JOIN feed f ON tf.feed_id = f.feed_id) r GROUP BY r.tag_text limit 5;

# 인기도가 높은 게시물 상위 5개
# 1. 피드별 좋아요 개수
SELECT f.feed_id, f.building_id, z.zzim_type, COUNT(*) FROM feed f INNER JOIN zzim z ON f.feed_id = z.feed_id WHERE z.zzim_type = 'LIKE' AND f.building_id = 10003 GROUP BY f.feed_id;

# 2. 북마크별 좋아요 개수
SELECT f.feed_id, f.building_id, z.zzim_type, COUNT(*) FROM feed f INNER JOIN zzim z ON f.feed_id = z.feed_id WHERE z.zzim_type = 'BOOKMARK' AND f.building_id = 10003 GROUP BY f.feed_id;

# 3. 피드별 조회수 개수
SELECT feed_id, view_cnt FROM feed;

# 4. 종합
SELECT f.feed_id, f.title, f.writer_id, m.nickname, f.view_cnt + 3 * COALESCE(like_count, 0) + 5 * COALESCE(bookmark_count, 0) AS popularity
FROM feed f
LEFT JOIN (
	SELECT f.feed_id, COUNT(*) like_count FROM feed f INNER JOIN zzim z ON f.feed_id = z.feed_id WHERE z.zzim_type = 'LIKE' GROUP BY f.feed_id
) likes ON f.feed_id = likes.feed_id
LEFT JOIN (
	SELECT f.feed_id, COUNT(*) bookmark_count FROM feed f INNER JOIN zzim z ON f.feed_id = z.feed_id WHERE z.zzim_type = 'BOOKMARK' GROUP BY f.feed_id
) bookmarks ON f.feed_id = bookmarks.feed_id
LEFT JOIN
	members m ON f.writer_id = m.member_id
WHERE f.building_id = 10003
ORDER BY popularity DESC
LIMIT 5;

SELECT MIN(view_cnt), MAX(view_cnt) FROM feed;

# 유저가 어떤 태그의 글에 좋아요를 눌렀는지 확인한다. + 값 스케일링
SELECT z.member_id, r.tag_text, COUNT(*) as tag_count FROM zzim z
INNER JOIN
(SELECT f.feed_id, t.*
FROM tag t
INNER JOIN tag_feed f ON f.tag_id = t.tag_id) r
ON r.feed_id = z.feed_id
WHERE z.zzim_type = 'LIKE'
GROUP BY r.tag_text, z.member_id;

SELECT * FROM zzim WHERE feed_id = 10010 AND member_id = "member_1";
SELECT * FROM zzim WHERE zzim_id = 11474;
SELECT * FROM tag_feed;

SELECT * FROM feed WHERE title LIKE '%title%' OR feed_text LIKE '%title%';

delete from Feed WHERE feed_id = 10070;

# 전체 피드를 가져와서 인기도 순서대로 나열
SELECT f.*, m.nickname, b.building_name, f.view_cnt + 3 * COALESCE(like_count, 0) + 5 * COALESCE(bookmark_count, 0) AS popularity
FROM feed f
LEFT JOIN (
	SELECT f.feed_id, COUNT(*) like_count FROM feed f INNER JOIN zzim z ON f.feed_id = z.feed_id WHERE z.zzim_type = 'LIKE' GROUP BY f.feed_id
) likes ON f.feed_id = likes.feed_id
LEFT JOIN (
	SELECT f.feed_id, COUNT(*) bookmark_count FROM feed f INNER JOIN zzim z ON f.feed_id = z.feed_id WHERE z.zzim_type = 'BOOKMARK' GROUP BY f.feed_id
) bookmarks ON f.feed_id = bookmarks.feed_id
LEFT JOIN
	members m ON f.writer_id = m.member_id
LEFT JOIN
	building b ON f.building_id = b.building_id 
ORDER BY popularity DESC;

SELECT count(feed_id) FROM zzim WHERE feed_id = 10001 AND zzim_type = 'LIKE'; 

# 피드의 인기도 가지고 오기
